/**
 * Opt-in persistence for eval reports, writing to the tables created by
 * supabase/migrations/20260824120000_eval_result_storage.sql.
 *
 * Nothing here runs unless the invocation asked for it (`--persist` on the
 * command line, or EVAL_PERSIST=1), so the default eval tasks keep working
 * offline and without credentials. Persisting requires SUPABASE_URL (or
 * EVAL_SUPABASE_URL) and
 * SUPABASE_SERVICE_ROLE_KEY; the tables accept no writes below service role.
 */

export interface EvalRunRecord {
  kind: 'deterministic' | 'live'
  suite: string
  model: string | null
  promptVersion: string | null
  startedAt: string
  finishedAt: string
  caseCount: number
  passedCount: number
  metrics: Record<string, unknown>
  costMicros: number | null
  notes: string | null
}

export interface EvalCaseRecord {
  caseId: string
  passed: boolean
  expected: unknown
  actual: unknown
  failureKind: string | null
  latencyMs: number | null
}

/** True only when the caller explicitly opted in. Never touches env it cannot read. */
export function persistenceRequested(): boolean {
  if (process.argv.slice(2).includes('--persist')) return true
  return readableEnv('EVAL_PERSIST') === '1'
}

export async function persistEvalRun(run: EvalRunRecord, cases: EvalCaseRecord[]): Promise<void> {
  const supabaseUrl = (readableEnv('SUPABASE_URL') ?? readableEnv('EVAL_SUPABASE_URL'))
    ?.replace(/\/$/u, '')
  const serviceRoleKey = readableEnv('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error(
      'Eval persistence needs SUPABASE_URL (or EVAL_SUPABASE_URL) and SUPABASE_SERVICE_ROLE_KEY',
    )
  }

  const [runRow] = await insert(supabaseUrl, serviceRoleKey, 'eval_runs', [{
    kind: run.kind,
    suite: run.suite,
    git_ref: readableEnv('EVAL_GIT_REF') ?? readableEnv('GITHUB_SHA'),
    model: run.model,
    prompt_version: run.promptVersion,
    started_at: run.startedAt,
    finished_at: run.finishedAt,
    case_count: run.caseCount,
    passed_count: run.passedCount,
    metrics: run.metrics,
    cost_micros: run.costMicros,
    notes: run.notes,
  }], 'return=representation') as Array<{ id: string }>
  if (typeof runRow?.id !== 'string') throw new Error('eval_runs insert returned no id')

  await insert(
    supabaseUrl,
    serviceRoleKey,
    'eval_cases',
    cases.map((record) => ({
      eval_run_id: runRow.id,
      case_id: record.caseId,
      passed: record.passed,
      expected: record.expected ?? null,
      actual: record.actual ?? null,
      failure_kind: record.failureKind,
      latency_ms: record.latencyMs,
    })),
    'return=minimal',
  )

  // Stderr on purpose: stdout stays the machine-readable report.
  console.error(`Persisted eval run ${runRow.id} with ${cases.length} cases`)
}

async function insert(
  supabaseUrl: string,
  serviceRoleKey: string,
  table: string,
  rows: unknown[],
  prefer: string,
): Promise<unknown> {
  const response = await fetch(`${supabaseUrl}/rest/v1/${table}`, {
    method: 'POST',
    headers: {
      apikey: serviceRoleKey,
      authorization: `Bearer ${serviceRoleKey}`,
      'content-type': 'application/json',
      prefer,
    },
    body: JSON.stringify(rows),
  })
  if (!response.ok) {
    throw new Error(`${table} insert failed with ${response.status}: ${await response.text()}`)
  }
  if (prefer === 'return=representation') return await response.json()
  await response.body?.cancel()
  return null
}

/** Reads an env var, treating empty as absent. On Deno this first had to check
 * `Deno.permissions` so the deterministic task, which ran without --allow-env,
 * would not trigger a prompt. Node has no permission model for env, so the
 * guard has nothing to protect against and the read is unconditional. */
function readableEnv(name: string): string | null {
  return process.env[name]?.trim() || null
}
