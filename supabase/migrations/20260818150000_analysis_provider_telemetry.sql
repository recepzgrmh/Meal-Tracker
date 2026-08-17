alter table public.analysis_runs
  add column if not exists provider_input_tokens integer check (provider_input_tokens is null or provider_input_tokens >= 0),
  add column if not exists provider_output_tokens integer check (provider_output_tokens is null or provider_output_tokens >= 0),
  add column if not exists provider_attempts smallint check (provider_attempts is null or provider_attempts between 0 and 20),
  add column if not exists retrieval_cache_hit boolean,
  add column if not exists estimated_cost_micros bigint check (estimated_cost_micros is null or estimated_cost_micros >= 0);

comment on column public.analysis_runs.estimated_cost_micros is
  'Estimated provider cost in millionths of one US dollar, computed from versioned eval pricing.';
