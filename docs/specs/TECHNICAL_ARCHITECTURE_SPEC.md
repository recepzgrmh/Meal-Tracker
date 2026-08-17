# Meal Clarity — Technical Architecture Specification

Status: implementation-ready draft  
Date: 17 August 2026  
Scope: Flutter client, Supabase, Edge Functions, Storage, offline sync, tests,
security, observability, and delivery

## 1. Architecture decision summary

| Concern | Decision |
|---|---|
| Mobile | Flutter, iOS + Android |
| Presentation | MVVM; widgets render immutable view state |
| State/DI | Riverpod providers around ViewModels and repositories |
| Navigation | `go_router` with bootstrap/auth/onboarding redirects |
| Serialization | `freezed` + `json_serializable` |
| Remote backend | Supabase Auth, Postgres, Storage, Edge Functions |
| Local persistence | Drift/SQLite |
| Sync | custom transactional outbox + pull refresh |
| AI boundary | authenticated Supabase Edge Function; text/photo/mixed contract |
| AI provider | OpenAI Responses API through server-side secret |
| Retrieval | alias/lexical first, pgvector fallback, constrained rerank |
| Observability | structured function logs + database traces; Sentry optional |
| DB tests | pgTAP and client-level integration tests |
| CI | Flutter gates + Supabase migration/lint/test + Edge Function tests |

This is a modular monolith, not a microservice system. One deployable Flutter
client and a small set of Supabase Edge Functions are enough for the case. The
boundaries allow a later FastAPI service if CPU-heavy processing, long-running
jobs, or provider orchestration outgrows Edge Function limits.

## 2. System context

```text
┌──────────────────────────────────────────────────────────────┐
│ Flutter                                                     │
│  Views → ViewModels → Repositories                          │
│                         ├─ Drift local source               │
│                         └─ Supabase remote source           │
└───────────────────────────────┬──────────────────────────────┘
                                │ publishable key + user JWT
                                ▼
┌──────────────────────────────────────────────────────────────┐
│ Supabase                                                     │
│  Auth ── PostgREST/RLS ── Postgres/pgvector ── Storage/RLS   │
│                   │                 ▲                        │
│                   └─ Edge Functions ┘                        │
└───────────────────────────────┬──────────────────────────────┘
                                │ server-side secret only
                                ▼
                         OpenAI API
```

Trust boundaries:

- Flutter is untrusted. The publishable key is public by design.
- User JWT establishes identity; RLS establishes data authorization.
- Edge Functions validate auth and inputs but do not trust client `user_id`,
  totals, confidence, or candidate IDs.
- Meal photos remain in a private bucket. Object paths are scoped as
  `{auth.uid()}/{clientRequestId}/source.ext`; the function rejects path/request
  ownership mismatches before provider access.
- Service-role/secret keys and `OPENAI_API_KEY` exist only as hosted function
  secrets.

## 3. Flutter module layout

Target layout:

```text
lib/
├── bootstrap/
│   ├── app_bootstrap.dart
│   ├── app_config.dart
│   └── providers.dart
├── core/
│   ├── errors/
│   ├── network/
│   ├── observability/
│   ├── routing/
│   └── sync/
├── domain/
│   ├── auth/
│   ├── foods/
│   ├── meals/
│   └── profile/
├── data/
│   ├── local/
│   ├── remote/
│   ├── mappers/
│   └── repositories/
├── features/
│   ├── onboarding/
│   ├── auth/
│   ├── today/
│   ├── meal_flow/
│   ├── history/
│   └── profile/
└── design_system/
```

Layer rules:

- domain imports Dart only
- repositories expose domain objects, never Supabase maps or Drift rows
- remote/local DTOs map at the data boundary
- ViewModels depend on repository interfaces
- widgets depend on ViewModels/view states, never database clients
- all time, UUID, connectivity, and analytics behaviors are injectable

## 4. Supabase client configuration

The current Flutter API initializes with project URL and a publishable key. Use
the new `publishableKey` parameter; never ship a secret/service key. Source:
[Supabase Flutter initialization](https://supabase.com/docs/reference/dart/initializing).

Compile-time configuration:

```text
SUPABASE_URL=https://nntxerlndotwgezmlesw.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
APP_ENV=development|staging|production
```

Rules:

- use `--dart-define-from-file` with untracked per-environment JSON
- commit `config/example.json` with placeholders only
- validate URL, key prefix, and environment before `runApp`
- production build fails in CI if placeholder values remain
- publishable key may exist in the binary; security relies on RLS and function
  auth, not hiding it

Initialization sequence:

1. Flutter binding
2. configuration validation
3. observability setup
4. Drift database open
5. Supabase initialize
6. repository/provider graph
7. app render
8. background session refresh and sync trigger

## 5. Authentication architecture

### Repository API

```dart
abstract interface class AuthRepository {
  Stream<AuthStatus> watchStatus();
  Future<void> requestEmailOtp(String email);
  Future<AuthUser> verifyEmailOtp(String email, String code);
  Future<AuthUser> signInWithApple();
  Future<void> signOut();
  Future<void> deleteAccount();
}
```

`AuthStatus`:

```text
unknown | unauthenticated | authenticating | authenticated | refreshFailed
```

Deep-link contract:

- application scheme: `mealclarity://`
- auth callback: `mealclarity://auth/callback`
- password recovery: `mealclarity://auth/recovery`
- allow-list exact redirects in Supabase Auth settings
- universal/app links are production hardening; custom scheme is sufficient for
  the case if tested on both platforms

Supabase notes that many mobile auth methods require deep links and Flutter
automatically handles auth callback URLs. Sources:
[Native mobile deep linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking),
[Flutter upgrade/auth callbacks](https://supabase.com/docs/reference/dart/upgrade-guide).

### OTP configuration

- production email template sends a six-digit token, not only a magic link
- verify with email and current OTP type supported by the installed SDK
- resend cooldown mirrors server settings
- custom SMTP required before external testing due built-in provider limits
- auth callback and OTP flows tested on real iOS/Android devices

### Apple sign-in gate

Implement only after:

- final bundle ID exists
- Apple Developer capability enabled
- Supabase Apple provider configured
- first-login full name capture behavior is handled

Supabase documents that Apple supplies the full name only on first
authorization, so it must be persisted immediately when present. Source:
[Supabase Login with Apple](https://supabase.com/docs/guides/auth/social-login/auth-apple).

## 6. Remote repository contracts

### Read APIs

Direct RLS-scoped PostgREST reads:

- profile
- meals for a date range
- meal items joined with meals
- canonical foods for manual search (through an RPC when ranking is needed)

### Write APIs

Direct RLS-scoped writes:

- profile preferences
- meal-item edits and delete operations where current grants permit

Edge Function writes:

- analyze meal
- commit analyzed draft
- account deletion
- photo and mixed-input analysis

Rationale: AI commits must validate the analysis owner, status, selected
candidates, idempotency key, and server-derived nutrition in one trusted flow.

### Repository interfaces

```dart
abstract interface class MealRepository {
  Stream<List<Meal>> watchDay(LocalDate date);
  Future<MealDraft> analyze(AnalyzeMealCommand command);
  Future<Meal> commitDraft(CommitMealCommand command);
  Future<void> updateItem(UpdateMealItemCommand command);
  Future<void> deleteMeal(DeleteMealCommand command);
  Future<SyncResult> sync();
}
```

All mutation commands carry:

- `operationId` UUID generated once and persisted before the request
- entity ID generated client-side where applicable
- expected entity version / `updated_at`
- command creation timestamp

## 7. Edge Function topology

```text
supabase/functions/
├── _shared/
│   ├── auth.ts
│   ├── cors.ts
│   ├── errors.ts
│   ├── logging.ts
│   ├── schemas.ts
│   └── openai.ts
├── analyze-meal/
├── commit-meal/
├── search-foods/
├── delete-account/
└── generate-food-embedding/   # admin/queue only
```

### Function authentication

- user functions keep `verify_jwt = true`
- handler also uses user-auth mode and derives user ID from verified claims
- admin/queue embedding function uses a dedicated secret auth mode
- no public `verify_jwt = false` function in MVP

Supabase recommends keeping JWT verification enabled for user-invoked functions
and using an RLS-scoped client for the caller. Sources:
[Securing Edge Functions](https://supabase.com/docs/guides/functions/auth),
[Authorization headers](https://supabase.com/docs/guides/functions/auth-headers).

### Function request envelope

```json
{
  "request_id": "uuid",
  "client_version": "1.0.0+1",
  "locale": "tr-TR",
  "payload": {}
}
```

Response envelope:

```json
{
  "data": {},
  "error": null,
  "meta": {
    "trace_id": "uuid",
    "request_id": "uuid",
    "duration_ms": 812,
    "schema_version": "2026-08-17"
  }
}
```

Stable errors:

```text
AUTH_REQUIRED
INVALID_INPUT
RATE_LIMITED
ANALYSIS_TIMEOUT
PROVIDER_UNAVAILABLE
CATALOG_EMPTY
DRAFT_EXPIRED
DRAFT_NOT_READY
CONFLICT
INTERNAL
```

### Runtime constraints

Current hosted Edge Function limits include 256 MB memory, 2 seconds CPU per
request, and 150 seconds wall-clock/idle timeout on Free. AI work is mostly
network I/O, but normalization/retrieval logic must remain bounded. Source:
[Edge Function limits](https://supabase.com/docs/guides/functions/limits).

Rules:

- end-user analysis budget: 12 seconds; provider timeout: 8 seconds
- no unbounded loops or large catalog payloads
- top-k candidates only
- 20 MB bundle ceiling, but target under 2 MB
- long embedding backfills use queue/cron batches, not the request path

## 8. Offline-first architecture

Flutter's official offline-first guidance makes repositories the single source
of truth that combine local and remote sources. Drift supplies typed SQLite,
reactive streams, transactions, and migration testing. Sources:
[Flutter offline-first](https://docs.flutter.dev/app-architecture/design-patterns/offline-first),
[Drift](https://drift.simonbinder.eu/),
[Drift migrations](https://drift.simonbinder.eu/migrations/).

### Local tables

```text
local_profiles
local_meals
local_meal_items
sync_operations
sync_checkpoints
app_preferences
```

Every cached domain row includes:

- remote UUID
- owner user UUID
- remote `updated_at`
- local `dirty` flag
- local tombstone flag
- last sync error code

`sync_operations`:

```text
operation_id UUID PK
user_id UUID
entity_type
entity_id UUID
operation_type create|update|delete
payload_json
base_updated_at
attempt_count
next_attempt_at
status pending|in_flight|blocked|failed
created_at
```

### Read path

1. ViewModel subscribes to repository stream.
2. Repository emits Drift result immediately.
3. Repository starts a remote refresh when session/network allows.
4. Remote rows merge into Drift in one transaction.
5. Drift emits updated UI.

No UI reads directly from Supabase after the offline layer is introduced.

### Write path

1. Validate command locally.
2. In one Drift transaction, apply optimistic row and insert outbox operation.
3. UI immediately shows `pending`.
4. Sync worker sends operation using persisted `operation_id` as idempotency key.
5. Server response replaces canonical server fields and clears the outbox row.
6. Permanent validation/conflict failure becomes `blocked` and visible.

### Retry policy

Retry:

- connection failure
- timeout
- 429 honoring `Retry-After`
- 5xx

Do not retry automatically:

- auth 401 after one refresh attempt
- validation 400/422
- forbidden 403
- domain conflict 409 without resolution

Backoff: full jitter, base 1 second, cap 60 seconds, maximum 6 automatic
attempts per foreground session. Persist attempts across process restarts.

`connectivity_plus` is only an optimization signal; its own documentation warns
that a reported connection type does not guarantee internet access. Source:
[connectivity_plus](https://pub.dev/packages/connectivity_plus).

### Conflict policy

- server is authoritative for nutrition, ownership, confidence, and analysis
  metadata
- user-editable fields use optimistic concurrency via `updated_at`
- if remote changed after the operation's base timestamp, return `409 CONFLICT`
- meal-item portion conflict presents remote vs local choice; do not silently
  merge nutrition
- deletes are tombstones locally until server acknowledgment

### Realtime role

Realtime is an invalidation signal, not a guaranteed sync transport. On a
received event, schedule a filtered pull. On reconnect, always pull from the
checkpoint. Supabase documents delivery/scaling limitations for Postgres
Changes and recommends Broadcast for scalable use cases. Sources:
[Realtime Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes),
[Subscribing to changes](https://supabase.com/docs/guides/realtime/subscribing-to-database-changes).

For this personal case app, Realtime is a stretch. Foreground pull plus outbox
is the required correctness path.

## 9. Storage specification

Bucket:

```text
meal-photos
```

Properties:

- private
- max file size: 8 MB
- allowed MIME: `image/jpeg`, `image/png`, `image/webp`, `image/heic`
- path: `<auth.uid()>/<meal_id>/<object_uuid>.<ext>`
- client compresses to max 2048 px long edge before upload where supported
- EXIF/GPS metadata removed before upload
- original local file retained only until successful upload unless user opts in

Policies:

- authenticated user can select/insert/update/delete only when first path
  segment equals their user ID
- bucket is never public
- signed URLs only for temporary external display; the app normally downloads
  with the user JWT

Supabase Storage is private by default and uses RLS on `storage.objects`; object
upload requires an INSERT policy. Sources:
[Storage buckets](https://supabase.com/docs/guides/storage/buckets/fundamentals),
[Storage access control](https://supabase.com/docs/guides/storage/security/access-control).

Upload lifecycle:

1. create meal / reserve meal UUID
2. stage local image and outbox operation
3. upload with `upsert: false`
4. write object path to meal through an authorized update/function
5. if DB write fails, enqueue orphan cleanup
6. delete object when meal deletion is acknowledged

## 10. Database changes still required

Forward-only migrations:

1. profile onboarding fields and version
2. meal row version / conflict-safe RPCs
3. hybrid lexical/vector search RPC
4. idempotent analysis commit RPC or function transaction helper
5. private `meal-photos` bucket and RLS policies
6. account deletion function and retention behavior
7. optional Realtime publication/trigger

Never edit already-deployed migrations. Each change receives a timestamped
migration and a focused commit.

## 11. Testing strategy

### Flutter unit

- domain nutrition invariants
- DTO/domain mapping
- auth state transitions
- onboarding resume/versioning
- sync scheduling and backoff with fake clock
- outbox deduplication and retry classification
- conflict resolution

### Flutter widget/golden

- every onboarding state at normal and 200% text scale
- OTP pending/error/resend states
- Today cached/offline/pending/failed states
- clarification identity and portion variants
- reduced-motion mode

### Flutter integration

- onboarding → OTP stub → Today
- analyze → clarify → commit → relaunch → cached Today
- offline edit → process restart → online sync exactly once
- expired session → reauth → queued operation resumes
- account switch data isolation

### Database pgTAP

Supabase recommends pgTAP for schema, constraints, functions, and RLS, including
negative cases across anonymous/authenticated roles. Source:
[Supabase testing overview](https://supabase.com/docs/guides/local-development/testing/overview).

Required suites:

- profiles RLS ownership
- meals CRUD ownership
- meal-items cannot target another user's meal
- analysis/candidate visibility
- correction ownership
- storage path ownership
- meal total trigger after insert/update/delete
- client-supplied meal totals are ignored
- duplicate `(user_id, client_request_id)` rejected or returns same result
- catalog cannot be mutated by authenticated client
- service function cannot accept forged user ID

### Edge Function tests

- schema validation fixtures
- missing/invalid JWT
- provider timeout/429/invalid structured output
- candidate allow-list violation
- idempotent replay
- redaction snapshot: no raw meal text in logs
- contract snapshots consumed by Flutter DTO tests

### AI eval tests

- deterministic rules and retrieval on every PR
- 20-case provider smoke suite on protected/manual CI
- full dataset nightly or pre-release

## 12. Observability

One trace ID flows through Flutter, Edge Function, `analysis_runs`, and commit.

Client breadcrumbs:

- screen/route changes
- sync operation state changes
- stable error codes
- no raw meal text, email, token, signed URL, or photo bytes

Function structured log:

```json
{
  "level": "info",
  "event": "analysis.stage.completed",
  "trace_id": "uuid",
  "analysis_id": "uuid",
  "user_hash": "hmac",
  "stage": "retrieve.hybrid",
  "duration_ms": 31,
  "candidate_count": 5,
  "model": "text-embedding-3-small",
  "version": "retrieval-2026-08-17"
}
```

Dashboards:

- function success/error rate
- p50/p95 end-to-end and stage latency
- OpenAI token use, cached tokens, and cost estimate
- catalog miss and no-match rate
- clarification and correction rates
- outbox depth, oldest queued age, sync failure rate
- RLS/auth failure rate by endpoint (without PII)

## 13. Security and privacy controls

- secret scanning in CI
- dependency lockfiles committed
- least-privilege Data API grants (already introduced)
- RLS on all exposed and Storage tables
- no user-supplied `user_id` trusted server-side
- raw prompts excluded from standard logs
- short retention for provider request/response debug samples
- correction data is not training consent
- model/provider data-processing settings documented
- photo EXIF removed
- account deletion covers Auth user, profile, meals, analysis traces, corrections,
  Storage objects, and local cache
- nutrition is an estimate with no diagnosis/treatment claim

## 14. CI/CD gates

Pull request:

```text
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
supabase db start
supabase db reset
supabase db lint --local --level warning
supabase test db
supabase functions test
```

Protected/manual:

- iOS Simulator integration test
- Android emulator integration test
- provider smoke eval with spend cap
- build iOS simulator artifact and Android APK

Main branch:

- apply Supabase migrations once
- deploy changed Edge Functions
- run remote lint/smoke checks
- produce tagged mobile artifacts

Deployment rules:

- database migrations before functions that depend on them
- backward-compatible response schema during client rollout
- no automatic destructive migration
- secrets configured out of band
- rollback is forward-fix migration/function redeploy, not history rewriting

## 15. Definition of done — architecture

- app boots with real Supabase configuration and no secret keys
- auth session survives process restart
- authenticated data is isolated by tested RLS
- Today reads from Drift and refreshes from Supabase
- queued mutation survives restart and is idempotent
- analyze and commit functions enforce schema and ownership
- private photo bucket rejects cross-user access
- remote database lint and pgTAP pass
- function tests pass with provider fakes
- one end-to-end trace is visible across client/function/database
- architecture and trade-offs are demonstrated in README and Loom
