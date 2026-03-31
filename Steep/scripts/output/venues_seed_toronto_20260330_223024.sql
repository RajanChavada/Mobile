insert into public.venues
  (place_id, name, address, city, latitude, longitude, category, average_rating, review_count, is_active)
values
  ('ChIJs09aUcI0K4gR6phtG366G4g','FIKA Cafe','28 Kensington Ave, Toronto, ON M5T 2J9, Canada','Toronto',43.6535775,-79.4004428,'coffee',0.0,0,true)
on conflict (place_id) do update
set
  name = excluded.name,
  address = excluded.address,
  city = excluded.city,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  category = excluded.category,
  is_active = true;
