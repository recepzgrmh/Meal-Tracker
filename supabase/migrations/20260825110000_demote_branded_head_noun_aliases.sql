-- A plain Turkish word should reach the curated Turkish food, not a branded
-- product that happens to be named after it.
--
-- "2 yumurta" resolved to a tr_branded row literally called "Yumurta" at
-- priority 90, beating TürKomp's "Yumurta, tavuk, tam" at 60. The branded row
-- carries no real unit — its only portion is the importer's fake basis
-- "1.65 portion (100 g)" — so two eggs came out as 200 g and 286 kcal against a
-- true ~100 g and ~140.
--
-- Why 55 and not 79. The identity-ambiguity threshold is 80, so demoting to 79
-- would have made the branded row ask a question — but it would still have won
-- the match, because the curated generic sits at 60. Head-noun aliases on
-- generic_core are deliberately 60: "yumurta" names a family, not a food, and
-- that is exactly the case the identity question exists for. To let the curated
-- family win, the branded alias has to go below it.
--
-- Scope is only the collisions: a tr_branded alias at >= 80 whose exact text a
-- generic_core row already answers. A branded product with a distinctive name
-- keeps its priority and stays the best answer for its own name — nothing here
-- makes "Nutella" harder to find. Rows are not deleted, and a demoted alias is
-- still retrieved, still offered among the identity alternatives.

with curated_head_nouns as (
  select distinct a.alias
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
   and a.alias in (select alias from curated_head_nouns);
