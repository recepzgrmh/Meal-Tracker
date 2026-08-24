import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'
import {
  backfillCatalogEmbeddings,
  createEmbeddings,
  DEFAULT_EMBEDDING_MODEL,
  sha256,
} from '../_shared/embeddings.ts'

/**
 * Locale-relevance floor for meal analysis.
 *
 * A meal sentence is not a product name, so a row with no relevance to the
 * query's market is noise rather than a long-tail answer.
 *
 * 40 is not a round number picked by feel — it is the gap in the measured
 * distribution. Turkey relevance in `tr_branded` is discrete and its lowest two
 * buckets are 25 (29 rows) and 30 (1,821 rows, where the "Kremal" row that
 * broke "kremalı tavuklu makarna" sits); the next value used is 40. Cutting in
 * that gap removes those 1,850 rows and keeps everything above, so a real
 * imported product like Nutella at 45 stays reachable. A floor of 50 would have
 * taken Nutella with it.
 *
 * Combined with the RPC's generic_core exemption this leaves 16,647 of 60,000
 * rows in scope for a Turkish meal query, dropping every off_en_global,
 * usda_branded_quality and quality_global row — tiers whose Turkey relevance is
 * below 50 for 100% of their contents.
 *
 * Manual catalog search deliberately does not use this: someone typing a
 * specific imported product should still find it.
 */
export const ANALYSIS_LOCALE_RELEVANCE_FLOOR = 40

interface HybridSearchOptions {
  query: string
  locale: 'tr-TR' | 'en-US'
  limit: number
  openAiApiKey: string
  /** Omit to search the whole catalog; set for the analyze path. */
  minLocaleRelevance?: number
  /**
   * Skip the catalog embedding backfill for this call.
   *
   * The backfill is maintenance — it embeds up to 50 stale rows and writes them
   * back — and it was running inside the request the user is waiting on, so
   * every analysis paid for catalog upkeep. Manual catalog search still runs it,
   * which keeps the mechanism alive without putting it on the path where
   * latency is felt. A scheduled worker is the real home for it.
   */
  skipBackfill?: boolean
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
  if (!options.skipBackfill) {
    try {
      const backfill = await backfillCatalogEmbeddings(adminClient, {
        apiKey: options.openAiApiKey,
        model,
        batchSize: 50,
      })
      backfilledFoods = backfill.updated
      backfillTokens = backfill.promptTokens
    } catch {
      return lexicalSearch(userClient, options, backfilledFoods)
    }
  }

  const catalogFingerprint = await computeCatalogFingerprint(adminClient, options.locale, model)
  const normalizedQuery = normalizeQuery(options.query, options.locale)
  const queryHash = await sha256(normalizedQuery)
  // The floor changes which rows are eligible, so it has to be part of the key:
  // without it an unfiltered manual-search result could be replayed to the
  // analyze path, reintroducing exactly the rows the floor exists to remove.
  const cacheKey = await sha256(
    `${options.locale}|${model}|${catalogFingerprint}|${
      options.minLocaleRelevance ?? 'none'
    }|${queryHash}`,
  )
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
      p_min_locale_relevance: options.minLocaleRelevance ?? null,
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
    return lexicalSearch(userClient, options, backfilledFoods)
  }
}

export async function lexicalSearch(
  client: SupabaseClient,
  options: Pick<HybridSearchOptions, 'query' | 'locale' | 'limit' | 'minLocaleRelevance'>,
  backfilledFoods: number,
): Promise<HybridSearchResult> {
  const { data, error } = await client.rpc('hybrid_search_food_catalog', {
    p_query: options.query,
    p_query_embedding: null,
    p_locale: options.locale,
    p_limit: options.limit,
    // The embedding step failed, not the relevance rule: a degraded search must
    // not become a wider one.
    p_min_locale_relevance: options.minLocaleRelevance ?? null,
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
  // Reading every food row cost a full-table transfer per request and was
  // silently truncated by the API row cap, so the fingerprint described only a
  // fraction of the catalog. Three aggregates describe all of it instead.
  const [active, embedded, latest] = await Promise.all([
    client.from('foods').select('id', { count: 'exact', head: true }).eq('is_active', true),
    client.from('foods').select('id', { count: 'exact', head: true })
      .eq('is_active', true).eq('embedding_model', model).not('embedding_source_hash', 'is', null),
    client.from('foods').select('updated_at')
      .eq('is_active', true).order('updated_at', { ascending: false }).limit(1).maybeSingle(),
  ])
  for (const result of [active, embedded, latest]) {
    if (result.error) throw result.error
  }
  return sha256(JSON.stringify({
    locale,
    model,
    activeFoods: active.count ?? 0,
    embeddedFoods: embedded.count ?? 0,
    updatedAt: latest.data?.updated_at ?? null,
  }))
}

export function normalizeQuery(value: string, locale: 'tr-TR' | 'en-US'): string {
  return value.normalize('NFKC').trim().replace(/\s+/g, ' ').toLocaleLowerCase(locale)
}

/**
 * A vector index always returns its k nearest neighbours, however far away they
 * are, so "is there a result?" is never evidence of a match. At 0.35 unrelated
 * Turkish words routinely cleared the bar, which is how non-food tokens reached
 * the selector with a straight face. Vector-only rows now need a genuinely
 * close neighbour; anything weaker must be corroborated by the lexical side.
 */
export const MIN_SEMANTIC_SIMILARITY = 0.62

export function filterGroundedRows(
  rows: Array<Record<string, unknown>>,
  minimumSemanticSimilarity = MIN_SEMANTIC_SIMILARITY,
): Array<Record<string, unknown>> {
  return rows.filter((row) => {
    if (row.lexical_rank != null) return true
    const similarity = Number(row.semantic_similarity)
    return Number.isFinite(similarity) && similarity >= minimumSemanticSimilarity
  })
}
