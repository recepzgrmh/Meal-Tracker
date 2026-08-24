-- Reciprocal-rank fusion throws away the similarity that produced the ranks:
-- two candidates whose ranks are adjacent score within ~0.001 of each other, so
-- among a cluster of near-identical rows the order is effectively arbitrary.
-- Asked for "kremalı tavuklu mantarlı makarna", retrieval found the right five
-- pasta rows and then put "ev yapımı kremalı ETLİ makarna" above "ev yapımı
-- kremalı TAVUKLU makarna".
--
-- Rank fusion is kept — it is what makes the two arms comparable at all — and
-- given back the signal it discards, in the form the request actually asks for.
--
-- Recall alone does not order these: "ev yapımı kremalı tavuklu makarna",
-- "...tavuklu sebzeli makarna" and "hazır ısıtmalık ...tavuklu sebzeli makarna"
-- all contain three of the four query words and tie. What separates them is
-- precision — how much of the row is *not* what was asked for — so the two are
-- combined as an F1. Measured on the reported query that orders them 0.750,
-- 0.667, 0.600, with "kremalı etli makarna" falling to 0.500.
--
-- Weight 0.10 against an RRF spread of roughly 0.05 across ten ranks: overlap
-- decides among near-ties and can overturn a modest rank gap, but a row both
-- arms rank far down does not climb on overlap alone.

create or replace function public.query_name_overlap(p_query text, p_name text)
returns numeric
language sql
immutable
set search_path = ''
as $$
  -- Words shorter than three characters are dropped: "ve", "bir", "ile" appear
  -- everywhere and would flatten the signal. Matching is by substring in both
  -- directions so Turkish suffixes ("makarna" in "makarnalık") still count.
  with q as (
    select distinct w
    from pg_catalog.unnest(
      pg_catalog.regexp_split_to_array(pg_catalog.lower(pg_catalog.btrim(p_query)), '[^[:alnum:]]+')
    ) as w
    where pg_catalog.char_length(w) >= 3
  ),
  n as (
    select distinct w
    from pg_catalog.unnest(
      pg_catalog.regexp_split_to_array(pg_catalog.lower(pg_catalog.btrim(p_name)), '[^[:alnum:]]+')
    ) as w
    where pg_catalog.char_length(w) >= 3
  ),
  scored as (
    select
      (select pg_catalog.count(*) from q) as q_total,
      (select pg_catalog.count(*) from n) as n_total,
      (select pg_catalog.count(*) from q
        where pg_catalog.strpos(pg_catalog.lower(p_name), q.w) > 0) as recall_hits,
      (select pg_catalog.count(*) from n
        where pg_catalog.strpos(pg_catalog.lower(p_query), n.w) > 0) as precision_hits
  )
  select case
    when scored.q_total = 0 or scored.n_total = 0 then 0::numeric
    when scored.recall_hits = 0 or scored.precision_hits = 0 then 0::numeric
    else 2::numeric
      * (scored.recall_hits::numeric / scored.q_total::numeric)
      * (scored.precision_hits::numeric / scored.n_total::numeric)
      / (
        (scored.recall_hits::numeric / scored.q_total::numeric)
        + (scored.precision_hits::numeric / scored.n_total::numeric)
      )
  end
  from scored
$$;

revoke all on function public.query_name_overlap(text, text) from public, anon;
grant execute on function public.query_name_overlap(text, text) to authenticated, service_role;

drop function if exists public.hybrid_search_food_catalog(text, extensions.vector, text, integer);

create or replace function public.hybrid_search_food_catalog(
  p_query text,
  p_query_embedding extensions.vector(1536),
  p_locale text default 'tr-TR',
  p_limit integer default 7,
  p_min_locale_relevance numeric default null
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
  v_relevance_key text := case
    when p_locale = 'tr-TR' then 'turkey_relevance_score'
    else 'english_relevance_score'
  end;
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
  with relevant_foods as not materialized (
    -- One place decides what is in scope, so the lexical and vector arms can
    -- never disagree about which rows exist.
    --
    -- NOT MATERIALIZED is required, not cosmetic: this CTE is referenced twice,
    -- which makes Postgres materialize it by default. That would buffer every
    -- in-scope row including its 1536-dimension embedding and, worse, put a
    -- scan between the vector arm and its ivfflat index. Inlining keeps the
    -- predicate as a plain filter the planner can push into both arms.
    select f.*
    from public.foods f
    where f.is_active
      and (
        p_min_locale_relevance is null
        or f.metadata ->> 'tier' = 'generic_core'
        -- Only a row that carries a score can fail on it. Rows seeded before
        -- the lean import have no relevance metadata at all, and absence of a
        -- signal is not evidence of irrelevance — excluding them would drop
        -- curated foods to remove noise they were never part of. A malformed
        -- value is treated the same way rather than raising and taking down
        -- every search.
        or (f.metadata ->> v_relevance_key) is null
        or (f.metadata ->> v_relevance_key) !~ '^[0-9]+(\.[0-9]+)?$'
        or (f.metadata ->> v_relevance_key)::numeric >= p_min_locale_relevance
      )
  ),
  lexical_raw as (
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
    join relevant_foods f on f.id = a.food_id
    where a.locale = p_locale
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
    from relevant_foods f
    where p_query_embedding is not null
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
        coalesce(1.0 / (60 + lexical_ranked.lexical_rank), 0::numeric)
        + coalesce(1.0 / (60 + vector_ranked.vector_rank), 0::numeric)
      )::numeric as rrf_score
    from candidate_ids ids
    left join lexical_ranked using (food_id)
    left join vector_ranked using (food_id)
  )
  select
    f.id,
    public.localized_name(f.canonical_name::text, f.metadata, p_locale),
    coalesce(fused.matched_alias, f.canonical_name::text),
    case
      when fused.method = 'exact_alias' then fused.method
      when fused.lexical_rank is not null and fused.vector_rank is not null then 'hybrid_rrf'
      when fused.vector_rank is not null then 'semantic'
      else fused.method
    end,
    pg_catalog.round(
      least(
        1::numeric,
        fused.rrf_score * 25
          + case when fused.method = 'exact_alias' then 0.55 else 0 end
          + coalesce(
            public.query_name_overlap(
              v_query,
              public.localized_name(f.canonical_name::text, f.metadata, p_locale)
            ),
            0::numeric
          ) * 0.10
      ),
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
  order by
    (fused.method = 'exact_alias') desc,
    -- NULLS LAST is not cosmetic: DESC sorts NULLs first in Postgres, so a
    -- single row whose overlap came back NULL would be promoted to the top of
    -- the list ahead of every genuine match.
    coalesce(
      public.query_name_overlap(
        v_query,
        public.localized_name(f.canonical_name::text, f.metadata, p_locale)
      ),
      0::numeric
    ) desc,
    fused.rrf_score desc,
    fused.semantic_similarity desc nulls last,
    public.localized_name(f.canonical_name::text, f.metadata, p_locale),
    f.id
  limit v_limit;
end;
$$;

revoke all on function public.hybrid_search_food_catalog(text, extensions.vector, text, integer, numeric)
  from public, anon;
grant execute on function public.hybrid_search_food_catalog(text, extensions.vector, text, integer, numeric)
  to authenticated, service_role;

comment on function public.hybrid_search_food_catalog(text, extensions.vector, text, integer, numeric) is
  'Fuses exact alias, full-text/trigram, and pgvector cosine ranks using deterministic reciprocal-rank fusion. p_min_locale_relevance, when set, keeps generic_core rows and drops rows whose locale relevance score is below the floor; manual catalog search leaves it null so every imported product stays reachable.';
