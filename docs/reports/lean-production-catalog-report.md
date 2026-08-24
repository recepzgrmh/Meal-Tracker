# Lean Production Catalog Report

Updated: 2026-08-23

## Decision

**LEAN CATALOG IMPORTED — 60,000/60,000 VERIFIED**

The full 1,228,891-food canonical-v2 catalog remains the immutable offline
source of truth. A deterministic 60,000-food subset was selected for the
Supabase Free Plan without modifying normalized, cleaned, or canonical inputs.

## Selection policy

- Target: 60,000 canonical foods.
- Include every generic USDA/TürKomp canonical food with complete kcal,
  protein, carbohydrate, and fat values.
- Branded candidates require a meaningful name and complete kcal, protein,
  carbohydrate, and fat values.
- Minimum computed branded quality score: 75.
- Prefer genuine Turkish market/language/barcode/name signals; do not invent
  weak Turkish relevance to fill a quota.
- Reserve deterministic source-diversity tiers for OFF English/global and USDA
  Branded products.
- Keep only lean resolver fields in the future DB payload; heavyweight source
  provenance remains in compressed JSONL.

## Result

| Tier | Canonical foods |
|---|---:|
| Generic core (macro-complete USDA generic + TürKomp) | 13,908 |
| Turkish-relevant branded | 4,589 |
| OFF English/global | 18,000 |
| USDA Branded membership required | 12,000 |
| Remaining quality-global | 11,503 |
| **Total** | **60,000** |

The Turkish tier stopped at 4,589 because only that many eligible canonical
groups had a meaningful Turkey signal. The configured 12,000 target was not
filled with weaker records.

## Production import and measured size

- Compressed selection manifest: approximately 2.7 MB.
- `public.foods`: 60,000 lean records plus 3 pre-existing records.
- `public.food_aliases`: 120,000 lean rows (TR + EN lookup coverage).
- `public.food_portions`: 120,000 lean rows (TR + EN portion coverage).
- Complete kcal + protein + carbohydrate + fat: 60,000/60,000.
- Invalid portion weights: 0.
- Database size after import: 215,641,235 bytes (about 205.7 MiB).
- Hot catalog relations: 185,942,016 bytes (about 177.3 MiB).
- `default_transaction_read_only`: `off`.

The first pilot proved that the audit-heavy `catalog_v2_*` layout would exceed
the Free Plan at 60,000 rows. Production therefore stores only hot resolver
fields in `foods`, `food_aliases`, and `food_portions`; full provenance remains
in the canonical-v2 JSONL artifacts.

## Determinism

Two full streaming runs produced identical hashes:

- `selected-canonical-foods.jsonl.gz`:
  `0605c5d2bcfac014a7af8c82f1a3e88c89b1b08d59719a8152bcd5ccdbecd4f2`
- `lean-catalog-metrics.json`:
  `0981a0e9488e84181e1f46ab9e32ffd24b654e329c74db309b0c6c8fe63999fa`

Outputs:

- `data/lean-catalog/selected-canonical-foods.jsonl.gz`
- `data/lean-catalog/lean-catalog-metrics.json`
- `tool/food_import/bin/build-lean-production-catalog.ts`

The `search-food-catalog` Edge Function reads this Supabase catalog directly;
there is no runtime provider switch. Semantic embedding backfill is disabled by
default to avoid consuming the Free Plan with 1,536-dimensional vectors;
deterministic lexical search remains active.
