-- ============================================================================
-- Analysis quality telemetry
--
-- Two problems this fixes.
--
-- 1. commit_analyzed_meal hardcoded match_method='manual' and
--    review_status='accepted' for every item, so the columns carried no
--    information. The real match method already sits in
--    analysis_candidates.rationale.method, and analysis_runs.output holds the
--    model's original proposal — everything needed to tell whether the user
--    accepted or changed the answer is already in the database.
--
-- 2. meal_item_corrections was declared but never written, so no correction
--    signal existed at all.
--
-- The commit RPC now diffs the committed items against the stored proposal and
-- records what changed. Correction writes are wrapped so telemetry can never
-- stop a meal from being logged.
--
-- Known limitation: a proposed item the user dropped entirely cannot be
-- recorded, because meal_item_corrections.meal_item_id is NOT NULL and no
-- meal_items row exists for it.
-- ============================================================================

create or replace function public.commit_analyzed_meal(
  p_analysis_run_id uuid,
  p_commit_request_id uuid,
  p_meal_id uuid,
  p_name text,
  p_occurred_at timestamptz,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_analysis_status text;
  v_output jsonb;
  v_existing_meal public.meals%rowtype;
  v_meal public.meals%rowtype;
  v_item jsonb;
  v_food public.foods%rowtype;
  v_candidate public.analysis_candidates%rowtype;
  v_position integer := 0;
  v_grams numeric;
  -- telemetry
  v_proposal jsonb;
  v_proposed_grams numeric;
  v_method text;
  v_review_status text;
  v_food_changed boolean;
  v_portion_changed boolean;
  v_item_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication required';
  end if;
  if p_analysis_run_id is null or p_commit_request_id is null or p_meal_id is null then
    raise exception using errcode = '22023', message = 'analysis, commit, and meal ids are required';
  end if;
  if p_name is null or pg_catalog.char_length(pg_catalog.btrim(p_name)) not between 1 and 120 then
    raise exception using errcode = '22023', message = 'meal name must contain 1 to 120 characters';
  end if;
  if p_occurred_at is null then
    raise exception using errcode = '22023', message = 'occurred_at is required';
  end if;
  if p_items is null or pg_catalog.jsonb_typeof(p_items) <> 'array' then
    raise exception using errcode = '22023', message = 'items must be an array';
  end if;
  if pg_catalog.jsonb_array_length(p_items) not between 1 and 50 then
    raise exception using errcode = '22023', message = 'items must contain 1 to 50 entries';
  end if;
  if (
    select pg_catalog.count(*) <> pg_catalog.count(distinct item ->> 'item_key')
    from pg_catalog.jsonb_array_elements(p_items) item
  ) then
    raise exception using errcode = '22023', message = 'item keys must be unique';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_analysis_run_id::text, 0)
  );

  select status, output
    into v_analysis_status, v_output
    from public.analysis_runs
    where id = p_analysis_run_id and user_id = v_user_id;
  if not found then
    raise exception using errcode = '42501', message = 'analysis run is unavailable';
  end if;

  select *
    into v_existing_meal
    from public.meals
    where user_id = v_user_id and client_request_id = p_commit_request_id;
  if found then
    if v_existing_meal.id <> p_meal_id or
       v_existing_meal.analysis_run_id is distinct from p_analysis_run_id then
      raise exception using errcode = '23505', message = 'commit request id reused';
    end if;
    return pg_catalog.jsonb_build_object(
      'meal_id', v_existing_meal.id,
      'analysis_run_id', v_existing_meal.analysis_run_id,
      'row_version', v_existing_meal.row_version,
      'calories', v_existing_meal.calories,
      'protein', v_existing_meal.protein,
      'carbs', v_existing_meal.carbs,
      'fat', v_existing_meal.fat,
      'replayed', true
    );
  end if;

  if v_analysis_status <> 'needs_review' then
    raise exception using errcode = '40001', message = 'analysis run is not ready to commit';
  end if;
  if exists (
    select 1 from public.meals
    where id = p_meal_id and user_id <> v_user_id
  ) then
    raise exception using errcode = '42501', message = 'meal id is unavailable';
  end if;
  if exists (
    select 1 from public.meals
    where id = p_meal_id and user_id = v_user_id
  ) then
    raise exception using errcode = '23505', message = 'meal id already exists';
  end if;

  insert into public.meals (
    id,
    user_id,
    analysis_run_id,
    client_request_id,
    name,
    raw_input,
    occurred_at
  )
  select
    p_meal_id,
    v_user_id,
    p_analysis_run_id,
    p_commit_request_id,
    pg_catalog.btrim(p_name),
    raw_input,
    p_occurred_at
  from public.analysis_runs
  where id = p_analysis_run_id and user_id = v_user_id;

  for v_item in
    select value
    from pg_catalog.jsonb_array_elements(p_items)
  loop
    if nullif(v_item ->> 'item_key', '') is null or nullif(v_item ->> 'food_id', '') is null then
      raise exception using errcode = '22023', message = 'item_key and food_id are required';
    end if;
    begin
      v_grams := (v_item ->> 'grams')::numeric;
    exception when invalid_text_representation then
      raise exception using errcode = '22023', message = 'grams must be numeric';
    end;
    if v_grams is null or v_grams <= 0 or v_grams > 10000 then
      raise exception using errcode = '22023', message = 'grams must be between 0 and 10000';
    end if;
    if nullif(v_item ->> 'portion_label', '') is null or
       pg_catalog.char_length(v_item ->> 'portion_label') > 120 then
      raise exception using errcode = '22023', message = 'portion_label is required';
    end if;

    select *
      into v_candidate
      from public.analysis_candidates
      where analysis_run_id = p_analysis_run_id
        and item_key = v_item ->> 'item_key'
        and food_id = (v_item ->> 'food_id')::uuid
      order by rank
      limit 1;
    if not found then
      raise exception using errcode = '22023', message = 'food is outside the grounded candidate set';
    end if;

    select *
      into v_food
      from public.foods
      where id = v_candidate.food_id and is_active;
    if not found then
      raise exception using errcode = '22023', message = 'catalog food is unavailable';
    end if;

    -- ── What did the model originally propose for this item? ──────────────
    v_proposal := (
      select element
      from pg_catalog.jsonb_array_elements(
        case when pg_catalog.jsonb_typeof(v_output -> 'items') = 'array'
          then v_output -> 'items' else '[]'::jsonb end
      ) element
      where element ->> 'itemKey' = v_item ->> 'item_key'
      limit 1
    );

    v_method := coalesce(
      nullif(v_candidate.rationale ->> 'method', ''),
      nullif(v_proposal ->> 'matchMethod', ''),
      'manual'
    );
    if v_method not in ('exact', 'alias', 'retrieval', 'llm', 'manual', 'fallback') then
      v_method := 'manual';
    end if;

    v_food_changed := v_proposal is not null
      and nullif(v_proposal ->> 'foodId', '') is not null
      and (v_proposal ->> 'foodId') is distinct from (v_item ->> 'food_id');

    begin
      v_proposed_grams := nullif(v_proposal ->> 'grams', '')::numeric;
    exception when others then
      v_proposed_grams := null;
    end;

    -- A gram or two of rounding is not a correction; 2% or 1 g, whichever is
    -- larger, keeps noise out of the portion-error metric.
    v_portion_changed := v_proposed_grams is not null
      and pg_catalog.abs(v_proposed_grams - v_grams)
          > pg_catalog.greatest(1::numeric, v_proposed_grams * 0.02);

    v_review_status := case
      when v_food_changed or v_portion_changed then 'corrected'
      else 'accepted'
    end;

    v_item_id := extensions.gen_random_uuid();

    insert into public.meal_items (
      id,
      meal_id,
      food_id,
      position,
      source_text,
      canonical_name,
      portion_label,
      grams,
      calories_per_100g,
      protein_per_100g,
      carbs_per_100g,
      fat_per_100g,
      confidence,
      match_method,
      review_status,
      nutrition_source
    ) values (
      v_item_id,
      p_meal_id,
      v_food.id,
      v_position,
      coalesce(nullif(v_item ->> 'source_text', ''), v_food.canonical_name::text),
      v_food.canonical_name::text,
      v_item ->> 'portion_label',
      v_grams,
      v_food.calories_per_100g,
      v_food.protein_per_100g,
      v_food.carbs_per_100g,
      v_food.fat_per_100g,
      pg_catalog.greatest(0, pg_catalog.least(1, coalesce(v_candidate.retrieval_score, 0.5))),
      v_method,
      v_review_status,
      v_food.source || ':' || v_food.source_food_id
    );

    -- ── Correction log. Never allowed to block the commit. ────────────────
    if v_food_changed then
      begin
        insert into public.meal_item_corrections (
          user_id, meal_item_id, analysis_run_id, before_value, after_value, reason
        ) values (
          v_user_id, v_item_id, p_analysis_run_id,
          pg_catalog.jsonb_build_object(
            'food_id', v_proposal ->> 'foodId',
            'canonical_name', v_proposal ->> 'canonicalName',
            'confidence', v_proposal ->> 'confidence',
            'match_method', v_proposal ->> 'matchMethod'
          ),
          pg_catalog.jsonb_build_object(
            'food_id', v_item ->> 'food_id',
            'canonical_name', v_food.canonical_name::text
          ),
          'wrong_food'
        );
      exception when others then
        null;
      end;
    end if;

    if v_portion_changed then
      begin
        insert into public.meal_item_corrections (
          user_id, meal_item_id, analysis_run_id, before_value, after_value, reason
        ) values (
          v_user_id, v_item_id, p_analysis_run_id,
          pg_catalog.jsonb_build_object(
            'grams', v_proposed_grams,
            'portion_label', v_proposal ->> 'portionLabel'
          ),
          pg_catalog.jsonb_build_object(
            'grams', v_grams,
            'portion_label', v_item ->> 'portion_label'
          ),
          'wrong_portion'
        );
      exception when others then
        null;
      end;
    end if;

    v_position := v_position + 1;
  end loop;

  update public.analysis_runs
    set status = 'completed', completed_at = coalesce(completed_at, now())
    where id = p_analysis_run_id and user_id = v_user_id;

  select * into strict v_meal
    from public.meals
    where id = p_meal_id and user_id = v_user_id;

  return pg_catalog.jsonb_build_object(
    'meal_id', v_meal.id,
    'analysis_run_id', v_meal.analysis_run_id,
    'row_version', v_meal.row_version,
    'calories', v_meal.calories,
    'protein', v_meal.protein,
    'carbs', v_meal.carbs,
    'fat', v_meal.fat,
    'replayed', false
  );
end;
$$;

revoke all on function public.commit_analyzed_meal(uuid, uuid, uuid, text, timestamptz, jsonb)
  from public, anon;
grant execute on function public.commit_analyzed_meal(uuid, uuid, uuid, text, timestamptz, jsonb)
  to authenticated, service_role;

comment on function public.commit_analyzed_meal(uuid, uuid, uuid, text, timestamptz, jsonb) is
  'Atomically commits one owned analysis using catalog-authoritative nutrition snapshots, '
  'recording the real match method and any food or portion the user changed.';
