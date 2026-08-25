# CI/CD runbook

> [!NOTE]
> **Superseded**: The active meal-analysis runtime is `backend/` (Node.js/TypeScript).
> This document was written during the Supabase Edge Functions (Deno) era and
> may reference architecture that has since been ported. See `backend/README.md`
> for the current backend layout.

CI runs on pull requests and `main` and has five independent jobs:

- Flutter formatting, static analysis, 264 portable unit/widget tests, and an Android compile
- Deno formatting/lint/type-check, 44 tests, and the 63-case free deterministic eval
- a macOS job for the visual golden baselines and both integration flows
- a fresh local Supabase migration rebuild, database lint, and contract tests
- a tracked-file credential-pattern scan

The admin dashboard tests are currently run locally, not in CI.

Action dependencies and tool versions are pinned. CI never receives the OpenAI
key and never runs a paid model evaluation.

The committed iOS visual golden is verified on macOS because font
rasterization is not pixel-identical on Linux. It remains part of the normal
local `flutter test` suite; Linux CI excludes only the `golden` tag.

## Production Supabase deployment

The deployment job applies database migrations before deploying all Edge
Functions. It is inert until the repository variable
`SUPABASE_DEPLOY_ENABLED=true` exists. Configure the GitHub `production`
environment with:

- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_PASSWORD`
- `SUPABASE_PROJECT_ID`

Use environment approval rules if the repository plan supports them. Keep the
deploy switch disabled until the first CI run is green. A failed migration
prevents function deployment; migrations are forward-only and are not
automatically rolled back.

## Paid live evaluation

The manual `Paid live AI eval` workflow requires an explicit cost checkbox,
caps the runner at 100 cases, and uses the protected `ai-evaluation`
environment. Configure a dedicated low-privilege eval user:

- `EVAL_SUPABASE_URL`
- `EVAL_SUPABASE_PUBLISHABLE_KEY`
- `EVAL_USER_JWT` (short-lived; rotate before each run)

Provider secrets remain hosted in Supabase and are never copied into GitHub.
The runner prints aggregate metrics and does not print JWTs, raw image URLs, or
provider payloads.

The deployment structure follows the official Supabase recommendations for
[GitHub Actions function deployment](https://supabase.com/docs/guides/functions/deploy)
and [migration environments](https://supabase.com/docs/guides/deployment/managing-environments).
