insert into public.food_aliases (food_id, alias, locale, priority)
values
  ('10000000-0000-0000-0000-000000000001', 'egg', 'en-US', 100),
  ('10000000-0000-0000-0000-000000000001', 'boiled egg', 'en-US', 100),
  ('10000000-0000-0000-0000-000000000001', 'hard-boiled egg', 'en-US', 95),
  ('10000000-0000-0000-0000-000000000002', 'white cheese', 'en-US', 100),
  ('10000000-0000-0000-0000-000000000002', 'Turkish white cheese', 'en-US', 100),
  ('10000000-0000-0000-0000-000000000002', 'feta', 'en-US', 35),
  ('10000000-0000-0000-0000-000000000003', 'simit', 'en-US', 100),
  ('10000000-0000-0000-0000-000000000003', 'Turkish sesame ring', 'en-US', 90),
  ('10000000-0000-0000-0000-000000000003', 'Turkish bagel', 'en-US', 55),
  ('10000000-0000-0000-0000-000000000003', 'gevrek', 'tr-TR', 85)
on conflict (alias, locale, food_id) do update set priority = excluded.priority;

insert into public.food_portions (food_id, label, grams, locale, is_default)
values
  ('10000000-0000-0000-0000-000000000001', '1 piece', 50, 'en-US', true),
  ('10000000-0000-0000-0000-000000000002', 'small', 15, 'en-US', false),
  ('10000000-0000-0000-0000-000000000002', '1 serving', 30, 'en-US', true),
  ('10000000-0000-0000-0000-000000000002', 'large', 50, 'en-US', false),
  ('10000000-0000-0000-0000-000000000003', 'half', 50, 'en-US', false),
  ('10000000-0000-0000-0000-000000000003', '1 piece', 100, 'en-US', true)
on conflict (food_id, label, locale) do update set
  grams = excluded.grams,
  is_default = excluded.is_default;
