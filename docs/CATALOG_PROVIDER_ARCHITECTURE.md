# Production Catalog Architecture

> [!NOTE]
> **Superseded**: The active meal-analysis runtime is `backend/` (Node.js/TypeScript).
> This document was written during the Supabase Edge Functions (Deno) era and
> may reference architecture that has since been ported. See `backend/README.md`
> for the current backend layout.

Updated: 2026-08-23

## Decision

Meal Clarity uses one runtime nutrition catalog: the deterministic 60,000-food
Supabase release named `canonical-v2-lean-60k`.

```text
Flutter app
    │ authenticated catalog-search.v2 request
    ▼
Supabase Edge Function
    │ exact alias + full-text/trigram search
    ▼
foods / food_aliases / food_portions
```

There is no runtime provider switch, external catalog endpoint, or second
production database. The Edge Function reads the Supabase catalog directly and
the admin dashboard exposes its metrics as read-only status.

## Why 60,000 foods

The source-preserving pipeline normalized 1,400,586 records, retained 1,242,528
cleaned records, and produced 1,228,891 traceable canonical foods. That complete
corpus remains an immutable data artifact for audit, provenance, future
experiments, and deterministic re-selection.

The entire audit-rich corpus is intentionally not loaded into the case-study
backend. Doing so would substantially increase storage, indexes, import time,
and query cost without a proportional improvement to the product demonstration.
Instead, a reproducible selector publishes 60,000 high-value foods balanced
across macro-complete generic foods, Turkey-relevant branded products,
English/global Open Food Facts products, USDA Branded groups, and other
high-quality global records.

## Runtime guarantees

- All 60,000 foods contain calories, protein, carbohydrate, and fat per 100 g.
- 120,000 Turkish/English aliases support locale-aware lookup.
- 120,000 Turkish/English portion rows support portion resolution.
- Invalid portion rows: zero.
- Pre-existing application foods remain untouched.
- Normalized and canonical source artifacts are never overwritten by the
  runtime import.
- Re-running selection and import is deterministic and idempotent.

## Verified production footprint

| Metric | Result |
|---|---:|
| Selected foods | 60,000 |
| Complete core macros | 60,000 |
| TR/EN aliases | 120,000 |
| TR/EN portions | 120,000 |
| Invalid portions | 0 |
| Pre-existing foods preserved | 3 |
| Database size after import | 215,641,235 bytes |
| Hot catalog relations | 185,942,016 bytes |
| Database mode | read-write |

## Admin dashboard

Settings → Data sources reports the active catalog version and live counts for
foods, macro-complete foods, aliases, and portions. These values are
informational. The dashboard cannot switch catalog providers.

## Future expansion

The production catalog should grow only when measured recall improvements
justify the additional storage and query cost. Any expansion requires a new
versioned deterministic selection, validation report, load test, and explicit
release rather than importing the entire available corpus by default.
