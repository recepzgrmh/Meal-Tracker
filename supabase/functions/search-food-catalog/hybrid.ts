import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'
import {
  backfillCatalogEmbeddings,
  createEmbeddings,
  DEFAULT_EMBEDDING_MODEL,
  sha256,
} from '../_shared/embeddings.ts'

interface HybridSearchOptions {
  query: string
  locale: 'tr-TR' | 'en-US'
  limit: number
  openAiApiKey: string
}

export interface HybridSearchResult {
  rows: Array<Record<string, unknown>>
  cacheHit: boolean
  fallback: boolean
  embeddingModel: string | null
  embeddingPromptTokens: number
  backfilledFoods: number
}

export async function hybridSearch(
  userClient: SupabaseClient,
  adminClient: SupabaseClient,
  options: HybridSearchOptions,
): Promise<HybridSearchResult> {
  const model = Deno.env.get('OPENAI_EMBEDDING_MODEL')?.trim() || DEFAULT_EMBEDDING_MODEL
  let backfilledFoods = 0
  let backfillTokens = 0
  try {
    const backfill = await backfillCatalogEmbeddings(adminClient, {
      apiKey: options.openAiApiKey,
      model,
      batchSize: 50,
    })
    backfilledFoods = backfill.updated
    backfillTokens = backfill.promptTokens
  } catch {
    return lexicalFallback(userClient, options, backfilledFoods)
  }

  const catalogFingerprint = await computeCatalogFingerprint(adminClient, options.locale, model)
  const normalizedQuery = normalizeQuery(options.query, options.locale)
  const queryHash = await sha256(normalizedQuery)
  const cacheKey = await sha256(`${options.locale}|${model}|${catalogFingerprint}|${queryHash}`)
  const { data: cached } = await adminClient.from('ai_retrieval_cache')
    .select('candidates,hit_count').eq('cache_key', cacheKey)
    .gt('expires_at', new Date().toISOString()).maybeSingle()
  if (cached && Array.isArray(cached.candidates)) {
    await adminClient.from('ai_retrieval_cache').update({
      hit_count: Number(cached.hit_count) + 1,
    }).eq('cache_key', cacheKey)
    return {
      rows: filterGroundedRows(cached.candidates as Array<Record<string, unknown>>),
      cacheHit: true,
      fallback: false,
      embeddingModel: model,
      embeddingPromptTokens: backfillTokens,
      backfilledFoods,
    }
  }

  try {
    const embedded = await createEmbeddings([normalizedQuery], {
      apiKey: options.openAiApiKey,
      model,
    })
    const { data, error } = await userClient.rpc('hybrid_search_food_catalog', {
      p_query: normalizedQuery,
      p_query_embedding: embedded.vectors[0],
      p_locale: options.locale,
      p_limit: options.limit,
    })
    if (error) throw error
    const rows = filterGroundedRows((data ?? []) as Array<Record<string, unknown>>)
    await adminClient.from('ai_retrieval_cache').upsert({
      cache_key: cacheKey,
      query_hash: queryHash,
      locale: options.locale,
      embedding_model: model,
      catalog_fingerprint: catalogFingerprint,
      query_embedding: embedded.vectors[0],
      candidates: rows,
      expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    })
    return {
      rows,
      cacheHit: false,
      fallback: false,
      embeddingModel: model,
      embeddingPromptTokens: backfillTokens + embedded.promptTokens,
      backfilledFoods,
    }
  } catch {
    return lexicalFallback(userClient, options, backfilledFoods)
  }
}

async function lexicalFallback(
  client: SupabaseClient,
  options: Pick<HybridSearchOptions, 'query' | 'locale' | 'limit'>,
  backfilledFoods: number,
): Promise<HybridSearchResult> {
  const { data, error } = await client.rpc('hybrid_search_food_catalog', {
    p_query: options.query,
    p_query_embedding: null,
    p_locale: options.locale,
    p_limit: options.limit,
  })
  if (error) throw error
  return {
    rows: (data ?? []) as Array<Record<string, unknown>>,
    cacheHit: false,
    fallback: true,
    embeddingModel: null,
    embeddingPromptTokens: 0,
    backfilledFoods,
  }
}

async function computeCatalogFingerprint(
  client: SupabaseClient,
  locale: string,
  model: string,
): Promise<string> {
  const { data, error } = await client.from('foods')
    .select('id,embedding_source_hash,embedding_model,updated_at')
    .eq('is_active', true).order('id')
  if (error) throw error
  return sha256(JSON.stringify({ locale, model, foods: data ?? [] }))
}

export function normalizeQuery(value: string, locale: 'tr-TR' | 'en-US'): string {
  return value.normalize('NFKC').trim().replace(/\s+/g, ' ').toLocaleLowerCase(locale)
}

export function filterGroundedRows(
  rows: Array<Record<string, unknown>>,
  minimumSemanticSimilarity = 0.35,
): Array<Record<string, unknown>> {
  return rows.filter((row) => {
    if (row.lexical_rank != null) return true
    const similarity = Number(row.semantic_similarity)
    return Number.isFinite(similarity) && similarity >= minimumSemanticSimilarity
  })
}
