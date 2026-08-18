# Meal Clarity

An accuracy-first mobile meal logger built for the EatBetter full-stack case
study.

The mobile vertical slice connects to an authenticated, catalog-grounded
Supabase analysis pipeline while retaining deterministic fixtures for tests:

- Today dashboard with totals derived from meal items
- Turkish/English localized app and locale-aware AI requests
- text-only, photo-only, and mixed meal composer
- camera/library picker with private per-user Storage uploads
- strict vision extraction followed by deterministic catalog matching
- hybrid retrieval: exact alias + full-text/trigram + pgvector, fused with RRF
- constrained LLM selection from a server-created candidate allow-list
- idempotent embedding backfill and private retrieval/response caches
- explicit `NO_MATCH` with a manual catalog search and correction flow
- real and mock analysis behind a replaceable `MealRepository` boundary
- Editable structured food review
- Human-in-the-loop portion clarification
- Log success with undo instead of a blocking success screen
- Catalog photography with explicit provenance labels
- Meal detail with deterministic portion editing and delete confirmation
- MVVM presentation state with replaceable data repositories
- Supabase foundation for auth, canonical foods, vector retrieval, meal
  persistence, correction feedback, and analysis traces
- versioned OTA Turkish/English copy with cached ARB fallback

![Current iOS progress](meal-clarity-progress.png)

## Run

```sh
flutter pub get
flutter run --dart-define-from-file=config/app_config.dev.json
```

Run the internal AI quality console as a separate React web app:

```sh
cd admin-dashboard
npm install
npm run dev
```

Demo metrics are labeled `DEMO DATA`. The investigation path connects Overview,
AI Quality, Meal Inspector, and Trace Inspector with shareable URL state.

The admin interface supports Turkish and English. Its Mobile App area models
the existing Supabase OTA translation contract (`tr`/`en`, monotonic version,
500-character values, 64 KB payload, ARB fallback), including draft validation,
staging promotion, production role gating, history, rollback, feature flags,
minimum-version control, and percentage rollout.

## Verify

```sh
flutter analyze
flutter test
flutter test integration_test/meal_logging_test.dart -d <device-id>
deno task --config supabase/deno.json check
deno task --config supabase/deno.json test
deno task --config supabase/deno.json eval
```

The integration test has been exercised on an iOS Simulator. It covers the
critical ambiguous-input path from composition through portion clarification
to the daily overview.

## Architecture

- `domain`: immutable nutrition, food, draft, and logged-meal models
- `data`: repository contracts and deterministic demo implementations
- `view_models`: flow, daily overview, and detail state without widget concerns
- `features`: Flutter views, navigation, sheets, and interaction details
- `supabase`: reproducible local config, forward-only migrations, and seed data

Nutrition totals are derived from meal items in both the Flutter domain and the
database. The database snapshots per-100g values on each logged item for audit
history, then generated columns and a trigger calculate item and meal totals.

AI analysis requires `OPENAI_API_KEY` as an Edge Function secret.
`OPENAI_VISION_MODEL`, `OPENAI_SELECTION_MODEL`, and `OPENAI_EMBEDDING_MODEL`
are optional; each has a versioned default. None belongs in Flutter config or
source control.

## AI accuracy path

```text
text / private photo
  → deterministic normalization + vision extraction
  → exact alias, full-text/trigram, and pgvector candidates
  → reciprocal-rank fusion
  → strict-schema LLM choice from allowed food IDs only
  → catalog portions and nutrition
  → clarification or NO_MATCH/manual correction
  → idempotent commit and correction feedback
```

Nutrition is never accepted from the model or client. Weak vector-only matches
are rejected. Provider timeout/429/5xx responses are retried with a bound;
refusals are not retried. Mixed input can fall back to text, while a failed
photo-only request returns a retryable 503. Model, prompt, retrieval version,
latency, attempts, tokens, cache hits, fallback reason, and estimated cost are
recorded without putting raw meal text into standard logs.

The deterministic Turkish regression set currently passes 60/60 cases:
identity precision/recall/F1 `1.00`, portion MAPE `0`, and no-match specificity
`1.00`. A separate paid live runner covers 20 Turkish/English hybrid cases and
four photo fixtures and reports p50/p95 latency, tokens, cache hits, and cost.
The labels are engineering labels, not clinical validation; see
[`docs/AI_EVAL_REPORT.md`](docs/AI_EVAL_REPORT.md) and
[`docs/LIVE_EVAL.md`](docs/LIVE_EVAL.md).

## Supabase

No hosted project is required to develop the schema:

```sh
supabase start
supabase db reset
supabase db lint
```

When the hosted project is ready, apply the same committed migrations without
recreating the schema manually:

```sh
supabase login
supabase link --project-ref <project-ref>
supabase db push
```

Do not commit the service-role key or database password. The mobile app will
only receive the project URL and publishable/anon key; privileged AI writes
belong in an Edge Function or backend service.

The schema includes:

- user-owned profiles and meals protected by row-level security
- canonical foods, localized aliases, portions, and `pgvector` embeddings
- idempotency keys for analysis runs and meal logging
- prompt/model/retrieval versions, latency, trace IDs, and ranked candidates
- per-item confidence, match method, review status, and correction feedback
- generated nutrition values and server-controlled meal totals
- private `meal-photos` Storage with authenticated owner-path policies
- private AI response/retrieval caches keyed by hashes, never raw input
- versioned, public-read/service-write OTA translation bundles with a 64 KB cap

The migrations and seed have been deployed to the hosted Supabase project.
Remote `db lint` reports no schema errors, and local/remote migration history is
in sync. The first local Docker image pull stalled on this machine, so local
`db reset` remains a separate environment follow-up rather than a schema blocker.

Production-style OTP delivery uses a signature-verified Supabase Send Email
Hook backed by Resend. Deployment, secret handling, rollback, and verification
steps are documented in
[`docs/SEND_EMAIL_HOOK_RUNBOOK.md`](docs/SEND_EMAIL_HOOK_RUNBOOK.md).

The product and architecture research is in
`CASE_STUDY_RESEARCH_REPORT_TR.md`.

Implementation specifications and the dependency-ordered sprint backlog are in
[`docs/specs`](docs/specs/README.md) and [`docs/SPRINT_PLAN.md`](docs/SPRINT_PLAN.md).

Generated food asset disclosure is in `docs/ASSET_PROVENANCE.md`.
CI, protected production deployment, and paid-eval setup are documented in
[`docs/CI_CD.md`](docs/CI_CD.md).

## Trade-off, limits, and next steps

The biggest trade-off is a deliberately small curated nutrition catalog. It
makes correctness, provenance, and `NO_MATCH` behavior demonstrable in seven
days, but limits recall. At scale, embedding jobs need a durable worker and
dead-letter handling; cache/catalog invalidation needs versioned rollouts; and
hot RRF queries need load testing and index tuning.

Top three accuracy improvements:

1. Expand the catalog and have a dietitian independently review multilingual
   aliases, portion priors, and the gold labels.
2. Run blinded live text/photo evals, calibrate clarification thresholds by
   nutrition impact, and compare pinned model snapshots.
3. Learn from accepted manual corrections without auto-promoting unreviewed
   user labels into the canonical catalog.

The main privacy risks are meal-photo retention, sensitive dietary inferences,
provider data transfer, and leaked privileged keys. Current mitigations include
private owner-scoped Storage/RLS, `store: false`, server-only secrets, redacted
logs, and short bounded request payloads. EXIF stripping, automated retention
cleanup, account deletion, and a formal DPIA remain production work.

AI tools were used for implementation and research. Runtime OpenAI calls are
restricted to photo extraction, embeddings, and allow-listed candidate
selection; all nutrition and persistence invariants are enforced in code and
Postgres.
