import type { SupabaseClient } from '@supabase/supabase-js'
import { errorResponse, jsonResponse, redactedLog } from '../../shared/http.ts'
import { CommitRequestValidationError, parseCommitMealRequest } from './request.ts'

interface CommitContext {
  supabase: SupabaseClient
  userClaims?: Record<string, unknown>
}

interface CommitRpcResult {
  meal_id: string
  analysis_run_id: string
  row_version: number
  calories: number
  protein: number
  carbs: number
  fat: number
  replayed: boolean
}

export async function handleCommitMeal(
  request: Request,
  rawContext: unknown,
): Promise<Response> {
  const traceId = crypto.randomUUID()
  if (request.method !== 'POST') {
    return errorResponse('METHOD_NOT_ALLOWED', 'Only POST is supported', traceId, 405)
  }

  let body
  try {
    body = parseCommitMealRequest(await request.json())
  } catch (error) {
    const validation = error instanceof CommitRequestValidationError ? error : null
    return errorResponse(
      'INVALID_REQUEST',
      validation?.message ?? 'Body must be valid JSON',
      traceId,
      400,
      false,
      validation?.field ? { field: validation.field } : undefined,
    )
  }

  const context = rawContext as CommitContext
  const userId = userIdFromClaims(context.userClaims)
  const startedAt = performance.now()
  try {
    const { data, error } = await context.supabase.rpc('commit_analyzed_meal', {
      p_analysis_run_id: body.analysisRunId,
      p_commit_request_id: body.commitRequestId,
      p_meal_id: body.mealId,
      p_name: body.name,
      p_occurred_at: body.occurredAt,
      p_items: body.items.map((item) => ({
        item_id: item.itemId,
        item_key: item.itemKey,
        food_id: item.foodId ?? null,
        estimate_id: item.estimateId ?? null,
        source_text: item.sourceText,
        portion_label: item.portionLabel,
        grams: item.grams,
      })),
    })
    if (error) return databaseError(error, traceId)
    const result = data as CommitRpcResult
    redactedLog('info', 'meal_commit_completed', {
      traceId,
      userId,
      analysisRunId: body.analysisRunId,
      mealId: result.meal_id,
      itemCount: body.items.length,
      replayed: result.replayed,
      latencyMs: Math.round(performance.now() - startedAt),
    })
    return jsonResponse({
      contractVersion: 'meal-commit.v1',
      traceId,
      mealId: result.meal_id,
      analysisRunId: result.analysis_run_id,
      rowVersion: Number(result.row_version),
      nutrition: {
        calories: Number(result.calories),
        protein: Number(result.protein),
        carbs: Number(result.carbs),
        fat: Number(result.fat),
      },
      replayed: result.replayed,
    })
  } catch (error) {
    redactedLog('error', 'meal_commit_failed', {
      traceId,
      userId,
      analysisRunId: body.analysisRunId,
      errorType: error instanceof Error ? error.name : 'UnknownError',
    })
    return errorResponse('INTERNAL_ERROR', 'Öğün kaydedilemedi', traceId, 500, true)
  }
}

function databaseError(
  error: { code?: string; message?: string },
  traceId: string,
): Response {
  const code = error.code ?? 'DATABASE_ERROR'
  if (code === '42501') {
    return errorResponse('FORBIDDEN', 'Bu analize erişilemiyor', traceId, 403)
  }
  if (code === '40001' || code === '23505') {
    return errorResponse('CONFLICT', 'Analiz daha önce işlendi', traceId, 409)
  }
  if (code === '22023' || code === '22P02' || code === '23514') {
    return errorResponse('INVALID_REQUEST', 'Öğün doğrulanamadı', traceId, 422)
  }
  return errorResponse('INTERNAL_ERROR', 'Öğün kaydedilemedi', traceId, 500, true)
}

function userIdFromClaims(claims?: Record<string, unknown>): string {
  const value = claims?.sub ?? claims?.id
  return typeof value === 'string' ? value : 'unknown'
}
