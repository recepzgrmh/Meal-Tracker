-- The batched form was right; the join was not. Updating `foods` FROM
-- jsonb_array_elements leaves the planner guessing at the element count — the
-- default estimate for a set-returning function is 100 rows — and against a
-- 60,000-row table whose rows each carry a 1536-dimension vector it chose to
-- scan the whole thing, which ran past the statement timeout every time.
--
-- Looping and updating by primary key removes the choice: fifty index lookups
-- inside one function call, still one HTTP request, no plan to get wrong. The
-- point of the batch was never to write in a single statement, only to stop
-- paying a network round trip per row.

create or replace function public.apply_catalog_embeddings(p_rows jsonb)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_entry jsonb;
  v_count integer := 0;
begin
  if pg_catalog.jsonb_typeof(p_rows) <> 'array' then
    raise exception using errcode = '22023', message = 'p_rows must be a json array';
  end if;

  for v_entry in select * from pg_catalog.jsonb_array_elements(p_rows) loop
    update public.foods
       set embedding = (v_entry ->> 'embedding')::extensions.vector,
           embedding_model = v_entry ->> 'model',
           embedding_source_hash = v_entry ->> 'hash',
           embedding_updated_at = pg_catalog.now()
     where id = (v_entry ->> 'id')::uuid;
    if found then
      v_count := v_count + 1;
    end if;
  end loop;

  return v_count;
end;
$$;

revoke all on function public.apply_catalog_embeddings(jsonb) from public, anon, authenticated;
grant execute on function public.apply_catalog_embeddings(jsonb) to service_role;

comment on function public.apply_catalog_embeddings(jsonb) is
  'Applies a batch of catalog embeddings by primary key in one call. Each element carries id, embedding (pgvector text form), model and hash.';
