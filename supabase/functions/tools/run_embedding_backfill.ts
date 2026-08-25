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
const batchSize = Math.max(1, Math.min(500, Number(Deno.env.get('BACKFILL_BATCH_SIZE') ?? 500)))

const { count: total } = await client.from('foods')
  .select('id', { count: 'exact', head: true }).eq('is_active', true)

let updated = 0
let promptTokens = 0
let idleRounds = 0

// Stops on two consecutive rounds that changed nothing: one empty round can
// simply mean the cursor reached the end of the table and wrapped.
const MAX_CONSECUTIVE_FAILURES = 25
// Only the provider call carries its own timeout; the PostgREST reads and the
// vector writes do not, so a stalled HTTP/2 stream would hang the run with no
// output and no error at all. A round is bounded here instead: rounds are
// resumable, so abandoning one costs nothing but the work it had not committed.
const ROUND_TIMEOUT_MS = Math.max(
  30_000,
  Number(Deno.env.get('BACKFILL_ROUND_TIMEOUT_MS') ?? 120_000),
)

function withTimeout<T>(work: Promise<T>, label: string): Promise<T> {
  return Promise.race([
    work,
    new Promise<never>((_, reject) =>
      setTimeout(
        () => reject(new Error(`${label} exceeded ${ROUND_TIMEOUT_MS}ms`)),
        ROUND_TIMEOUT_MS,
      )
    ),
  ])
}
let consecutiveFailures = 0

while (idleRounds < 2) {
  let result
  try {
    result = await withTimeout(
      // The provider default of 8s was sized for a single query embedding; a
      // round now sends up to 500 documents at once.
      backfillCatalogEmbeddings(client, { apiKey, model, batchSize, timeoutMs: 60_000 }),
      'backfill round',
    )
    consecutiveFailures = 0
  } catch (error) {
    // A statement timeout or a transient provider error must not end a run that
    // has hours of work behind it. Nothing was half-committed: the cursor only
    // advances after a round succeeds, and a row counts as done only once its
    // own hash is stored, so the failed window is simply retried.
    // Statement timeouts and HTTP/2 stream errors are what writing tens of
    // thousands of 1536-dimension vectors over PostgREST looks like; they are
    // noise, not a reason to abandon a run with hours of work behind it. Only a
    // long unbroken streak means something is actually wrong.
    consecutiveFailures += 1
    const detail = error instanceof Error ? error.message : JSON.stringify(error)
    console.error(`round failed (${consecutiveFailures}/${MAX_CONSECUTIVE_FAILURES}): ${detail}`)
    if (consecutiveFailures >= MAX_CONSECUTIVE_FAILURES) throw error
    await new Promise((resolve) =>
      setTimeout(resolve, Math.min(30_000, 2_000 * consecutiveFailures))
    )
    continue
  }
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
