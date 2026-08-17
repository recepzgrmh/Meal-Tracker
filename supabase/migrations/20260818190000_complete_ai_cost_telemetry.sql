alter table public.analysis_runs
  add column if not exists embedding_input_tokens integer
    check (embedding_input_tokens is null or embedding_input_tokens >= 0);

comment on column public.analysis_runs.embedding_input_tokens is
  'Embedding API prompt tokens, including an opportunistic catalog backfill when it occurred.';
