# Meal Clarity — Delivery Sprints

Status: ready to execute  
Planning date: 17 August 2026  
Cadence: seven-day case-study delivery, focused daily sprints

## 1. Planning principles

- Accuracy proof is the product, not a final polish task.
- Each sprint ends with a runnable vertical increment.
- Database changes are forward-only migrations with pgTAP coverage.
- UI code follows MVVM; repositories isolate local/remote/provider details.
- Every logical change receives its own commit.
- A feature is not done without failure states, observability, and tests.
- The demo must remain runnable if the model provider is unavailable; a
  deterministic fixture mode is retained.

## 2. Current delivery status — Sprint 2 complete, Sprint 3 active

Already delivered:

- Flutter iOS/Android scaffold
- high-quality Today/composer/review/clarification/detail vertical slice
- MVVM ViewModels and repository boundary
- resumable onboarding, passwordless email OTP, session restore, and route state machine
- Drift local source of truth for meals, items, profiles, sync operations, and checkpoints
- cache-first Today/History streams with app-resume refresh
- transactional optimistic writes and durable, sequential outbox replay
- full-jitter retry persistence and blocked conflict/validation states
- versioned conflict-safe Supabase meal mutation RPC
- authenticated `analyze-meal` Edge Function contract and deterministic Turkish parser
- unit, widget, golden, Deno, and iOS integration tests
- hosted Supabase project linked and migrated
- RLS, explicit Data API grants, canonical catalog schema, pgvector column/index
- seed foods, aliases, and portions
- idempotency/data trace schema
- deployed meal RPC and `analyze-meal` function
- remote database lint and unauthenticated function-gateway checks passing

Current limitations:

- Flutter meal analysis still uses the deterministic fixture repository; the new
  function is not connected to the composer yet
- `commit-meal` is not implemented; the current outbox writes reviewed meals
  through the conflict-safe RPC
- deterministic analysis currently covers the curated egg, white-cheese, and
  simit catalog slice
- no OpenAI extraction/reranking or catalog embeddings have been generated
- no Storage bucket/policies
- no pgTAP suites
- live OTP and authenticated function smoke tests remain manual environment gates

## 3. Dependency path

```text
Configuration
  → Auth/session
    → Onboarding profile
      → Real repository + Drift
        → Edge Function contracts
          → Deterministic retrieval
            → Embeddings + constrained LLM
              → Evals/observability
                → CI/release/Loom
```

Storage can run after auth and in parallel with AI, but photo recognition does
not enter the critical path.

## 4. Sprint 1 — Bootstrap, auth, and onboarding

Timebox: Day 1  
Goal: a first-time user can onboard, authenticate with email OTP, relaunch, and
reach the existing app shell with a persisted Supabase session.

### Backlog

#### S1-01 — Configuration boundary

- add `supabase_flutter`
- add typed `AppConfig`
- consume `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` through
  `--dart-define-from-file`
- add placeholder-safe example config and gitignore real configs
- fail early with a developer-safe configuration screen

Acceptance:

- production build cannot use a placeholder URL/key
- secret/service key scan is negative
- initialization is unit-tested

#### S1-02 — App router and bootstrap state

- introduce `go_router`
- bootstrap/auth/onboarding/app-shell route groups
- route redirect derives from one state machine
- no protected-screen flash
- deep-link callback routes reserved

Acceptance:

- cold boot route tests cover no session, session/profile incomplete, ready,
  and expired session

#### S1-03 — Auth repository

- Supabase implementation and fake implementation
- email OTP request and verify
- auth state subscription
- persisted session restore
- resend timer/error mapping
- sign out

Acceptance:

- real OTP works on iOS Simulator and one Android emulator/physical device
- auth errors expose stable domain codes
- ViewModel tests use fakes, not global Supabase instance

#### S1-04 — Onboarding UI

- implement OB-01, OB-02, OB-03 from product spec
- deterministic interactive demo
- resumable progress/version storage
- optional target/profile write after auth
- 200% text scale and reduced motion

Acceptance:

- onboarding → auth → Today device integration test
- process kill/relaunch resumes the current step
- no permissions requested

#### S1-05 — Supabase auth configuration

- exact mobile redirect allow-list
- OTP email template
- test built-in provider limits
- document custom SMTP production blocker

### Tests

- AuthViewModel unit suite
- router redirect tests
- onboarding widget/golden tests at two text scales
- OTP integration with provider fake in CI
- one manual/secure live OTP smoke test

### Asset gate

User may deliver `onboarding_hero_breakfast_v1.webp` using
`docs/specs/ONBOARDING_ASSET_BRIEF.md`. The sprint proceeds with a code-native
fallback if it is not ready.

### Sprint 1 exit demo

Fresh install → interactive onboarding → email OTP → Today → relaunch → Today.

## 5. Sprint 2 — Local database, real CRUD, and sync outbox

Timebox: Day 2  
Goal: Today/History use Drift as the local source of truth and synchronize real
Supabase meal data safely.

Status: complete. Automated exit coverage verifies persistent local logging,
atomic outbox creation, cache-first replacement protection, account isolation,
retry scheduling, conflict blocking, app-resume refresh, and successful remote
reconciliation. The real reconnect demo remains a manual authenticated smoke
test for the Loom.

### Backlog

#### S2-01 — Drift foundation

- Drift schema for profiles, meals, items, operations, checkpoints, preferences
- DAOs and reactive day queries
- generated migration baseline and migration tests
- local rows partitioned by user ID

#### S2-02 — Mapping and repository

- remote DTO, local DTO, domain mapping
- `SupabaseMealRemoteDataSource`
- `DriftMealLocalDataSource`
- offline-first `MealRepository`
- keep mock repository selectable for fixture/demo mode

#### S2-03 — Pull refresh

- fetch date window for current user
- transactional merge
- checkpoint per user/date window
- foreground/app-resume refresh
- stale/offline UI metadata

#### S2-04 — Mutation outbox

- operation UUID persisted before network call
- optimistic update + outbox in one transaction
- sequential worker with full-jitter backoff
- status pending/in-flight/blocked/failed
- no automatic retry for validation/forbidden/conflict

#### S2-05 — Conflict-safe remote API

- migration for row-version/updated-at precondition
- RPC or function for conflict-safe edit/delete
- replay returns stable result
- server remains authoritative for nutrition totals

#### S2-06 — History MVP

- cached day list
- empty/loading/offline/error states
- tap to existing detail screen

### Tests

- Drift DAO and migration tests
- repository cache-first tests
- fake-clock retry/backoff tests
- outbox survives restart
- account-switch isolation
- offline edit → reconnect → exactly-once integration test

### Sprint 2 exit demo

Log fixture meal online → airplane mode → edit portion → kill/relaunch → meal is
visible as pending → reconnect → one remote mutation and synced state.

## 6. Sprint 3 — Edge Function contract and deterministic AI core

Timebox: Day 3  
Goal: replace mock analysis transport with a secure function while keeping the
first results deterministic and catalog-grounded.

Status: active. S3-01 is complete and deployed. S3-02 has a tested deterministic
parser, strict request boundary, idempotent `analysis_runs` persistence, trace
logging, catalog-only matches, and explicit `NO_MATCH`. The production Flutter
composer now invokes the function through a strict DTO/repository boundary,
preserves catalog and trace provenance, and maps stable failure codes to safe UI
messages. S3-03 is also deployed: reviewed drafts enter the durable client
outbox, `commit-meal` verifies the authenticated analysis/candidate set, and an
atomic RPC snapshots nutrition from the canonical catalog before completing the
analysis. Client-supplied calories and macros are never accepted. Manual search
backend is deployed with bounded exact alias, full-text, and trigram ranking.
The versioned 60-case Turkish gold set and deterministic eval runner are also
complete; the first measured iteration improved exact-case accuracy from 85.00%
to 93.33% and portion MAPE from 10.51% to 1.28%. Secure manual-candidate
registration and its Flutter correction UI remain.

### Backlog

#### S3-01 — Shared Edge Function runtime

- Deno/TypeScript function scaffold
- authenticated user wrapper
- request/response schemas
- structured errors and CORS
- trace ID and redacted structured logging
- provider interfaces and fakes

#### S3-02 — `analyze-meal` v1

- validate user/request/input
- create/replay `analysis_runs` idempotently
- Turkish normalization
- deterministic phrase/quantity extraction baseline
- exact alias match
- portion resolver for egg, cheese, simit, bread, yogurt
- persist candidates/output/status

#### S3-03 — `commit-meal`

- verify analysis ownership/readiness
- server-side catalog snapshot and nutrition calculation
- transactionally insert meal/items and mark analysis completed
- idempotent replay
- Flutter remote integration

#### S3-04 — Manual fallback search

- catalog search RPC/function
- exact + trigram/FTS ranking
- `NO_MATCH` and manual selection UI

#### S3-05 — Gold dataset v1

- 60 reviewed Turkish cases
- JSONL schema and validator
- tags/error taxonomy
- deterministic eval runner and baseline report

### Tests

- function auth and schema contracts
- normalization/quantity table tests
- forged user ID rejected
- duplicate request produces one analysis/meal
- nutrition invariant tests
- Flutter contract fixtures

### Sprint 3 exit demo

Real authenticated Flutter call → function → catalog-grounded draft → clarify →
server commit → Drift refresh → Today.

## 7. Sprint 4 — Structured LLM, embeddings, and hybrid retrieval

Timebox: Day 4  
Goal: handle messy and colloquial input while measuring whether each AI stage
improves accuracy.

### Backlog

#### S4-01 — OpenAI provider integration

- server secret and spend guard
- Responses API client
- strict extraction JSON Schema
- `gpt-5.6-luna` baseline with configurable reasoning effort
- provider timeout, 429, refusal, invalid-output behavior
- prompt/schema/model version fields

#### S4-02 — Prompt v1

- bounded extraction-only developer prompt
- Turkish portion ontology
- positive, negative, negation, and adversarial examples
- stable cacheable prefix and user input last
- snapshot tests for request construction

#### S4-03 — Embedding pipeline

- `text-embedding-3-small`, 1,536 dimensions
- canonical food embedding document template
- protected batch generator
- source hash/model/version persistence
- retry/dead-letter state
- seed catalog backfill

#### S4-04 — Hybrid search RPC

- exact alias, trigram/FTS, vector top-k
- RRF fusion and deterministic bonuses/penalties
- candidate allow-list maximum 7
- active/locale/source filtering
- HNSW query aligned with cosine operator class

#### S4-05 — Constrained rerank

- deterministic selection when safe
- LLM candidate choice or `NO_MATCH` only for ambiguity
- server allow-list validation
- candidate trace persistence

#### S4-06 — Impact-based clarification

- feature-based confidence bands
- identity/preparation/portion priority
- nutrition-impact thresholds
- maximum-question budget
- response contract to existing review UI

#### S4-07 — Eval comparison

- deterministic baseline vs LLM extraction vs hybrid retrieval
- metrics by food family and ambiguity tag
- latency/cost/cached-token report
- reject changes that improve aggregate score but regress critical ambiguity

### Tests

- provider fake for all CI paths
- live-provider 20-case protected smoke suite
- embedding determinism/versioning tests
- candidate ID injection test
- no-match and prompt-injection cases
- clarification rule table tests

### Sprint 4 exit demo

Known alias, typo/regional alias, and catalog miss examples shown side-by-side
with candidate traces and eval improvement.

## 8. Sprint 5 — Storage, database security tests, and observability

Timebox: Day 5  
Goal: close security/reliability gaps and make system behavior inspectable.

### Backlog

#### S5-01 — Private meal-photo bucket

- migration creates `meal-photos`
- 8 MB and MIME restrictions
- user-ID path policies for select/insert/update/delete
- client staging/compression/EXIF removal
- upload outbox and orphan cleanup
- attachment UI feature flag; no recognition claim

#### S5-02 — pgTAP foundation

- test users/roles helpers
- profile, meals, items, analysis, correction RLS suites
- cross-user negative tests
- nutrition trigger/data-integrity suites
- idempotency constraints
- Storage RLS suites

#### S5-03 — Client-level backend integration

- two real test users
- user A cannot read/write user B
- expired/invalid token paths
- direct catalog mutation rejected
- photo cross-user access rejected

#### S5-04 — Observability

- trace ID from client through DB
- redacted function stage logs
- latency/token/cache/candidate fields
- client error breadcrumbs
- simple SQL views or exported report for demo dashboard

#### S5-05 — Reliability hardening

- timeout/retry matrices
- provider circuit/degraded fixture mode
- double-tap and concurrent commit test
- queue age and dead-letter visibility
- account deletion plan/function

#### S5-06 — Apple sign-in (stretch)

- only if Apple Developer configuration is ready
- native button and first-login name capture
- otherwise keep spec and visible disabled-free UI (do not show broken button)

### Tests

- `supabase db reset`, lint, pgTAP
- Edge Function Deno tests
- Storage integration tests
- forced 429/timeout/5xx tests
- log-redaction snapshots

### Sprint 5 exit demo

Two-user RLS attack test, photo access denial, idempotent double commit, and one
trace shown end to end.

## 9. Sprint 6 — Product polish, CI/CD, evaluation, and submission

Timebox: Days 6–7  
Goal: turn the working system into a credible, measurable case-study package.

### Backlog

#### S6-01 — UI/UX quality pass

- all empty/loading/offline/error/conflict states
- motion and Reduce Motion
- Dynamic Type/text scale
- VoiceOver/TalkBack labels and focus order
- small-screen and keyboard QA
- image compression/caching/performance

#### S6-02 — Full regression

- Flutter unit/widget/golden
- iOS and Android device integration
- Drift migrations/outbox
- Supabase reset/lint/pgTAP
- function tests
- 60+ case AI report; target 150 if time allows

#### S6-03 — CI/CD

- PR Flutter workflow
- PR Supabase local DB/test workflow
- protected provider eval workflow with spend cap
- main migration/function deployment
- Android APK artifact
- iOS Simulator build or TestFlight if signing allows
- required checks and secret scanning

#### S6-04 — README and architecture communication

- setup in under 10 minutes
- system diagram and request flow
- model/prompt/catalog versions
- eval methodology/table
- known failures and privacy risks
- trade-offs and top three next accuracy improvements
- explicit AI/tool/asset disclosure

#### S6-05 — Loom 5–10 minutes

Suggested timeline:

```text
0:00 problem and accuracy thesis
0:45 onboarding/auth
1:30 happy-path meal log
3:00 clarification and correction
4:15 architecture and security
5:30 eval dashboard/failure examples
7:00 offline/idempotency demo
8:15 trade-offs and next steps
```

#### S6-06 — Email summary

- what was built
- deliberately omitted scope
- biggest trade-off
- measured result
- repository/build/video links
- next three improvements

### Final acceptance gates

- clean clone builds with documented configuration
- hosted backend and functions respond
- no secrets in repository or mobile bundle
- all required CI gates green
- first meal flow passes both platforms
- remote schema history matches committed migrations
- eval numbers reproducible from versioned inputs
- failure modes are honest and correctable

## 10. Commit plan

Use focused commits; examples:

```text
docs: add implementation specs and sprint plan
chore: add typed environment configuration
feat: initialize Supabase Flutter client
feat: add resumable onboarding flow
feat: add passwordless email authentication
test: cover onboarding and auth state transitions
feat: add Drift meal cache
feat: add transactional sync outbox
test: cover offline replay and account isolation
feat: add authenticated meal analysis function
feat: add idempotent meal commit function
test: add Edge Function contract coverage
feat: add hybrid food retrieval
feat: generate versioned food embeddings
eval: add Turkish meal gold dataset baseline
feat: add private meal photo storage
test: add database and Storage RLS coverage
ci: gate Flutter and Supabase changes
docs: publish case study results and trade-offs
```

No `feat: complete app` or one-shot mega commit.

## 11. Risk register

| Risk | Probability | Impact | Mitigation |
|---|---:|---:|---|
| Custom SMTP not ready | High | Medium | demo with limited provider; document external-beta blocker |
| Apple developer config unavailable | Medium | Low | email OTP is primary; Apple is stretch |
| Docker/Supabase images stall locally | Medium | High | CI/remote lint now; repair Docker before pgTAP sprint |
| OpenAI account/model access unavailable | Medium | High | provider abstraction + deterministic fixture mode |
| Turkish food catalog licensing | High | High | curated demo records; no TürKomp scraping; provenance |
| Generated portion images misrepresent grams | High | High | label prototype until real scale validation |
| Offline sync scope grows | Medium | High | single-user entities, outbox, no generic CRDT/realtime replication |
| Edge Function CPU/runtime limits | Low | Medium | bounded top-k, async embedding jobs, external service escape hatch |
| Seven-day scope overload | High | High | scope kill order below |

## 12. Scope kill order

Cut in this order:

1. Apple sign-in
2. meal-photo upload UI (keep bucket/policy tests)
3. Realtime/Broadcast
4. advanced History search
5. onboarding raster hero (keep code-native version)
6. 150-case target down to 60 reviewed cases

Do not cut:

- auth/session and RLS
- editable structured result
- human-in-the-loop clarification
- catalog-derived nutrition
- idempotent commit
- deterministic offline outbox for core edits
- pgTAP ownership/data-integrity tests
- versioned eval report
- working mobile integration demo

## 13. Immediate next actions

1. User generates or delivers optional onboarding hero using the asset brief.
2. Remove stale `SUPABASE_ACCESS_TOKEN` exports from `~/.zshrc` so CLI profiles
   do not switch accounts unexpectedly.
3. Obtain the project's publishable key through the Supabase Connect dialog;
   never copy a secret key into Flutter.
4. Start Sprint 1 with configuration/bootstrap commits before UI screens.
5. Configure OTP email template and exact redirect allow-list.
