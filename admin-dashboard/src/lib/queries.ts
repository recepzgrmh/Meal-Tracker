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

export type ProductionCatalogStatus = {
  catalog_version: string
  food_records: number
  macro_complete_records: number
  alias_records: number
  portion_records: number
}

export async function fetchProductionCatalogStatus(): Promise<ProductionCatalogStatus> {
  const { data, error } = await requireClient().from('admin_production_catalog_status').select('*').single()
  if (error) throw error
  return data as ProductionCatalogStatus
}

export type CatalogFoodRow = {
  food_id: string
  canonical_name: string
  locale: string
  category: string | null
  brand: string | null
  barcode: string | null
  tier: string | null
  dataset_version: string | null
  calories_per_100g: number
  protein_per_100g: number
  carbs_per_100g: number
  fat_per_100g: number
  total_count: number
}

export type CatalogFoodPage = { rows: CatalogFoodRow[]; total: number }

export async function fetchProductionCatalogFoods(input: {
  query: string
  kind: 'all' | 'generic' | 'branded'
  tier: string
  page: number
  pageSize: number
}): Promise<CatalogFoodPage> {
  const { data, error } = await requireClient().rpc('admin_search_production_foods', {
    p_query: input.query,
    p_kind: input.kind,
    p_tier: input.tier,
    p_page: input.page,
    p_page_size: input.pageSize,
  })
  if (error) throw error
  const rows = (data ?? []) as CatalogFoodRow[]
  return { rows, total: Number(rows[0]?.total_count ?? 0) }
}

export type CatalogFoodAlias = { id: number; alias: string; locale: string; priority: number }
export type CatalogFoodPortion = { id: number; label: string; grams: number; locale: string; is_default: boolean }
export type CatalogFoodDetail = {
  id: string
  canonical_name: string
  locale: string
  source: string
  source_food_id: string
  calories_per_100g: number
  protein_per_100g: number
  carbs_per_100g: number
  fat_per_100g: number
  metadata: Record<string, unknown>
  food_aliases: CatalogFoodAlias[]
  food_portions: CatalogFoodPortion[]
}

export async function fetchProductionCatalogFood(foodId: string): Promise<CatalogFoodDetail> {
  const { data, error } = await requireClient()
    .from('foods')
    .select(`
      id, canonical_name, locale, source, source_food_id,
      calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, metadata,
      food_aliases(id, alias, locale, priority),
      food_portions(id, label, grams, locale, is_default)
    `)
    .eq('id', foodId)
    .eq('source', 'canonical_v2_lean')
    .single()
  if (error) throw error
  return data as unknown as CatalogFoodDetail
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

export async function fetchTraces(filter: TraceFilter, days: number, limit = 200, userId?: string): Promise<TraceRow[]> {
  let query = requireClient()
    .from('analysis_runs')
    .select('*')
    .gte('created_at', sinceIso(days))
    .order('created_at', { ascending: false })
    .limit(limit)
  if (userId) query = query.eq('user_id', userId)
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

/* ============================================================================
   Development-phase metrics. Sources are the views added in
   supabase/migrations/20260822091000_admin_dev_metrics.sql.
   ========================================================================= */

export type CalibrationRow = {
  bucket: number
  bucket_floor_pct: number
  items: number
  corrected: number
  correction_rate: number | null
  avg_confidence: number | null
}

export async function fetchCalibration(): Promise<CalibrationRow[]> {
  return unwrap<CalibrationRow[]>(
    await requireClient().from('admin_confidence_calibration').select('*').order('bucket', { ascending: true }),
  )
}

export type MatchMethodRow = {
  match_method: string
  items: number
  corrected: number
  correction_rate: number | null
  avg_confidence: number | null
}

export async function fetchMatchMethods(): Promise<MatchMethodRow[]> {
  return unwrap<MatchMethodRow[]>(
    await requireClient().from('admin_match_method_quality').select('*').order('items', { ascending: false }),
  )
}

export type PortionErrorRow = {
  canonical_name: string
  corrections: number
  mean_abs_error_g: number | null
  mean_signed_error_g: number | null
  worst_error_g: number | null
}

export async function fetchPortionError(): Promise<PortionErrorRow[]> {
  return unwrap<PortionErrorRow[]>(
    await requireClient().from('admin_portion_error').select('*').order('mean_abs_error_g', { ascending: false, nullsFirst: false }).limit(20),
  )
}

export type VersionRow = {
  model_name: string
  prompt_version: string
  runs: number
  failed: number
  success_rate: number | null
  p50_latency_ms: number | null
  p95_latency_ms: number | null
  p99_latency_ms: number | null
  input_tokens: number
  output_tokens: number
  embedding_tokens: number
  cost_micros: number
  avg_cost_micros: number | null
  cache_hit_rate: number | null
  retry_rate: number | null
  vision_fallback_rate: number | null
  first_seen: string
  last_seen: string
}

export async function fetchVersions(): Promise<VersionRow[]> {
  return unwrap<VersionRow[]>(
    await requireClient().from('admin_version_comparison').select('*').order('last_seen', { ascending: false }),
  )
}

export type LatencyBucketRow = { bucket_floor_ms: number; runs: number }

export async function fetchLatencyHistogram(): Promise<LatencyBucketRow[]> {
  return unwrap<LatencyBucketRow[]>(
    await requireClient().from('admin_latency_histogram').select('*').order('bucket_floor_ms', { ascending: true }),
  )
}

export type StuckRunRow = {
  id: string
  trace_id: string
  user_id: string
  status: string
  input_kind: string
  model_name: string | null
  created_at: string
  age_seconds: number
}

export async function fetchStuckRuns(): Promise<StuckRunRow[]> {
  return unwrap<StuckRunRow[]>(
    await requireClient().from('admin_stuck_runs').select('*').order('created_at', { ascending: true }),
  )
}

export type UncommittedRunRow = {
  id: string
  trace_id: string
  user_id: string
  input_kind: string
  raw_input: string
  model_name: string | null
  latency_ms: number | null
  created_at: string
  proposed_items: number
}

export async function fetchUncommittedRuns(limit = 50): Promise<UncommittedRunRow[]> {
  return unwrap<UncommittedRunRow[]>(
    await requireClient().from('admin_uncommitted_runs').select('*').order('created_at', { ascending: false }).limit(limit),
  )
}

export type CandidateMarginRow = {
  analysis_run_id: string
  item_key: string
  candidates: number
  top_score: number | null
  runner_up_score: number | null
  margin: number | null
  selected_rank: number | null
}

export async function fetchCandidateMargins(limit = 500): Promise<CandidateMarginRow[]> {
  return unwrap<CandidateMarginRow[]>(
    await requireClient().from('admin_candidate_margin').select('*').order('margin', { ascending: true, nullsFirst: false }).limit(limit),
  )
}

/* ============================================================================
   AI eval results. Sources are the tables added in
   supabase/migrations/20260824120000_eval_result_storage.sql; the eval
   runners write them only when invoked with --persist.
   ========================================================================= */

export type EvalRunRow = {
  id: string
  kind: 'deterministic' | 'live'
  suite: string
  git_ref: string | null
  model: string | null
  prompt_version: string | null
  started_at: string
  finished_at: string
  case_count: number
  passed_count: number
  metrics: Record<string, number | null>
  cost_micros: number | null
  notes: string | null
  created_at: string
}

export async function fetchEvalRuns(limit = 100): Promise<EvalRunRow[]> {
  return unwrap<EvalRunRow[]>(
    await requireClient().from('eval_runs').select('*').order('created_at', { ascending: false }).limit(limit),
  )
}

export type EvalCaseRow = {
  id: number
  eval_run_id: string
  case_id: string
  passed: boolean
  expected: unknown
  actual: unknown
  failure_kind: string | null
  latency_ms: number | null
}

export async function fetchEvalCases(evalRunId: string): Promise<EvalCaseRow[]> {
  return unwrap<EvalCaseRow[]>(
    await requireClient().from('eval_cases').select('*').eq('eval_run_id', evalRunId).order('case_id', { ascending: true }),
  )
}

/** The newest runs, for watching a device hit the pipeline in real time. */
export async function fetchRecentRuns(limit = 25, userId?: string): Promise<TraceRow[]> {
  let query = requireClient()
    .from('analysis_runs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit)
  if (userId) query = query.eq('user_id', userId)
  const { data, error } = await query
  if (error) throw error
  return (data ?? []) as unknown as TraceRow[]
}
