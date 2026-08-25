-- 20260825110000 compared alias text case-sensitively and so matched almost
-- nothing. The branded rows store "Yumurta" and "Beyaz Peynir"; the curated
-- generic rows store "yumurta" and "beyaz peynir". In SQL those are different
-- strings, so the demotion passed straight over the exact rows it was written
-- for and "2 yumurta" kept resolving to the branded row at priority 90.
--
-- They are not different strings to the matcher, which lowercases both the
-- input and every alias before comparing (`normalizeTurkishInput`). Anything
-- reasoning about alias collisions has to fold the same way the matcher does or
-- it is reasoning about a different catalog than the one that runs.
--
-- Turkish lowercasing is used deliberately rather than `lower()`: for I/İ the
-- two disagree, and the matcher folds with Turkish rules for a tr-TR alias.

with curated_head_nouns as (
  select distinct lower(a.alias collate "tr-TR-x-icu") as alias
  from public.food_aliases a
  join public.foods f on f.id = a.food_id
  where a.locale = 'tr-TR'
    and f.is_active
    and f.metadata ->> 'tier' = 'generic_core'
)
update public.food_aliases a
   set priority = 55
  from public.foods f
 where f.id = a.food_id
   and a.locale = 'tr-TR'
   and f.is_active
   and f.metadata ->> 'tier' = 'tr_branded'
   and a.priority >= 80
   and lower(a.alias collate "tr-TR-x-icu") in (select alias from curated_head_nouns);
