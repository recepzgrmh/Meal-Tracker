import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'

export const DEFAULT_EMBEDDING_MODEL = 'text-embedding-3-small'
// text-embedding-3-small is a Matryoshka model, so 512 is the same embedding as
// 1536 truncated and renormalized, not a weaker one. At 1536 a single vector is
// 6 KB and every catalog row paid an out-of-line TOAST write, which put the
// 60,003-row catalog over the database's size ceiling on its own.
export const EMBEDDING_DIMENSIONS = 512
const EMBEDDING_SCAN_WINDOW = 500
// Keeps the generated PostgREST URL well inside gateway limits: 100 uuids is
// roughly 4 KB of query string.
const ALIAS_QUERY_BATCH_SIZE = 100
// Rows per apply_catalog_embeddings() call. 100 rows of 512-dimension vectors
// serialize to roughly 550 KB of JSON, comfortably inside gateway body limits,
// and the function's per-key updates finish far inside the statement timeout.
const APPLY_BATCH_SIZE = 100

function chunkIds(ids: string[], size: number): string[][] {
  const batches: string[][] = []
  for (let index = 0; index < ids.length; index += size) {
    batches.push(ids.slice(index, index + size))
  }
  return batches
}

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
  /** Cursor after this run. Null means a full pass finished with nothing stale. */
  cursor: string | null
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
      if (attempt === maxAttempts) throw error
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
  if (!locked) {
    return { locked: false, scanned: 0, updated: 0, promptTokens: 0, model, cursor: null }
  }
  try {
    const { data: cursorValue, error: cursorError } = await client.rpc('catalog_embedding_cursor')
    if (cursorError) throw cursorError
    const cursor = typeof cursorValue === 'string' ? cursorValue : null

    // A window that always started at the first food could never reach the rest
    // of the catalog, so the scan resumes after the persisted cursor.
    let typedFoods = await scanWindow(client, cursor)
    if (typedFoods.length === 0 && cursor !== null) {
      await client.rpc('advance_catalog_embedding_cursor', { p_food_id: null })
      typedFoods = await scanWindow(client, null)
    }
    if (typedFoods.length === 0) {
      return { locked: true, scanned: 0, updated: 0, promptTokens: 0, model, cursor: null }
    }

    // PostgREST takes filters in the query string, so 500 ids in one `in()` is
    // a ~20 KB URL that the gateway rejects outright. The failure surfaced as a
    // bare "error sending request" and, inside the search path, was swallowed
    // by the fallback to lexical search — so the backfill could fail on every
    // call without anything reporting it.
    const typedAliases: AliasRow[] = []
    for (const batch of chunkIds(typedFoods.map((food) => food.id), ALIAS_QUERY_BATCH_SIZE)) {
      const { data: aliases, error: aliasesError } = await client.from('food_aliases')
        .select('food_id,alias,locale').in('food_id', batch)
      if (aliasesError) throw aliasesError
      typedAliases.push(...((aliases ?? []) as AliasRow[]))
    }
    const documents = await Promise.all(typedFoods.map(async (food) => {
      const document = buildFoodEmbeddingDocument(food, typedAliases)
      return { food, document, hash: await sha256(document) }
    }))
    const stale = documents.filter(({ food, hash }) =>
      food.embedding_model !== model || food.embedding_source_hash !== hash
    ).slice(0, Math.min(options.batchSize ?? 50, 500))
    const windowExhausted = typedFoods.length < EMBEDDING_SCAN_WINDOW
    if (stale.length === 0) {
      // Nothing left to embed in this window: step past it, or wrap when the
      // window was the tail of the catalog.
      const nextCursor = windowExhausted ? null : typedFoods[typedFoods.length - 1].id
      await client.rpc('advance_catalog_embedding_cursor', { p_food_id: nextCursor })
      return {
        locked: true,
        scanned: typedFoods.length,
        updated: 0,
        promptTokens: 0,
        model,
        cursor: nextCursor,
      }
    }

    const embedded = await createEmbeddings(stale.map((row) => row.document), options)
    // One apply_catalog_embeddings() call per chunk, not one PostgREST request
    // per row: a round's writes cost a handful of round trips instead of
    // hundreds. The function updates by primary key inside a loop, so the
    // statement budget goes to index lookups and cannot be lost to a
    // misplanned join. The vector travels in its text form because that is
    // what pgvector parses out of jsonb.
    const rows = stale.map((row, index) => ({
      id: row.food.id,
      embedding: `[${embedded.vectors[index].join(',')}]`,
      model: embedded.model,
      hash: row.hash,
    }))
    for (let start = 0; start < rows.length; start += APPLY_BATCH_SIZE) {
      const { error: applyError } = await client.rpc('apply_catalog_embeddings', {
        p_rows: rows.slice(start, start + APPLY_BATCH_SIZE),
      })
      if (applyError) throw applyError
    }

    // Resume just past the last food actually embedded. Anything still stale
    // behind that point stays in front of the cursor for the next run.
    const nextCursor = stale[stale.length - 1].food.id
    await client.rpc('advance_catalog_embedding_cursor', { p_food_id: nextCursor })
    return {
      locked: true,
      scanned: typedFoods.length,
      updated: stale.length,
      promptTokens: embedded.promptTokens,
      model: embedded.model,
      cursor: nextCursor,
    }
  } finally {
    await client.rpc('finish_catalog_embedding_job')
  }
}

async function scanWindow(client: SupabaseClient, cursor: string | null): Promise<FoodRow[]> {
  let query = client.from('foods').select(
    'id,canonical_name,locale,embedding_model,embedding_source_hash',
  ).eq('is_active', true).order('id').limit(EMBEDDING_SCAN_WINDOW)
  if (cursor) query = query.gt('id', cursor)
  const { data, error } = await query
  if (error) throw error
  return (data ?? []) as FoodRow[]
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
