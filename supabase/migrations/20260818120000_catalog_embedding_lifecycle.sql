alter table public.foods
  add column if not exists embedding_source_hash text,
  add column if not exists embedding_updated_at timestamptz;

alter table public.foods
  drop constraint if exists foods_embedding_metadata_consistent;

alter table public.foods
  add constraint foods_embedding_metadata_consistent check (
    (embedding is null and embedding_model is null and embedding_source_hash is null and embedding_updated_at is null)
    or
    (embedding is not null and embedding_model is not null and embedding_source_hash is not null and embedding_updated_at is not null)
  );

create index if not exists foods_embedding_stale_idx
  on public.foods (embedding_model, embedding_source_hash)
  where is_active;

create table if not exists public.catalog_embedding_jobs (
  job_name text primary key,
  locked_until timestamptz not null default '-infinity',
  updated_at timestamptz not null default now()
);

alter table public.catalog_embedding_jobs enable row level security;

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

create or replace function public.finish_catalog_embedding_job()
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  update public.catalog_embedding_jobs
  set locked_until = '-infinity', updated_at = pg_catalog.now()
  where job_name = 'catalog-backfill';
$$;

revoke all on table public.catalog_embedding_jobs from public, anon, authenticated;
revoke all on function public.claim_catalog_embedding_job(integer) from public, anon, authenticated;
revoke all on function public.finish_catalog_embedding_job() from public, anon, authenticated;
grant execute on function public.claim_catalog_embedding_job(integer) to service_role;
grant execute on function public.finish_catalog_embedding_job() to service_role;

comment on column public.foods.embedding_source_hash is
  'SHA-256 of the canonical embedding document. A changed hash makes the embedding stale.';
comment on function public.claim_catalog_embedding_job(integer) is
  'Claims a short renewable lease that serializes catalog embedding backfills across Edge instances.';
