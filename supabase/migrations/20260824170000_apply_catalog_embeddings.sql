-- Writing embeddings one row per HTTP request is what made a full catalog
-- backfill an hour of wall clock and the source of all three ways it failed
-- today: 500 ids in one PostgREST filter produced a URL the gateway rejected,
-- concurrent single-row writes contended on the pgvector index until they hit
-- the statement timeout, and a stalled HTTP/2 stream hung the run with no error
-- at all because only the provider call carried a timeout.
--
-- One statement per batch removes all three. 60,000 requests become roughly
-- 1,200, the index sees one write set instead of thousands of competing ones,
-- and there is a single stream to fail rather than tens of thousands.
--
-- The vector arrives as its text form ("[0.1,0.2,...]") because that is what
-- pgvector parses, and jsonb has no vector type of its own.

create or replace function public.apply_catalog_embeddings(p_rows jsonb)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  if pg_catalog.jsonb_typeof(p_rows) <> 'array' then
    raise exception using errcode = '22023', message = 'p_rows must be a json array';
  end if;

  update public.foods f
     set embedding = r.embedding,
         embedding_model = r.model,
         embedding_source_hash = r.hash,
         embedding_updated_at = pg_catalog.now()
    from (
      select
        (entry ->> 'id')::uuid as id,
        (entry ->> 'embedding')::extensions.vector as embedding,
        entry ->> 'model' as model,
        entry ->> 'hash' as hash
      from pg_catalog.jsonb_array_elements(p_rows) as entry
    ) r
   where f.id = r.id;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- Backfill is maintenance run with the service key, never from a user session.
revoke all on function public.apply_catalog_embeddings(jsonb) from public, anon, authenticated;
grant execute on function public.apply_catalog_embeddings(jsonb) to service_role;

comment on function public.apply_catalog_embeddings(jsonb) is
  'Applies a batch of catalog embeddings in one statement. Each element carries id, embedding (pgvector text form), model and hash.';
