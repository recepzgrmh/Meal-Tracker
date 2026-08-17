create or replace function public.claim_catalog_embedding_job(p_lease_seconds integer default 60)
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_claimed boolean;
begin
  if p_lease_seconds not between 10 and 300 then
    raise exception using errcode = '22023', message = 'lease must be between 10 and 300 seconds';
  end if;

  insert into public.catalog_embedding_jobs (job_name, locked_until)
  values ('catalog-backfill', pg_catalog.now() + pg_catalog.make_interval(secs => p_lease_seconds))
  on conflict (job_name) do update
    set locked_until = excluded.locked_until,
        updated_at = pg_catalog.now()
    where public.catalog_embedding_jobs.locked_until < pg_catalog.now()
  returning true into v_claimed;

  return coalesce(v_claimed, false);
end;
$$;

do $migration$
declare
  v_definition text;
begin
  select pg_catalog.pg_get_functiondef(
    'public.hybrid_search_food_catalog(text,extensions.vector,text,integer)'::pg_catalog.regprocedure
  ) into v_definition;
  execute pg_catalog.replace(v_definition, 'pg_catalog.coalesce', 'coalesce');
end;
$migration$;
