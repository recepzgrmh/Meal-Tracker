-- The HNSW index is why the backfill kept slowing down: every insert walks the
-- graph to place the new vector, and that walk gets more expensive as the graph
-- grows — observed as 8.6 rows/s decaying to 3.3 with ~28,000 rows still to go.
--
-- Dropping it turns each write into a plain heap update. Semantic search keeps
-- working through a sequential scan (~60,000 rows, low hundreds of ms) and the
-- semantic arm is not returning trustworthy results until the backfill finishes
-- anyway, so nothing of value is lost in the window.
--
-- A follow-up migration recreates the index once the backfill completes;
-- building it in one pass over the finished column takes minutes, against the
-- hours the incremental inserts were costing.

drop index if exists public.foods_embedding_hnsw_idx;
