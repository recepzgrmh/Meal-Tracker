import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'

export const DEFAULT_EMBEDDING_MODEL = 'text-embedding-3-small'
export const EMBEDDING_DIMENSIONS = 1536

interface FoodRow {
  id: string
  canonical_name: string
  locale: string
  embedding_model: string | null
  embedding_source_hash: string | null
}

interface AliasRow {
  food_id: string
  alias: string
  locale: string
}

interface EmbeddingClientOptions {
  apiKey: string
  model?: string
  fetcher?: typeof fetch
  timeoutMs?: number
  maxAttempts?: number
}

export interface EmbeddingBatchResult {
  vectors: number[][]
  promptTokens: number
  model: string
  attempts: number
}

export interface CatalogBackfillResult {
  locked: boolean
  scanned: number
  updated: number
  promptTokens: number
  model: string
}

export function buildFoodEmbeddingDocument(food: FoodRow, aliases: AliasRow[]): string {
  const localizedAliases = aliases
    .filter((alias) => alias.food_id === food.id)
    .map((alias) => `${alias.locale}:${normalizeForEmbedding(alias.alias)}`)
    .filter((value, index, values) => values.indexOf(value) === index)
    .sort()
  return [
    `locale:${food.locale}`,
    `food:${normalizeForEmbedding(food.canonical_name)}`,
    `aliases:${localizedAliases.join('|')}`,
  ].join('\n')
}

export async function sha256(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value)
  const digest = await crypto.subtle.digest('SHA-256', bytes)
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('')
}

export async function createEmbeddings(
  inputs: string[],
  options: EmbeddingClientOptions,
): Promise<EmbeddingBatchResult> {
  if (inputs.length === 0) {
    return {
      vectors: [],
      promptTokens: 0,
      model: options.model ?? DEFAULT_EMBEDDING_MODEL,
      attempts: 0,
    }
  }
  const model = options.model ?? DEFAULT_EMBEDDING_MODEL
  const fetcher = options.fetcher ?? fetch
  const timeoutMs = options.timeoutMs ?? 8_000
  const maxAttempts = options.maxAttempts ?? 3
  let lastStatus = 0

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), timeoutMs)
    try {
      const response = await fetcher('https://api.openai.com/v1/embeddings', {
        method: 'POST',
        headers: {
          authorization: `Bearer ${options.apiKey}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify({ model, input: inputs, dimensions: EMBEDDING_DIMENSIONS }),
        signal: controller.signal,
      })
      lastStatus = response.status
      if (response.ok) {
        const payload = await response.json() as Record<string, unknown>
        const rows = Array.isArray(payload.data) ? payload.data : []
        const vectors = rows
          .map((row) => row as { index?: number; embedding?: unknown })
          .sort((left, right) => Number(left.index) - Number(right.index))
          .map((row) => validateVector(row.embedding))
        if (vectors.length !== inputs.length) {
          throw new Error('Embedding provider returned an invalid batch')
        }
        const usage = payload.usage as { prompt_tokens?: unknown } | undefined
        return {
          vectors,
          promptTokens: Number(usage?.prompt_tokens ?? 0),
          model,
          attempts: attempt,
        }
      }
      if (![408, 409, 429].includes(response.status) && response.status < 500) break
    } catch (error) {
      if (
        !(error instanceof DOMException && error.name === 'AbortError') || attempt === maxAttempts
      ) {
        if (attempt === maxAttempts) throw error
      }
    } finally {
      clearTimeout(timeout)
    }
    await delay(100 * 2 ** (attempt - 1))
  }
  throw new Error(`Embedding provider failed with ${lastStatus || 'network_error'}`)
}

export async function backfillCatalogEmbeddings(
  client: SupabaseClient,
  options: EmbeddingClientOptions & { batchSize?: number },
): Promise<CatalogBackfillResult> {
  const model = options.model ?? DEFAULT_EMBEDDING_MODEL
  const { data: locked, error: lockError } = await client.rpc('claim_catalog_embedding_job', {
    p_lease_seconds: 60,
  })
  if (lockError) throw lockError
  if (!locked) return { locked: false, scanned: 0, updated: 0, promptTokens: 0, model }
  try {
    const { data: foods, error: foodsError } = await client.from('foods').select(
      'id,canonical_name,locale,embedding_model,embedding_source_hash',
    ).eq('is_active', true).order('id').limit(500)
    if (foodsError) throw foodsError
    const typedFoods = (foods ?? []) as FoodRow[]
    if (typedFoods.length === 0) {
      return { locked: true, scanned: 0, updated: 0, promptTokens: 0, model }
    }

    const ids = typedFoods.map((food) => food.id)
    const { data: aliases, error: aliasesError } = await client.from('food_aliases')
      .select('food_id,alias,locale').in('food_id', ids)
    if (aliasesError) throw aliasesError
    const typedAliases = (aliases ?? []) as AliasRow[]
    const documents = await Promise.all(typedFoods.map(async (food) => {
      const document = buildFoodEmbeddingDocument(food, typedAliases)
      return { food, document, hash: await sha256(document) }
    }))
    const stale = documents.filter(({ food, hash }) =>
      food.embedding_model !== model || food.embedding_source_hash !== hash
    ).slice(0, Math.min(options.batchSize ?? 50, 100))
    if (stale.length === 0) {
      return { locked: true, scanned: typedFoods.length, updated: 0, promptTokens: 0, model }
    }

    const embedded = await createEmbeddings(stale.map((row) => row.document), options)
    const timestamp = new Date().toISOString()
    for (let index = 0; index < stale.length; index += 1) {
      const { error } = await client.from('foods').update({
        embedding: embedded.vectors[index],
        embedding_model: embedded.model,
        embedding_source_hash: stale[index].hash,
        embedding_updated_at: timestamp,
      }).eq('id', stale[index].food.id)
      if (error) throw error
    }
    return {
      locked: true,
      scanned: typedFoods.length,
      updated: stale.length,
      promptTokens: embedded.promptTokens,
      model: embedded.model,
    }
  } finally {
    await client.rpc('finish_catalog_embedding_job')
  }
}

function validateVector(value: unknown): number[] {
  if (!Array.isArray(value) || value.length !== EMBEDDING_DIMENSIONS) {
    throw new Error(`Embedding vector must have ${EMBEDDING_DIMENSIONS} dimensions`)
  }
  const vector = value.map(Number)
  if (vector.some((entry) => !Number.isFinite(entry))) {
    throw new Error('Embedding vector is invalid')
  }
  return vector
}

function normalizeForEmbedding(value: string): string {
  return value.normalize('NFKC').trim().replace(/\s+/g, ' ').toLocaleLowerCase('tr-TR')
}

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds))
}
