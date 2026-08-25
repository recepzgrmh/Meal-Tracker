// Loads .env for local runs. ESM executes imports in order, so this must stay
// first: the CLI entrypoints read process.env at module scope. No-ops when the
// file is absent, which is the case on Railway where env is injected directly.
import 'dotenv/config'
import express from 'express'
import { mountAuthedHandler, mountPublicHandler } from './lib/route-adapter.ts'
import { redactedLog } from './shared/http.ts'
import { handleAnalyzeMeal } from './routes/analyze-meal/index.ts'
import { handleCommitMeal } from './routes/commit-meal/index.ts'
import { handleSearchFoodCatalog } from './routes/search-food-catalog/index.ts'
import { handleSendEmail } from './routes/send-email/index.ts'

const app = express()

// Deliberately NOT express.json(). Two reasons, both load-bearing:
//  1. Every handler still calls `await request.json()` itself, exactly as it did
//     on the Edge Runtime, so parsing here would consume the stream twice.
//  2. send-email verifies a standardwebhooks HMAC over the raw body.
//     express.json() would hand it a re-serialized object and every signature
//     would fail.
//
// raw (Buffer), not text (string): `express.text` decodes using the charset the
// caller declared and the adapter would then re-encode as UTF-8, so a body that
// declared iso-8859-1, or one carrying invalid UTF-8, would reach the HMAC
// check as different bytes than were signed. Handing the Buffer straight to the
// Request keeps the bytes untouched until a handler decodes them, which is
// exactly what the Edge Runtime did.
//
// `type: () => true` rather than '*/*': body-parser matches on the Content-Type
// header, and '*/*' does NOT match a request that omits the header entirely —
// its body would be silently dropped. This matches unconditionally.
app.use(express.raw({ type: () => true, limit: '10mb' }))

app.get('/healthz', (_req, res) => {
  res.json({ ok: true })
})

app.all('/analyze-meal', mountAuthedHandler(handleAnalyzeMeal))
app.all('/commit-meal', mountAuthedHandler(handleCommitMeal))
app.all('/search-food-catalog', mountAuthedHandler(handleSearchFoodCatalog))
app.all('/send-email', mountPublicHandler(handleSendEmail))

const port = Number(process.env.PORT ?? 8080)

app.listen(port, () => {
  redactedLog('info', 'server_started', { port })
})
