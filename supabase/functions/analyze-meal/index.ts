import { withSupabase } from 'npm:@supabase/server@1.4.1'
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'
import {
  ANALYSIS_CONTRACT_VERSION,
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
import { extractFoodsFromPhoto } from './vision.ts'

interface RunRow {
  id: string
  trace_id: string
  status: string
  output: AnalyzeMealResponse | null
}

interface SupabaseContext {
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
      const groundedInput = [body.input, vision?.normalizedDescription]
        .filter((value) => value && value.trim().length > 0)
        .join(' ve ')
      const catalog = await loadCatalog(context, body.locale ?? 'tr-TR')
      const analysis = analyzeDeterministically(groundedInput, catalog)
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
          retrieval: 'exact-alias-v1',
          model: vision?.model ?? null,
          ...(vision ? { promptVersion: vision.promptVersion } : {}),
        },
        replayed: false,
      }
      await persistResult(context, run.id, output, Math.round(performance.now() - startedAt))

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
      retrieval_version: 'exact-alias-v1',
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
      model_name: null,
      prompt_version: null,
      retrieval_version: 'exact-alias-v1',
      latency_ms: latencyMs,
      completed_at: new Date().toISOString(),
      error_code: null,
      error_detail: null,
    })
    .eq('id', runId)
  if (runError) throw runError
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
