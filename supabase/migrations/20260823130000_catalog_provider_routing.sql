-- Runtime catalog routing. The mobile contract remains catalog-search.v2;
-- only the server-side provider changes.

create table if not exists public.catalog_provider_config (
  singleton boolean primary key default true check (singleton),
  active_provider text not null default 'supabase_lean'
    check (active_provider in ('supabase_lean', 'self_hosted')),
  fallback_enabled boolean not null default true,
  supabase_catalog_version text not null default 'canonical-v2-lean-60k',
  self_hosted_catalog_version text not null default 'canonical-v2',
  self_hosted_expected_records bigint not null default 1228891 check (self_hosted_expected_records >= 0),
  updated_by uuid,
  updated_at timestamptz not null default now()
);

insert into public.catalog_provider_config (singleton)
values (true)
on conflict (singleton) do nothing;

alter table public.catalog_provider_config enable row level security;
revoke all on table public.catalog_provider_config from public, anon, authenticated;
grant select on table public.catalog_provider_config to authenticated, service_role;

drop policy if exists "console admins read catalog provider" on public.catalog_provider_config;
create policy "console admins read catalog provider"
on public.catalog_provider_config for select to authenticated
using ((select public.is_console_admin()));

create or replace function public.admin_set_catalog_provider(
  p_provider text,
  p_fallback_enabled boolean default true
)
returns public.catalog_provider_config
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.catalog_provider_config;
begin
  if not public.is_console_admin() then
    raise exception using errcode = '42501', message = 'console admin access required';
  end if;
  if p_provider not in ('supabase_lean', 'self_hosted') then
    raise exception using errcode = '22023', message = 'unsupported catalog provider';
  end if;
  update public.catalog_provider_config
  set active_provider = p_provider,
      fallback_enabled = p_fallback_enabled,
      updated_by = (select auth.uid()),
      updated_at = now()
  where singleton
  returning * into result;
  return result;
end;
$$;

revoke all on function public.admin_set_catalog_provider(text, boolean) from public, anon;
grant execute on function public.admin_set_catalog_provider(text, boolean) to authenticated;

create or replace view public.admin_catalog_provider_status
with (security_invoker = true)
as
select
  config.active_provider,
  config.fallback_enabled,
  config.supabase_catalog_version,
  config.self_hosted_catalog_version,
  config.self_hosted_expected_records,
  config.updated_at,
  (select count(*)::bigint from public.foods where source = 'canonical_v2_lean' and is_active) as supabase_records,
  (select count(*)::bigint from public.foods where source = 'canonical_v2_lean' and is_active
    and num_nonnulls(calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g) = 4) as supabase_macro_complete_records
from public.catalog_provider_config config
where config.singleton;

revoke all on public.admin_catalog_provider_status from public, anon;
grant select on public.admin_catalog_provider_status to authenticated, service_role;

comment on table public.catalog_provider_config is
  'Singleton server-side route for catalog-search.v2. External URL and token remain Edge Function secrets.';
