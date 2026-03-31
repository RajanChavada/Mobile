#!/usr/bin/env python3
"""
Generate seed venues for Supabase from Brave Search + Google Places Text Search.

Outputs:
  - CSV suitable for Supabase Table Editor import
  - SQL upsert script for public.venues

Required env:
  - BRAVE_SEARCH_API
  - GOOGLE_MAPS_API

Usage:
  python3 scripts/seed_venues.py --city "Toronto" --max-results 60
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set


BRAVE_ENDPOINT = "https://api.search.brave.com/res/v1/web/search"
GOOGLE_TEXT_SEARCH_ENDPOINT = "https://maps.googleapis.com/maps/api/place/textsearch/json"


@dataclass
class VenueCandidate:
    place_id: str
    name: str
    address: str
    city: str
    latitude: float
    longitude: float
    category_votes: Set[str] = field(default_factory=set)
    user_ratings_total: int = 0
    rating: float = 0.0

    @property
    def category(self) -> str:
        votes = self.category_votes
        if "matcha" in votes and "coffee" in votes:
            return "both"
        if "matcha" in votes:
            return "matcha"
        if "coffee" in votes:
            return "coffee"
        return "other"


def load_env(dotenv_paths: List[Path]) -> Dict[str, str]:
    data = dict(os.environ)
    for dotenv_path in dotenv_paths:
        if not dotenv_path.exists():
            continue
        for raw in dotenv_path.read_text().splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            data.setdefault(key, value)
    return data


def http_get_json(url: str, headers: Optional[Dict[str, str]] = None) -> Dict:
    req = urllib.request.Request(url, headers=headers or {})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def normalize_name(value: str) -> str:
    name = re.sub(r"\s+", " ", value).strip()
    name = re.sub(r"\s+\|\s+.*$", "", name)
    name = re.sub(r"\s+-\s+.*$", "", name)
    return name


def classify_from_text(text: str) -> Optional[str]:
    lowered = text.lower()
    has_matcha = "matcha" in lowered
    has_coffee = any(k in lowered for k in ("coffee", "espresso", "cafe", "caf\u00e9", "roaster"))
    if has_matcha and has_coffee:
        return "both"
    if has_matcha:
        return "matcha"
    if has_coffee:
        return "coffee"
    return None


def brave_seed_names(api_key: str, city: str, count: int) -> List[str]:
    queries = [
        f"best coffee shops in {city}",
        f"best matcha in {city}",
        f"popular cafes in {city}",
    ]
    names: List[str] = []
    for q in queries:
        params = urllib.parse.urlencode({"q": q, "count": count})
        url = f"{BRAVE_ENDPOINT}?{params}"
        payload = http_get_json(url, headers={"X-Subscription-Token": api_key})
        for item in payload.get("web", {}).get("results", []):
            title = normalize_name(item.get("title", ""))
            if title:
                names.append(title)
        time.sleep(0.2)

    seen = set()
    deduped = []
    for n in names:
        k = n.lower()
        if k not in seen:
            seen.add(k)
            deduped.append(n)
    return deduped


def google_text_search(api_key: str, query: str, pages: int = 2) -> List[Dict]:
    results: List[Dict] = []
    next_page_token = None
    for _ in range(pages):
        params = {"query": query, "key": api_key}
        if next_page_token:
            params = {"pagetoken": next_page_token, "key": api_key}
        url = f"{GOOGLE_TEXT_SEARCH_ENDPOINT}?{urllib.parse.urlencode(params)}"
        payload = http_get_json(url)
        status = payload.get("status")
        if status not in ("OK", "ZERO_RESULTS"):
            if status == "INVALID_REQUEST" and next_page_token:
                time.sleep(2.0)
                continue
            err = payload.get("error_message", "No error_message provided")
            print(f"[google] query='{query}' status={status} error='{err}'", file=sys.stderr)
            break
        results.extend(payload.get("results", []))
        next_page_token = payload.get("next_page_token")
        if not next_page_token:
            break
        time.sleep(2.0)  # required before pagetoken becomes valid
    return results


def infer_category(place: Dict, query_category: str) -> str:
    text = f"{place.get('name', '')} {' '.join(place.get('types', []))}"
    inferred = classify_from_text(text)
    if inferred in ("coffee", "matcha"):
        return inferred
    if inferred == "both":
        return "both"
    return query_category


def collect_candidates(brave_key: Optional[str], google_key: str, city: str) -> Dict[str, VenueCandidate]:
    candidates: Dict[str, VenueCandidate] = {}

    category_queries = {
        "coffee": [
            f"specialty coffee {city}",
            f"best espresso {city}",
            f"coffee shop {city}",
        ],
        "matcha": [
            f"matcha cafe {city}",
            f"best matcha latte {city}",
            f"tea bar matcha {city}",
        ],
    }

    for category, queries in category_queries.items():
        for q in queries:
            for place in google_text_search(google_key, q, pages=2):
                place_id = place.get("place_id")
                geometry = place.get("geometry", {}).get("location", {})
                if not place_id or "lat" not in geometry or "lng" not in geometry:
                    continue
                cat = infer_category(place, category)
                existing = candidates.get(place_id)
                if existing is None:
                    existing = VenueCandidate(
                        place_id=place_id,
                        name=place.get("name", "").strip(),
                        address=place.get("formatted_address", "").strip(),
                        city=city,
                        latitude=float(geometry["lat"]),
                        longitude=float(geometry["lng"]),
                        user_ratings_total=int(place.get("user_ratings_total", 0) or 0),
                        rating=float(place.get("rating", 0.0) or 0.0),
                    )
                    candidates[place_id] = existing
                existing.category_votes.add(cat)
            time.sleep(0.2)

    if brave_key:
        brave_names = brave_seed_names(brave_key, city, count=10)
        for name in brave_names:
            places = google_text_search(google_key, f"{name} {city}", pages=1)
            if not places:
                continue
            place = places[0]
            place_id = place.get("place_id")
            geometry = place.get("geometry", {}).get("location", {})
            if not place_id or "lat" not in geometry or "lng" not in geometry:
                continue

            category = infer_category(place, query_category=classify_from_text(name) or "other")
            existing = candidates.get(place_id)
            if existing is None:
                existing = VenueCandidate(
                    place_id=place_id,
                    name=place.get("name", "").strip(),
                    address=place.get("formatted_address", "").strip(),
                    city=city,
                    latitude=float(geometry["lat"]),
                    longitude=float(geometry["lng"]),
                    user_ratings_total=int(place.get("user_ratings_total", 0) or 0),
                    rating=float(place.get("rating", 0.0) or 0.0),
                )
                candidates[place_id] = existing
            existing.category_votes.add(category)
    else:
        print("[seed] BRAVE_SEARCH_API not set; continuing with Google Places only.", file=sys.stderr)

    return candidates


def write_csv(path: Path, records: Iterable[VenueCandidate]) -> None:
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "place_id",
                "name",
                "address",
                "city",
                "latitude",
                "longitude",
                "category",
                "average_rating",
                "review_count",
                "is_active",
            ],
        )
        writer.writeheader()
        for r in records:
            writer.writerow(
                {
                    "place_id": r.place_id,
                    "name": r.name,
                    "address": r.address,
                    "city": r.city,
                    "latitude": r.latitude,
                    "longitude": r.longitude,
                    "category": r.category,
                    "average_rating": 0.0,
                    "review_count": 0,
                    "is_active": "true",
                }
            )


def sql_escape(value: str) -> str:
    return value.replace("'", "''")


def write_sql(path: Path, records: Iterable[VenueCandidate]) -> None:
    rows = []
    for r in records:
        rows.append(
            "('{place_id}','{name}','{address}','{city}',{lat},{lng},'{category}',0.0,0,true)".format(
                place_id=sql_escape(r.place_id),
                name=sql_escape(r.name),
                address=sql_escape(r.address),
                city=sql_escape(r.city),
                lat=r.latitude,
                lng=r.longitude,
                category=sql_escape(r.category),
            )
        )

    sql = """insert into public.venues
  (place_id, name, address, city, latitude, longitude, category, average_rating, review_count, is_active)
values
  {rows}
on conflict (place_id) do update
set
  name = excluded.name,
  address = excluded.address,
  city = excluded.city,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  category = excluded.category,
  is_active = true;""".format(rows=",\n  ".join(rows))

    path.write_text(sql + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Seed popular coffee/matcha venues.")
    p.add_argument("--city", default="Toronto", help="City to seed")
    p.add_argument("--max-results", type=int, default=60, help="Max deduped venues to output")
    p.add_argument(
        "--output-dir",
        default="scripts/output",
        help="Directory for generated CSV/SQL files",
    )
    return p.parse_args()


def main() -> int:
    args = parse_args()
    script_path = Path(__file__).resolve()
    project_root = script_path.parents[1]   # .../Mobile/Steep
    workspace_root = script_path.parents[2] # .../Mobile
    env = load_env([
        workspace_root / ".env",
        project_root / ".env",
    ])

    brave_key = env.get("BRAVE_SEARCH_API")
    google_key = env.get("GOOGLE_MAPS_API")
    if not google_key:
        print("Missing GOOGLE_MAPS_API in env/.env", file=sys.stderr)
        return 1

    candidates = collect_candidates(brave_key, google_key, args.city)
    if not candidates:
        print(
            "No venues found. Check GOOGLE_MAPS_API restrictions: for this script you need a key allowed for Places Web Service (Text Search) calls from your machine/server, not only iOS-app restricted keys.",
            file=sys.stderr,
        )
        return 2

    ranked = sorted(
        candidates.values(),
        key=lambda r: (r.user_ratings_total, r.rating),
        reverse=True,
    )
    selected = ranked[: max(1, args.max_results)]

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    stamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    slug = re.sub(r"[^a-z0-9]+", "_", args.city.lower()).strip("_")

    csv_path = output_dir / f"venues_seed_{slug}_{stamp}.csv"
    sql_path = output_dir / f"venues_seed_{slug}_{stamp}.sql"
    write_csv(csv_path, selected)
    write_sql(sql_path, selected)

    counts = {"coffee": 0, "matcha": 0, "both": 0, "other": 0}
    for r in selected:
        counts[r.category] = counts.get(r.category, 0) + 1

    print(f"Wrote {len(selected)} venues")
    print(f"CSV: {csv_path}")
    print(f"SQL: {sql_path}")
    print("Category counts:", counts)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
