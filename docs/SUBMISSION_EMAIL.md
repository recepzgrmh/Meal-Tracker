# Submission email draft

Subject: Case study submission — Meal Clarity

Hi [name],

Here is my case-study submission: an accuracy-first meal logger built with
Flutter, Supabase (Postgres + Edge Functions on Deno/TypeScript), and a React
admin console.

The one design decision I would ask you to remember is the grounding
invariant: the model interprets, the catalog decides. Nutrition values can
never be invented by the model or forged by the client — the commit path
re-reads catalog rows inside Postgres, and AI estimates are bounds-checked,
labeled, and server-persisted fallbacks.

Accuracy is measured three ways: a deterministic parser regression gate in CI
(perfect scores there mean "no parsing regressions", not product accuracy), a
live eval of 24 bilingual text and photo cases against the deployed function
(latency, tokens, cost, results in the admin dashboard), and commit-time
correction diffs as ongoing telemetry. The eval set is small and the
confidence thresholds are still hand-picked, uncalibrated constants.

Deliberate non-goals: no model fine-tuning, no barcode scanning, and the full
1.2M-food corpus stays offline in favor of a reproducible 60k catalog.

Repo: [repo link]
Walkthrough: [Loom link]

Thanks for reading,
[author]
