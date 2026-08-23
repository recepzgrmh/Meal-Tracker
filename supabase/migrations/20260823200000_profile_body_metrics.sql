-- The calorie target used to be a single number the user typed, or the 2100
-- kcal column default. These columns hold the answers it is now derived from,
-- plus the resulting macro targets, so the estimate can be recomputed and
-- explained rather than just asserted.

alter table public.profiles
  add column biological_sex text
    check (biological_sex in ('female', 'male', 'unspecified')),
  add column birth_year integer
    check (birth_year between 1900 and 2200),
  add column height_cm numeric(5, 1)
    check (height_cm between 100 and 250),
  add column weight_kg numeric(5, 1)
    check (weight_kg between 30 and 400),
  add column target_weight_kg numeric(5, 1)
    check (target_weight_kg between 30 and 400),
  add column activity_level text
    check (activity_level in ('sedentary', 'light', 'moderate', 'high', 'athlete')),
  add column weight_goal text
    check (weight_goal in ('lose', 'maintain', 'gain')),
  add column goal_pace text
    check (goal_pace in ('slow', 'steady', 'fast')),
  add column diet_pattern text
    check (diet_pattern in ('balanced', 'high_protein', 'low_carb', 'keto',
      'mediterranean', 'pescatarian', 'vegetarian', 'vegan')),
  add column measurement_system text not null default 'metric'
    check (measurement_system in ('metric', 'imperial')),
  add column daily_protein_target_g integer
    check (daily_protein_target_g between 0 and 500),
  add column daily_carb_target_g integer
    check (daily_carb_target_g between 0 and 1500),
  add column daily_fat_target_g integer
    check (daily_fat_target_g between 0 and 500),
  add column calorie_target_source text not null default 'default'
    check (calorie_target_source in ('default', 'computed', 'manual'));

grant update (
  biological_sex,
  birth_year,
  height_cm,
  weight_kg,
  target_weight_kg,
  activity_level,
  weight_goal,
  goal_pace,
  diet_pattern,
  measurement_system,
  daily_protein_target_g,
  daily_carb_target_g,
  daily_fat_target_g,
  calorie_target_source
) on table public.profiles to authenticated;

comment on column public.profiles.biological_sex is
  'Input to the Mifflin-St Jeor equation, not a gender identity field. "unspecified" uses the midpoint of the two published constants.';
comment on column public.profiles.diet_pattern is
  'Drives the macro split and, later, diet-conflict hints during analysis. Not a nutrition prescription.';
comment on column public.profiles.calorie_target_source is
  'Whether daily_calorie_target is the app default, an estimate derived from the body columns, or a number the user entered.';
