insert into public.venues
  (place_id, name, address, city, latitude, longitude, category, average_rating, review_count, is_active)
values
  ('ChIJm58KgjDL1IkRaEwUb3FXeCY','NEO COFFEE BAR','161 Frederick St Unit 100, Toronto, ON M5A 1J9, Canada','Toronto',43.6506513,-79.3691669,'coffee',0.0,0,true),
  ('ChIJS5xKTs80K4gRKD5q5-SgtZM','Library Coffee','281 Dundas St W, Toronto, ON M5T 1G1, Canada','Toronto',43.6543249,-79.3908424,'coffee',0.0,0,true),
  ('ChIJO4Y0YI7L1IkRaZ0Nndyhf7A','MATCHA MATCHA','407 Church St, Toronto, ON M5B 1J2, Canada','Toronto',43.6623054,-79.37926019999999,'other',0.0,0,true),
  ('ChIJRRcM18E0K4gRKwRR6ALuPX4','Found Coffee | College','324 College St, Toronto, ON M5T 1S3, Canada','Toronto',43.6576525,-79.40263809999999,'coffee',0.0,0,true),
  ('ChIJJd7GGAA1K4gRgQx9neVZzD4','Vintage Cat Cafe Toronto','1274 St Clair Ave W, Toronto, ON M6E 1B9, Canada','Toronto',43.6773328,-79.4471166,'coffee',0.0,0,true),
  ('ChIJfdgn1kY0K4gRFaL2RlJR10g','Propeller Coffee Co.','50 Wade Ave, Toronto, ON M6H 2Z3, Canada','Toronto',43.6594069,-79.44491300000001,'coffee',0.0,0,true),
  ('ChIJL0OAV9w1K4gRUTl0iNxyWu8','Ethica Coffee Roasters','213 Sterling Rd, Toronto, ON M6R 2B2, Canada','Toronto',43.6552893,-79.44526809999999,'coffee',0.0,0,true),
  ('ChIJhexiVts0K4gRBd5-fbPJIoc','Hale Coffee Company','300 Campbell Ave Unit #103, Toronto, ON M6P 3V6, Canada','Toronto',43.6656971,-79.4500753,'coffee',0.0,0,true),
  ('ChIJEQ4LqpE1K4gRmsdIPXfAXsI','El Pacho Coffee Roasters','40 University Ave Unit 8, Toronto, ON M5J 1T1, Canada','Toronto',43.6459891,-79.3841131,'coffee',0.0,0,true),
  ('ChIJp6TlSbg1K4gRxW07pIYvIA0','Butter & Blue','7 Baldwin St, Toronto, ON M5T 1L1, Canada','Toronto',43.6560582,-79.3925864,'coffee',0.0,0,true),
  ('ChIJMxdFNAA1K4gRqAgyuXHgqRg','Nabulu Coffee','6 St Joseph St, Toronto, ON M4Y 1J7, Canada','Toronto',43.6660706,-79.38562290000002,'coffee',0.0,0,true),
  ('ChIJCU1G3lU1K4gR8PO7sj2uAEM','Library Coffee','917 Queen St W, Toronto, ON M6J 1G5, Canada','Toronto',43.6453187,-79.412552,'coffee',0.0,0,true),
  ('ChIJIaWzQLQ1K4gROgPmWY236zI','Black wolf coffee','717 Bay St., Toronto, ON M5G 2J9, Canada','Toronto',43.6590503,-79.3849008,'coffee',0.0,0,true),
  ('ChIJbXnN0Mw1K4gRvQyfYYpzs6w','Augusta Coffee Bar','229 Augusta Ave, Toronto, ON M5T 2L4, Canada','Toronto',43.6544546,-79.4018767,'coffee',0.0,0,true),
  ('ChIJ2c_gB0Y1K4gRBkrOOICFtLs','Buno Coffee (St Clair W)','136 Lauder Ave, Toronto, ON M6H 3E5, Canada','Toronto',43.67837859999999,-79.4398768,'coffee',0.0,0,true),
  ('ChIJu3qb1y_L1IkROlJP4lq4fhQ','Everyday Gourmet Coffee Roasters','95 Front St E, Toronto, ON M5E 1C2, Canada','Toronto',43.6490124,-79.3718028,'coffee',0.0,0,true),
  ('ChIJnbFcq-k1K4gRItmtgGUuZ4Q','Subtext Coffee Roasters','130 Cawthra Ave Unit 104, Toronto, ON M6N 3C2, Canada','Toronto',43.6711224,-79.4646231,'coffee',0.0,0,true),
  ('ChIJeZUuank1K4gRK2IF-58ptmA','MATCHA MATCHA','294 Dundas St W, Toronto, ON M5T 1G2, Canada','Toronto',43.6545071,-79.3912893,'other',0.0,0,true),
  ('ChIJJ2J4-C81K4gRi2AOH99WUD8','Coast to Coast Coffee','130 Cawthra Ave Unit 103, Toronto, ON M6N 3C2, Canada','Toronto',43.67108229999999,-79.4646099,'coffee',0.0,0,true),
  ('ChIJXTQ-t6s1K4gReGLEX3LwL2Y','Graination Specialty Coffee','204 Spadina Ave. Ground floor, Toronto, ON M5T 2C2, Canada','Toronto',43.6504334,-79.39732359999999,'coffee',0.0,0,true),
  ('ChIJa8_45JU1K4gRiq-MZ3JL8RE','SOLARIS COFFEE','2A St Patrick St, Toronto, ON M5T 1T9, Canada','Toronto',43.6505829,-79.38882149999999,'coffee',0.0,0,true),
  ('ChIJjbfahQI1K4gR556CTbg4-7o','11th R Coffee','70 Temperance St, Toronto, ON M5H 0B1, Canada','Toronto',43.6505301,-79.3821482,'coffee',0.0,0,true),
  ('ChIJt5fX3241K4gRpzr4Xp-4gSo','Odin Coffee Roasters','180 John St, Toronto, ON M5T 1X5, Canada','Toronto',43.650672,-79.39177459999999,'coffee',0.0,0,true)
on conflict (place_id) do update
set
  name = excluded.name,
  address = excluded.address,
  city = excluded.city,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  category = excluded.category,
  is_active = true;
