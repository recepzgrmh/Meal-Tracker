begin;

select plan(11);

insert into auth.users (id, aud, role)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated')
on conflict (id) do nothing;

insert into public.analysis_runs (
  id, user_id, client_request_id, raw_input, input_kind, status, output, image_path
)
values
  (
    '20000000-0000-4000-8000-000000000001',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '21000000-0000-4000-8000-000000000001',
    'yumurta', 'text', 'needs_review',
    '{"items":[{"itemKey":"item-1","foodId":"10000000-0000-0000-0000-000000000001","canonicalName":"Yumurta","grams":50,"portionLabel":"1 adet","confidence":0.95,"matchMethod":"exact"}]}'::jsonb,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/21000000-0000-4000-8000-000000000001/source.jpg'
  ),
  (
    '20000000-0000-4000-8000-000000000002',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '21000000-0000-4000-8000-000000000002',
    'peynir', 'text', 'needs_review',
    '{"items":[{"itemKey":"item-1","foodId":"10000000-0000-0000-0000-000000000002","canonicalName":"Peynir","grams":30,"portionLabel":"1 porsiyon","confidence":0.8,"matchMethod":"alias"}]}'::jsonb,
    null
  ),
  (
    '20000000-0000-4000-8000-000000000003',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '21000000-0000-4000-8000-000000000003',
    'yumurta', 'text', 'needs_review',
    '{"items":[{"itemKey":"item-1","foodId":"10000000-0000-0000-0000-000000000001","canonicalName":"Yumurta","grams":50,"portionLabel":"1 adet","confidence":0.95,"matchMethod":"exact"}]}'::jsonb,
    null
  );

insert into public.analysis_candidates (
  analysis_run_id, item_key, food_id, rank, retrieval_score, selected, rationale
)
values
  ('20000000-0000-4000-8000-000000000001', 'item-1', '10000000-0000-0000-0000-000000000001', 1, 0.95, true, '{"method":"exact"}'),
  ('20000000-0000-4000-8000-000000000002', 'item-1', '10000000-0000-0000-0000-000000000002', 1, 0.80, true, '{"method":"alias"}'),
  ('20000000-0000-4000-8000-000000000003', 'item-1', '10000000-0000-0000-0000-000000000001', 1, 0.95, true, '{"method":"exact"}');

set local role authenticated;
set local request.jwt.claim.sub = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

select lives_ok(
  $$select public.commit_analyzed_meal(
    '20000000-0000-4000-8000-000000000001',
    '22000000-0000-4000-8000-000000000001',
    '23000000-0000-4000-8000-000000000001',
    'Kahvaltı', now(),
    '[{"item_id":"24000000-0000-4000-8000-000000000001","item_key":"item-1","food_id":"10000000-0000-0000-0000-000000000001","source_text":"yumurta","portion_label":"1 adet","grams":50}]'::jsonb
  )$$,
  'unchanged grounded item commits'
);
select is(
  (select id::text from public.meal_items where meal_id = '23000000-0000-4000-8000-000000000001'),
  '24000000-0000-4000-8000-000000000001',
  'client item UUID is preserved'
);
select is(
  (select image_path from public.meals where id = '23000000-0000-4000-8000-000000000001'),
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/21000000-0000-4000-8000-000000000001/source.jpg',
  'analysis photo path is copied to meal'
);

select lives_ok(
  $$select public.commit_analyzed_meal(
    '20000000-0000-4000-8000-000000000002',
    '22000000-0000-4000-8000-000000000002',
    '23000000-0000-4000-8000-000000000002',
    'Review variant', now(),
    '[{"item_id":"24000000-0000-4000-8000-000000000002","item_key":"item-1","food_id":"10000000-0000-0000-0000-000000000003","source_text":"simit","portion_label":"1 adet","grams":100}]'::jsonb
  )$$,
  'review variant outside original candidate set commits'
);
select is(
  (select food_id::text from public.meal_items where id = '24000000-0000-4000-8000-000000000002'),
  '10000000-0000-0000-0000-000000000003',
  'review variant uses selected active catalog food'
);
select is(
  (select review_status from public.meal_items where id = '24000000-0000-4000-8000-000000000002'),
  'corrected',
  'review variant is marked corrected'
);
select ok(
  exists(select 1 from public.meal_item_corrections where meal_item_id = '24000000-0000-4000-8000-000000000002' and reason = 'wrong_food'),
  'review variant emits wrong_food telemetry'
);

select lives_ok(
  $$select public.commit_analyzed_meal(
    '20000000-0000-4000-8000-000000000003',
    '22000000-0000-4000-8000-000000000003',
    '23000000-0000-4000-8000-000000000003',
    'Manual addition', now(),
    '[{"item_id":"24000000-0000-4000-8000-000000000003","item_key":"manual-item-1","food_id":"10000000-0000-0000-0000-000000000002","source_text":"peynir","portion_label":"30 g","grams":30}]'::jsonb
  )$$,
  'manual catalog addition commits'
);
select is(
  (select food_id::text from public.meal_items where id = '24000000-0000-4000-8000-000000000003'),
  '10000000-0000-0000-0000-000000000002',
  'manual addition uses active catalog food'
);
select is(
  (select calories_per_100g::numeric from public.meal_items where id = '24000000-0000-4000-8000-000000000003'),
  (select calories_per_100g::numeric from public.foods where id = '10000000-0000-0000-0000-000000000002'),
  'manual nutrition is read from server catalog'
);
select ok(
  exists(select 1 from public.meal_item_corrections where meal_item_id = '24000000-0000-4000-8000-000000000003' and reason = 'missing_item'),
  'manual addition emits missing_item telemetry'
);

select * from finish();
rollback;
