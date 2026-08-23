-- The case-study runtime has one production catalog: the deterministic 60K
-- Supabase release. Remove the unused provider switch and expose read-only
-- catalog metrics to console admins.

drop view if exists public.admin_catalog_provider_status;
drop function if exists public.admin_set_catalog_provider(text, boolean);
drop table if exists public.catalog_provider_config;

create or replace view public.admin_production_catalog_status
with (security_invoker = true)
as
select
  'canonical-v2-lean-60k'::text as catalog_version,
  count(*)::bigint as food_records,
  count(*) filter (
    where num_nonnulls(
      food.calories_per_100g,
      food.protein_per_100g,
      food.carbs_per_100g,
      food.fat_per_100g
    ) = 4
  )::bigint as macro_complete_records,
  (
    select count(*)::bigint
    from public.food_aliases alias
    join public.foods alias_food on alias_food.id = alias.food_id
    where alias_food.source = 'canonical_v2_lean' and alias_food.is_active
  ) as alias_records,
  (
    select count(*)::bigint
    from public.food_portions portion
    join public.foods portion_food on portion_food.id = portion.food_id
    where portion_food.source = 'canonical_v2_lean' and portion_food.is_active
  ) as portion_records
from public.foods food
where food.source = 'canonical_v2_lean'
  and food.is_active
  and public.is_console_admin();

revoke all on public.admin_production_catalog_status from public, anon;
grant select on public.admin_production_catalog_status to authenticated, service_role;

comment on view public.admin_production_catalog_status is
  'Read-only metrics for the deterministic 60K Supabase production catalog.';
