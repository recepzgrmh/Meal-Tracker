# Meal Clarity — Node.js backend

Node.js 20 / TypeScript service behind the meal-logging pipeline. It serves the
three routes the mobile app calls on the critical path, plus the Supabase Auth
email webhook.

| Route | Auth | Purpose |
| --- | --- | --- |
| `POST /analyze-meal` | user JWT | messy input (text / voice transcript / photo) → canonical foods, portions, nutrition |
| `POST /commit-meal` | user JWT | idempotent write of a reviewed analysis into the meal log |
| `POST /search-food-catalog` | user JWT | hybrid catalog lookup used by the manual-correction sheet |
| `POST /send-email` | webhook HMAC | Supabase Auth "Send Email" hook |
| `GET /healthz` | none | liveness |

## Why this exists

The pipeline originally ran on Supabase Edge Functions (Deno). It was ported to
Node.js/TypeScript, which is the stack this service is required to run on. The
port was deliberately kept as a **move, not a rewrite**: the business logic
files are byte-identical to their Deno originals apart from three mechanical
substitutions, so the behaviour under test is the same behaviour that shipped.

What actually changed:

| Deno | Node |
| --- | --- |
| `Deno.serve` / `withSupabase({auth:'user'})` | Express + `src/lib/route-adapter.ts` |
| `Deno.env.get('X')` | `process.env.X` |
| `Deno.readTextFile` | `node:fs/promises` `readFile` |
| `npm:` / `https://esm.sh/` specifiers | real npm dependencies |
| `jsr:@std/assert` | `test/assert.ts` shim over vitest's `expect` |

Every route handler is still shaped `(Request) => Promise<Response>` against the
Web Fetch API — the shape it had on the Edge Runtime. `src/lib/web-adapter.ts`
is the only place Express's req/res objects are translated, which is what let
the handler bodies move over untouched.

`supabase/functions/` is intentionally left in the repository, unported and
undeployed, as the "before" side of this migration.

## Layout

```
src/
  server.ts                  Express bootstrap, route mounting, /healthz
  lib/web-adapter.ts         Web Request/Response  <->  Express req/res
  lib/route-adapter.ts       JWT verification, Supabase client construction
  shared/                    contracts, http helpers, embeddings  (was _shared/)
  routes/<route>/            one directory per route, logic unchanged from Deno
  cli/                       eval + backfill entrypoints
test/                        1:1 with the former supabase/functions/tests
```

## Running it

```bash
npm install
cp .env.example .env      # fill in the values
npm run dev               # http://localhost:8080
```

| Script | What it does |
| --- | --- |
| `npm run dev` | watch-mode server |
| `npm start` | server (what Railway runs) |
| `npm run typecheck` | `tsc --noEmit` |
| `npm test` | vitest, 99 tests |
| `npm run eval` | deterministic eval over `evals/gold/*.jsonl` — no network, no cost |
| `npm run eval:live` | live eval against a running backend — **calls paid provider APIs** |
| `npm run backfill:embeddings` | re-embeds stale catalog rows to completion |

There is no build step. `tsx` runs the TypeScript directly and `tsc --noEmit`
type-checks it. This is what allows the ported files to keep the `.ts` import
extensions Deno required, so they stay diffable against their originals.

## Auth

`mountAuthedHandler` pulls the bearer token and calls
`supabase.auth.getUser(token)`. Verification is delegated to Supabase's Auth
server rather than reimplemented against the project JWKS locally: it costs a
network call per request, but it cannot drift from Supabase's own notion of a
valid session, including revoked and banned users that a local signature check
would keep accepting until the token expired.

Each request gets two clients: `context.supabase` carries the caller's JWT so
row level security still applies, and `context.supabaseAdmin` is a process-wide
service-role client. They are not interchangeable.

## Deployment (Railway)

Nixpacks auto-detects Node, so there is nothing to author. Two settings matter:

- **Root directory** must be `backend/` — the repository root is a Flutter app.
- **Start command** is `npm start` (Railway picks this up from `package.json`).

Set every variable from `.env.example` in the Railway dashboard. `PORT` is
injected by Railway; `src/server.ts` reads it.

Railway is used because its free tier does not sleep to zero on idle, so the
first `analyze-meal` call after a quiet period is not paying a cold start on a
request that already chains several provider calls. The free tier is
time-boxed, which is a real limitation of this deployment.

### Cutover checklist

1. Deploy, confirm `GET /healthz` returns `{"ok":true}`.
2. Run one real `POST /analyze-meal` **including the photo path** — that path
   chains multiple provider calls and is the one most sensitive to a platform's
   request timeout.
3. Point the mobile build at it: `--dart-define=NODE_BACKEND_URL=https://…`.
4. Repoint Supabase Auth → Hooks → **Send Email** at `https://…/send-email` and
   re-set `SEND_EMAIL_HOOK_SECRET`. Confirm with the dashboard's *send test
   webhook* before deleting the Deno version — a miss here breaks auth emails
   silently.
5. Undeploy **only** `analyze-meal`, `commit-meal` and `search-food-catalog`
   from Supabase, so those three have exactly one live implementation.
   **`delete-account` must stay deployed** — it was not ported, and the app
   still calls it through `functions.invoke()`
   (`lib/src/auth/data/supabase_auth_repository.dart`). Removing it breaks
   account deletion with no compile-time warning.

## Accuracy work

`npm run eval` scores the deterministic pass against a hand-labelled Turkish
gold set and reports exact-case accuracy, food identity precision/recall/F1,
portion MAPE, and no-match specificity. It runs offline with no credentials, so
it is safe in CI. `npm run eval:live` exercises the full pipeline against a
running backend and requires `LIVE_EVAL_ACK=I_ACCEPT_PROVIDER_COST` because it
spends real provider budget.

Both can persist their results (`EVAL_PERSIST`) into `eval_runs` so a score can
be traced back to a commit.
