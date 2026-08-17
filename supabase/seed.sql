insert into public.foods (
  id,
  canonical_name,
  source,
  source_food_id,
  calories_per_100g,
  protein_per_100g,
  carbs_per_100g,
  fat_per_100g
)
values
  ('10000000-0000-0000-0000-000000000001', 'Tavuk Yumurtası, Haşlanmış', 'curated-demo', 'egg-boiled', 155, 12.6, 1.1, 10.6),
  ('10000000-0000-0000-0000-000000000002', 'Beyaz Peynir, Tam Yağlı', 'curated-demo', 'white-cheese-full-fat', 289, 16.0, 2.5, 24.0),
  ('10000000-0000-0000-0000-000000000003', 'Simit', 'curated-demo', 'simit', 340, 10.0, 57.0, 8.0)
on conflict (source, source_food_id) do update set
  canonical_name = excluded.canonical_name,
  calories_per_100g = excluded.calories_per_100g,
  protein_per_100g = excluded.protein_per_100g,
  carbs_per_100g = excluded.carbs_per_100g,
  fat_per_100g = excluded.fat_per_100g;

insert into public.food_aliases (food_id, alias, priority)
values
  ('10000000-0000-0000-0000-000000000001', 'yumurta', 100),
  ('10000000-0000-0000-0000-000000000001', 'haşlanmış yumurta', 100),
  ('10000000-0000-0000-0000-000000000002', 'peynir', 30),
  ('10000000-0000-0000-0000-000000000002', 'beyaz peynir', 100),
  ('10000000-0000-0000-0000-000000000003', 'simit', 100)
on conflict (alias, locale, food_id) do update set priority = excluded.priority;

insert into public.food_portions (food_id, label, grams, is_default)
values
  ('10000000-0000-0000-0000-000000000001', '1 adet', 50, true),
  ('10000000-0000-0000-0000-000000000002', 'az', 15, false),
  ('10000000-0000-0000-0000-000000000002', '1 porsiyon', 30, true),
  ('10000000-0000-0000-0000-000000000002', 'fazla', 50, false),
  ('10000000-0000-0000-0000-000000000003', 'yarım', 50, false),
  ('10000000-0000-0000-0000-000000000003', '1 adet', 100, true)
on conflict (food_id, label, locale) do update set
  grams = excluded.grams,
  is_default = excluded.is_default;
