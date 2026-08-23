-- AI estimate fallback groundwork.
--
-- 1. A vision call that succeeds but sees no food is a valid answer, not a
--    provider failure; the telemetry constraint learns the new reason.
-- 2. analysis_estimates stores server-recorded, bounds-checked macro
--    estimates for foods the catalog could not ground. The client can only
--    reference these rows by id; it can never supply nutrition itself.
-- 3. analysis_runs.estimate_item_count records how many response items were
--    estimates so quality dashboards can track fallback volume.
-- 4. meal_items learns 'ai_estimate': such rows never claim a catalog food
--    and must record which estimate their nutrition was copied from.

alter table public.analysis_runs
  drop constraint if exists analysis_runs_vision_fallback_reason_check;
alter table public.analysis_runs
  add constraint analysis_runs_vision_fallback_reason_check
  check (
    vision_fallback_reason is null
    or vision_fallback_reason in
      ('timeout', 'rate_limit', 'refusal', 'provider_error', 'no_food_detected')
  );

alter table public.analysis_runs
  add column if not exists estimate_item_count integer
    check (estimate_item_count is null or estimate_item_count >= 0);

comment on column public.analysis_runs.estimate_item_count is
  'How many response items carried AI-estimated nutrition instead of a catalog food.';

create table public.analysis_estimates (
  id uuid primary key default extensions.gen_random_uuid(),
  analysis_run_id uuid not null references public.analysis_runs (id) on delete cascade,
  item_key text not null,
  display_name text not null check (char_length(display_name) between 1 and 120),
  estimated_grams numeric(10, 2) not null check (estimated_grams between 1 and 3000),
  -- Mirrors the server-side acceptance bounds in analyze-meal/estimate.ts so
  -- an out-of-range estimate can never be recorded, whatever wrote it.
  calories_per_100g numeric(10, 3) not null check (calories_per_100g between 0 and 900),
  protein_per_100g numeric(10, 3) not null check (protein_per_100g between 0 and 100),
  carbs_per_100g numeric(10, 3) not null check (carbs_per_100g between 0 and 100),
  fat_per_100g numeric(10, 3) not null check (fat_per_100g between 0 and 100),
  confidence numeric(5, 4) not null check (confidence between 0 and 1),
  model text not null,
  prompt_version text not null,
  created_at timestamptz not null default now(),
  unique (analysis_run_id, item_key)
);

create index analysis_estimates_run_idx on public.analysis_estimates (analysis_run_id, item_key);

alter table public.analysis_estimates enable row level security;

-- Owner-read via run ownership, exactly like analysis_candidates. Writes stay
-- service-role only: no insert or update policy exists for authenticated.
create policy "analysis_estimates_select_own" on public.analysis_estimates for select to authenticated
using (exists (
  select 1 from public.analysis_runs ar
  where ar.id = analysis_run_id and ar.user_id = (select auth.uid())
));

grant select on table public.analysis_estimates to authenticated;
grant all privileges on table public.analysis_estimates to service_role;

alter table public.meal_items
  drop constraint if exists meal_items_match_method_check;
alter table public.meal_items
  add constraint meal_items_match_method_check check (
    match_method in ('exact', 'alias', 'retrieval', 'llm', 'manual', 'fallback', 'ai_estimate')
  );

-- food_id was already nullable (on delete set null keeps logged meals after a
-- catalog food is retired), so no relaxation is needed. The constraint pins
-- provenance instead: an estimated item never claims a catalog food and
-- always records which estimate its nutrition was copied from.
alter table public.meal_items
  add constraint meal_items_estimate_provenance check (
    match_method <> 'ai_estimate'
    or (food_id is null and nutrition_source like 'ai_estimate:%')
  );

comment on table public.analysis_estimates is
  'Server-recorded AI macro estimates for foods the catalog could not ground. '
  'Nutrition is copied from here at commit time, never from the client.';
