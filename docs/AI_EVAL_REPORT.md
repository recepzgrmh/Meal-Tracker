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

## Live status

The hosted run is not yet a clean measurement. After the SQL repair the pipeline
reaches the provider, and the remaining blocker is an OpenAI `401` on the
selection call, so the LLM path is still unmeasured. The six passing cases all
resolve through the deterministic alias path, and the six identity mismatches
are expectations authored against the three-food seed catalog before the
60,000-food production catalog was loaded; each needs review to decide whether
the returned food is the correct production entry or a genuine accuracy failure.
Those numbers should be replaced, not cited, once a valid provider key is in
place.
