/**
 * Runs the catalog embedding backfill to completion, outside any request.
 *
 * The backfill embeds up to 50 stale rows per call and it lives on the search
 * request path, which was tolerable while almost nothing was stale. Translating
 * 54,857 rows changed their aliases, aliases are part of the embedding
 * document, and so every one of those rows became stale at once — leaving the
 * request path to grind through them 50 at a time, paying a provider call
 * inside a request a user is waiting on, for well over a thousand searches.
 *
 * This imports the same `backfillCatalogEmbeddings` the functions use rather
 * than reimplementing it: the document format and its hash have to match
 * exactly, or rows would be re-embedded forever without ever being marked
 * current.
 *
 *   SUPABASE_URL=https://PROJECT.supabase.co \
 *   SUPABASE_SERVICE_ROLE_KEY=... \
 *   OPENAI_API_KEY=... \
 *   deno task --config supabase/deno.json backfill:embeddings
 *
 * Safe to stop and rerun: progress is a persisted cursor plus a per-row hash,
 * and the advisory lock means it cannot collide with a live request.
 */
import { createClient } from 'npm:@supabase/supabase-js@2.112.3'
import { backfillCatalogEmbeddings, DEFAULT_EMBEDDING_MODEL } from '../_shared/embeddings.ts'

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim()
  if (!value) throw new Error(`${name} is required`)
  return value
}

const client = createClient(
  requiredEnv('SUPABASE_URL'),
  requiredEnv('SUPABASE_SERVICE_ROLE_KEY'),
  { auth: { persistSession: false } },
)
const apiKey = requiredEnv('OPENAI_API_KEY')
const model = Deno.env.get('OPENAI_EMBEDDING_MODEL')?.trim() || DEFAULT_EMBEDDING_MODEL
const batchSize = Math.max(1, Math.min(100, Number(Deno.env.get('BACKFILL_BATCH_SIZE') ?? 100)))

const { count: total } = await client.from('foods')
  .select('id', { count: 'exact', head: true }).eq('is_active', true)

let updated = 0
let promptTokens = 0
let idleRounds = 0

// Stops on two consecutive rounds that changed nothing: one empty round can
// simply mean the cursor reached the end of the table and wrapped.
while (idleRounds < 2) {
  const result = await backfillCatalogEmbeddings(client, { apiKey, model, batchSize })
  if (!result.locked) {
    console.error('another worker holds the backfill lease; retrying in 5s')
    await new Promise((resolve) => setTimeout(resolve, 5_000))
    continue
  }
  if (result.updated === 0) {
    idleRounds += 1
    continue
  }
  idleRounds = 0
  updated += result.updated
  promptTokens += result.promptTokens
  console.error(
    `embedded ${updated.toLocaleString()} rows (${promptTokens.toLocaleString()} tokens)`,
  )
}

const { count: embedded } = await client.from('foods')
  .select('id', { count: 'exact', head: true })
  .eq('is_active', true).eq('embedding_model', model).not('embedding_source_hash', 'is', null)

console.error(
  `done: ${embedded?.toLocaleString() ?? '?'} of ${total?.toLocaleString() ?? '?'} active rows ` +
    `carry a current ${model} embedding`,
)
