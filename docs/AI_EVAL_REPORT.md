# Deterministic Turkish Meal Baseline

Date: 18 August 2026

Dataset: `turkish_meals_v1` (60 cases)

Catalog: `catalog_v1` (egg, white cheese, simit)

Pipeline: `deterministic-tr-v1`

## Result

| Metric | Baseline | Evidence isolation | Morphology + bidirectional portion |
|---|---:|---:|---:|
| Exact-case accuracy | 85.00% | 93.33% | 100.00% |
| Food identity precision | 100.00% | 100.00% | 100.00% |
| Food identity recall | 97.01% | 97.01% | 100.00% |
| Food identity F1 | 98.48% | 98.48% | 100.00% |
| Portion MAPE | 10.51% | 1.28% | 0.00% |
| No-match specificity | 100.00% | 100.00% | 100.00% |
| Failed cases | 9 | 4 | 0 |

The benchmark exposed quantity leakage between adjacent food mentions. For
example, in `2 yumurta, 30 g beyaz peynir`, the original resolver could attach
`30 g` to the egg. Restricting portion evidence to the immediate prefix/suffix
and preserving `½` before Unicode normalization improved exact-case accuracy by
8.33 percentage points and reduced portion MAPE by 9.23 percentage points.

The next iteration added bounded Turkish case/possessive suffix handling and
portion evidence after the food mention. It closed all four documented
regressions without reducing no-match specificity.

## Closed regressions

| Case | Failure class | Implemented behavior |
|---|---|---|
| `tr-016` — `yumurta 2 adet` | E5 suffix count | Count after food mention |
| `tr-033` — `beyaz peynirden 20 g` | E2 Turkish morphology | Inflected multi-word alias + suffix grams |
| `tr-044` — `simitin yarısı` | E2 + E5 morphology/fraction | Possessive alias + half expression |
| `tr-045` — `bir buçuk simit` | E5 fractional number | Turkish mixed-number parser |

## Metric definitions

- Exact-case accuracy: every expected food is found, no extra food is emitted,
  and each portion is within 10% of the reviewed gram label.
- Identity precision/recall/F1: micro-averaged canonical food IDs.
- Portion MAPE: mean absolute percentage error for matched expected foods.
- No-match specificity: catalog-miss cases that produce zero invented foods.

## Reproduction

```bash
cd supabase
deno task eval
```

Append `--persist` with service-role credentials to store the run in
`eval_runs`/`eval_cases`, which the admin console reads on its AI Evals page.

The current labels were authored for engineering evaluation and have not yet
been independently reviewed by a dietitian. They are suitable for regression
comparison, not clinical validation or nutrition advice.

## What the live harness caught

The deterministic suite is a parser gate and passes offline, so it cannot see
anything about the deployed system. The first real run of the live harness
against the hosted project returned a 30% pass rate, and the failure breakdown
in `eval_cases` explained why: seven cases carried `PROVIDER_UNAVAILABLE` with

```
Candidate grounding is unavailable:
function pg_catalog.coalesce(numeric, integer) does not exist
```

`COALESCE`, `GREATEST`, `LEAST`, and `NULLIF` are parser constructs rather than
catalog functions. The grammar only matches them as bare keywords, so a
schema-qualified `pg_catalog.coalesce(...)` is parsed as an ordinary function
call and rejected with `42883` when the statement executes. Qualifying them is
also unnecessary under `set search_path = ''`, because the parser resolves the
keyword before any schema lookup.

Two deployed functions carried the qualified form:

- `analysis_cost_budget_check`, which runs immediately before grounding, so
  every model-backed analysis failed and surfaced as a provider outage
- `commit_analyzed_meal`, on the confidence clamp, so every analyzed-meal
  commit would have failed at the moment a user saved a reviewed meal

Migration `20260824130000` repairs whatever is deployed through
`pg_get_functiondef` instead of restating each body, then asserts the pattern is
gone so a reintroduction fails the migration. `supabase/tests/
schema_qualified_constructs_test.sql` keeps the guard in the suite.

The defect is worth recording because of how it evaded the existing gates. It is
valid SQL, so `db lint` accepts it. The Deno tests mock `fetch`, so they never
reach Postgres. The pgTAP commit test needs a local database that had not been
run. Only an end-to-end run against the deployed project executed the statement,
and only because failures were persisted per case was the cause visible rather
than a generic provider error. An earlier migration, `20260818170000`, had
already repaired one instance of the same pattern, and later migrations
reintroduced it — which is why the fix now ends in an assertion instead of a
one-off replacement.

Two further defects sat behind the first, and each was found the same way. The
selection call then failed with a bare `400`, because the provider had retired
`minimal` as a reasoning effort for the configured model. The client recorded
only the status, so the cause was invisible; capturing a bounded slice of the
provider error body turned "failed with 400" into `Unsupported value: 'minimal'
is not supported`, which named the fix. Before that, a run whose cases all
reported `401` looked like a provider outage but was an expired eval JWT —
`tool/eval/run_live_eval.sh` now mints one per run so the token is never the
variable under test.

## Live status

First clean end-to-end measurement of the hosted pipeline, 20 bilingual text
cases:

| Metric | Value |
| --- | --- |
| Pass rate (identity exact and portion within 10%) | 0.40 |
| Identity exact accuracy | 0.55 |
| No-match accuracy | 0.17 |
| Portion MAPE | 1.46 |
| Latency p50 / p95 | 1685 ms / 13435 ms |
| Tokens in / out | 5564 / 676 |
| Estimated cost | $0.002 |

These are honest numbers on a small set, and the shape is more useful than the
headline. Identity is the stronger half at `0.55`; portions are the weak half,
with a MAPE far above the 10% gate, which says the gram estimates rather than
the food choices are what a user would spend time correcting. No-match accuracy
of `0.17` is the least trustworthy figure here because only a handful of cases
exercise abstention.

Two caveats before anyone cites the pass rate. Some expectations were authored
against the three-food seed catalog before the 60,000-food production catalog
was loaded, so a mismatch may mean the gold label points at a seed entry while
the system correctly returned a production one; each identity failure needs
review to separate a stale label from a real error. And p95 latency above 13 s
is a product problem independent of accuracy.

The immediate next steps are to review the identity failures case by case,
re-label where the production entry is correct, and then re-measure so portion
error can be attacked against a trustworthy baseline.
