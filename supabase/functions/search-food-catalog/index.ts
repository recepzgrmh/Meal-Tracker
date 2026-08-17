import { withSupabase } from 'npm:@supabase/server@1.4.1'
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'
import { errorResponse, jsonResponse, redactedLog } from '../_shared/http.ts'
import { parseSearchRequest, SearchRequestValidationError } from './request.ts'

interface SearchContext {
  supabase: SupabaseClient
  userClaims?: Record<string, unknown>
}

export default {
  fetch: withSupabase({ auth: 'user' }, async (request: Request, rawContext: unknown) => {
    const traceId = crypto.randomUUID()
    if (request.method !== 'POST') {
      return errorResponse('METHOD_NOT_ALLOWED', 'Only POST is supported', traceId, 405)
    }
    let body
    try {
      body = parseSearchRequest(await request.json())
    } catch (error) {
      const validation = error instanceof SearchRequestValidationError ? error : null
      return errorResponse(
        'INVALID_REQUEST',
        validation?.message ?? 'Body must be valid JSON',
        traceId,
        400,
        false,
        validation?.field ? { field: validation.field } : undefined,
      )
    }

    const context = rawContext as SearchContext
    const startedAt = performance.now()
    const { data, error } = await context.supabase.rpc('search_food_catalog', {
      p_query: body.query,
      p_locale: body.locale,
      p_limit: body.limit,
    })
    if (error) {
      const status = error.code === '22023' ? 422 : error.code === '42501' ? 403 : 500
      const code = status === 422
        ? 'INVALID_REQUEST'
        : status === 403
        ? 'FORBIDDEN'
        : 'INTERNAL_ERROR'
      return errorResponse(code, 'Katalog araması tamamlanamadı', traceId, status, status >= 500)
    }

    const candidates = (data ?? []).map((row: Record<string, unknown>) => ({
      foodId: row.food_id,
      canonicalName: row.canonical_name,
      matchedAlias: row.matched_alias,
      matchMethod: row.match_method,
      score: Number(row.score),
      defaultGrams: row.default_grams == null ? null : Number(row.default_grams),
      defaultPortionLabel: row.default_portion_label,
      nutritionPer100g: {
        calories: Number(row.calories_per_100g),
        protein: Number(row.protein_per_100g),
        carbs: Number(row.carbs_per_100g),
        fat: Number(row.fat_per_100g),
      },
      nutritionSource: row.nutrition_source,
    }))
    redactedLog('info', 'catalog_search_completed', {
      traceId,
      userId: userIdFromClaims(context.userClaims),
      queryLength: body.query.length,
      candidateCount: candidates.length,
      latencyMs: Math.round(performance.now() - startedAt),
    })
    return jsonResponse({
      contractVersion: 'catalog-search.v1',
      traceId,
      query: body.query,
      candidates,
    })
  }),
}

function userIdFromClaims(claims?: Record<string, unknown>): string {
  const value = claims?.sub ?? claims?.id
  return typeof value === 'string' ? value : 'unknown'
}
