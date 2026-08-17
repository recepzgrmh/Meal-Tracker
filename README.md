# Meal Clarity

An accuracy-first mobile meal logger built for the EatBetter full-stack case
study.

The mobile vertical slice now connects to an authenticated, catalog-grounded
Supabase analysis pipeline while retaining deterministic fixtures for tests:

- Today dashboard with totals derived from meal items
- Turkish/English localized app and locale-aware AI requests
- text-only, photo-only, and mixed meal composer
- camera/library picker with private per-user Storage uploads
- strict vision extraction followed by deterministic catalog matching
- real and mock analysis behind a replaceable `MealRepository` boundary
- Editable structured food review
- Human-in-the-loop portion clarification
- Log success with undo instead of a blocking success screen
- Catalog photography with explicit provenance labels
- Meal detail with deterministic portion editing and delete confirmation
- MVVM presentation state with replaceable data repositories
- Local Supabase foundation for auth, canonical foods, vector retrieval, meal
  persistence, correction feedback, and analysis traces

![Current iOS progress](meal-clarity-progress.png)

## Run

```sh
flutter pub get
flutter run --dart-define-from-file=config/app_config.dev.json
```

## Verify

```sh
flutter analyze
flutter test
flutter test integration_test/meal_logging_test.dart -d <device-id>
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

Photo analysis additionally requires `OPENAI_API_KEY` as an Edge Function
secret. `OPENAI_VISION_MODEL` is optional; the function has a versioned default.
Neither value belongs in Flutter config or source control.

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
