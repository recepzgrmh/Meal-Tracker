create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema extensions;
create extension if not exists vector with schema extensions;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  locale text not null default 'tr-TR',
  timezone text not null default 'Europe/Istanbul',
  daily_calorie_target integer not null default 2100 check (daily_calorie_target between 500 and 10000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.foods (
  id uuid primary key default extensions.gen_random_uuid(),
  canonical_name extensions.citext not null,
  locale text not null default 'tr-TR',
  source text not null,
  source_food_id text not null,
  calories_per_100g numeric(10, 3) not null check (calories_per_100g >= 0),
  protein_per_100g numeric(10, 3) not null check (protein_per_100g >= 0),
  carbs_per_100g numeric(10, 3) not null check (carbs_per_100g >= 0),
  fat_per_100g numeric(10, 3) not null check (fat_per_100g >= 0),
  embedding extensions.vector(1536),
  embedding_model text,
  metadata jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source, source_food_id)
);

create table public.food_aliases (
  id bigint generated always as identity primary key,
  food_id uuid not null references public.foods (id) on delete cascade,
  alias extensions.citext not null,
  locale text not null default 'tr-TR',
  priority smallint not null default 0 check (priority between -100 and 100),
  created_at timestamptz not null default now(),
  unique (alias, locale, food_id)
);

create table public.food_portions (
  id bigint generated always as identity primary key,
  food_id uuid not null references public.foods (id) on delete cascade,
  label extensions.citext not null,
  grams numeric(10, 2) not null check (grams > 0 and grams <= 10000),
  locale text not null default 'tr-TR',
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  unique (food_id, label, locale)
);

create table public.analysis_runs (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  client_request_id uuid not null,
  trace_id uuid not null default extensions.gen_random_uuid(),
  raw_input text not null check (char_length(raw_input) between 1 and 4000),
  input_kind text not null default 'text' check (input_kind in ('text', 'voice', 'image', 'mixed')),
  status text not null default 'pending' check (status in ('pending', 'running', 'needs_review', 'completed', 'failed')),
  model_name text,
  prompt_version text,
  retrieval_version text,
  latency_ms integer check (latency_ms is null or latency_ms >= 0),
  output jsonb,
  error_code text,
  error_detail text,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (user_id, client_request_id),
  unique (trace_id)
);

create table public.analysis_candidates (
  id bigint generated always as identity primary key,
  analysis_run_id uuid not null references public.analysis_runs (id) on delete cascade,
  item_key text not null,
  food_id uuid references public.foods (id) on delete set null,
  rank smallint not null check (rank > 0),
  retrieval_score numeric(8, 6) check (retrieval_score is null or retrieval_score between -1 and 1),
  rerank_score numeric(8, 6) check (rerank_score is null or rerank_score between 0 and 1),
  selected boolean not null default false,
  rationale jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (analysis_run_id, item_key, rank)
);

create table public.meals (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  analysis_run_id uuid references public.analysis_runs (id) on delete set null,
  client_request_id uuid not null,
  name text not null check (char_length(name) between 1 and 120),
  raw_input text,
  occurred_at timestamptz not null,
  image_path text,
  calories numeric(12, 2) not null default 0 check (calories >= 0),
  protein numeric(12, 2) not null default 0 check (protein >= 0),
  carbs numeric(12, 2) not null default 0 check (carbs >= 0),
  fat numeric(12, 2) not null default 0 check (fat >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, client_request_id)
);

create table public.meal_items (
  id uuid primary key default extensions.gen_random_uuid(),
  meal_id uuid not null references public.meals (id) on delete cascade,
  food_id uuid references public.foods (id) on delete set null,
  position smallint not null default 0 check (position >= 0),
  source_text text not null,
  canonical_name text not null,
  portion_label text not null,
  grams numeric(10, 2) not null check (grams > 0 and grams <= 10000),
  calories_per_100g numeric(10, 3) not null check (calories_per_100g >= 0),
  protein_per_100g numeric(10, 3) not null check (protein_per_100g >= 0),
  carbs_per_100g numeric(10, 3) not null check (carbs_per_100g >= 0),
  fat_per_100g numeric(10, 3) not null check (fat_per_100g >= 0),
  calories numeric(12, 2) generated always as (round(calories_per_100g * grams / 100, 2)) stored,
  protein numeric(12, 2) generated always as (round(protein_per_100g * grams / 100, 2)) stored,
  carbs numeric(12, 2) generated always as (round(carbs_per_100g * grams / 100, 2)) stored,
  fat numeric(12, 2) generated always as (round(fat_per_100g * grams / 100, 2)) stored,
  confidence numeric(5, 4) not null check (confidence between 0 and 1),
  match_method text not null check (match_method in ('exact', 'alias', 'retrieval', 'llm', 'manual', 'fallback')),
  review_status text not null default 'unreviewed' check (review_status in ('unreviewed', 'accepted', 'corrected', 'rejected')),
  nutrition_source text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (meal_id, position)
);

create table public.meal_item_corrections (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  meal_item_id uuid not null references public.meal_items (id) on delete cascade,
  analysis_run_id uuid references public.analysis_runs (id) on delete set null,
  before_value jsonb not null,
  after_value jsonb not null,
  reason text check (reason in ('wrong_food', 'wrong_portion', 'wrong_nutrition', 'missing_item', 'other')),
  created_at timestamptz not null default now()
);

create index foods_canonical_name_idx on public.foods (canonical_name);
create index foods_embedding_hnsw_idx on public.foods using hnsw (embedding extensions.vector_cosine_ops) where embedding is not null;
create index food_aliases_alias_idx on public.food_aliases (alias, locale);
create index analysis_runs_user_created_idx on public.analysis_runs (user_id, created_at desc);
create index analysis_candidates_run_idx on public.analysis_candidates (analysis_run_id, item_key, rank);
create index meals_user_occurred_idx on public.meals (user_id, occurred_at desc);
create index meal_items_meal_idx on public.meal_items (meal_id, position);
create index corrections_user_created_idx on public.meal_item_corrections (user_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger foods_set_updated_at before update on public.foods
for each row execute function public.set_updated_at();
create trigger meals_set_updated_at before update on public.meals
for each row execute function public.set_updated_at();
create trigger meal_items_set_updated_at before update on public.meal_items
for each row execute function public.set_updated_at();

create or replace function public.initialize_meal_totals()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.calories = 0;
  new.protein = 0;
  new.carbs = 0;
  new.fat = 0;
  return new;
end;
$$;

create trigger meals_initialize_totals before insert on public.meals
for each row execute function public.initialize_meal_totals();

create or replace function public.sync_meal_totals()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_meal_id uuid := coalesce(new.meal_id, old.meal_id);
begin
  update public.meals
  set
    calories = totals.calories,
    protein = totals.protein,
    carbs = totals.carbs,
    fat = totals.fat,
    updated_at = now()
  from (
    select
      coalesce(sum(mi.calories), 0) as calories,
      coalesce(sum(mi.protein), 0) as protein,
      coalesce(sum(mi.carbs), 0) as carbs,
      coalesce(sum(mi.fat), 0) as fat
    from public.meal_items mi
    where mi.meal_id = target_meal_id
  ) totals
  where meals.id = target_meal_id;
  return coalesce(new, old);
end;
$$;

create trigger meal_items_sync_totals
after insert or update or delete on public.meal_items
for each row execute function public.sync_meal_totals();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', new.raw_user_meta_data ->> 'name'));
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.foods enable row level security;
alter table public.food_aliases enable row level security;
alter table public.food_portions enable row level security;
alter table public.analysis_runs enable row level security;
alter table public.analysis_candidates enable row level security;
alter table public.meals enable row level security;
alter table public.meal_items enable row level security;
alter table public.meal_item_corrections enable row level security;

create policy "profiles_select_own" on public.profiles for select to authenticated
using ((select auth.uid()) = id);
create policy "profiles_update_own" on public.profiles for update to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "foods_read_catalog" on public.foods for select to authenticated using (is_active);
create policy "food_aliases_read_catalog" on public.food_aliases for select to authenticated using (true);
create policy "food_portions_read_catalog" on public.food_portions for select to authenticated using (true);

create policy "analysis_runs_select_own" on public.analysis_runs for select to authenticated
using ((select auth.uid()) = user_id);
create policy "analysis_candidates_select_own" on public.analysis_candidates for select to authenticated
using (exists (
  select 1 from public.analysis_runs ar
  where ar.id = analysis_run_id and ar.user_id = (select auth.uid())
));

create policy "meals_select_own" on public.meals for select to authenticated
using ((select auth.uid()) = user_id);
create policy "meals_insert_own" on public.meals for insert to authenticated
with check (
  (select auth.uid()) = user_id and (
    analysis_run_id is null or exists (
      select 1 from public.analysis_runs ar
      where ar.id = analysis_run_id and ar.user_id = (select auth.uid())
    )
  )
);
create policy "meals_delete_own" on public.meals for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "meal_items_select_own" on public.meal_items for select to authenticated
using (exists (
  select 1 from public.meals m
  where m.id = meal_id and m.user_id = (select auth.uid())
));
create policy "meal_items_insert_own" on public.meal_items for insert to authenticated
with check (exists (
  select 1 from public.meals m
  where m.id = meal_id and m.user_id = (select auth.uid())
));
create policy "meal_items_update_own" on public.meal_items for update to authenticated
using (exists (
  select 1 from public.meals m
  where m.id = meal_id and m.user_id = (select auth.uid())
)) with check (exists (
  select 1 from public.meals m
  where m.id = meal_id and m.user_id = (select auth.uid())
));
create policy "meal_items_delete_own" on public.meal_items for delete to authenticated
using (exists (
  select 1 from public.meals m
  where m.id = meal_id and m.user_id = (select auth.uid())
));

create policy "corrections_select_own" on public.meal_item_corrections for select to authenticated
using ((select auth.uid()) = user_id);
create policy "corrections_insert_own" on public.meal_item_corrections for insert to authenticated
with check (
  (select auth.uid()) = user_id and exists (
    select 1
    from public.meal_items mi
    join public.meals m on m.id = mi.meal_id
    where mi.id = meal_item_id and m.user_id = (select auth.uid())
  )
);

revoke all on function public.sync_meal_totals() from public;
revoke all on function public.initialize_meal_totals() from public;
revoke all on function public.handle_new_user() from public;
