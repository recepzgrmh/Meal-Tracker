-- ============================================================================
-- Eval result storage
--
-- The deterministic and live eval runners print a JSON report and forget it.
-- These tables give each run a durable home so the admin console can chart
-- quality over time instead of asking someone to paste a report into chat.
--
-- Write path: only the eval runners, holding the service role key, insert
-- here (opt-in via --persist / EVAL_PERSIST=1). Neither anon nor
-- authenticated receives any write grant.
--
-- Read path: the same pattern as 20260821120000_admin_console_reads.sql —
-- RLS on, a select policy gated by public.is_console_admin(), and an explicit
-- select grant to authenticated (default privileges revoke everything).
-- ============================================================================

-- ── Tables ──────────────────────────────────────────────────────────────────

create table public.eval_runs (
  id uuid primary key default extensions.gen_random_uuid(),
  kind text not null check (kind in ('deterministic', 'live')),
  suite text not null,
  git_ref text,
  model text,
  prompt_version text,
  started_at timestamptz not null,
  finished_at timestamptz not null,
  case_count integer not null check (case_count >= 0),
  passed_count integer not null check (passed_count >= 0),
  metrics jsonb not null default '{}'::jsonb,
  cost_micros bigint,
  notes text,
  created_at timestamptz not null default now()
);

create table public.eval_cases (
  id bigint generated always as identity primary key,
  eval_run_id uuid not null references public.eval_runs (id) on delete cascade,
  case_id text not null,
  passed boolean not null,
  expected jsonb,
  actual jsonb,
  failure_kind text,
  latency_ms integer
);

create index eval_cases_eval_run_id_idx on public.eval_cases (eval_run_id);
create index eval_runs_created_at_idx on public.eval_runs (created_at desc);

-- ── Row level security ──────────────────────────────────────────────────────
-- Console admins may read; nobody below service role may write. The service
-- role bypasses RLS, so no insert policy is needed for it.

alter table public.eval_runs enable row level security;
alter table public.eval_cases enable row level security;

drop policy if exists "console admins read eval runs" on public.eval_runs;
create policy "console admins read eval runs"
  on public.eval_runs for select to authenticated using (public.is_console_admin());

drop policy if exists "console admins read eval cases" on public.eval_cases;
create policy "console admins read eval cases"
  on public.eval_cases for select to authenticated using (public.is_console_admin());

-- ── Grants ──────────────────────────────────────────────────────────────────
-- Default privileges (20260817130000) already revoke table access from anon
-- and authenticated and grant everything to service_role; state the intent
-- explicitly anyway so this file reads on its own.

grant select on table public.eval_runs, public.eval_cases to authenticated;
grant select, insert on table public.eval_runs, public.eval_cases to service_role;

comment on table public.eval_runs is
  'One row per eval runner invocation that opted into persistence; metrics holds the report headline numbers.';
comment on table public.eval_cases is
  'Per-case outcome for an eval run, including the expected and actual payloads for failure triage.';
