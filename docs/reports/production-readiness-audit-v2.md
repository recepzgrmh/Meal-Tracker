# Production Readiness Audit — Canonical V2

# READY

Canonical-v2 was validated without importing anything into Supabase or another database. Cleaned datasets and canonical-v1 remain unchanged.

## Before → after

| Metric | Canonical V1 | Canonical V2 |
|---|---:|---:|
| Cleaned/source records | 1,242,528 | 1,242,528 |
| Canonical foods | 1,226,178 | 1,228,891 |
| Automatic merge reductions | 16,350 | 13,637 |
| Barcode merge reductions | 16,158 | 13,374 |
| Generic merge reductions | 192 | 263 |
| Blocked barcode groups | 0 | 334 |
| TR↔EN merged groups | 0 | 18 |
| TürKomp↔USDA shared generic canonical IDs | 0 | 18 |
| Review candidates | 153,370 | 2,469 |
| Preparation/state conflicts in auto merges | not blocked structurally | 0 |
| Nutrition conflicts in auto merges | not blocked structurally | 0 |
| CRITICAL automatic false-merge candidates | 236 | 0 |
| HIGH automatic false-merge candidates | 303 | 0 |

## Validation gates

| Gate | Result |
|---|---|
| Source mapping integrity | PASS |
| Canonical ID validity/uniqueness | PASS |
| Contradictory barcode auto merge | PASS |
| Preparation/state conflict | PASS |
| Nutrition contradiction in auto merge | PASS |
| Review queue reduction | PASS |
| TR↔EN coverage increased | PASS |
| Byte-level deterministic outputs | PASS |

## Non-blocking documentation warnings

- fewer_than_30_report_examples:tr_en_merges:18

## Decision

**READY** — all required integrity, safety, coverage, queue, and idempotence gates passed. This decision applies to the derived canonical-v2 files only; no database import was performed.
