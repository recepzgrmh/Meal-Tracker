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

The current labels were authored for engineering evaluation and have not yet
been independently reviewed by a dietitian. They are suitable for regression
comparison, not clinical validation or nutrition advice.
