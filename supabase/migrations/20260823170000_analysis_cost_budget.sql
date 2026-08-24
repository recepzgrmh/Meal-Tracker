-- Enforce a configurable daily AI spend ceiling before an Edge Function calls
-- a model. Running analyses reserve a small amount so concurrent requests are
-- included instead of all observing the same stale total.
create or replace function public.analysis_cost_budget_check(
  p_user_id uuid,
  p_user_limit_micros bigint,
  p_global_limit_micros bigint,
  p_request_reserve_micros bigint
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_day_start timestamptz := pg_catalog.date_trunc('day', pg_catalog.now() at time zone 'utc') at time zone 'utc';
  v_user_spend bigint;
  v_global_spend bigint;
  v_user_running bigint;
  v_global_running bigint;
  v_user_projected bigint;
  v_global_projected bigint;
begin
  if p_user_id is null or p_user_limit_micros <= 0 or
     p_global_limit_micros <= 0 or p_request_reserve_micros <= 0 then
    raise exception using errcode = '22023', message = 'positive budget inputs are required';
  end if;

  -- Serialize checks briefly so simultaneous starts cannot all pass against an
  -- identical snapshot. The running rows themselves act as reservations.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('analysis-cost-budget'));

  select
    pg_catalog.coalesce(pg_catalog.sum(estimated_cost_micros) filter (where status <> 'running'), 0),
    pg_catalog.count(*) filter (where status = 'running')
  into v_global_spend, v_global_running
  from public.analysis_runs
  where created_at >= v_day_start;

  select
    pg_catalog.coalesce(pg_catalog.sum(estimated_cost_micros) filter (where status <> 'running'), 0),
    pg_catalog.count(*) filter (where status = 'running')
  into v_user_spend, v_user_running
  from public.analysis_runs
  where user_id = p_user_id and created_at >= v_day_start;

  v_user_projected := v_user_spend + v_user_running * p_request_reserve_micros;
  v_global_projected := v_global_spend + v_global_running * p_request_reserve_micros;

  return pg_catalog.jsonb_build_object(
    'allowed', v_user_projected <= p_user_limit_micros and v_global_projected <= p_global_limit_micros,
    'userProjectedMicros', v_user_projected,
    'globalProjectedMicros', v_global_projected,
    'userLimitMicros', p_user_limit_micros,
    'globalLimitMicros', p_global_limit_micros
  );
end;
$$;

revoke all on function public.analysis_cost_budget_check(uuid, bigint, bigint, bigint) from public;
revoke all on function public.analysis_cost_budget_check(uuid, bigint, bigint, bigint) from anon;
revoke all on function public.analysis_cost_budget_check(uuid, bigint, bigint, bigint) from authenticated;
grant execute on function public.analysis_cost_budget_check(uuid, bigint, bigint, bigint) to service_role;

comment on function public.analysis_cost_budget_check(uuid, bigint, bigint, bigint) is
  'Returns whether daily user/global AI cost ceilings permit a model-backed analysis.';
