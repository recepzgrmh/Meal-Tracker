# `data/` — food database working area

Local staging area for third-party food/nutrition datasets. **Nothing here ships
in the app bundle.** The Flutter app only ever reads files under `assets/`; this
directory is the pipeline input that produces those assets.

```
data/
├── raw/                    # untouched downloads, byte-identical to the source
│   ├── usda/
│   │   ├── fndds/          # FNDDS (Food & Nutrient DB for Dietary Studies)
│   │   ├── foundation/     # Foundation Foods
│   │   └── sr_legacy/      # SR Legacy
│   ├── turkomp/            # TÜRKOMP (Ulusal Gıda Kompozisyon Veri Tabanı)
│   ├── open_food_facts/    # OFF exports (JSONL / CSV / MongoDB dump)
│   └── kaggle/             # Kaggle datasets, one folder per dataset slug
├── interim/                # intermediate parse output, safe to delete & rebuild
├── processed/              # normalized, deduped, app-shaped output
└── sources.json            # provenance manifest — one entry per raw artifact
```

## Rules

1. **`raw/` is read-only.** Never edit a downloaded file in place. If it needs
   fixing, fix it in the normalize step and write to `interim/` or `processed/`.
2. **Every raw artifact gets a `sources.json` entry** with `sourceUrl`,
   `retrievedAt`, `bytes`, `sha256` and `license`. This mirrors the existing
   convention in `tool/catalog/snapshots/snapshot_index.json` — every value that
   ends up in the app must be traceable back to a hashed source file.
3. **`raw/`, `interim/` and `processed/` are git-ignored** (see the `data/`
   section in the root `.gitignore`). Only `README.md`, `sources.json` and
   `.gitkeep` files are committed. The datasets are large and most of them
   cannot be redistributed.
4. **Licenses differ per source.** USDA is public domain; TÜRKOMP requires
   attribution; Open Food Facts data is ODbL (share-alike) and its images are
   CC BY-SA. Record the license in `sources.json` before using a source, and
   reflect it in `docs/ASSET_PROVENANCE.md` when its data reaches `assets/`.

## Naming

Include the source release in the filename so two vintages can coexist:

```
data/raw/usda/foundation/FoodData_Central_foundation_food_csv_2025-04.zip
data/raw/turkomp/turkomp_export_2025-11-03.csv
data/raw/open_food_facts/openfoodfacts-products_2026-01-12.jsonl.gz
data/raw/kaggle/<dataset-slug>/<file>
```

## Hashing a download

```bash
shasum -a 256 data/raw/usda/foundation/<file>
```

Paste the digest into `sources.json` in the same commit that adds the entry.

## Where the code lives

Import/normalize scripts live in `tool/food_import/` (Dart, run with
`dart run tool/food_import/bin/<script>.dart`), following the existing
`tool/catalog/` layout. `data/` holds only data.
