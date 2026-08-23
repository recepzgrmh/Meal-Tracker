import { type EvalCaseRecord, persistenceRequested, persistEvalRun } from './persist_eval_run.ts'

interface ExpectedItem {
  foodId: string
  grams?: number
  minGrams?: number
  maxGrams?: number
}

interface EvalCase {
  id: string
  locale: 'tr-TR' | 'en-US'
  input?: string
  image?: string
  expectedItems: ExpectedItem[]
  expectNoMatch?: boolean
  tags: string[]
}

interface CaseResult {
  id: string
  passed: boolean
  identityExact: boolean
  noMatchCorrect: boolean | null
  portionErrors: number[]
  latencyMs: number
  retrievalCacheHit: boolean
  responseCacheHit: boolean
  inputTokens: number
  outputTokens: number
  embeddingTokens: number
  estimatedCostMicros: number
  errorCode: string | null
}

const root = new URL('../../../', import.meta.url)
const supabaseUrl = requiredEnv('EVAL_SUPABASE_URL').replace(/\/$/u, '')
const publishableKey = requiredEnv('EVAL_SUPABASE_PUBLISHABLE_KEY')
const userJwt = requiredEnv('EVAL_USER_JWT')
if (Deno.env.get('LIVE_EVAL_ACK') !== 'I_ACCEPT_PROVIDER_COST') {
  throw new Error('Set LIVE_EVAL_ACK=I_ACCEPT_PROVIDER_COST to run paid provider evals')
}
const maxCases = Math.min(100, Math.max(1, Number(Deno.env.get('EVAL_MAX_CASES') ?? 20)))
const datasetArg = Deno.args.find((arg) => !arg.startsWith('--')) ??
  'evals/gold/bilingual_hybrid_v1.jsonl'
const cases = (await loadCases(new URL(datasetArg, root))).slice(0, maxCases)
const userId = jwtSubject(userJwt)
const results: CaseResult[] = []
const caseRecords: EvalCaseRecord[] = []
const startedAt = new Date().toISOString()

for (const gold of cases) {
  const clientRequestId = crypto.randomUUID()
  const startedAt = performance.now()
  const photo = gold.image ? await uploadPhoto(gold.image, userId, clientRequestId) : null
  const response = await fetch(`${supabaseUrl}/functions/v1/analyze-meal`, {
    method: 'POST',
    headers: authHeaders(),
    body: JSON.stringify({
      clientRequestId,
      input: gold.input ?? '',
      inputKind: photo ? (gold.input ? 'mixed' : 'photo') : 'text',
      locale: gold.locale,
      ...(photo ? { photo } : {}),
    }),
  })
  const payload = await response.json() as Record<string, unknown>
  const latencyMs = Math.round(performance.now() - startedAt)
  const error = payload.error as Record<string, unknown> | undefined
  if (!response.ok) {
    const noMatchCorrect = gold.expectNoMatch === true && error?.code === 'NO_MATCH'
    const errorCode = String(error?.code ?? response.status)
    results.push(emptyResult(gold.id, latencyMs, noMatchCorrect, errorCode))
    caseRecords.push({
      caseId: gold.id,
      passed: noMatchCorrect,
      expected: { items: gold.expectedItems, expectNoMatch: gold.expectNoMatch === true },
      actual: { error: errorCode },
      failureKind: noMatchCorrect ? null : errorCode,
      latencyMs,
    })
    continue
  }

  const actualItems = Array.isArray(payload.items)
    ? payload.items as Array<Record<string, unknown>>
    : []
  const actualIds = new Set(actualItems.map((item) => String(item.foodId)))
  const expectedIds = new Set(gold.expectedItems.map((item) => item.foodId))
  const identityExact = setEquals(actualIds, expectedIds)
  const portionErrors = gold.expectedItems.flatMap((expected) => {
    const actual = actualItems.find((item) => item.foodId === expected.foodId)
    if (!actual) return []
    const grams = Number(actual.grams)
    if (expected.grams != null) return [Math.abs(grams - expected.grams) / expected.grams]
    if (expected.minGrams != null && grams < expected.minGrams) {
      return [(expected.minGrams - grams) / expected.minGrams]
    }
    if (expected.maxGrams != null && grams > expected.maxGrams) {
      return [(grams - expected.maxGrams) / expected.maxGrams]
    }
    return [0]
  })
  const telemetry = await loadTelemetry(String(payload.analysisRunId))
  const passed = identityExact && portionErrors.every((error) => error <= 0.10)
  caseRecords.push({
    caseId: gold.id,
    passed,
    expected: { items: gold.expectedItems, expectNoMatch: gold.expectNoMatch === true },
    actual: { items: actualItems },
    failureKind: passed ? null : identityExact ? 'portion' : 'identity',
    latencyMs,
  })
  results.push({
    id: gold.id,
    passed,
    identityExact,
    noMatchCorrect: gold.expectNoMatch === true ? false : null,
    portionErrors,
    latencyMs,
    retrievalCacheHit: telemetry.retrieval_cache_hit === true,
    responseCacheHit: telemetry.response_cache_hit === true,
    inputTokens: Number(telemetry.provider_input_tokens ?? 0),
    outputTokens: Number(telemetry.provider_output_tokens ?? 0),
    embeddingTokens: Number(telemetry.embedding_input_tokens ?? 0),
    estimatedCostMicros: Number(telemetry.estimated_cost_micros ?? 0),
    errorCode: null,
  })
}

const latencies = results.map((result) => result.latencyMs).sort((a, b) => a - b)
const portionErrors = results.flatMap((result) => result.portionErrors)
const report = {
  dataset: datasetArg,
  generatedAt: new Date().toISOString(),
  cases: results.length,
  pricingVersion: 'openai-standard-2026-08-18',
  metrics: {
    passRate: round(divide(results.filter((result) => result.passed).length, results.length)),
    identityExactAccuracy: round(divide(
      results.filter((result) => result.identityExact).length,
      results.length,
    )),
    noMatchAccuracy: round(divide(
      results.filter((result) => result.noMatchCorrect === true).length,
      results.filter((result) => result.noMatchCorrect !== null).length,
    )),
    portionMape: round(
      divide(portionErrors.reduce((sum, value) => sum + value, 0), portionErrors.length),
    ),
    latencyP50Ms: percentile(latencies, 0.50),
    latencyP95Ms: percentile(latencies, 0.95),
    retrievalCacheHitRate: round(divide(
      results.filter((result) => result.retrievalCacheHit).length,
      results.length,
    )),
    responseCacheHitRate: round(divide(
      results.filter((result) => result.responseCacheHit).length,
      results.length,
    )),
    inputTokens: sum(results, 'inputTokens'),
    outputTokens: sum(results, 'outputTokens'),
    embeddingTokens: sum(results, 'embeddingTokens'),
    estimatedCostUsd: round(sum(results, 'estimatedCostMicros') / 1_000_000),
  },
  failures: results.filter((result) => !result.passed),
  results,
}

console.log(JSON.stringify(report, null, 2))

if (persistenceRequested()) {
  await persistEvalRun({
    kind: 'live',
    suite: report.dataset,
    model: null,
    promptVersion: null,
    startedAt,
    finishedAt: report.generatedAt,
    caseCount: results.length,
    passedCount: results.filter((result) => result.passed).length,
    metrics: report.metrics,
    costMicros: sum(results, 'estimatedCostMicros'),
    notes: `pricing ${report.pricingVersion}`,
  }, caseRecords)
}

async function loadCases(url: URL): Promise<EvalCase[]> {
  const content = await Deno.readTextFile(url)
  const values = url.pathname.endsWith('.jsonl')
    ? content.split('\n').filter(Boolean).map((line) => JSON.parse(line))
    : JSON.parse(content)
  if (!Array.isArray(values)) throw new Error('Eval dataset must be an array or JSONL')
  return values as EvalCase[]
}

async function uploadPhoto(imagePath: string, userId: string, requestId: string) {
  const file = await Deno.readFile(new URL(imagePath, root))
  const path = `${userId}/${requestId}/source.png`
  const response = await fetch(`${supabaseUrl}/storage/v1/object/meal-photos/${path}`, {
    method: 'POST',
    headers: { ...authHeaders(), 'content-type': 'image/png', 'x-upsert': 'false' },
    body: file,
  })
  if (!response.ok) throw new Error(`Eval photo upload failed with ${response.status}`)
  return { bucket: 'meal-photos', path, mimeType: 'image/png' }
}

async function loadTelemetry(analysisRunId: string): Promise<Record<string, unknown>> {
  const fields = [
    'latency_ms',
    'provider_input_tokens',
    'provider_output_tokens',
    'embedding_input_tokens',
    'retrieval_cache_hit',
    'response_cache_hit',
    'estimated_cost_micros',
  ].join(',')
  const response = await fetch(
    `${supabaseUrl}/rest/v1/analysis_runs?id=eq.${analysisRunId}&select=${fields}`,
    { headers: authHeaders() },
  )
  if (!response.ok) return {}
  const rows = await response.json()
  return Array.isArray(rows) && rows[0] ? rows[0] as Record<string, unknown> : {}
}

function authHeaders(): Record<string, string> {
  return {
    apikey: publishableKey,
    authorization: `Bearer ${userJwt}`,
    'content-type': 'application/json',
  }
}

function jwtSubject(jwt: string): string {
  const encoded = jwt.split('.')[1]
  if (!encoded) throw new Error('EVAL_USER_JWT is invalid')
  const normalized = encoded.replace(/-/gu, '+').replace(/_/gu, '/')
  const payload = JSON.parse(atob(normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=')))
  if (typeof payload.sub !== 'string') throw new Error('EVAL_USER_JWT has no subject')
  return payload.sub
}

function emptyResult(
  id: string,
  latencyMs: number,
  noMatchCorrect: boolean,
  errorCode: string,
): CaseResult {
  return {
    id,
    passed: noMatchCorrect,
    identityExact: noMatchCorrect,
    noMatchCorrect,
    portionErrors: [],
    latencyMs,
    retrievalCacheHit: false,
    responseCacheHit: false,
    inputTokens: 0,
    outputTokens: 0,
    embeddingTokens: 0,
    estimatedCostMicros: 0,
    errorCode,
  }
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim()
  if (!value) throw new Error(`${name} is required`)
  return value
}

function setEquals(left: Set<string>, right: Set<string>): boolean {
  return left.size === right.size && [...left].every((value) => right.has(value))
}

function divide(numerator: number, denominator: number): number {
  return denominator === 0 ? 0 : numerator / denominator
}

function round(value: number): number {
  return Math.round(value * 10000) / 10000
}

function percentile(sorted: number[], fraction: number): number {
  if (sorted.length === 0) return 0
  return sorted[Math.min(sorted.length - 1, Math.ceil(sorted.length * fraction) - 1)]
}

function sum(results: CaseResult[], key: keyof CaseResult): number {
  return results.reduce((total, result) => total + Number(result[key]), 0)
}
