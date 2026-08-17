alter table public.analysis_runs
  drop constraint if exists analysis_runs_input_kind_check;

alter table public.analysis_runs
  add constraint analysis_runs_input_kind_check
  check (input_kind in ('text', 'voice', 'image', 'photo', 'mixed'));

insert into public.food_aliases (food_id, alias, locale, priority)
select id, alias, 'en-US', priority
from public.foods
cross join lateral (
  values
    (case source_food_id
      when 'egg-boiled' then 'egg'
      when 'white-cheese-full-fat' then 'white cheese'
      when 'simit' then 'simit'
    end, 100),
    (case source_food_id
      when 'egg-boiled' then 'boiled egg'
      when 'white-cheese-full-fat' then 'feta cheese'
      when 'simit' then 'turkish bagel'
    end, 90),
    (case source_food_id
      when 'egg-boiled' then 'eggs'
      when 'white-cheese-full-fat' then 'cheese'
      when 'simit' then 'bagel'
    end, 80),
    (case source_food_id
      when 'egg-boiled' then 'boiled eggs'
    end, 90)
) as aliases(alias, priority)
where source = 'curated-demo' and alias is not null
on conflict (alias, locale, food_id) do update set priority = excluded.priority;

insert into public.food_portions (food_id, label, grams, locale, is_default)
select id,
  case source_food_id
    when 'egg-boiled' then '1 piece'
    when 'white-cheese-full-fat' then '30 g'
    when 'simit' then '1 piece'
  end,
  case source_food_id
    when 'egg-boiled' then 50
    when 'white-cheese-full-fat' then 30
    when 'simit' then 100
  end,
  'en-US',
  true
from public.foods
where source = 'curated-demo'
on conflict (food_id, label, locale) do update set
  grams = excluded.grams,
  is_default = excluded.is_default;
