-- 20260825090000 deleted every Turkish alias on the foreign branded tiers. It
-- fixed what it was aimed at — "badem" no longer resolves to popcorn seasoning
-- salt — and took something real with it. "kremalı tavuklu makarna" had been
-- reaching "Turkey Pasta" through the alias "tavuklu makarna"; afterwards it
-- fell through to an AI estimate, and a Turkish query in the manual catalog
-- search stopped finding those 30,000 rows at all. Deleting was the wrong verb.
--
-- The Turkish names were never lost: 20260824150000 stores them on
-- `foods.metadata->>'canonical_name_tr'` and only the derived alias rows were
-- removed, so this regenerates them without re-running any translation.
--
-- They come back at priority 55, below the 60 that generic_core head nouns
-- carry. That is what deletion was standing in for. When the original
-- migration was written the matcher ordered equal-length matches by nothing at
-- all, so a lower priority would not have stopped a branded row winning on
-- Postgres row order — removal was the only lever. The matcher now breaks ties
-- by priority, so the ordering can be stated instead of enforced by absence:
--
--   * a plain word like "badem" reaches the curated food, because 60 > 55;
--   * "tavuklu makarna", which no curated row answers, still reaches this one;
--   * and when one of these does win it is below the ambiguity threshold of 80,
--     so it asks "which food?" rather than answering silently at 0.98.
--
-- Manual catalog search and semantic retrieval get the rows back either way,
-- which is the half of the regression a demotion alone would not have caused.

insert into public.food_aliases (food_id, alias, locale, priority)
select f.id, btrim(f.metadata ->> 'canonical_name_tr'), 'tr-TR', 55
from public.foods f
where f.is_active
  and f.metadata ->> 'tier' in ('off_en_global', 'usda_branded_quality')
  and nullif(btrim(f.metadata ->> 'canonical_name_tr'), '') is not null
on conflict (alias, locale, food_id) do nothing;
