-- The backfill scanned `order by id limit 500` on every run, so it only ever
-- saw the same first 500 foods. Once those were embedded it reported "nothing
-- stale" forever and the remaining catalog never received an embedding, which
-- left the vector half of hybrid retrieval empty.
--
-- A persisted cursor lets each run continue where the previous one stopped and
-- wrap around to the start after a full pass.

alter table public.catalog_embedding_jobs
  add column if not exists cursor_food_id uuid;

comment on column public.catalog_embedding_jobs.cursor_food_id is
  'Highest foods.id already considered by the backfill. Null restarts the scan from the beginning.';

create or replace function public.catalog_embedding_cursor()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select cursor_food_id
  from public.catalog_embedding_jobs
  where job_name = 'catalog-backfill';
$$;

create or replace function public.advance_catalog_embedding_cursor(p_food_id uuid default null)
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  insert into public.catalog_embedding_jobs (job_name, cursor_food_id)
  values ('catalog-backfill', p_food_id)
  on conflict (job_name) do update
    set cursor_food_id = excluded.cursor_food_id,
        updated_at = pg_catalog.now();
$$;

revoke all on function public.catalog_embedding_cursor() from public, anon, authenticated;
revoke all on function public.advance_catalog_embedding_cursor(uuid) from public, anon, authenticated;
grant execute on function public.catalog_embedding_cursor() to service_role;
grant execute on function public.advance_catalog_embedding_cursor(uuid) to service_role;

comment on function public.advance_catalog_embedding_cursor(uuid) is
  'Moves the catalog embedding backfill cursor. Passing null wraps the scan back to the first food.';
