# Meal Clarity

An accuracy-first meal logger built for the EatBetter full-stack case study.
The core rule is that the model interprets and the catalog decides: language
models turn free text and photos into structured guesses, but every gram,
calorie, and portion that reaches the database comes from a versioned food
catalog resolved on the server. Nutrition can never be invented by the model or
forged by the client, because the commit path re-reads catalog values inside
Postgres and rejects anything else.

The vertical slice is a Flutter app (Turkish/English), a **Node.js/TypeScript
backend** (`backend/`) serving the meal-logging pipeline, Supabase for auth,
storage and Postgres, and a React admin console for AI quality, cost, and
catalog inspection. Ambiguity is surfaced instead of hidden: uncertain portions
and food types trigger explicit clarification sheets, and unmatched foods end in
a visible `NO_MATCH` with manual search rather than a fabricated answer.

![Current iOS progress](meal-clarity-progress.png)

## Run

The app needs a running backend. Start it first — see `backend/README.md`:

```sh
cd backend
npm install
cp .env.example .env      # fill in the values
npm run dev               # http://localhost:8080
```

Then the app. Firebase config is generated, not committed — crash reporting is
wired to Crashlytics and the generated files carry project identifiers, so they
stay local:

```sh
flutter pub get
dart pub global activate flutterfire_cli   # once
flutterfire configure                      # writes lib/firebase_options.dart
flutter run --dart-define-from-file=config/app_config.dev.json
```

A stub `lib/firebase_options.dart` is committed so the app compiles in CI, but
`flutterfire configure` is what overwrites it with real credentials along with
`android/app/google-services.json` and
`ios/Runner/GoogleService-Info.plist`.

`config/app_config.dev.json` is untracked; copy `config/app_config.example.json`
and fill it in. `NODE_BACKEND_URL` points at the backend above — use
`http://localhost:8080` on an iOS simulator or desktop, and
`http://10.0.2.2:8080` on an Android emulator, which is how it reaches the host
machine. A real device or a release build needs an HTTPS URL; the app refuses to
start otherwise.

The internal AI quality console is a React app run separately. It is an
operator tool, not the product — the product is the Flutter app above:

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

cd backend
npm run typecheck
npm test
npm run eval          # offline accuracy gate: no credentials, no network
```

`npm run eval` is the regression gate: it scores the deterministic Turkish
parser against a hand-labelled gold set and needs neither a database nor a
provider key, so it runs in CI on every push. A perfect score there means
Turkish parsing has not regressed — it is not product accuracy. See
[Evaluation](#evaluation) for what each layer does and does not prove.

The integration test has been exercised on an iOS Simulator. It covers the
critical ambiguous-input path from composition through portion clarification
to the daily overview.

## Architecture

- `lib/src/domain`: immutable nutrition, food, draft, and logged-meal models
- `lib/src/data`: repository contracts and deterministic demo implementations
- `lib/src/view_models`: flow, daily overview, and detail state (MVVM, no
  widget concerns)
- `lib/src/features`: Flutter views, navigation, sheets, and interaction detail
- `backend/src/routes`: the Node.js/TypeScript service — one directory per
  route, with the analyze pipeline's stages as siblings of its entrypoint
- `backend/src/shared`: wire contracts, HTTP helpers, embedding client
- `backend/src/lib`: the Express seam — Web Fetch adapter and auth middleware
- `backend/src/cli`: eval and catalog-backfill entrypoints, run out of band
- `supabase`: reproducible local config, forward-only migrations, seed data,
  and the two Edge Functions that stay deployed (`send-email`,
  `delete-account`)
- `admin-dashboard`: internal React console for AI quality, evals, and catalog
  browsing. Not the product — the product is the Flutter app.

### Data Provenance

The 60k-food catalog is built from multiple data sources, maintaining full traceability.
For detailed information on sources, licensing, and attribution requirements (including ODbL for Open Food Facts and non-commercial terms for TürKomp), please refer to the [Data Provenance and Licensing](data/sources.json) manifest and the [TürKomp usage notes](data/TURKOMP_SOURCE.md).

Nutrition totals are derived from meal items in both the Flutter domain and the
database. The database snapshots per-100g values on each logged item for audit
history, then generated columns and a trigger calculate item and meal totals.
Real and mock analysis sit behind a replaceable `MealRepository` boundary, so
tests run against deterministic fixtures. Row-level security scopes profiles,
meals, and private `meal-photos` Storage to their owner; analysis runs and meal
commits are idempotent by request key.

AI analysis requires `OPENAI_API_KEY` in the backend's environment
(`backend/.env`, gitignored). `OPENAI_VISION_MODEL`, `OPENAI_SELECTION_MODEL`,
and `OPENAI_EMBEDDING_MODEL` are optional; each has a versioned default. None
belongs in Flutter config or source control — the app never holds a provider
key.

### Backend runtime choice

The meal-logging service is a **Node.js 20 / TypeScript** app on Express, in
`backend/`. It serves `analyze-meal`, `commit-meal` and `search-food-catalog` —
the three routes the mobile app calls on the critical path.

It did not start there. The first implementation ran as Supabase Edge Functions
on Deno, because Supabase's integrated auth, row-level security and private
Storage bought reliability and security properties (owner-scoped photos,
RLS-enforced meal access, signature-verified email hooks) that would otherwise
have consumed the schedule as custom Node middleware. That bought speed early
and cost a rewrite later, which is the trade worth naming.

The port was deliberately a **move, not a rewrite**: the business-logic files
are byte-identical to their Deno originals apart from three mechanical
substitutions (`Deno.env.get` → `process.env`, `Deno.readTextFile` →
`node:fs/promises`, `npm:`/CDN specifiers → real dependencies), and every route
handler still has the Web Fetch shape `(Request) => Promise<Response>` it had on
the Edge Runtime. `backend/src/lib/web-adapter.ts` is the only place Express's
req/res is translated. The deterministic eval produces byte-identical output on
both runtimes, which is the evidence that the behaviour did not drift.

Supabase remains the database, auth and storage provider — that part was never
the deviation. Two Edge Functions stay deployed on purpose: `send-email`, which
Supabase Auth calls from the internet and therefore cannot point at a laptop,
and `delete-account`, which was out of scope for the port.
`supabase/functions/` is kept in the repository, undeployed for the three ported
routes, as the "before" side of the migration.

## AI accuracy path

```text
text / private photo
  → deterministic normalization, then text or vision extraction when it is
    not enough (identity and amount only — the schema has no nutrition field)
  → per-food exact alias, full-text/trigram, and pgvector candidates
  → reciprocal-rank fusion
  → strict-schema LLM choice from allowed food IDs only
  → catalog portions and nutrition
  → clarification or NO_MATCH/manual correction
  → idempotent commit and correction feedback
```

Extraction reads the sentence; the catalog decides every number. A rule-based
parser cannot separate food words from a conversational Turkish sentence — it
used to turn "yedim" and "kanka" into foods — so understanding moved to a model
whose output schema physically cannot carry a calorie. See
[`docs/TEXT_UNDERSTANDING_FIX.md`](docs/TEXT_UNDERSTANDING_FIX.md).

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

**Regression gate (deterministic, free, runs in CI).** A 63-case suite runs
the parsing and reconciliation code against a 3-food fixture catalog with no
network, no retrieval, and no LLM. It currently passes 63/63 with identity
precision/recall/F1 `1.00`, portion MAPE `0`, and no-match specificity `1.00`.
Those perfect numbers mean exactly one thing: no regressions in the
deterministic Turkish parsing path. A 3-food fixture cannot exercise hybrid
retrieval, embedding quality, or model behavior, so this gate says nothing
about product accuracy — it exists to catch code changes that break parsing.

**Live eval (paid, product accuracy).** A separate runner sends 26
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
and a stated claim of USDA-sourced, dietitian-reviewed nutrition data. In its UX,
no visible confidence indicator was observed in the public iOS listing (reviewed August 2026), and no barcode scanning is mentioned.
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

### Worked examples

Illustrative outputs based on the deterministic pipeline. Live results may differ slightly.

**`kanka 2 yumurta ve biraz beyaz peynir yedim`** — 3.4 s

```
Yumurta, tavuk, tam        100 g   identity question raised
Beyaz Peynir, Tam Yağlı     30 g   portion question raised
unmatched: []
```

The filler (`kanka`, `yedim`) never becomes a food: leftovers after the rule
pass are handed to a language model that returns identity and amount only, so
an open-ended set of Turkish verbs and slang does not need a stopword list it
could never close. `2 yumurta` resolves from the catalog's per-unit portion, so
no one is asked "how many grams is an egg?" — but *which* egg is asked, because
the alias that matched is generic and boiled and fried differ by 26%.

**`kremalı tavuklu makarna`** — 19.7 s

```
Kremalı tavuklu makarna (hazır/karışık, yaklaşık)   170 kcal/100 g   ai_estimate
```

No single catalog row is this dish. The system says so: one item, labelled an
AI estimate, shown in the UI with a distinct chip and `~` on every number, and
stored with `review_status = 'unreviewed'`. It does not invent a catalog match
to look confident.

### A failure this found in its own catalog

The most useful thing measurement did was expose a systematic wrong-match bug
here, not in a competitor.

Turkish aliases had been machine-generated for the entire imported catalog,
including 30,000 foreign supermarket products, at priority 85–90 — above the
identity-ambiguity threshold of 80. The curated Turkish foods they collided
with sat at 60. Two things then went wrong at once and neither surfaced as an
error:

- The matcher never ranked by priority. It sorted by match position and length
  only, so among identical-length matches the winner was whichever row the
  catalog query returned first.
- Priority was read later, only to decide whether to ask. At 85 the wrong
  winner reported confidence 0.98 and asked nothing.

Measured before and after, on the live catalog:

| Input | Before | After |
| --- | --- | --- |
| `yoğurt` | branded USDA yoghurt, 94 kcal, no question | `Yoğurt, kaymaklı` 77 kcal, identity question |
| `badem` | could resolve to *Imitation butter flavor popcorn seasoning salt*, 0 kcal | `Badem` 42 kcal, identity question |
| `kremalı tavuklu makarna` | 6 fragments including a Romanian brand row "Kremal" at 485 kcal, cream counted twice | one labelled estimate |

Fixed on both sides: 68,535 junk aliases removed by migration, and the matcher
given a priority tie-break plus a stable final ordering so the same sentence
cannot resolve differently between two runs — an eval whose score moves with
Postgres row order measures nothing.

This is the comparison point that matters most: not that this system is free of
wrong matches, but that wrong matches are *findable*. A confidence number, a
recorded clarification reason, and a reproducible eval are what turned "the app
sometimes picks something odd" into a named defect with a before/after.

## Known issues

- The analyze path has a concurrent-duplicate race: two identical requests in
  a tight window can double-run the pipeline and double the provider spend.
  The commit path is unaffected — idempotency keys make duplicate commits
  safe. Text extraction adds one more provider call to what that race wastes.
- Confidence thresholds are uncalibrated hand-picked constants, including the
  raised `MIN_SEMANTIC_SIMILARITY` and the text-extraction prompt, which has
  not been tuned against a held-out set. Calibrating them against observed
  correction rates is pending.
- Component gram amounts for a decomposed dish are grounded per ingredient in
  the catalog, but the ratio between ingredients is a model guess and will show
  up as portion error until it is measured.
- Portion estimation is the weakest measured part of the pipeline. The first
  clean hosted run scores identity exact accuracy `0.55` but portion MAPE
  `1.46`, far outside the 10% gate, so gram estimates are what a user would
  spend time correcting. Some gold labels also predate the 60,000-food catalog
  and need review before the pass rate is cited. See
  [`docs/AI_EVAL_REPORT.md`](docs/AI_EVAL_REPORT.md).
- Analysis p95 latency is above 13 s on the hosted project, which is a product
  problem independent of accuracy.
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

### Biggest trade-off

**Grounding over coverage.** The model is never allowed to emit a nutrition
number. It picks an id from a server-built allow-list, and every gram and
calorie is re-read from the catalog inside Postgres at commit time. That makes
fabricated nutrition structurally impossible — and it means anything the
catalog does not contain cannot be logged as a catalog fact, no matter how
confident the model is. A dish like `kremalı tavuklu makarna` therefore comes
back as a labelled estimate rather than a clean match.

The cost is real and visible: recall is bounded by the catalog, and the
catalog is 60,000 rows rather than the 1.2M available. The reason to accept it
is that a wrong number the user trusts is worse than a visible gap they can
correct, and only one of those two failure modes is recoverable.

Second, named because it shaped the code: the service started on Supabase Edge
Functions (Deno) for the integrated auth, RLS and Storage, then had to be
ported to Node.js/TypeScript. Speed early, a rewrite later. The port was kept
mechanical precisely so the behaviour could be shown not to have drifted.

### How I would improve accuracy next (top 3)

1. **Calibrate the thresholds.** `0.80` identity ambiguity, `0.82`/`0.78`
   vision confidence, `0.05` score gap are hand-picked constants, not fitted to
   anything. Correction telemetry already records which items users actually
   changed; fitting the thresholds to that turns friction into a measured
   quantity instead of a guess.
2. **Blinded live evals on a larger, dietitian-reviewed gold set.** The
   deterministic gate is 60 cases against a 3-food fixture and proves only that
   Turkish parsing has not regressed. Product accuracy needs the live eval run
   against pinned model snapshots, with photo cases, and labels someone
   qualified reviewed.
3. **Learn from accepted corrections.** Every commit already writes a
   correction diff. Mining those for missing aliases and wrong portion priors
   is the highest-yield catalog work available — without auto-promoting
   unreviewed user labels into the canonical catalog.

### What breaks at scale

- **Retrieval latency, first.** A composite dish takes ~20 s today because each
  extracted component is resolved with its own catalog load, embedding call and
  selection round trip. That is sequential work per component and it is the
  first thing users would abandon over. Batching the component lookups into one
  retrieval pass is the fix.
- **The vector index against the plan.** 60,003 × 512-dim vectors plus an
  ivfflat index is 373 MB; the whole database sits at 494 MB against a 500 MB
  ceiling. Dropping the index is not an option — measured, the same query is
  144 ms with it and 10.4 s without. Growth needs a bigger plan, fewer
  dimensions, or a partitioned catalog.
- **Embedding backfill.** It runs as a foreground job with a persisted cursor.
  At catalog scale it needs a durable worker with dead-letter handling; a
  catalog-wide alias change currently invalidates every embedding at once.
- **Provider limits and cost.** ~$0.0002 per meal is fine at demo volume; rate
  limits and per-user cost caps are not modelled.
- **Cache and catalog invalidation** are keyed by a catalog fingerprint but
  rolled out globally, not versioned per cohort.

### Biggest security and privacy risks

Meal photos and dietary patterns are health-adjacent personal data, which is
the core exposure. Present controls: photos live in owner-scoped private
Storage, meals are RLS-enforced per user, the service-role key never leaves the
server, the auth email hook is signature-verified, provider calls are sent with
`store: false`, and `redactedLog` keeps user text, addresses, tokens and keys
out of logs — pinned by a test.

Known gaps, in the order I would close them: EXIF is not stripped before upload,
so location can ride along with a photo; there is no retention or deletion
schedule for stored photos; account deletion removes the auth user but has no
verified cascade audit; and no DPIA exists for the provider transfer. The
largest single-point risk is the service-role key — it bypasses RLS entirely,
so its blast radius is the whole dataset.

### Tooling disclosure

This project was built with **Claude Code (Anthropic)** as the primary coding
assistant, used for implementation, refactoring, test authoring, the Deno→Node
port, and the catalog investigation documented above; **OpenAI image generation**
produced the onboarding illustrations (see `docs/ASSET_PROVENANCE.md`). Research
and competitor review used web search. Every architectural decision, threshold,
and trade-off in this document was reviewed and is defended here on its merits —
the assistant wrote code and prose, it did not choose the invariants.

Separately and unrelated: runtime OpenAI calls are restricted to photo
extraction, embeddings, and allow-listed candidate selection. All nutrition and
persistence invariants are enforced in code and Postgres, not by a model.
