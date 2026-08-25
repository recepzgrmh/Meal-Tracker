-- The previous migration removed Turkish aliases from foreign branded tiers.
-- 1,336 collisions survive it on the remaining uncurated tiers: a Turkish
-- alias at priority >= 80 on a row that is not curated, where a curated
-- generic_core or tr_branded row already carries the same alias.
--
-- 'badem' is the example that made this visible. After the branded sweep it
-- still resolved to "Imitation butter flavor popcorn seasoning salt" (0 kcal,
-- quality_global, priority 85) alongside the correct "Badem, iç, kavrulmuş"
-- (600 kcal, generic_core, priority 60). The matcher sorts by match position
-- and length, never by priority, so between two identical-length matches for
-- the same word the winner is row order — and at 85 the wrong one also
-- reports confidence 0.98 with no clarification question.
--
-- Only the colliding aliases go, and only where a curated row already answers
-- the same word. The other 21,386 uncurated Turkish aliases stay: no curated
-- alternative exists for those, so they are the only way to reach that food in
-- Turkish, and removing them would lose real coverage.
--
-- Demotion below 80 was the alternative. It would surface the ambiguity as a
-- question, but the wrong row could still win the tie-break, so the user would
-- be asked to choose between a real almond and popcorn salt. Deleting resolves
-- it in favour of the curated catalog instead.

with curated as (
  select distinct a.alias
  from public.food_aliases a
  join public.foods f on f.id = a.food_id
  where a.locale = 'tr-TR'
    and f.is_active
    and f.metadata ->> 'tier' in ('generic_core', 'tr_branded')
)
delete from public.food_aliases a
using public.foods f
where a.food_id = f.id
  and a.locale = 'tr-TR'
  and f.is_active
  and coalesce(f.metadata ->> 'tier', '') not in ('generic_core', 'tr_branded')
  and a.priority >= 80
  and a.alias in (select alias from curated);
