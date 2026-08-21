import { NotAuthorizedError, requireClient } from './supabase'

/* ============================================================================
   Every read here maps to a real table or view in
   supabase/migrations/. Nothing is synthesised: if a number is not in the
   database, the screen that wants it renders an empty state instead.
   ========================================================================= */

const unwrap = <T>({ data, error }: { data: T | null; error: unknown }): T => {
  if (error) throw error
  return (data ?? []) as T
}

export const sinceIso = (days: number) => new Date(Date.now() - days * 86_400_000).toISOString()

/* ── Session and authorization ───────────────────────────────────────────── */

export async function getSession() {
  const { data } = await requireClient().auth.getSession()
  return data.session
}

export async function signInWithPassword(email: string, password: string) {
  const { error } = await requireClient().auth.signInWithPassword({ email, password })
  if (error) throw error
}

/**
 * The project's send-email hook delivers a one-time code, not a link, for every
 * auth action — so code sign-in is the flow that actually matches the backend.
 * `shouldCreateUser: false` keeps this from minting accounts for typos.
 */
export async function sendEmailCode(email: string) {
  const { error } = await requireClient().auth.signInWithOtp({
    email,
    options: { shouldCreateUser: false },
  })
  if (error) throw error
}

export async function verifyEmailCode(email: string, token: string) {
  const { error } = await requireClient().auth.verifyOtp({ email, token, type: 'email' })
  if (error) throw error
}

export async function signOut() {
  await requireClient().auth.signOut()
}

/** Fails loudly rather than silently returning empty tables to a non-admin. */
export async function assertConsoleAdmin() {
  const { data, error } = await requireClient().rpc('is_console_admin')
  if (error) throw error
  if (data !== true) throw new NotAuthorizedError()
}

/* ── Analysis volume, latency, cost ──────────────────────────────────────── */

export type DailyRow = {
  day: string
  runs: number
  completed: number
  failed: number
  with_photo: number
  avg_latency_ms: number | null
  p95_latency_ms: number | null
  cost_micros: number
  input_tokens: number
  output_tokens: number
  retried: number
}

export async function fetchAnalysisDaily(days: number): Promise<DailyRow[]> {
  return unwrap<DailyRow[]>(
    await requireClient()
      .from('admin_analysis_daily')
      .select('*')
      .gte('day', sinceIso(days).slice(0, 10))
      .order('day', { ascending: true }),
  )
}

/* ── Quality ─────────────────────────────────────────────────────────────── */

export type CategoryQualityRow = {
  canonical_name: string
  items: number
  corrected: number
  correction_rate: number | null
  avg_confidence: number | null
}

export async function fetchCategoryQuality(limit = 12): Promise<CategoryQualityRow[]> {
  return unwrap<CategoryQualityRow[]>(
    await requireClient()
      .from('admin_category_quality')
      .select('*')
      .gte('items', 5)
      .order('correction_rate', { ascending: false, nullsFirst: false })
      .limit(limit),
  )
}

export type CorrectionReasonRow = { reason: string; occurrences: number; affected_users: number; last_seen: string }

export async function fetchCorrectionReasons(): Promise<CorrectionReasonRow[]> {
  return unwrap<CorrectionReasonRow[]>(
    await requireClient().from('admin_correction_reasons').select('*').order('occurrences', { ascending: false }),
  )
}

/* ── Reliability ─────────────────────────────────────────────────────────── */

export type ErrorRow = { error_code: string; occurrences: number; last_seen: string }

export async function fetchErrorBreakdown(): Promise<ErrorRow[]> {
  return unwrap<ErrorRow[]>(
    await requireClient().from('admin_error_breakdown').select('*').order('occurrences', { ascending: false }),
  )
}

/* ── Review queue ────────────────────────────────────────────────────────── */

export type QueueRow = {
  item_id: string
  meal_id: string
  user_id: string
  meal_name: string
  occurred_at: string
  image_path: string | null
  canonical_name: string
  portion_label: string
  grams: number
  calories: number
  confidence_pct: number
  match_method: string
  review_status: string
  trace_id: string | null
  model_name: string | null
  prompt_version: string | null
  latency_ms: number | null
  correction_count: number
}

export type QueueFilter = 'unreviewed' | 'overconfident' | 'low' | 'corrected' | 'all'

export async function fetchReviewQueue(filter: QueueFilter, limit = 200): Promise<QueueRow[]> {
  let query = requireClient().from('admin_review_queue').select('*').order('occurred_at', { ascending: false }).limit(limit)
  if (filter === 'unreviewed') query = query.eq('review_status', 'unreviewed')
  if (filter === 'corrected') query = query.eq('review_status', 'corrected')
  if (filter === 'low') query = query.lt('confidence_pct', 80)
  // An overconfident mistake is a high-confidence item the user then corrected.
  if (filter === 'overconfident') query = query.gte('confidence_pct', 88).eq('review_status', 'corrected')
  return unwrap<QueueRow[]>(await query)
}

/* ── Traces ──────────────────────────────────────────────────────────────── */

export type TraceRow = {
  id: string
  trace_id: string
  user_id: string
  status: string
  input_kind: string
  model_name: string | null
  prompt_version: string | null
  retrieval_version: string | null
  latency_ms: number | null
  error_code: string | null
  error_detail: string | null
  provider_attempts: number | null
  provider_input_tokens: number | null
  provider_output_tokens: number | null
  estimated_cost_micros: number | null
  retrieval_cache_hit: boolean | null
  vision_fallback_reason: string | null
  raw_input: string
  output: unknown
  created_at: string
  completed_at: string | null
}

export type TraceFilter = 'all' | 'errors' | 'slow' | 'retried'

export async function fetchTraces(filter: TraceFilter, days: number, limit = 200): Promise<TraceRow[]> {
  let query = requireClient()
    .from('analysis_runs')
    .select('*')
    .gte('created_at', sinceIso(days))
    .order('created_at', { ascending: false })
    .limit(limit)
  if (filter === 'errors') query = query.eq('status', 'failed')
  if (filter === 'slow') query = query.gt('latency_ms', 6000)
  if (filter === 'retried') query = query.gt('provider_attempts', 1)
  const { data, error } = await query
  if (error) throw error
  return (data ?? []) as unknown as TraceRow[]
}

export async function fetchTrace(traceId: string): Promise<TraceRow | null> {
  const { data, error } = await requireClient().from('analysis_runs').select('*').eq('trace_id', traceId).maybeSingle()
  if (error) throw error
  return (data as unknown as TraceRow) ?? null
}

/** Mirrors public.analysis_candidates exactly — see the initial schema migration. */
export type CandidateRow = {
  id: number
  analysis_run_id: string
  item_key: string
  food_id: string | null
  rank: number
  retrieval_score: number | null
  rerank_score: number | null
  selected: boolean
  rationale: { method?: string; needsClarification?: boolean; clarificationReason?: string | null } | null
  foods: { canonical_name: string } | null
}

export async function fetchTraceCandidates(analysisRunId: string): Promise<CandidateRow[]> {
  const { data, error } = await requireClient()
    .from('analysis_candidates')
    .select('*, foods(canonical_name)')
    .eq('analysis_run_id', analysisRunId)
    .order('item_key', { ascending: true })
    .order('rank', { ascending: true })
  if (error) throw error
  return (data ?? []) as unknown as CandidateRow[]
}

/* ── Accounts ────────────────────────────────────────────────────────────── */

export type AccountRow = {
  user_id: string
  meals: number
  items: number
  corrected_items: number
  first_meal_at: string | null
  last_meal_at: string | null
}

export async function fetchAccounts(limit = 200): Promise<AccountRow[]> {
  return unwrap<AccountRow[]>(
    await requireClient().from('admin_account_summary').select('*').order('last_meal_at', { ascending: false, nullsFirst: false }).limit(limit),
  )
}

/* ── OTA translation bundles ─────────────────────────────────────────────── */

export type BundleRow = {
  locale: 'tr' | 'en'
  version: number
  status: 'draft' | 'staging' | 'production' | 'archived'
  values: Record<string, string>
  created_at: string
  updated_at: string
  published_at: string | null
}

export async function fetchBundles(): Promise<BundleRow[]> {
  return unwrap<BundleRow[]>(
    await requireClient()
      .from('translation_bundles')
      .select('locale,version,status,values,created_at,updated_at,published_at')
      .order('locale', { ascending: true })
      .order('version', { ascending: false }),
  )
}
