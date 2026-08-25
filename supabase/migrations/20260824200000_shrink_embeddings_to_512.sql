-- The catalog does not fit the plan it runs on: `foods` is 576 MB of a 728 MB
-- database against a 500 MB ceiling, and 476 MB of that is the TOAST holding
-- one 1536-dimension vector per row. A 1536-dim float4 vector is 6 KB, well
-- past the 2 KB TOAST threshold, so every row pays an out-of-line write.
--
-- text-embedding-3-small is a Matryoshka model: asking the API for
-- `dimensions: 512` does not produce a different embedding, it returns the
-- first 512 components of the same 1536-dim vector, L2-normalized. That is
-- reproducible locally, so the shrink costs one table rewrite instead of
-- 60,003 re-embedding calls and the hours of wall clock they took last time.
-- Because the vectors are equivalent either way, embedding_model and
-- embedding_source_hash stay correct and the backfill still sees zero stale
-- rows afterwards.
--
-- The rewrite also reclaims the 11,331 dead tuples the original backfill left
-- behind, which plain autovacuum cannot return to the filesystem.

-- A full rewrite of a 576 MB table outlives the role's statement timeout.
set local statement_timeout = 0;

alter table public.foods
  alter column embedding type extensions.vector(512)
  using extensions.l2_normalize(extensions.subvector(embedding, 1, 512));

-- Same treatment for the query-embedding cache so cached vectors stay
-- comparable to the catalog. It is 14 rows, but a dimension mismatch here
-- would fail every semantic lookup at runtime rather than at deploy time.
alter table public.ai_retrieval_cache
  alter column query_embedding type extensions.vector(512)
  using extensions.l2_normalize(extensions.subvector(query_embedding, 1, 512));

-- hybrid_search_food_catalog takes an undimensioned `vector` parameter, so it
-- needs no signature change; it compares against foods.embedding, which is now
-- 512 on both sides.
