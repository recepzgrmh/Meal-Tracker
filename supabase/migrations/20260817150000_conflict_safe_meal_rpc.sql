alter table public.meals
  add column row_version bigint not null default 1
  check (row_version > 0);

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
      nullif(v_item ->> 'food_id', '')::uuid,
      (v_item ->> 'position')::smallint,
      v_item ->> 'source_text',
      v_item ->> 'canonical_name',
      v_item ->> 'portion_label',
      (v_item ->> 'grams')::numeric,
      (v_item ->> 'calories_per_100g')::numeric,
      (v_item ->> 'protein_per_100g')::numeric,
      (v_item ->> 'carbs_per_100g')::numeric,
      (v_item ->> 'fat_per_100g')::numeric,
      1,
      'manual',
      'accepted',
      v_item ->> 'nutrition_source'
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
  'Applies one authenticated, idempotent meal outbox operation atomically.';
