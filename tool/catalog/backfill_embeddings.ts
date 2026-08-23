#!/usr/bin/env -S deno run --allow-env --allow-net
//
// One-off catalog embedding backfill.
//
// The in-request backfill inside hybridSearch only embeds a small batch per
// analysis call, so filling a 60k catalog through user traffic would take over
// a thousand requests and charge every one of them for catalog maintenance.
// This drains the same queue directly, reusing backfillCatalogEmbeddings so the
// embedding document and staleness hash cannot drift from the runtime.
//
// Usage:
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... OPENAI_API_KEY=... \
//     deno run --allow-env --allow-net tool/catalog/backfill_embeddings.ts

import { createClient } from 'npm:@supabase/supabase-js@2.112.3'
import {
  backfillCatalogEmbeddings,
  DEFAULT_EMBEDDING_MODEL,
} from '../../supabase/functions/_shared/embeddings.ts'

const BATCH_SIZE = 100

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim()
  if (!value) throw new Error(`${name} is required`)
  return value
}

const client = createClient(
  requireEnv('SUPABASE_URL'),
  requireEnv('SUPABASE_SERVICE_ROLE_KEY'),
  { auth: { persistSession: false } },
)
const apiKey = requireEnv('OPENAI_API_KEY')
const model = Deno.env.get('OPENAI_EMBEDDING_MODEL')?.trim() || DEFAULT_EMBEDDING_MODEL

let embedded = 0
let promptTokens = 0
let passes = 0

while (true) {
  const result = await backfillCatalogEmbeddings(client, { apiKey, model, batchSize: BATCH_SIZE })
  if (!result.locked) {
    console.error('another backfill holds the lease; retrying in 5s')
    await new Promise((resolve) => setTimeout(resolve, 5_000))
    continue
  }
  passes += 1
  embedded += result.updated
  promptTokens += result.promptTokens
  if (result.updated > 0) {
    console.error(`embedded ${embedded} foods (${promptTokens} prompt tokens)`)
  }
  // A pass that found nothing stale and wrapped the cursor means the whole
  // catalog is current.
  if (result.updated === 0 && result.cursor === null) break
}

console.log(JSON.stringify({ model, passes, embedded, promptTokens }, null, 2))
