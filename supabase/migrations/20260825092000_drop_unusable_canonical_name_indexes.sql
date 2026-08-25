-- Two indexes on foods.canonical_name that nothing can use any more.
--
-- They were built for the original ranked search, which matched on the bare
-- column: `similarity(f.canonical_name, v_query)` and a to_tsvector over the
-- same. 20260824150000 introduced localized names and 20260824160000 rewrote
-- the retrieval function to wrap every read as
-- `public.localized_name(f.canonical_name, f.metadata, p_locale)`. An index on
-- the bare column cannot serve a predicate over a function of that column, so
-- both went cold the moment that landed.
--
-- pg_stat_user_indexes confirms it rather than assuming: 0 and 2 scans across
-- eight days of live traffic, against 162,012 on foods_source_source_food_id_key
-- over the same period. Neither is unique, primary, or backing a constraint.
--
-- Together they hold 10 MB that the database does not have to spare: the
-- catalog with its vector index sits just over the plan's ceiling, and this is
-- space being spent on nothing. Recreating either is a one-line migration if a
-- future query matches the bare column again.

drop index if exists public.foods_canonical_name_trgm_idx;
drop index if exists public.foods_canonical_name_idx;
