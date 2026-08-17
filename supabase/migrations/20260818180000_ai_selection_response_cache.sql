create table public.ai_selection_cache (
  cache_key text primary key,
  query_hash text not null,
  locale text not null check (locale in ('tr-TR', 'en-US')),
  model text not null,
  prompt_version text not null,
  candidate_fingerprint text not null,
  selection jsonb not null check (pg_catalog.jsonb_typeof(selection) = 'object'),
  hit_count bigint not null default 0,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index ai_selection_cache_expiry_idx on public.ai_selection_cache (expires_at);
alter table public.ai_selection_cache enable row level security;
revoke all on table public.ai_selection_cache from public, anon, authenticated;
grant select, insert, update, delete on table public.ai_selection_cache to service_role;

create trigger ai_selection_cache_set_updated_at before update on public.ai_selection_cache
for each row execute function public.set_updated_at();

alter table public.analysis_runs
  add column if not exists response_cache_hit boolean;
