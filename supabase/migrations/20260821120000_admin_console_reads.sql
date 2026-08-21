-- ============================================================================
-- Admin console read access
--
-- Why this exists: every table in this schema is owner-scoped by RLS, so a
-- browser holding the anon/publishable key can only ever see its own rows.
-- The admin console needs cross-user reads. The wrong way to get them is to
-- ship the service-role key to the browser. The right way is an explicit
-- admin allow-list plus additive read-only policies, which is what this does.
--
-- Nothing here grants write access. Admin mutations must still go through an
-- authenticated server endpoint.
-- ============================================================================

-- ── Allow-list ──────────────────────────────────────────────────────────────

create table if not exists public.console_admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  note text,
  granted_at timestamptz not null default now(),
  granted_by uuid references auth.users (id) on delete set null
);

alter table public.console_admins enable row level security;

-- Security definer so the policies below can call it without recursing into
-- console_admins' own RLS. Empty search_path per Supabase linter guidance.
create or replace function public.is_console_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.console_admins where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_console_admin() from public;
grant execute on function public.is_console_admin() to authenticated;

drop policy if exists "console admins read the allow-list" on public.console_admins;
create policy "console admins read the allow-list"
  on public.console_admins for select
  to authenticated
  using (public.is_console_admin());

-- ── Additive read policies ──────────────────────────────────────────────────
-- These sit alongside the existing owner-scoped policies. Postgres ORs
-- permissive policies together, so end users are unaffected.

drop policy if exists "console admins read analysis runs" on public.analysis_runs;
create policy "console admins read analysis runs"
  on public.analysis_runs for select to authenticated using (public.is_console_admin());

drop policy if exists "console admins read meals" on public.meals;
create policy "console admins read meals"
  on public.meals for select to authenticated using (public.is_console_admin());

drop policy if exists "console admins read meal items" on public.meal_items;
create policy "console admins read meal items"
  on public.meal_items for select to authenticated using (public.is_console_admin());

drop policy if exists "console admins read corrections" on public.meal_item_corrections;
create policy "console admins read corrections"
  on public.meal_item_corrections for select to authenticated using (public.is_console_admin());

drop policy if exists "console admins read profiles" on public.profiles;
create policy "console admins read profiles"
  on public.profiles for select to authenticated using (public.is_console_admin());

-- Draft and staging bundles are invisible to the app; the console needs them.
drop policy if exists "console admins read all translation bundles" on public.translation_bundles;
create policy "console admins read all translation bundles"
  on public.translation_bundles for select to authenticated using (public.is_console_admin());

-- ── Aggregation views ───────────────────────────────────────────────────────
-- security_invoker keeps RLS in force: an admin sees the whole population, a
-- normal user querying the same view sees only their own rows.

create or replace view public.admin_analysis_daily
with (security_invoker = on) as
select
  date_trunc('day', created_at)::date                                       as day,
  count(*)                                                                  as runs,
  count(*) filter (where status = 'completed')                              as completed,
  count(*) filter (where status = 'failed')                                 as failed,
  count(*) filter (where input_kind in ('image', 'mixed'))                  as with_photo,
  round(avg(latency_ms))                                                    as avg_latency_ms,
  percentile_cont(0.95) within group (order by latency_ms)                  as p95_latency_ms,
  sum(coalesce(estimated_cost_micros, 0))                                   as cost_micros,
  sum(coalesce(provider_input_tokens, 0))                                   as input_tokens,
  sum(coalesce(provider_output_tokens, 0))                                  as output_tokens,
  count(*) filter (where coalesce(provider_attempts, 1) > 1)                as retried
from public.analysis_runs
group by 1;

create or replace view public.admin_error_breakdown
with (security_invoker = on) as
select
  coalesce(error_code, 'UNKNOWN')                                           as error_code,
  count(*)                                                                  as occurrences,
  max(created_at)                                                           as last_seen
from public.analysis_runs
where status = 'failed'
group by 1;

create or replace view public.admin_correction_reasons
with (security_invoker = on) as
select
  coalesce(reason, 'other')                                                 as reason,
  count(*)                                                                  as occurrences,
  count(distinct user_id)                                                   as affected_users,
  max(created_at)                                                           as last_seen
from public.meal_item_corrections
group by 1;

-- Correction rate per canonical food, which is what the quality page ranks.
create or replace view public.admin_category_quality
with (security_invoker = on) as
select
  mi.canonical_name                                                         as canonical_name,
  count(*)                                                                  as items,
  count(*) filter (where mi.review_status = 'corrected')                    as corrected,
  round(
    100.0 * count(*) filter (where mi.review_status = 'corrected')
    / nullif(count(*), 0)
  , 1)                                                                      as correction_rate,
  round(avg(mi.confidence) * 100, 1)                                        as avg_confidence
from public.meal_items mi
group by 1;

-- One row per meal item that a reviewer may need to look at.
create or replace view public.admin_review_queue
with (security_invoker = on) as
select
  mi.id                                                                     as item_id,
  m.id                                                                      as meal_id,
  m.user_id                                                                 as user_id,
  m.name                                                                    as meal_name,
  m.occurred_at                                                             as occurred_at,
  m.image_path                                                              as image_path,
  mi.canonical_name                                                         as canonical_name,
  mi.portion_label                                                          as portion_label,
  mi.grams                                                                  as grams,
  mi.calories                                                               as calories,
  round(mi.confidence * 100)                                                as confidence_pct,
  mi.match_method                                                           as match_method,
  mi.review_status                                                          as review_status,
  ar.trace_id                                                               as trace_id,
  ar.model_name                                                             as model_name,
  ar.prompt_version                                                         as prompt_version,
  ar.latency_ms                                                             as latency_ms,
  (select count(*) from public.meal_item_corrections c where c.meal_item_id = mi.id) as correction_count
from public.meal_items mi
join public.meals m on m.id = mi.meal_id
left join public.analysis_runs ar on ar.id = m.analysis_run_id;

create or replace view public.admin_account_summary
with (security_invoker = on) as
select
  m.user_id                                                                 as user_id,
  count(distinct m.id)                                                      as meals,
  count(mi.id)                                                              as items,
  count(mi.id) filter (where mi.review_status = 'corrected')                as corrected_items,
  min(m.created_at)                                                         as first_meal_at,
  max(m.created_at)                                                         as last_meal_at
from public.meals m
left join public.meal_items mi on mi.meal_id = m.id
group by 1;

grant select on
  public.admin_analysis_daily,
  public.admin_error_breakdown,
  public.admin_correction_reasons,
  public.admin_category_quality,
  public.admin_review_queue,
  public.admin_account_summary
to authenticated;

-- ── Enrolment ───────────────────────────────────────────────────────────────
-- Run once, as the service role, with the UUID of the console operator:
--
--   insert into public.console_admins (user_id, note)
--   values ('00000000-0000-0000-0000-000000000000', 'console operator')
--   on conflict (user_id) do nothing;
