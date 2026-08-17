import { withSupabase } from 'npm:@supabase/server@1.4.1'
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'
import {
  ANALYSIS_CONTRACT_VERSION,
  type AnalysisItem,
  type AnalyzeMealResponse,
  DETERMINISTIC_PIPELINE_VERSION,
  VISION_PIPELINE_VERSION,
} from '../_shared/contracts.ts'
import { errorResponse, jsonHeaders, jsonResponse, redactedLog } from '../_shared/http.ts'
import {
  analyzeDeterministically,
  type CatalogAlias,
  type CatalogFood,
  type CatalogPortion,
} from './deterministic.ts'
import { parseAnalyzeMealRequest, RequestValidationError } from './request.ts'
import { reconcileModalities } from './reconcile.ts'
import { extractFoodsFromPhoto } from './vision.ts'
import {
  type CandidateSelectionResult,
  type RetrievalCandidate,
  selectCatalogCandidates,
} from './candidate-selector.ts'
import { hybridSearch } from '../search-food-catalog/hybrid.ts'

interface RunRow {
  id: string
  trace_id: string
  status: string
  output: AnalyzeMealResponse | null
}

interface SupabaseContext {
  supabase: SupabaseClient
  supabaseAdmin: SupabaseClient
  userClaims?: Record<string, unknown>
}

export default {
  fetch: withSupabase({ auth: 'user' }, async (request: Request, rawContext: unknown) => {
    const context = rawContext as SupabaseContext
    if (request.method === 'OPTIONS') return new Response('ok', { headers: jsonHeaders })

    const requestTraceId = crypto.randomUUID()
    if (request.method !== 'POST') {
      return errorResponse(
        'METHOD_NOT_ALLOWED',
        'Only POST is supported',
        requestTraceId,
        405,
      )
    }

    let body
    try {
      body = parseAnalyzeMealRequest(await request.json())
    } catch (error) {
      const validation = error instanceof RequestValidationError ? error : null
      return errorResponse(
        'INVALID_REQUEST',
        validation?.message ?? 'Body must be valid JSON',
        requestTraceId,
        400,
        false,
        validation?.field ? { field: validation.field } : undefined,
      )
    }

    const userId = userIdFromClaims(context.userClaims)
    if (!userId) {
      return errorResponse(
        'INTERNAL_ERROR',
        'Authenticated user is unavailable',
        requestTraceId,
        500,
      )
    }
    if (body.photo && !body.photo.path.startsWith(`${userId}/${body.clientRequestId}/`)) {
      return errorResponse(
        'FORBIDDEN',
        'Photo path does not belong to this request',
        requestTraceId,
        403,
      )
    }

    const startedAt = performance.now()
    let run: RunRow | null = null
    try {
      run = await findRun(context, userId, body.clientRequestId)
      if (run?.output && ['needs_review', 'completed'].includes(run.status)) {
        redactedLog('info', 'analysis_replayed', {
          traceId: run.trace_id,
          analysisRunId: run.id,
          userId,
        })
        return jsonResponse({ ...run.output, replayed: true })
      }

      run ??= await createRun(context, {
        userId,
        clientRequestId: body.clientRequestId,
        traceId: requestTraceId,
        input: body.input || '[photo]',
        inputKind: body.inputKind ?? 'text',
      })

      const vision = body.photo
        ? await extractFoodsFromPhoto(
          context.supabaseAdmin,
          body.photo,
          body.locale ?? 'tr-TR',
          body.input,
        )
        : null
      const catalog = await loadCatalog(context, body.locale ?? 'tr-TR')
      const textAnalysis = analyzeDeterministically(body.input, catalog)
      const visionAnalysis = vision
        ? analyzeDeterministically(vision.normalizedDescription, catalog)
        : null
      const analysis = reconcileModalities(textAnalysis, visionAnalysis)
      const grounding = await groundUnmatchedText(context, {
        query: analysis.unmatchedText.join(' '),
        locale: body.locale ?? 'tr-TR',
        existingFoodIds: new Set(analysis.items.map((item) => item.foodId)),
      })
      if (grounding) {
        const groundedItems = toAnalysisItems(grounding.selection, grounding.candidates)
        analysis.items.push(...groundedItems)
        if (groundedItems.length > 0) analysis.unmatchedText = []
        analysis.items.forEach((item, index) => item.itemKey = `item-${index + 1}`)
      }
      if (analysis.items.length === 0) {
        await markRunFailed(context, run.id, 'NO_MATCH', 'No catalog-grounded food was found')
        return errorResponse(
          'NO_MATCH',
          'Yiyeceği katalogda güvenle eşleştiremedik',
          run.trace_id,
          422,
          false,
          { unmatchedText: analysis.unmatchedText },
        )
      }

      const output: AnalyzeMealResponse = {
        contractVersion: ANALYSIS_CONTRACT_VERSION,
        analysisRunId: run.id,
        traceId: run.trace_id,
        status: 'needs_review',
        normalizedInput: analysis.normalizedInput,
        items: analysis.items,
        unmatchedText: analysis.unmatchedText,
        pipeline: {
          extraction: vision ? VISION_PIPELINE_VERSION : DETERMINISTIC_PIPELINE_VERSION,
          retrieval: 'hybrid-rrf-v1',
          model: grounding?.selection.model ?? vision?.model ?? null,
          ...(grounding
            ? { promptVersion: grounding.selection.promptVersion }
            : vision
            ? { promptVersion: vision.promptVersion }
            : {}),
        },
        replayed: false,
      }
      await persistResult(
        context,
        run.id,
        output,
        Math.round(performance.now() - startedAt),
        grounding,
      )

      redactedLog('info', 'analysis_completed', {
        traceId: run.trace_id,
        analysisRunId: run.id,
        userId,
        inputLength: body.input.length,
        hasPhoto: Boolean(body.photo),
        visionModel: vision?.model ?? null,
        itemCount: output.items.length,
        unmatchedCount: output.unmatchedText.length,
        latencyMs: Math.round(performance.now() - startedAt),
      })
      return jsonResponse(output)
    } catch (error) {
      if (run) await markRunFailed(context, run.id, 'INTERNAL_ERROR', safeErrorMessage(error))
      redactedLog('error', 'analysis_failed', {
        traceId: run?.trace_id ?? requestTraceId,
        analysisRunId: run?.id ?? null,
        userId,
        errorType: error instanceof Error ? error.name : 'UnknownError',
      })
      return errorResponse(
        'INTERNAL_ERROR',
        'Analiz şu anda tamamlanamadı',
        run?.trace_id ?? requestTraceId,
        500,
        true,
      )
    }
  }),
}

async function findRun(
  context: SupabaseContext,
  userId: string,
  clientRequestId: string,
): Promise<RunRow | null> {
  const { data, error } = await context.supabaseAdmin
    .from('analysis_runs')
    .select('id,trace_id,status,output')
    .eq('user_id', userId)
    .eq('client_request_id', clientRequestId)
    .maybeSingle()
  if (error) throw error
  return data as RunRow | null
}

async function createRun(
  context: SupabaseContext,
  input: {
    userId: string
    clientRequestId: string
    traceId: string
    input: string
    inputKind: string
  },
): Promise<RunRow> {
  const { data, error } = await context.supabaseAdmin
    .from('analysis_runs')
    .upsert({
      user_id: input.userId,
      client_request_id: input.clientRequestId,
      trace_id: input.traceId,
      raw_input: input.input,
      input_kind: input.inputKind,
      status: 'running',
      retrieval_version: 'hybrid-rrf-v1',
    }, { onConflict: 'user_id,client_request_id', ignoreDuplicates: true })
    .select('id,trace_id,status,output')
    .maybeSingle()
  if (error) throw error
  if (data) return data as RunRow

  const replay = await findRun(context, input.userId, input.clientRequestId)
  if (!replay) throw new Error('Analysis run could not be created')
  if (replay.status === 'running') {
    throw new Error('Concurrent analysis is already running')
  }
  return replay
}

async function loadCatalog(
  context: SupabaseContext,
  locale: 'tr-TR' | 'en-US',
): Promise<CatalogFood[]> {
  const [foodsResult, aliasesResult, portionsResult] = await Promise.all([
    context.supabaseAdmin.from('foods').select(
      'id,canonical_name,calories_per_100g,protein_per_100g,carbs_per_100g,fat_per_100g',
    ).eq('is_active', true),
    context.supabaseAdmin.from('food_aliases').select('food_id,alias,priority').eq(
      'locale',
      locale,
    ),
    context.supabaseAdmin.from('food_portions').select('food_id,label,grams,is_default').eq(
      'locale',
      locale,
    ),
  ])
  for (const result of [foodsResult, aliasesResult, portionsResult]) {
    if (result.error) throw result.error
  }

  const aliasesByFood = groupByFood<CatalogAlias>(aliasesResult.data, (row) => ({
    value: String(row.alias),
    priority: Number(row.priority),
  }))
  const portionsByFood = groupByFood<CatalogPortion>(portionsResult.data, (row) => ({
    label: String(row.label),
    grams: Number(row.grams),
    isDefault: Boolean(row.is_default),
  }))

  return (foodsResult.data ?? []).map((row: Record<string, unknown>) => ({
    id: String(row.id),
    canonicalName: String(row.canonical_name),
    nutritionPer100g: {
      calories: Number(row.calories_per_100g),
      protein: Number(row.protein_per_100g),
      carbs: Number(row.carbs_per_100g),
      fat: Number(row.fat_per_100g),
    },
    aliases: aliasesByFood.get(String(row.id)) ?? [],
    portions: portionsByFood.get(String(row.id)) ?? [],
  })).filter((food: CatalogFood) => food.aliases.length > 0 && food.portions.length > 0)
}

async function persistResult(
  context: SupabaseContext,
  runId: string,
  output: AnalyzeMealResponse,
  latencyMs: number,
  grounding: GroundingResult | null,
): Promise<void> {
  const candidates = output.items.map((item) => ({
    analysis_run_id: runId,
    item_key: item.itemKey,
    food_id: item.foodId,
    rank: 1,
    retrieval_score: item.confidence,
    selected: true,
    rationale: {
      method: item.matchMethod,
      needsClarification: item.needsClarification,
      clarificationReason: item.clarificationReason ?? null,
    },
  }))
  const { error: candidateError } = await context.supabaseAdmin
    .from('analysis_candidates')
    .upsert(candidates, { onConflict: 'analysis_run_id,item_key,rank' })
  if (candidateError) throw candidateError

  const { error: runError } = await context.supabaseAdmin
    .from('analysis_runs')
    .update({
      status: 'needs_review',
      output,
      model_name: grounding?.selection.model ?? output.pipeline.model,
      prompt_version: grounding?.selection.promptVersion ?? output.pipeline.promptVersion ?? null,
      retrieval_version: 'hybrid-rrf-v1',
      latency_ms: latencyMs,
      provider_input_tokens: grounding?.selection.inputTokens ?? null,
      provider_output_tokens: grounding?.selection.outputTokens ?? null,
      provider_attempts: grounding?.selection.attempts ?? null,
      retrieval_cache_hit: grounding?.cacheHit ?? null,
      completed_at: new Date().toISOString(),
      error_code: null,
      error_detail: null,
    })
    .eq('id', runId)
  if (runError) throw runError
}

interface GroundingResult {
  candidates: RetrievalCandidate[]
  selection: CandidateSelectionResult
  cacheHit: boolean
}

async function groundUnmatchedText(
  context: SupabaseContext,
  input: {
    query: string
    locale: 'tr-TR' | 'en-US'
    existingFoodIds: Set<string>
  },
): Promise<GroundingResult | null> {
  if (input.query.trim().length < 2) return null
  const apiKey = Deno.env.get('OPENAI_API_KEY')?.trim()
  if (!apiKey) return null
  try {
    const retrieval = await hybridSearch(context.supabase, context.supabaseAdmin, {
      query: input.query,
      locale: input.locale,
      limit: 10,
      openAiApiKey: apiKey,
    })
    const candidates = retrieval.rows.map(toRetrievalCandidate).filter((candidate) =>
      candidate !== null && !input.existingFoodIds.has(candidate.foodId)
    ) as RetrievalCandidate[]
    if (candidates.length === 0) return null
    const selection = await selectCatalogCandidates({
      apiKey,
      locale: input.locale,
      input: input.query,
      candidates,
    })
    return { candidates, selection, cacheHit: retrieval.cacheHit }
  } catch (error) {
    const detail = providerErrorDetail(error)
    redactedLog('info', 'candidate_grounding_fallback', {
      errorType: detail.type,
      errorCode: detail.code,
      errorMessage: detail.message,
    })
    return null
  }
}

function providerErrorDetail(
  error: unknown,
): { type: string; code: string | null; message: string } {
  if (error instanceof Error) {
    return { type: error.name, code: null, message: error.message.slice(0, 180) }
  }
  if (typeof error === 'object' && error !== null) {
    const row = error as Record<string, unknown>
    return {
      type: 'ProviderError',
      code: typeof row.code === 'string' ? row.code : null,
      message: typeof row.message === 'string'
        ? row.message.slice(0, 180)
        : 'Unknown provider error',
    }
  }
  return { type: 'UnknownError', code: null, message: 'Unknown provider error' }
}

function toRetrievalCandidate(row: Record<string, unknown>): RetrievalCandidate | null {
  const defaultGrams = Number(row.default_grams)
  if (!row.food_id || !Number.isFinite(defaultGrams) || defaultGrams <= 0) return null
  return {
    foodId: String(row.food_id),
    canonicalName: String(row.canonical_name),
    matchedAlias: String(row.matched_alias),
    score: Number(row.score),
    defaultGrams,
    defaultPortionLabel: String(row.default_portion_label),
    nutritionPer100g: {
      calories: Number(row.calories_per_100g),
      protein: Number(row.protein_per_100g),
      carbs: Number(row.carbs_per_100g),
      fat: Number(row.fat_per_100g),
    },
  }
}

function toAnalysisItems(
  selection: CandidateSelectionResult,
  candidates: RetrievalCandidate[],
): AnalysisItem[] {
  if (selection.noMatch) return []
  const byId = new Map(candidates.map((candidate) => [candidate.foodId, candidate]))
  return selection.selections.flatMap((selected, index) => {
    const candidate = byId.get(selected.candidateId)
    if (!candidate) return []
    return [{
      itemKey: `item-grounded-${index + 1}`,
      sourceText: selected.sourceText,
      foodId: candidate.foodId,
      canonicalName: candidate.canonicalName,
      portionLabel: `${Math.round(selected.estimatedGrams)} g`,
      grams: selected.estimatedGrams,
      quantity: 1,
      confidence: Math.round(Math.min(selected.confidence, candidate.score) * 100) / 100,
      matchMethod: 'llm' as const,
      needsClarification: true,
      clarificationReason: 'portion' as const,
      nutritionPer100g: candidate.nutritionPer100g,
    }]
  })
}

async function markRunFailed(
  context: SupabaseContext,
  runId: string,
  code: string,
  detail: string,
): Promise<void> {
  const { error } = await context.supabaseAdmin.from('analysis_runs').update({
    status: 'failed',
    error_code: code,
    error_detail: detail.slice(0, 500),
    completed_at: new Date().toISOString(),
  }).eq('id', runId)
  if (error) redactedLog('error', 'analysis_failure_persistence_failed', { analysisRunId: runId })
}

function groupByFood<T>(
  rows: Array<Record<string, unknown>> | null,
  map: (row: Record<string, unknown>) => T,
): Map<string, T[]> {
  const grouped = new Map<string, T[]>()
  for (const row of rows ?? []) {
    const foodId = String(row.food_id)
    grouped.set(foodId, [...(grouped.get(foodId) ?? []), map(row)])
  }
  return grouped
}

function userIdFromClaims(claims?: Record<string, unknown>): string | null {
  const value = claims?.sub ?? claims?.id
  return typeof value === 'string' && value.length > 0 ? value : null
}

function safeErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message.slice(0, 500) : 'Unknown error'
}
