-- Read-only, server-paginated production catalog browser for console admins.

create or replace function public.admin_search_production_foods(
  p_query text default '',
  p_kind text default 'all',
  p_tier text default 'all',
  p_page integer default 1,
  p_page_size integer default 25
)
returns table (
  food_id uuid,
  canonical_name text,
  locale text,
  category text,
  brand text,
  barcode text,
  tier text,
  dataset_version text,
  calories_per_100g numeric,
  protein_per_100g numeric,
  carbs_per_100g numeric,
  fat_per_100g numeric,
  total_count bigint
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_query text := trim(coalesce(p_query, ''));
  normalized_kind text := lower(coalesce(p_kind, 'all'));
  normalized_tier text := lower(coalesce(p_tier, 'all'));
  safe_page integer := greatest(coalesce(p_page, 1), 1);
  safe_page_size integer := least(greatest(coalesce(p_page_size, 25), 1), 100);
begin
  if not public.is_console_admin() then
    raise exception using errcode = '42501', message = 'console admin access required';
  end if;
  if normalized_kind not in ('all', 'generic', 'branded') then
    raise exception using errcode = '22023', message = 'unsupported food kind';
  end if;

  return query
  with filtered as (
    select food.*
    from public.foods food
    where food.source = 'canonical_v2_lean'
      and food.is_active
      and (
        normalized_kind = 'all'
        or (normalized_kind = 'branded' and coalesce(food.metadata ->> 'brand', food.metadata ->> 'barcode') is not null)
        or (normalized_kind = 'generic' and food.metadata ->> 'brand' is null and food.metadata ->> 'barcode' is null)
      )
      and (normalized_tier = 'all' or lower(coalesce(food.metadata ->> 'tier', '')) = normalized_tier)
      and (
        normalized_query = ''
        or food.canonical_name::text ilike '%' || normalized_query || '%'
        or food.source_food_id ilike '%' || normalized_query || '%'
        or coalesce(food.metadata ->> 'brand', '') ilike '%' || normalized_query || '%'
        or coalesce(food.metadata ->> 'barcode', '') ilike '%' || normalized_query || '%'
        or exists (
          select 1
          from public.food_aliases alias
          where alias.food_id = food.id
            and alias.alias::text ilike '%' || normalized_query || '%'
        )
      )
  )
  select
    filtered.id,
    filtered.canonical_name::text,
    filtered.locale,
    filtered.metadata ->> 'category',
    filtered.metadata ->> 'brand',
    filtered.metadata ->> 'barcode',
    filtered.metadata ->> 'tier',
    filtered.metadata ->> 'dataset_version',
    filtered.calories_per_100g,
    filtered.protein_per_100g,
    filtered.carbs_per_100g,
    filtered.fat_per_100g,
    count(*) over ()
  from filtered
  order by
    case when lower(filtered.canonical_name::text) = lower(normalized_query) then 0 else 1 end,
    case when filtered.canonical_name::text ilike normalized_query || '%' then 0 else 1 end,
    filtered.canonical_name::text,
    filtered.id
  limit safe_page_size
  offset (safe_page - 1) * safe_page_size;
end;
$$;

revoke all on function public.admin_search_production_foods(text, text, text, integer, integer) from public, anon;
grant execute on function public.admin_search_production_foods(text, text, text, integer, integer) to authenticated;

comment on function public.admin_search_production_foods(text, text, text, integer, integer) is
  'Console-admin-only, read-only and server-paginated browser for the 60K production catalog.';
