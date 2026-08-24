# Meal Clarity

An accuracy-first meal logger built for the EatBetter full-stack case study.
The core rule is that the model interprets and the catalog decides: language
models turn free text and photos into structured guesses, but every gram,
calorie, and portion that reaches the database comes from a versioned food
catalog resolved on the server. Nutrition can never be invented by the model or
forged by the client, because the commit path re-reads catalog values inside
Postgres and rejects anything else.

The vertical slice is a Flutter app (Turkish/English), a Supabase backend with
Edge Functions, and a React admin console for AI quality, cost, and catalog
inspection. Ambiguity is surfaced instead of hidden: uncertain portions and
food types trigger explicit clarification sheets, and unmatched foods end in a
visible `NO_MATCH` with manual search rather than a fabricated answer.

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
AI Quality, Meal Inspector, and Trace Inspector with shareable URL state. The
admin interface supports Turkish and English, manages the OTA translation
contract (draft validation, staging promotion, rollback, feature flags,
percentage rollout), and browses the live 60,000-food catalog with server-side
search — it never downloads the catalog as a single payload.

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

- `lib/src/domain`: immutable nutrition, food, draft, and logged-meal models
- `lib/src/data`: repository contracts and deterministic demo implementations
- `lib/src/view_models`: flow, daily overview, and detail state (MVVM, no
  widget concerns)
- `lib/src/features`: Flutter views, navigation, sheets, and interaction detail
- `supabase`: reproducible local config, forward-only migrations, Edge
  Functions, and seed data
- `admin-dashboard`: React console for AI quality, evals, and catalog browsing

Nutrition totals are derived from meal items in both the Flutter domain and the
database. The database snapshots per-100g values on each logged item for audit
history, then generated columns and a trigger calculate item and meal totals.
Real and mock analysis sit behind a replaceable `MealRepository` boundary, so
tests run against deterministic fixtures. Row-level security scopes profiles,
meals, and private `meal-photos` Storage to their owner; analysis runs and meal
commits are idempotent by request key.

AI analysis requires `OPENAI_API_KEY` as an Edge Function secret.
`OPENAI_VISION_MODEL`, `OPENAI_SELECTION_MODEL`, and `OPENAI_EMBEDDING_MODEL`
are optional; each has a versioned default. None belongs in Flutter config or
source control.

### Backend runtime choice

The case study asked for a Node.js/TypeScript backend. This project deviates:
the service layer runs as Supabase Edge Functions, which execute TypeScript on
Deno. The trade was deliberate. Within a take-home budget, Supabase's
integrated auth, row-level security, and private Storage bought reliability
and security properties (owner-scoped photos, RLS-enforced meal access,
signature-verified email hooks) that would otherwise have consumed most of the
schedule as custom Node middleware. The deviation is smaller than it looks:
the function code uses `npm:` specifiers and standard TypeScript, so it is
Node-portable, and the entire nutrition data pipeline tooling under
`tool/food_import/` already runs on Node.

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
are rejected. When the catalog has no acceptable match, the server can produce
a bounds-checked, clearly-labeled AI estimate that is persisted server-side —
the client still can never supply nutrition, and grounded catalog items always
take precedence over estimates. Provider timeout/429/5xx responses are retried
with a bound; refusals are not retried. Mixed input can fall back to text,
while a failed photo-only request returns a retryable 503. Model, prompt,
retrieval version, latency, attempts, tokens, cache hits, fallback reason, and
estimated cost are recorded without putting raw meal text into standard logs.

## Evaluation

Two instruments measure different things, and it matters not to confuse them.

**Regression gate (deterministic, free, runs in CI).** A 60-case suite runs
the parsing and reconciliation code against a 3-food fixture catalog with no
network, no retrieval, and no LLM. It currently passes 60/60 with identity
precision/recall/F1 `1.00`, portion MAPE `0`, and no-match specificity `1.00`.
Those perfect numbers mean exactly one thing: no regressions in the
deterministic Turkish parsing path. A 3-food fixture cannot exercise hybrid
retrieval, embedding quality, or model behavior, so this gate says nothing
about product accuracy — it exists to catch code changes that break parsing.

**Live eval (paid, product accuracy).** A separate runner sends 20
Turkish/English hybrid text cases and 4 photo fixtures through the deployed
analysis function and reports p50/p95 latency, tokens, cache hits, and cost.
This is the instrument that measures what a user would experience. Results are
persisted to the `eval_runs`/`eval_cases` tables and are viewable in the admin
dashboard's AI Evals page. The labels are engineering labels, not clinical
validation; see [`docs/AI_EVAL_REPORT.md`](docs/AI_EVAL_REPORT.md) and
[`docs/LIVE_EVAL.md`](docs/LIVE_EVAL.md).

### Error taxonomy

| Error class | How it is detected |
| --- | --- |
| Recognition error (food not extracted from text/photo) | Live-eval expected-item gates; `vision_fallback_reason` telemetry on photo paths |
| Canonicalization error (wrong catalog food chosen) | Live-eval identity checks; commit-time correction diffs when users repair the match |
| Portion error (right food, wrong amount) | Tolerance-banded portion checks in evals; correction diffs on committed amounts |
| No-match false positive (forced wrong match instead of `NO_MATCH`) | No-match specificity cases in both eval suites |
| No-match false negative (`NO_MATCH` despite catalog coverage) | Live-eval cases with known-covered foods; manual-search telemetry after `NO_MATCH` |
| Hallucinated extra food (item invented by the model) | Eval item-count gates; structurally limited by the allow-listed candidate schema |
| Missed clarification (ambiguity silently resolved) | Eval cases expecting `checkAmount`/`checkType` states; correction diffs on defaults |
| System failure (timeouts, provider errors, bad payloads) | `error_code` telemetry, retry/attempt counts, and cost/error breakdowns in the admin dashboard |

## Comparison with EatBetter

EatBetter ("EatBetter: AI Food Journal") is the Turkey-first incumbent this
case study is framed against: roughly 18k ratings on the Turkish App Store, a
photo-scan core flow, conversational logging via "Betty", a freemium model,
and a stated claim of USDA-sourced, dietitian-reviewed nutrition data. Its UX
shows no confidence indicator anywhere, and no barcode scanning is mentioned.
Public reviews repeat a few themes: portion estimates miss in both directions
(one reviewer: "2 minutes logging, 20 minutes fixing"), calorie counts are
"sometimes on the lower side", and one report describes logging failing
despite an active subscription. Sources: App Store US/TR listings, Google
Play listing, and eatbetter.app.

| Dimension | EatBetter (as observed) | This project | Status |
| --- | --- | --- | --- |
| Portion accuracy | Documented pain point; under- and over-estimates | Catalog portions, clarification sheets, tolerance-banded portion eval | Hypothesis — measured by correction rate and portion MAPE, not yet demonstrated |
| Uncertainty transparency | No confidence indicator in the UX | Explicit `checkAmount`/`checkType` states and labeled estimates | Design difference; plausibly better |
| Hallucinated nutrition | Unverifiable from outside | Structurally impossible: nutrition only from catalog rows re-read at commit | Verifiable property of ours, not a comparative win |
| Correction loop | Editing reportedly quick, but no visible feedback loop | Commit-time correction diffs recorded as feedback | Design difference |
| Reliability / offline | One public complaint about failed logging | Tested outbox with offline sync | Plausibly better; not comparatively verifiable |
| Turkish coverage | Turkish foods with dietitian review | 60k catalog with TR/EN aliases, TürKomp provenance | Contested — no superiority claim |

Most of these are hypotheses with a measurement plan, not demonstrated
improvements; commit-time correction telemetry is how we would prove or
disprove them.

## Known issues

- The analyze path has a concurrent-duplicate race: two identical requests in
  a tight window can double-run the pipeline and double the provider spend.
  The commit path is unaffected — idempotency keys make duplicate commits
  safe.
- Confidence thresholds are uncalibrated hand-picked constants. Calibrating
  them against observed correction rates is pending.
- The hosted live-eval numbers are not yet a clean measurement. A SQL defect
  that the live harness caught is fixed in `20260824130000`, but the selection
  call currently returns a provider `401`, so the LLM path is unmeasured and
  the passing cases resolve deterministically. See
  [`docs/AI_EVAL_REPORT.md`](docs/AI_EVAL_REPORT.md).
- Text-only analyze requests bypass the cost budget, leaving a bounded
  database-write amplification open.
- Embedding backfill runs synchronously in the search request path. In
  production it belongs in a scheduled worker.
- Privacy production work remains: EXIF stripping, automated retention
  cleanup, account deletion, and a formal DPIA. The main privacy risks are
  meal-photo retention, sensitive dietary inferences, provider data transfer,
  and leaked privileged keys; current mitigations are private owner-scoped
  Storage/RLS, `store: false`, server-only secrets, redacted logs, and short
  bounded request payloads.

## Nutrition data

A deterministic, source-preserving pipeline (Node, `tool/food_import/`)
normalized 1,400,586 records from USDA Foundation/FNDDS/SR Legacy/Branded,
TürKomp, and a quality-filtered Open Food Facts slice, then resolved them into
1,228,891 traceable canonical foods with reversible source mappings and
guarded merge rules (an identical GTIN alone never merges two products).
Re-running the pipeline produces byte-identical outputs. The stage-by-stage
detail lives in [`docs/reports/`](docs/reports/): see
[`cleaning-report.md`](docs/reports/cleaning-report.md),
[`canonicalization-v2-report.md`](docs/reports/canonicalization-v2-report.md),
[`production-readiness-audit-v2.md`](docs/reports/production-readiness-audit-v2.md),
and [`docs/NUTRITION_DATA_PIPELINE_CASE_STUDY_TR.md`](docs/NUTRITION_DATA_PIPELINE_CASE_STUDY_TR.md).

The running app deliberately serves a 60,000-food subset of that corpus, not
all 1.2M records. Loading the full audit-rich corpus would grow storage,
index size, import time, and query cost without improving the core demo in
proportion. The subset is a reproducible selection, not a sample: every food
has complete core macros, Turkish and English aliases, and a resolvable
portion row, balanced across generic, Turkey-relevant branded, and global
records. The full canonical artifacts remain available for audit and
re-selection; see
[`database-import-report.md`](docs/reports/database-import-report.md) and
[`lean-production-catalog-report.md`](docs/reports/lean-production-catalog-report.md).

## Supabase

No hosted project is required to develop the schema:

```sh
supabase start
supabase db reset
supabase db lint
```

When the hosted project is ready, apply the same committed migrations:

```sh
supabase login
supabase link --project-ref <project-ref>
supabase db push
```

Do not commit the service-role key or database password. The mobile app only
receives the project URL and publishable/anon key; privileged AI writes belong
in an Edge Function or backend service. Migrations and seed are deployed to
the hosted project with migration history in sync. Production-style OTP
delivery uses a signature-verified Send Email Hook backed by Resend; see
[`docs/SEND_EMAIL_HOOK_RUNBOOK.md`](docs/SEND_EMAIL_HOOK_RUNBOOK.md).

Product and architecture research is in `CASE_STUDY_RESEARCH_REPORT_TR.md`.
Implementation specifications and the sprint backlog are in
[`docs/specs`](docs/specs/README.md) and
[`docs/SPRINT_PLAN.md`](docs/SPRINT_PLAN.md). Generated food asset disclosure
is in `docs/ASSET_PROVENANCE.md`; the portion-reference programme is in
[`docs/PORTION_REFERENCE_PILOT.md`](docs/PORTION_REFERENCE_PILOT.md). CI,
protected deployment, and paid-eval setup are in
[`docs/CI_CD.md`](docs/CI_CD.md).

## Trade-offs, limits, and next steps

Serving 60,000 foods instead of 1,228,891 reduces runtime recall compared with
the complete corpus, but keeps storage, indexing, validation, and query
behavior appropriate for the case study. Expanding would require measured
recall gains, load tests, index tuning, and a versioned catalog rollout rather
than importing every record. At larger scale, embedding jobs need a durable
worker with dead-letter handling, and cache/catalog invalidation needs
versioned rollouts.

Top three accuracy improvements:

1. Expand the catalog and have a dietitian independently review multilingual
   aliases, portion priors, and the gold labels.
2. Run blinded live text/photo evals, calibrate clarification thresholds by
   nutrition impact, and compare pinned model snapshots.
3. Learn from accepted manual corrections without auto-promoting unreviewed
   user labels into the canonical catalog.

AI tools were used for implementation and research. Runtime OpenAI calls are
restricted to photo extraction, embeddings, and allow-listed candidate
selection; all nutrition and persistence invariants are enforced in code and
Postgres.
