-- ============================================================================
-- Development-phase metrics for the admin console.
--
-- Every view is security_invoker, so an operator on the console_admins
-- allow-list sees the whole population and a normal user sees only their own
-- rows. Nothing here is materialised; these are small tables during
-- development and correctness beats caching.
-- ============================================================================

-- ── Is the model's confidence honest? ───────────────────────────────────────
-- Buckets stated confidence in tenths and reports the rate at which the user
-- actually changed the answer. A well-calibrated model shows a correction rate
-- that falls as the bucket rises.
create or replace view public.admin_confidence_calibration
with (security_invoker = on) as
select
  pg_catalog.width_bucket(mi.confidence, 0, 1, 10)                          as bucket,
  ((pg_catalog.width_bucket(mi.confidence, 0, 1, 10) - 1) * 10)             as bucket_floor_pct,
  count(*)                                                                  as items,
  count(*) filter (where mi.review_status = 'corrected')                    as corrected,
  round(
    100.0 * count(*) filter (where mi.review_status = 'corrected')
    / nullif(count(*), 0)
  , 1)                                                                      as correction_rate,
  round(avg(mi.confidence) * 100, 1)                                        as avg_confidence
from public.meal_items mi
group by 1, 2;

-- ── Which matching strategy actually works? ─────────────────────────────────
create or replace view public.admin_match_method_quality
with (security_invoker = on) as
select
  mi.match_method                                                           as match_method,
  count(*)                                                                  as items,
  count(*) filter (where mi.review_status = 'corrected')                    as corrected,
  round(
    100.0 * count(*) filter (where mi.review_status = 'corrected')
    / nullif(count(*), 0)
  , 1)                                                                      as correction_rate,
  round(avg(mi.confidence) * 100, 1)                                        as avg_confidence
from public.meal_items mi
group by 1;

-- ── How wrong are the portions? ─────────────────────────────────────────────
-- Reads the correction log written by commit_analyzed_meal.
create or replace view public.admin_portion_error
with (security_invoker = on) as
select
  mi.canonical_name                                                         as canonical_name,
  count(*)                                                                  as corrections,
  round(avg(pg_catalog.abs(
    (c.after_value ->> 'grams')::numeric - (c.before_value ->> 'grams')::numeric
  )), 1)                                                                    as mean_abs_error_g,
  round(avg(
    (c.after_value ->> 'grams')::numeric - (c.before_value ->> 'grams')::numeric
  ), 1)                                                                     as mean_signed_error_g,
  round(max(pg_catalog.abs(
    (c.after_value ->> 'grams')::numeric - (c.before_value ->> 'grams')::numeric
  )), 1)                                                                    as worst_error_g
from public.meal_item_corrections c
join public.meal_items mi on mi.id = c.meal_item_id
where c.reason = 'wrong_portion'
  and pg_catalog.jsonb_typeof(c.before_value -> 'grams') is not null
  and pg_catalog.jsonb_typeof(c.after_value -> 'grams') is not null
group by 1;

-- ── Did the new prompt actually beat the old one? ───────────────────────────
create or replace view public.admin_version_comparison
with (security_invoker = on) as
select
  coalesce(ar.model_name, 'unknown')                                        as model_name,
  coalesce(ar.prompt_version, 'unknown')                                    as prompt_version,
  count(*)                                                                  as runs,
  count(*) filter (where ar.status = 'failed')                              as failed,
  round(
    100.0 * count(*) filter (where ar.status <> 'failed')
    / nullif(count(*), 0)
  , 1)                                                                      as success_rate,
  round(percentile_cont(0.5) within group (order by ar.latency_ms))         as p50_latency_ms,
  round(percentile_cont(0.95) within group (order by ar.latency_ms))        as p95_latency_ms,
  round(percentile_cont(0.99) within group (order by ar.latency_ms))        as p99_latency_ms,
  sum(coalesce(ar.provider_input_tokens, 0))                                as input_tokens,
  sum(coalesce(ar.provider_output_tokens, 0))                               as output_tokens,
  sum(coalesce(ar.embedding_input_tokens, 0))                               as embedding_tokens,
  sum(coalesce(ar.estimated_cost_micros, 0))                                as cost_micros,
  round(
    avg(coalesce(ar.estimated_cost_micros, 0))
  )                                                                         as avg_cost_micros,
  round(
    100.0 * count(*) filter (where ar.retrieval_cache_hit)
    / nullif(count(*) filter (where ar.retrieval_cache_hit is not null), 0)
  , 1)                                                                      as cache_hit_rate,
  round(
    100.0 * count(*) filter (where coalesce(ar.provider_attempts, 1) > 1)
    / nullif(count(*), 0)
  , 1)                                                                      as retry_rate,
  round(
    100.0 * count(*) filter (where ar.vision_fallback_reason is not null)
    / nullif(count(*), 0)
  , 1)                                                                      as vision_fallback_rate,
  min(ar.created_at)                                                        as first_seen,
  max(ar.created_at)                                                        as last_seen
from public.analysis_runs ar
group by 1, 2;

-- ── Where does latency actually sit? ────────────────────────────────────────
create or replace view public.admin_latency_histogram
with (security_invoker = on) as
select
  bucket_floor_ms,
  count(*)                                                                  as runs
from (
  select
    case
      when ar.latency_ms < 1000 then 0
      when ar.latency_ms < 15000 then (ar.latency_ms / 1000) * 1000
      else 15000
    end                                                                     as bucket_floor_ms
  from public.analysis_runs ar
  where ar.latency_ms is not null
) buckets
group by 1;

-- ── Runs that never finished ────────────────────────────────────────────────
-- The edge function crashing or timing out leaves these behind silently.
create or replace view public.admin_stuck_runs
with (security_invoker = on) as
select
  ar.id                                                                     as id,
  ar.trace_id                                                               as trace_id,
  ar.user_id                                                                as user_id,
  ar.status                                                                 as status,
  ar.input_kind                                                             as input_kind,
  ar.model_name                                                             as model_name,
  ar.created_at                                                             as created_at,
  round(extract(epoch from (now() - ar.created_at)))                        as age_seconds
from public.analysis_runs ar
where ar.status in ('pending', 'running')
  and ar.created_at < now() - interval '5 minutes';

-- ── Analyses the user abandoned ─────────────────────────────────────────────
-- Analysis succeeded, no meal was ever committed from it.
create or replace view public.admin_uncommitted_runs
with (security_invoker = on) as
select
  ar.id                                                                     as id,
  ar.trace_id                                                               as trace_id,
  ar.user_id                                                                as user_id,
  ar.input_kind                                                             as input_kind,
  ar.raw_input                                                              as raw_input,
  ar.model_name                                                             as model_name,
  ar.latency_ms                                                             as latency_ms,
  ar.created_at                                                             as created_at,
  pg_catalog.jsonb_array_length(
    case when pg_catalog.jsonb_typeof(ar.output -> 'items') = 'array'
      then ar.output -> 'items' else '[]'::jsonb end
  )                                                                         as proposed_items
from public.analysis_runs ar
where ar.status = 'needs_review'
  and not exists (select 1 from public.meals m where m.analysis_run_id = ar.id);

-- ── How close was the runner-up? ────────────────────────────────────────────
-- Stays empty until analyze-meal persists more than the chosen candidate; the
-- console says so rather than pretending the signal is flat.
create or replace view public.admin_candidate_margin
with (security_invoker = on) as
select
  ac.analysis_run_id                                                        as analysis_run_id,
  ac.item_key                                                               as item_key,
  count(*)                                                                  as candidates,
  max(ac.retrieval_score) filter (where ac.rank = 1)                        as top_score,
  max(ac.retrieval_score) filter (where ac.rank = 2)                        as runner_up_score,
  max(ac.retrieval_score) filter (where ac.rank = 1)
    - max(ac.retrieval_score) filter (where ac.rank = 2)                    as margin,
  min(ac.rank) filter (where ac.selected)                                   as selected_rank
from public.analysis_candidates ac
group by 1, 2;

-- ── Per-user daily rollup, for the "only my runs" filter ────────────────────
-- Percentiles cannot be summed, so the workspace-wide view stays separate
-- rather than being derived from this one.
create or replace view public.admin_analysis_daily_by_user
with (security_invoker = on) as
select
  ar.user_id                                                                as user_id,
  date_trunc('day', ar.created_at)::date                                    as day,
  count(*)                                                                  as runs,
  count(*) filter (where ar.status = 'completed')                           as completed,
  count(*) filter (where ar.status = 'failed')                              as failed,
  count(*) filter (where ar.input_kind in ('image', 'mixed'))               as with_photo,
  round(avg(ar.latency_ms))                                                 as avg_latency_ms,
  percentile_cont(0.95) within group (order by ar.latency_ms)               as p95_latency_ms,
  sum(coalesce(ar.estimated_cost_micros, 0))                                as cost_micros,
  sum(coalesce(ar.provider_input_tokens, 0))                                as input_tokens,
  sum(coalesce(ar.provider_output_tokens, 0))                               as output_tokens,
  count(*) filter (where coalesce(ar.provider_attempts, 1) > 1)             as retried
from public.analysis_runs ar
group by 1, 2;

grant select on
  public.admin_confidence_calibration,
  public.admin_match_method_quality,
  public.admin_portion_error,
  public.admin_version_comparison,
  public.admin_latency_histogram,
  public.admin_stuck_runs,
  public.admin_uncommitted_runs,
  public.admin_candidate_margin,
  public.admin_analysis_daily_by_user
to authenticated;
