create extension if not exists pg_trgm with schema extensions;

create index if not exists food_aliases_alias_trgm_idx
  on public.food_aliases using gin ((alias::text) extensions.gin_trgm_ops);
create index if not exists foods_canonical_name_trgm_idx
  on public.foods using gin ((canonical_name::text) extensions.gin_trgm_ops);

create or replace function public.search_food_catalog(
  p_query text,
  p_locale text default 'tr-TR',
  p_limit integer default 7
)
returns table (
  food_id uuid,
  canonical_name text,
  matched_alias text,
  match_method text,
  score numeric,
  default_grams numeric,
  default_portion_label text,
  calories_per_100g numeric,
  protein_per_100g numeric,
  carbs_per_100g numeric,
  fat_per_100g numeric,
  nutrition_source text
)
language plpgsql
stable
set search_path = ''
as $$
declare
  v_query text := pg_catalog.lower(pg_catalog.btrim(p_query));
  v_limit integer := least(20, greatest(1, p_limit));
begin
  if auth.uid() is null then
    raise exception using errcode = '42501', message = 'authentication required';
  end if;
  if v_query is null or pg_catalog.char_length(v_query) not between 2 and 120 then
    raise exception using errcode = '22023', message = 'query must contain 2 to 120 characters';
  end if;
  if p_locale <> 'tr-TR' then
    raise exception using errcode = '22023', message = 'unsupported locale';
  end if;

  return query
  with raw_candidates as (
    select
      f.id as food_id,
      f.canonical_name::text as canonical_name,
      a.alias::text as matched_alias,
      case
        when pg_catalog.lower(a.alias::text) = v_query then 'exact_alias'
        when pg_catalog.to_tsvector('pg_catalog.simple'::pg_catalog.regconfig, a.alias::text)
          @@ pg_catalog.websearch_to_tsquery('pg_catalog.simple'::pg_catalog.regconfig, v_query)
          then 'full_text'
        else 'trigram'
      end as match_method,
      case
        when pg_catalog.lower(a.alias::text) = v_query then 1::numeric
        else (
          greatest(
            extensions.similarity(a.alias::text, v_query),
            extensions.word_similarity(v_query, a.alias::text)
          ) * 0.78
          + pg_catalog.ts_rank_cd(
              pg_catalog.to_tsvector('pg_catalog.simple'::pg_catalog.regconfig, a.alias::text),
              pg_catalog.websearch_to_tsquery('pg_catalog.simple'::pg_catalog.regconfig, v_query),
              32
            ) * 0.12
          + ((a.priority + 100)::numeric / 200) * 0.10
        )
      end as score,
      f.calories_per_100g,
      f.protein_per_100g,
      f.carbs_per_100g,
      f.fat_per_100g,
      f.source || ':' || f.source_food_id as nutrition_source
    from public.food_aliases a
    join public.foods f on f.id = a.food_id
    where a.locale = p_locale
      and f.locale = p_locale
      and f.is_active
      and (
        pg_catalog.lower(a.alias::text) = v_query
        or a.alias::text operator(extensions.%) v_query
        or pg_catalog.to_tsvector('pg_catalog.simple'::pg_catalog.regconfig, a.alias::text)
          @@ pg_catalog.websearch_to_tsquery('pg_catalog.simple'::pg_catalog.regconfig, v_query)
      )
    union all
    select
      f.id,
      f.canonical_name::text,
      f.canonical_name::text,
      case
        when pg_catalog.lower(f.canonical_name::text) = v_query then 'exact_name'
        when pg_catalog.to_tsvector('pg_catalog.simple'::pg_catalog.regconfig, f.canonical_name::text)
          @@ pg_catalog.websearch_to_tsquery('pg_catalog.simple'::pg_catalog.regconfig, v_query)
          then 'full_text'
        else 'trigram'
      end,
      case
        when pg_catalog.lower(f.canonical_name::text) = v_query then 0.99::numeric
        else (
          greatest(
            extensions.similarity(f.canonical_name::text, v_query),
            extensions.word_similarity(v_query, f.canonical_name::text)
          ) * 0.88
          + pg_catalog.ts_rank_cd(
              pg_catalog.to_tsvector('pg_catalog.simple'::pg_catalog.regconfig, f.canonical_name::text),
              pg_catalog.websearch_to_tsquery('pg_catalog.simple'::pg_catalog.regconfig, v_query),
              32
            ) * 0.12
        )
      end,
      f.calories_per_100g,
      f.protein_per_100g,
      f.carbs_per_100g,
      f.fat_per_100g,
      f.source || ':' || f.source_food_id
    from public.foods f
    where f.locale = p_locale
      and f.is_active
      and (
        pg_catalog.lower(f.canonical_name::text) = v_query
        or f.canonical_name::text operator(extensions.%) v_query
        or pg_catalog.to_tsvector('pg_catalog.simple'::pg_catalog.regconfig, f.canonical_name::text)
          @@ pg_catalog.websearch_to_tsquery('pg_catalog.simple'::pg_catalog.regconfig, v_query)
      )
  ),
  ranked as (
    select
      raw_candidates.*,
      pg_catalog.row_number() over (
        partition by raw_candidates.food_id
        order by raw_candidates.score desc, raw_candidates.matched_alias
      ) as food_rank
    from raw_candidates
  )
  select
    ranked.food_id,
    ranked.canonical_name,
    ranked.matched_alias,
    ranked.match_method,
    pg_catalog.round(ranked.score, 6),
    portion.grams,
    portion.label::text,
    ranked.calories_per_100g,
    ranked.protein_per_100g,
    ranked.carbs_per_100g,
    ranked.fat_per_100g,
    ranked.nutrition_source
  from ranked
  left join lateral (
    select fp.grams, fp.label
    from public.food_portions fp
    where fp.food_id = ranked.food_id and fp.locale = p_locale
    order by fp.is_default desc, fp.id
    limit 1
  ) portion on true
  where ranked.food_rank = 1
  order by ranked.score desc, ranked.canonical_name, ranked.food_id
  limit v_limit;
end;
$$;

revoke all on function public.search_food_catalog(text, text, integer) from public, anon;
grant execute on function public.search_food_catalog(text, text, integer)
  to authenticated, service_role;

comment on function public.search_food_catalog(text, text, integer) is
  'Returns a bounded deterministic exact, full-text, and trigram ranking over active catalog foods.';
