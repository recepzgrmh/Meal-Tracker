create table public.ai_retrieval_cache (
  cache_key text primary key,
  query_hash text not null,
  locale text not null check (locale in ('tr-TR', 'en-US')),
  embedding_model text not null,
  catalog_fingerprint text not null,
  query_embedding extensions.vector(1536) not null,
  candidates jsonb not null check (pg_catalog.jsonb_typeof(candidates) = 'array'),
  hit_count bigint not null default 0,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index ai_retrieval_cache_expiry_idx on public.ai_retrieval_cache (expires_at);
alter table public.ai_retrieval_cache enable row level security;
revoke all on table public.ai_retrieval_cache from public, anon, authenticated;
grant select, insert, update, delete on table public.ai_retrieval_cache to service_role;

create trigger ai_retrieval_cache_set_updated_at before update on public.ai_retrieval_cache
for each row execute function public.set_updated_at();

create or replace function public.hybrid_search_food_catalog(
  p_query text,
  p_query_embedding extensions.vector(1536),
  p_locale text default 'tr-TR',
  p_limit integer default 7
)
returns table (
  food_id uuid,
  canonical_name text,
  matched_alias text,
  match_method text,
  score numeric,
  lexical_rank integer,
  vector_rank integer,
  semantic_similarity numeric,
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
  if p_locale not in ('tr-TR', 'en-US') then
    raise exception using errcode = '22023', message = 'unsupported locale';
  end if;

  return query
  with lexical_raw as (
    select
      f.id as food_id,
      a.alias::text as matched_alias,
      case
        when pg_catalog.lower(a.alias::text) = v_query then 'exact_alias'
        when pg_catalog.to_tsvector('pg_catalog.simple'::pg_catalog.regconfig, a.alias::text)
          @@ pg_catalog.websearch_to_tsquery('pg_catalog.simple'::pg_catalog.regconfig, v_query)
          then 'full_text'
        else 'trigram'
      end as method,
      case
        when pg_catalog.lower(a.alias::text) = v_query then 1::numeric
        else greatest(
          extensions.similarity(a.alias::text, v_query),
          extensions.word_similarity(v_query, a.alias::text)
        ) * 0.90 + ((a.priority + 100)::numeric / 200) * 0.10
      end as lexical_score
    from public.food_aliases a
    join public.foods f on f.id = a.food_id
    where a.locale = p_locale
      and f.is_active
      and (
        pg_catalog.lower(a.alias::text) = v_query
        or a.alias::text operator(extensions.%) v_query
        or pg_catalog.to_tsvector('pg_catalog.simple'::pg_catalog.regconfig, a.alias::text)
          @@ pg_catalog.websearch_to_tsquery('pg_catalog.simple'::pg_catalog.regconfig, v_query)
      )
  ),
  lexical_best as (
    select distinct on (lexical_raw.food_id)
      lexical_raw.food_id,
      lexical_raw.matched_alias,
      lexical_raw.method,
      lexical_raw.lexical_score
    from lexical_raw
    order by lexical_raw.food_id, lexical_raw.lexical_score desc, lexical_raw.matched_alias
  ),
  lexical_ranked as (
    select
      lexical_best.*,
      (pg_catalog.row_number() over (
        order by lexical_best.lexical_score desc, lexical_best.food_id
      ))::integer as lexical_rank
    from lexical_best
    order by lexical_rank
    limit 50
  ),
  vector_ranked as (
    select
      f.id as food_id,
      (1 - (f.embedding operator(extensions.<=>) p_query_embedding))::numeric as semantic_similarity,
      (pg_catalog.row_number() over (
        order by f.embedding operator(extensions.<=>) p_query_embedding, f.id
      ))::integer as vector_rank
    from public.foods f
    where p_query_embedding is not null
      and f.is_active
      and f.embedding is not null
      and (f.locale = p_locale or exists (
        select 1 from public.food_aliases locale_alias
        where locale_alias.food_id = f.id and locale_alias.locale = p_locale
      ))
    order by f.embedding operator(extensions.<=>) p_query_embedding, f.id
    limit 50
  ),
  candidate_ids as (
    select lexical_ranked.food_id from lexical_ranked
    union
    select vector_ranked.food_id from vector_ranked
  ),
  fused as (
    select
      ids.food_id,
      lexical_ranked.matched_alias,
      lexical_ranked.method,
      lexical_ranked.lexical_score,
      lexical_ranked.lexical_rank,
      vector_ranked.vector_rank,
      vector_ranked.semantic_similarity,
      (
        pg_catalog.coalesce(1.0 / (60 + lexical_ranked.lexical_rank), 0)
        + pg_catalog.coalesce(1.0 / (60 + vector_ranked.vector_rank), 0)
      )::numeric as rrf_score
    from candidate_ids ids
    left join lexical_ranked using (food_id)
    left join vector_ranked using (food_id)
  )
  select
    f.id,
    f.canonical_name::text,
    pg_catalog.coalesce(fused.matched_alias, f.canonical_name::text),
    case
      when fused.method = 'exact_alias' then fused.method
      when fused.lexical_rank is not null and fused.vector_rank is not null then 'hybrid_rrf'
      when fused.vector_rank is not null then 'semantic'
      else fused.method
    end,
    pg_catalog.round(
      least(1::numeric, fused.rrf_score * 25 + case when fused.method = 'exact_alias' then 0.55 else 0 end),
      6
    ),
    fused.lexical_rank,
    fused.vector_rank,
    pg_catalog.round(fused.semantic_similarity, 6),
    portion.grams,
    portion.label::text,
    f.calories_per_100g,
    f.protein_per_100g,
    f.carbs_per_100g,
    f.fat_per_100g,
    f.source || ':' || f.source_food_id
  from fused
  join public.foods f on f.id = fused.food_id
  left join lateral (
    select fp.grams, fp.label
    from public.food_portions fp
    where fp.food_id = f.id
    order by (fp.locale = p_locale) desc, fp.is_default desc, fp.id
    limit 1
  ) portion on true
  order by fused.rrf_score desc,
    (fused.method = 'exact_alias') desc,
    fused.semantic_similarity desc nulls last,
    f.canonical_name,
    f.id
  limit v_limit;
end;
$$;

revoke all on function public.hybrid_search_food_catalog(text, extensions.vector, text, integer)
  from public, anon;
grant execute on function public.hybrid_search_food_catalog(text, extensions.vector, text, integer)
  to authenticated, service_role;

comment on function public.hybrid_search_food_catalog(text, extensions.vector, text, integer) is
  'Fuses exact alias, full-text/trigram, and pgvector cosine ranks using deterministic reciprocal-rank fusion.';
