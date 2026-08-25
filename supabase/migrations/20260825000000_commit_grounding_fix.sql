-- Estimate-aware analyzed-meal commit.
--
-- Replaces public.commit_analyzed_meal from 20260823160000 (that file stays
-- untouched; this copy supersedes it). An item may now reference a
-- server-recorded AI estimate instead of a catalog food: the payload gains an
-- optional estimate_id, mutually exclusive with food_id. Nutrition for such
-- items is copied FROM analysis_estimates — the estimate must belong to the
-- same run (and therefore the same user) — never from the payload, keeping
-- the invariant that the client can never supply nutrition.

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
  v_image_path text;
  v_existing_meal public.meals%rowtype;
  v_meal public.meals%rowtype;
  v_item jsonb;
  v_food public.foods%rowtype;
  v_candidate public.analysis_candidates%rowtype;
  v_estimate public.analysis_estimates%rowtype;
  v_position integer := 0;
  v_grams numeric;
  v_food_id uuid;
  v_estimate_id uuid;
  v_item_id uuid;
  v_proposal jsonb;
  v_proposed_grams numeric;
  v_method text;
  v_review_status text;
  v_food_changed boolean;
  v_portion_changed boolean;
  v_manual_addition boolean;
  v_confidence numeric;
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
  if (
    select pg_catalog.count(*) <> pg_catalog.count(distinct item ->> 'item_id')
    from pg_catalog.jsonb_array_elements(p_items) item
  ) then
    raise exception using errcode = '22023', message = 'item ids must be unique';
  end if;

  -- Verify each food_id was in the grounded candidate set
  if exists (
    select 1 from pg_catalog.jsonb_array_elements(p_items) as item
    where item->>'food_id' is not null
    and not exists (
      select 1 from public.analysis_candidates ac
      where ac.analysis_run_id = p_analysis_run_id
      and ac.food_id = (item->>'food_id')::uuid
    )
  ) then
    raise exception 'Submitted food_id not in grounded candidate set'
      using errcode = '23514'; -- check_violation
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_analysis_run_id::text, 0)
  );

  select status, output, image_path
    into v_analysis_status, v_output, v_image_path
    from public.analysis_runs
    where id = p_analysis_run_id and user_id = v_user_id;
  if not found then
    raise exception using errcode = '42501', message = 'analysis run is unavailable';
  end if;

  select * into v_existing_meal
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
  if exists (select 1 from public.meals where id = p_meal_id) then
    if exists (select 1 from public.meals where id = p_meal_id and user_id <> v_user_id) then
      raise exception using errcode = '42501', message = 'meal id is unavailable';
    end if;
    raise exception using errcode = '23505', message = 'meal id already exists';
  end if;

  insert into public.meals (
    id, user_id, analysis_run_id, client_request_id, name, raw_input,
    occurred_at, image_path
  )
  select
    p_meal_id, v_user_id, p_analysis_run_id, p_commit_request_id,
    pg_catalog.btrim(p_name), raw_input, p_occurred_at, v_image_path
  from public.analysis_runs
  where id = p_analysis_run_id and user_id = v_user_id;

  for v_item in select value from pg_catalog.jsonb_array_elements(p_items)
  loop
    if nullif(v_item ->> 'item_id', '') is null or
       nullif(v_item ->> 'item_key', '') is null then
      raise exception using errcode = '22023', message = 'item_id and item_key are required';
    end if;
    if (nullif(v_item ->> 'food_id', '') is null) =
       (nullif(v_item ->> 'estimate_id', '') is null) then
      raise exception using errcode = '22023',
        message = 'exactly one of food_id and estimate_id is required';
    end if;
    begin
      v_item_id := (v_item ->> 'item_id')::uuid;
      v_food_id := nullif(v_item ->> 'food_id', '')::uuid;
      v_estimate_id := nullif(v_item ->> 'estimate_id', '')::uuid;
      v_grams := (v_item ->> 'grams')::numeric;
    exception when invalid_text_representation then
      raise exception using errcode = '22023',
        message = 'item_id, food_id, estimate_id and grams must be valid';
    end;
    if v_grams is null or v_grams <= 0 or v_grams > 10000 then
      raise exception using errcode = '22023', message = 'grams must be between 0 and 10000';
    end if;
    if nullif(v_item ->> 'portion_label', '') is null or
       pg_catalog.char_length(v_item ->> 'portion_label') > 120 then
      raise exception using errcode = '22023', message = 'portion_label is required';
    end if;

    v_proposal := (
      select element
      from pg_catalog.jsonb_array_elements(
        case when pg_catalog.jsonb_typeof(v_output -> 'items') = 'array'
          then v_output -> 'items' else '[]'::jsonb end
      ) element
      where element ->> 'itemKey' = v_item ->> 'item_key'
      limit 1
    );
    v_manual_addition := v_proposal is null;
    v_food_changed := false;

    begin
      v_proposed_grams := nullif(v_proposal ->> 'grams', '')::numeric;
    exception when others then
      v_proposed_grams := null;
    end;
    v_portion_changed := v_proposed_grams is not null
      and pg_catalog.abs(v_proposed_grams - v_grams)
          > pg_catalog.greatest(1::numeric, v_proposed_grams * 0.02);

    if v_estimate_id is not null then
      -- The estimate must belong to this exact run: run ownership was already
      -- verified above, so an id copied from someone else's (or another) run
      -- cannot smuggle nutrition into this meal.
      select * into v_estimate
        from public.analysis_estimates
        where id = v_estimate_id and analysis_run_id = p_analysis_run_id;
      if not found then
        raise exception using errcode = '42501', message = 'estimate is unavailable';
      end if;

      v_method := 'ai_estimate';
      -- Estimated nutrition is never silently trusted: the item stays flagged
      -- for review however closely the user kept the proposed portion.
      v_review_status := 'unreviewed';
      v_confidence := pg_catalog.greatest(0, pg_catalog.least(1, v_estimate.confidence));

      insert into public.meal_items (
        id, meal_id, food_id, position, source_text, canonical_name,
        portion_label, grams, calories_per_100g, protein_per_100g,
        carbs_per_100g, fat_per_100g, confidence, match_method,
        review_status, nutrition_source
      ) values (
        v_item_id, p_meal_id, null, v_position,
        coalesce(nullif(v_item ->> 'source_text', ''), v_estimate.display_name),
        v_estimate.display_name, v_item ->> 'portion_label', v_grams,
        v_estimate.calories_per_100g, v_estimate.protein_per_100g,
        v_estimate.carbs_per_100g, v_estimate.fat_per_100g, v_confidence,
        v_method, v_review_status, 'ai_estimate:' || v_estimate.id
      );
    else
      select * into v_candidate
        from public.analysis_candidates
        where analysis_run_id = p_analysis_run_id
          and item_key = v_item ->> 'item_key'
          and food_id = v_food_id
        order by rank
        limit 1;

      select * into v_food
        from public.foods
        where id = v_food_id and is_active;
      if not found then
        raise exception using errcode = '22023', message = 'catalog food is unavailable';
      end if;

      v_food_changed := v_proposal is not null
        and nullif(v_proposal ->> 'foodId', '') is not null
        and (v_proposal ->> 'foodId') is distinct from (v_item ->> 'food_id');

      if v_candidate.id is not null then
        v_method := coalesce(
          nullif(v_candidate.rationale ->> 'method', ''),
          nullif(v_proposal ->> 'matchMethod', ''),
          'manual'
        );
        v_confidence := pg_catalog.greatest(
          0, pg_catalog.least(1, coalesce(v_candidate.retrieval_score, 0.5))
        );
      else
        -- An explicit review choice may select any active catalog food. The
        -- payload cannot supply nutrition, so this does not weaken nutrition
        -- integrity or allow an arbitrary food row.
        v_method := 'manual';
        v_confidence := 1;
      end if;
      if v_method not in ('exact', 'alias', 'retrieval', 'llm', 'manual', 'fallback') then
        v_method := 'manual';
      end if;
      v_review_status := case
        when v_manual_addition or v_food_changed or v_portion_changed then 'corrected'
        else 'accepted'
      end;

      insert into public.meal_items (
        id, meal_id, food_id, position, source_text, canonical_name,
        portion_label, grams, calories_per_100g, protein_per_100g,
        carbs_per_100g, fat_per_100g, confidence, match_method,
        review_status, nutrition_source
      ) values (
        v_item_id, p_meal_id, v_food.id, v_position,
        coalesce(nullif(v_item ->> 'source_text', ''), v_food.canonical_name::text),
        v_food.canonical_name::text, v_item ->> 'portion_label', v_grams,
        v_food.calories_per_100g, v_food.protein_per_100g,
        v_food.carbs_per_100g, v_food.fat_per_100g, v_confidence,
        v_method, v_review_status, v_food.source || ':' || v_food.source_food_id
      );
    end if;

    if v_estimate_id is null and (v_manual_addition or v_food_changed) then
      begin
        insert into public.meal_item_corrections (
          user_id, meal_item_id, analysis_run_id, before_value, after_value, reason
        ) values (
          v_user_id, v_item_id, p_analysis_run_id,
          case when v_manual_addition then '{}'::jsonb else pg_catalog.jsonb_build_object(
            'food_id', v_proposal ->> 'foodId',
            'canonical_name', v_proposal ->> 'canonicalName',
            'confidence', v_proposal ->> 'confidence',
            'match_method', v_proposal ->> 'matchMethod'
          ) end,
          pg_catalog.jsonb_build_object(
            'food_id', v_food.id,
            'canonical_name', v_food.canonical_name::text
          ),
          case when v_manual_addition then 'missing_item' else 'wrong_food' end
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
  'Commits grounded, variant, manual, and AI-estimated review items. Nutrition comes from '
  'the active catalog or a same-run analysis_estimates row, never from the client payload.';
