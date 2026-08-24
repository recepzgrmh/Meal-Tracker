# `tool/food_import/`

Import pipeline for the third-party food databases staged in `data/`. Same
layout as `tool/catalog/`: entry points in `bin/`, shared logic in `src/`.

The active pipeline entry points are TypeScript files executed directly with
Node 22+ native type stripping.

Intended stages — each reads from the previous stage's directory and never
mutates its input:

| Stage        | Reads                       | Writes             | Job                                                       |
| ------------ | --------------------------- | ------------------ | --------------------------------------------------------- |
| normalize    | source archives/exports     | `data/normalized/` | source-preserving units, nutrients, portions, provenance  |
| OFF scoring  | normalized OFF              | `data/catalog/`    | quality and TR/EN relevance; quality-only production cut  |
| clean        | normalized + OFF production | `data/cleaned/`    | derived display/search fields and non-mutating flags      |
| canonicalize v1 | cleaned records          | `data/canonical/`  | retained audit baseline; never overwritten                |
| canonicalize v2 | cleaned records          | `data/canonical-v2/` | contradiction-gated identities, mappings, blocked/review candidates |
| promote      | reviewed canonical catalog  | Supabase/app       | intentionally not performed yet                           |

The source-preserving normalization stage is implemented in TypeScript and runs
directly on Node 22+ (native type stripping):

```
node tool/food_import/bin/normalize.ts
node tool/food_import/bin/validate-normalized.ts
node tool/food_import/bin/generate-report.ts
```

Run one source with `--source usda-fndds` (or `usda-foundation`,
`usda-sr-legacy`, `usda-branded`, `turkomp`, `openfoodfacts`). `--limit N` is
available only for development smoke tests. Open Food Facts is always streamed
from gzip line-by-line; USDA archives are streamed directly from ZIP members.
Outputs are written atomically to `data/normalized/*.jsonl.gz`. Re-running a
source replaces only that source's derived output and metrics.

The normalized Open Food Facts output can be scored for a global Turkish / English
branded catalog without changing the normalized source:

```
node tool/food_import/bin/score-openfoodfacts-catalog.ts
node tool/food_import/bin/validate-openfoodfacts-catalog.ts
```

This writes an all-products scored stream and a production-candidate stream under
`data/catalog/`. Only `data_quality_score` controls production eligibility;
Turkey and English relevance scores are ranking signals and never exclusion rules.

Cleaning and conservative canonicalization run after normalization/catalog scoring
and write only derived directories:

```
node tool/food_import/bin/clean-food-data.ts
node tool/food_import/bin/validate-cleaned.ts
node --max-old-space-size=4096 tool/food_import/bin/canonicalize-food-data.ts
node --max-old-space-size=4096 tool/food_import/bin/validate-canonical.ts
node --max-old-space-size=4096 tool/food_import/bin/canonicalize-v2.ts

# Use an independently generated shadow directory for byte-level idempotence.
CANONICAL_V2_OUTPUT_DIR=/private/tmp/canonical-v2-shadow \
CANONICAL_V2_WRITE_REPORT=0 \
node --max-old-space-size=4096 tool/food_import/bin/canonicalize-v2.ts

CANONICAL_V2_SHADOW_DIR=/private/tmp/canonical-v2-shadow \
node --max-old-space-size=4096 tool/food_import/bin/validate-canonical-v2.ts
```

Cleaning writes `data/cleaned/*.jsonl.gz` without changing normalized source
fields or nutrition values. Canonicalization writes `data/canonical/`; every input
record receives a source mapping. Automatic branded merges require a checksum-valid
identical GTIN. Medium-confidence name/brand collisions remain review candidates.

Canonical-v2 leaves that v1 directory untouched. An identical checksum-valid
GTIN is evidence, not proof: product name, brand, category, ingredients,
nutrition, market, source-quality context, and GTIN type are checked before an
automatic branded merge. Contradictions are written to a separate blocked stream.
Generic identity is token-order-independent but requires exact versioned
qualifiers plus compatible category/nutrition and source diversity. Different
valid GTINs are deterministic keep-separate outcomes and do not enter human review.
