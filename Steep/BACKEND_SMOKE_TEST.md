# Backend Smoke Test (Supabase)

Use this when the app still shows mock venues or empty map results.

## 1) Confirm app is not in mock mode

In app, if you see this info banner:

`Running in mock mode. Set SUPABASE_URL and SUPABASE_PUBLISHABLE...`

then the app is not reading Supabase config.

Set these in the iOS Run scheme (or xcconfig):

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE`
- `SUPABASE_AUTH_REDIRECT_URL=steep://auth-callback`

## 2) Verify data exists in Supabase

Run in SQL Editor:

```sql
select count(*) as venues_total from public.venues;
select city, count(*) from public.venues group by city order by count(*) desc;
```

If `venues_total` is `0`, re-import seed CSV/SQL.

## 3) Verify RLS + read policy on venues

```sql
alter table public.venues enable row level security;

create policy if not exists "venues_select_public"
on public.venues
for select
to anon, authenticated
using (is_active = true);
```

## 4) Verify app-critical tables do not block map boot

Map can load with only `venues`, but these should also have safe select policies:

- `public.logs`
- `public.profiles`
- `public.passport_stamps`

Example for feed:

```sql
alter table public.logs enable row level security;

create policy if not exists "logs_select_public"
on public.logs
for select
to anon, authenticated
using (is_public = true);
```

## 5) Quick auth callback check

Supabase Auth -> URL Configuration:

- Redirect URLs: `steep://auth-callback`

App config:

- `SUPABASE_AUTH_REDIRECT_URL=steep://auth-callback`

