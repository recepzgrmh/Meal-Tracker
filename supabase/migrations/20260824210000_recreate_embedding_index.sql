-- 20260824190000 dropped the HNSW index that served the semantic search arm so
-- the backfill would stop paying a graph walk per insert. This puts a vector
-- index back now that the column is settled at 512 dimensions.
--
-- The first attempt at this rebuilt HNSW and stalled: the instance's
-- maintenance_work_mem is 32MB, nowhere near enough for HNSW graph
-- construction over 60,003 x 1536-dim vectors, so the build spilled to disk and
-- kept getting slower as the graph grew. The second attempt switched to ivfflat
-- and still ran nearly an hour stuck in "performing k-means" — 32MB forces the
-- k-means step itself to spill and re-read rather than working the sample in
-- memory. Raising it for this build only fixes that without touching the role's
-- standing configuration.
--
-- At 512 dimensions the same data is a third of the size, so this build has far
-- more headroom than either failed attempt. lists = 50 follows pgvector's
-- rows/1000 guidance for 60,003 rows.

set local statement_timeout = 0;
set local maintenance_work_mem = '256MB';

create index foods_embedding_ivfflat_idx
  on public.foods
  using ivfflat (embedding extensions.vector_cosine_ops)
  with (lists = 50)
  where embedding is not null;
