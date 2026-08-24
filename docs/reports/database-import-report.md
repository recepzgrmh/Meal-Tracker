# Canonical-v2 Database Import Report

Updated: 2026-08-23

## Decision

**SUPABASE LEAN CATALOG READY**

The versioned schema is deployed and the direct PostgreSQL streaming importer
is operational. The oversized partial production load was removed before
publication and was never connected to the existing resolver. A Free Plan-sized
lean catalog was then selected, piloted, imported, and measured.

## Implemented

- Added an isolated, release-versioned `catalog_v2_*` relational catalog.
- Preserved source records, mappings, nutrition provenance, portions, aliases,
  branded metadata, review cases, and blocked matches in separate tables.
- Kept the existing `foods`, `food_aliases`, `food_portions`, and production
  resolver path unchanged.
- Implemented deterministic preferred-nutrition selection without averaging or
  imputing source nutrition.
- Implemented gzip JSONL streaming to PostgreSQL `COPY`; inputs are not loaded
  wholly into RAM.
- Added 5,000-record dependency-aware commits, `ON CONFLICT` idempotency, resume
  support, RLS-safe temporary import credentials, and automatic credential
  cleanup.
- Deployed migration `20260823110000_canonical_v2_catalog.sql` successfully.

## Current production state

| Item | Runtime state | Offline artifact |
|---|---:|---:|
| Supabase production foods | 60,000 | — |
| Canonical foods | — | 1,228,891 |
| Cleaned source records | — | 1,242,528 |
| Source mappings | — | 1,242,528 |
| Runtime catalog provider | Supabase only | — |

The approved cleanup permanently removed 765,000 unpublished, derived
`catalog_v2_canonical_foods` rows and the `loading` release. It did not change
the immutable local JSONL catalog or any normalized source record.

Historical post-cleanup verification, before the lean import:

- `catalog_v2_canonical_foods`: 0
- `catalog_v2_releases`: 0
- database size: 15 MB
- `catalog_v2_canonical_foods` relation size: 72 kB
- `default_transaction_read_only`: `on` (quota state had not refreshed yet)
- production `foods`: 3 (unchanged)
- production `food_aliases`: 20 (unchanged)
- production `food_portions`: 13 (unchanged)
- `meals`: 6 and `meal_items`: 12 (unchanged)
- stale temporary import roles: removed

## Full-catalog constraint discovered

At approximately 755,000 canonical rows, the canonical table and indexes used
about 716 MB. Supabase then enforced read-only mode. The official Free Plan
database-size threshold is 500 MB, so the remaining canonical foods and all
source/provenance tables cannot be inserted on the current quota.

The import process was stopped after the 765,000 checkpoint. Because a paid
plan is not available, those unpublished rows were explicitly truncated through
the SQL Editor after a production-table preflight. A read-only verification
query reported only 15 MB of database usage and zero catalog rows. The quota
state subsequently refreshed and the lean import completed in read-write mode.

## Current production result

The deterministic 60,000-row subset is imported into the existing resolver hot
path. It uses 120,000 bilingual aliases and 120,000 bilingual portions. The
complete database is about 205.7 MiB and read-write. The original 3 foods and
all meal/user data were preserved. The complete 1,228,891-food canonical-v2
catalog remains an immutable offline artifact rather than a second runtime
database. The admin dashboard reports Supabase catalog metrics but cannot
switch providers.
