alter table public.analysis_runs
  add column if not exists vision_fallback_reason text;

alter table public.analysis_runs
  drop constraint if exists analysis_runs_vision_fallback_reason_check;

alter table public.analysis_runs
  add constraint analysis_runs_vision_fallback_reason_check
  check (
    vision_fallback_reason is null
    or vision_fallback_reason in ('timeout', 'rate_limit', 'refusal', 'provider_error')
  );

comment on column public.analysis_runs.vision_fallback_reason is
  'Why photo extraction was skipped while text analysis continued.';
