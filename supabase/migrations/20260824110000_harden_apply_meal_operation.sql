-- Harden apply_meal_operation: the client can never supply nutrition.
--
-- The original definition (20260817150000_conflict_safe_meal_rpc.sql) inserted
-- client-supplied per-100g values verbatim, contradicting the invariant the
-- review-safe commit path (20260823160000_review_safe_meal_commit.sql) already
-- enforces by re-reading nutrition from public.foods.
--
-- This replacement keeps the advisory-lock, row_version optimistic-concurrency
-- and idempotent-replay behavior identical and changes only how item nutrition
-- is sourced:
--   * Items that carry a food_id are re-read from public.foods; the payload's
--     per-100g values and nutrition_source are ignored. Deactivated foods are
--     still honored so queued offline operations composed before a catalog
--     deactivation can drain instead of being stranded forever; the values
--     used are still the server's, never the client's.
--   * Items without a food_id are offline custom entries composed from the
--     local catalog cache. There is no server row to re-read, so the snapshot
--     is accepted as a residual trust decision, but clamped to sanity bounds
--     (calories 0-900 per 100g, protein/carbs/fat 0-100 per 100g, grams
--     1-10000) so a forged payload cannot inflate daily totals beyond what a
--     plausible food could. least()/greatest() are parser constructs and are
--     immune to search_path, so they need no schema qualification.

create or replace function public.apply_meal_operation(
  p_operation_id uuid,
  p_operation_type text,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_meal jsonb;
  v_item jsonb;
  v_meal_id uuid;
  v_replay_meal_id uuid;
  v_expected_version bigint;
  v_current_version bigint;
  v_food public.foods%rowtype;
  v_food_id uuid;
  v_grams numeric;
  v_calories_per_100g numeric;
  v_protein_per_100g numeric;
  v_carbs_per_100g numeric;
  v_fat_per_100g numeric;
  v_nutrition_source text;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication required';
  end if;

  if p_operation_type not in ('upsert', 'delete') then
    raise exception using errcode = '22023', message = 'unsupported operation type';
  end if;

  if p_payload ->> 'operation_id' is distinct from p_operation_id::text then
    raise exception using errcode = '22023', message = 'operation id mismatch';
  end if;

  if p_operation_type = 'delete' then
    v_meal_id := nullif(p_payload ->> 'meal_id', '')::uuid;
    v_expected_version := nullif(p_payload ->> 'expected_row_version', '')::bigint;
    if v_meal_id is null then
      raise exception using errcode = '22023', message = 'meal id is required';
    end if;

    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(v_meal_id::text, 0)
    );
    select row_version
      into v_current_version
      from public.meals
      where id = v_meal_id and user_id = v_user_id;

    if not found then
      return pg_catalog.jsonb_build_object(
        'operation_id', p_operation_id,
        'meal_id', v_meal_id,
        'replay', true
      );
    end if;
    if v_expected_version is not null and v_expected_version <> v_current_version then
      raise exception using errcode = '40001', message = 'meal version conflict';
    end if;

    delete from public.meals
      where id = v_meal_id and user_id = v_user_id;
    return pg_catalog.jsonb_build_object(
      'operation_id', p_operation_id,
      'meal_id', v_meal_id,
      'deleted', true
    );
  end if;

  v_meal := p_payload -> 'meal';
  if v_meal is null or pg_catalog.jsonb_typeof(v_meal) <> 'object' then
    raise exception using errcode = '22023', message = 'meal payload is required';
  end if;
  v_meal_id := nullif(v_meal ->> 'id', '')::uuid;
  v_expected_version := nullif(p_payload ->> 'expected_row_version', '')::bigint;
  if v_meal_id is null then
    raise exception using errcode = '22023', message = 'meal id is required';
  end if;
  if v_meal ->> 'user_id' is distinct from v_user_id::text then
    raise exception using errcode = '42501', message = 'meal ownership mismatch';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_meal_id::text, 0)
  );

  select id
    into v_replay_meal_id
    from public.meals
    where user_id = v_user_id and client_request_id = p_operation_id;
  if found then
    if v_replay_meal_id <> v_meal_id then
      raise exception using errcode = '23505', message = 'operation id reused';
    end if;
    return pg_catalog.jsonb_build_object(
      'operation_id', p_operation_id,
      'meal_id', v_meal_id,
      'replay', true
    );
  end if;

  select row_version
    into v_current_version
    from public.meals
    where id = v_meal_id and user_id = v_user_id;

  if found then
    if v_expected_version is null or v_expected_version <> v_current_version then
      raise exception using errcode = '40001', message = 'meal version conflict';
    end if;
    update public.meals
      set client_request_id = p_operation_id,
          name = v_meal ->> 'name',
          raw_input = v_meal ->> 'raw_input',
          occurred_at = (v_meal ->> 'occurred_at')::timestamptz,
          image_path = v_meal ->> 'image_path',
          row_version = row_version + 1
      where id = v_meal_id and user_id = v_user_id
      returning row_version into v_current_version;
  else
    if v_expected_version is not null then
      raise exception using errcode = '40001', message = 'meal no longer exists';
    end if;
    insert into public.meals (
      id,
      user_id,
      client_request_id,
      name,
      raw_input,
      occurred_at,
      image_path
    ) values (
      v_meal_id,
      v_user_id,
      p_operation_id,
      v_meal ->> 'name',
      v_meal ->> 'raw_input',
      (v_meal ->> 'occurred_at')::timestamptz,
      v_meal ->> 'image_path'
    )
    returning row_version into v_current_version;
  end if;

  delete from public.meal_items where meal_id = v_meal_id;
  for v_item in
    select value
    from pg_catalog.jsonb_array_elements(
      coalesce(v_meal -> 'items', '[]'::jsonb)
    )
  loop
    v_food_id := nullif(v_item ->> 'food_id', '')::uuid;
    v_grams := (v_item ->> 'grams')::numeric;

    if v_food_id is not null then
      -- Catalog-linked item: nutrition always comes from the server catalog.
      -- Client-supplied per-100g values and nutrition_source are ignored.
      select * into v_food
        from public.foods
        where id = v_food_id;
      if not found then
        raise exception using errcode = '22023', message = 'catalog food is unavailable';
      end if;
      v_calories_per_100g := v_food.calories_per_100g;
      v_protein_per_100g := v_food.protein_per_100g;
      v_carbs_per_100g := v_food.carbs_per_100g;
      v_fat_per_100g := v_food.fat_per_100g;
      v_nutrition_source := v_food.source || ':' || v_food.source_food_id;
    else
      -- Residual trust: an offline custom entry has no catalog row to
      -- re-read, so the client snapshot is accepted but clamped to bounds a
      -- real food cannot exceed. Nulls stay null so the table's NOT NULL
      -- constraints keep rejecting incomplete payloads as before.
      v_grams := least(10000::numeric, greatest(1::numeric, v_grams));
      v_calories_per_100g := least(
        900::numeric,
        greatest(0::numeric, (v_item ->> 'calories_per_100g')::numeric)
      );
      v_protein_per_100g := least(
        100::numeric,
        greatest(0::numeric, (v_item ->> 'protein_per_100g')::numeric)
      );
      v_carbs_per_100g := least(
        100::numeric,
        greatest(0::numeric, (v_item ->> 'carbs_per_100g')::numeric)
      );
      v_fat_per_100g := least(
        100::numeric,
        greatest(0::numeric, (v_item ->> 'fat_per_100g')::numeric)
      );
      v_nutrition_source := v_item ->> 'nutrition_source';
    end if;

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
      (v_item ->> 'id')::uuid,
      v_meal_id,
      v_food_id,
      (v_item ->> 'position')::smallint,
      v_item ->> 'source_text',
      v_item ->> 'canonical_name',
      v_item ->> 'portion_label',
      v_grams,
      v_calories_per_100g,
      v_protein_per_100g,
      v_carbs_per_100g,
      v_fat_per_100g,
      1,
      'manual',
      'accepted',
      v_nutrition_source
    );
  end loop;

  return pg_catalog.jsonb_build_object(
    'operation_id', p_operation_id,
    'meal_id', v_meal_id,
    'row_version', v_current_version,
    'replay', false
  );
end;
$$;

revoke all on function public.apply_meal_operation(uuid, text, jsonb) from public;
revoke all on function public.apply_meal_operation(uuid, text, jsonb) from anon;
grant execute on function public.apply_meal_operation(uuid, text, jsonb)
  to authenticated, service_role;

comment on function public.apply_meal_operation(uuid, text, jsonb) is
  'Applies one authenticated, idempotent meal outbox operation atomically; catalog-linked item nutrition is re-read from foods, custom entries are clamped.';
