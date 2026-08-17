# Meal Clarity Specifications

These documents turn the initial research report into implementation contracts.
When a conflict exists, the newest focused specification takes precedence over
the older broad research report.

- [Product and UX](PRODUCT_UX_SPEC.md) — onboarding, auth, meal UX, offline
  states, accessibility, and analytics
- [Technical architecture](TECHNICAL_ARCHITECTURE_SPEC.md) — Flutter/Supabase,
  Edge Functions, Drift sync, Storage, security, tests, and CI/CD
- [AI accuracy](AI_ACCURACY_SPEC.md) — extraction, retrieval, embeddings,
  prompting, clarification policy, evals, and release gates
- [Onboarding assets](ONBOARDING_ASSET_BRIEF.md) — required/optional assets,
  generation prompts, validation, and delivery checklist
- [Sprint plan](../SPRINT_PLAN.md) — dependency-ordered seven-day execution plan

## Locked decisions

- text-first meal input
- hybrid rules + retrieval + LLM
- nutrition only from a versioned catalog
- Flutter MVVM with repository boundaries
- Supabase Auth/Postgres/Storage/Edge Functions
- Drift local source of truth and transactional outbox
- email OTP primary authentication
- three-step interactive onboarding
- private meal-photo storage; photo recognition out of MVP
- pgTAP RLS/data-integrity tests
- repository-owned evaluation runner

