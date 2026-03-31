insert into public.venues
  (place_id, name, address, city, latitude, longitude, category, average_rating, review_count, is_active)
values
  
on conflict (place_id) do update
set
  name = excluded.name,
  address = excluded.address,
  city = excluded.city,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  category = excluded.category,
  is_active = true;
