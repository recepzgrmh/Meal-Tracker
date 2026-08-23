import { withSupabase } from 'npm:@supabase/server@1.4.1'
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'
import { errorResponse, jsonResponse, redactedLog } from '../_shared/http.ts'
import { hybridSearch, lexicalSearch } from './hybrid.ts'
import { parseSearchRequest, SearchRequestValidationError } from './request.ts'

interface SearchContext {
  supabase: SupabaseClient
  supabaseAdmin: SupabaseClient
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
    let search
    try {
      const apiKey = Deno.env.get('OPENAI_API_KEY')?.trim()
      const semanticEnabled = Deno.env.get('CATALOG_SEMANTIC_SEARCH_ENABLED') === 'true'
      search = semanticEnabled && apiKey
        ? await hybridSearch(context.supabase, context.supabaseAdmin, {
          query: body.query,
          locale: body.locale,
          limit: body.limit,
          openAiApiKey: apiKey,
        })
        : await lexicalSearch(context.supabase, body, 0)
    } catch (error) {
      redactedLog('error', 'catalog_search_failed', {
        traceId,
        userId: userIdFromClaims(context.userClaims),
        queryLength: body.query.length,
        errorType: error instanceof Error ? error.name : 'UnknownError',
        latencyMs: Math.round(performance.now() - startedAt),
      })
      return errorResponse('INTERNAL_ERROR', 'Katalog araması tamamlanamadı', traceId, 500, true)
    }

    const candidates = search.rows.map((row: Record<string, unknown>) => ({
      foodId: row.food_id,
      canonicalName: row.canonical_name,
      matchedAlias: row.matched_alias,
      matchMethod: row.match_method,
      score: Number(row.score),
      lexicalRank: row.lexical_rank == null ? null : Number(row.lexical_rank),
      vectorRank: row.vector_rank == null ? null : Number(row.vector_rank),
      semanticSimilarity: row.semantic_similarity == null ? null : Number(row.semantic_similarity),
      defaultGrams: row.default_grams == null ? null : Number(row.default_grams),
      // Explicitly nullable: a food with no tr-TR portion row yields NULL from
      // the RPC's left join lateral. Clients must handle it, not assume a label.
      defaultPortionLabel: row.default_portion_label ?? null,
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
      cacheHit: search.cacheHit,
      fallback: search.fallback,
      embeddingModel: search.embeddingModel,
      embeddingPromptTokens: search.embeddingPromptTokens,
      backfilledFoods: search.backfilledFoods,
      latencyMs: Math.round(performance.now() - startedAt),
    })
    return jsonResponse({
      contractVersion: 'catalog-search.v2',
      traceId,
      query: body.query,
      candidates,
      telemetry: {
        provider: 'supabase_lean',
        cacheHit: search.cacheHit,
        fallback: search.fallback,
        embeddingModel: search.embeddingModel,
        embeddingPromptTokens: search.embeddingPromptTokens,
      },
    })
  }),
}

function userIdFromClaims(claims?: Record<string, unknown>): string {
  const value = claims?.sub ?? claims?.id
  return typeof value === 'string' ? value : 'unknown'
}
