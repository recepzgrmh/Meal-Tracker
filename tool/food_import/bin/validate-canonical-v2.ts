#!/usr/bin/env node
import { createHash } from "node:crypto";
import { createReadStream, promises as fs } from "node:fs";
import { resolve } from "node:path";
import { readJsonlGz } from "../src/cleaning-common.ts";
import { CANONICAL_V2_VERSION } from "../canonical-v2-schema.ts";

const ROOT = resolve(import.meta.dirname, "../../..");
const DIR = resolve(process.env.CANONICAL_V2_OUTPUT_DIR ?? resolve(ROOT, "data/canonical-v2"));
const SHADOW = process.env.CANONICAL_V2_SHADOW_DIR ? resolve(process.env.CANONICAL_V2_SHADOW_DIR) : undefined;
const AUDIT_PATH = resolve(process.env.CANONICAL_V2_AUDIT_PATH ?? resolve(ROOT, "production-readiness-audit-v2.md"));
const HASH_FILES = ["canonical-foods.jsonl.gz", "canonical-source-mappings.jsonl.gz", "canonical-review-candidates.jsonl.gz", "canonical-blocked-merge-candidates.jsonl.gz", "canonicalization-metrics.json"];
const AUTO_METHODS = new Set(["verified_compatible_gtin", "generic_token_order_qualifier_guard"]);

async function sha(path: string) {
  const digest = createHash("sha256"), stream = createReadStream(path); for await (const chunk of stream) digest.update(chunk); return digest.digest("hex");
}
function md(value: unknown) { return String(value ?? "—").replaceAll("|", "/").replace(/\s+/g, " "); }

async function main() {
  const metrics = JSON.parse(await fs.readFile(resolve(DIR, "canonicalization-metrics.json"), "utf8"));
  const errors: string[] = [], warnings: string[] = [], ids = new Set<string>();
  let foodCount = 0, mappingCount = 0, reviewCount = 0, blockedCount = 0, autoMappingErrors = 0;
  for await (const food of readJsonlGz(resolve(DIR, "canonical-foods.jsonl.gz"))) {
    foodCount++;
    if (food.canonicalization_version !== CANONICAL_V2_VERSION || !/^cf2_[0-9a-f]{24}$/.test(food.canonical_id)) errors.push(`invalid_canonical_food:${food.canonical_id}`);
    if (ids.has(food.canonical_id)) errors.push(`duplicate_canonical_id:${food.canonical_id}`); ids.add(food.canonical_id);
    if (!Number.isInteger(food.source_count) || food.source_count < 1) errors.push(`invalid_source_count:${food.canonical_id}`);
  }
  const expectedOrdinal = new Map<string, number>(); let previousSource: string | undefined, closedSources = new Set<string>();
  for await (const mapping of readJsonlGz(resolve(DIR, "canonical-source-mappings.jsonl.gz"))) {
    mappingCount++;
    if (mapping.canonicalization_version !== CANONICAL_V2_VERSION || !ids.has(mapping.canonical_id)) errors.push(`mapping_missing_or_invalid_canonical:${mapping.source}:${mapping.source_id}`);
    if (previousSource && mapping.source !== previousSource) { closedSources.add(previousSource); if (closedSources.has(mapping.source)) errors.push(`source_mapping_order_reopened:${mapping.source}`); }
    previousSource = mapping.source;
    const expected = (expectedOrdinal.get(mapping.source) ?? 0) + 1;
    if (mapping.source_record_ordinal !== expected) errors.push(`source_ordinal_gap:${mapping.source}:${mapping.source_record_ordinal}:expected_${expected}`);
    expectedOrdinal.set(mapping.source, mapping.source_record_ordinal);
    if (!Array.isArray(mapping.match_reasons) || !Array.isArray(mapping.contradiction_flags) || typeof mapping.needs_review !== "boolean") errors.push(`mapping_schema:${mapping.source}:${mapping.source_id}`);
    if (AUTO_METHODS.has(mapping.match_method)) {
      const brandedSafe = mapping.match_method !== "verified_compatible_gtin" || (mapping.barcode_identity_status === "VERIFIED_COMPATIBLE" && mapping.match_confidence === "VERY_HIGH");
      const genericSafe = mapping.match_method !== "generic_token_order_qualifier_guard" || (["VERY_HIGH", "HIGH"].includes(mapping.match_confidence) && mapping.barcode_identity_status === "NOT_APPLICABLE");
      if (!brandedSafe || !genericSafe || mapping.contradiction_flags.length || mapping.needs_review) { autoMappingErrors++; errors.push(`unsafe_automatic_mapping:${mapping.source}:${mapping.source_id}`); }
    }
    if (mapping.match_reasons.includes("different_checksum_valid_gtin")) errors.push(`different_valid_gtin_entered_candidate_mapping:${mapping.source}:${mapping.source_id}`);
  }
  for await (const candidate of readJsonlGz(resolve(DIR, "canonical-review-candidates.jsonl.gz"))) {
    reviewCount++;
    if (candidate.candidate_type !== "HUMAN_REVIEW" || candidate.needs_review !== true || candidate.barcode_identity_status === "CONTRADICTED") errors.push(`invalid_review_candidate:${candidate.candidate_id}`);
    if ((candidate.contradiction_flags ?? []).includes("different_valid_gtin")) errors.push(`different_valid_gtin_in_human_queue:${candidate.candidate_id}`);
  }
  for await (const candidate of readJsonlGz(resolve(DIR, "canonical-blocked-merge-candidates.jsonl.gz"))) {
    blockedCount++;
    if (candidate.candidate_type !== "BLOCKED_CONTRADICTION" || candidate.needs_review !== false || candidate.barcode_identity_status !== "CONTRADICTED") errors.push(`invalid_blocked_candidate:${candidate.candidate_id}`);
    if (candidate.left?.canonical_id === candidate.right?.canonical_id) errors.push(`blocked_pair_still_merged:${candidate.candidate_id}`);
  }
  if (foodCount !== metrics.output.canonical_food_count) errors.push(`food_count:${foodCount}!=${metrics.output.canonical_food_count}`);
  if (mappingCount !== metrics.output.source_mapping_count || mappingCount !== metrics.input.total_cleaned_records) errors.push(`mapping_count:${mappingCount}`);
  if (reviewCount !== metrics.output.review_candidate_count) errors.push(`review_count:${reviewCount}!=${metrics.output.review_candidate_count}`);
  if (blockedCount !== metrics.output.blocked_barcode_candidate_pairs) errors.push(`blocked_count:${blockedCount}!=${metrics.output.blocked_barcode_candidate_pairs}`);
  if (mappingCount - foodCount !== metrics.output.automatic_merge_reductions) errors.push("automatic_merge_arithmetic_mismatch");
  if (metrics.safety.preparation_state_conflicts_in_automatic_merges !== 0) errors.push("preparation_state_conflicts_remain");
  if (metrics.safety.nutrition_conflicts_in_automatic_merges !== 0) errors.push("nutrition_conflicts_remain");
  if (metrics.safety.critical_automatic_false_merge_candidates !== 0) errors.push("critical_automatic_false_merge_risk_remains");
  if (metrics.safety.high_automatic_false_merge_candidates !== 0) errors.push("high_automatic_false_merge_risk_remains");
  if (metrics.output.review_candidate_count >= metrics.before.review_candidates) errors.push("review_queue_not_reduced");
  if (metrics.output.turkomp_usda_shared_generic_canonical_ids <= 0) errors.push("tr_en_generic_coverage_not_improved");
  for (const key of ["safe_generic_merges", "blocked_barcode_contradictions", "correct_separations", "human_review_candidates"]) if ((metrics.examples[key] ?? []).length < 30) warnings.push(`fewer_than_30_report_examples:${key}:${metrics.examples[key]?.length ?? 0}`);
  if ((metrics.examples.tr_en_merges ?? []).length < 30) warnings.push(`fewer_than_30_report_examples:tr_en_merges:${metrics.examples.tr_en_merges?.length ?? 0}`);

  const hashes: Record<string, string> = {}, shadowHashes: Record<string, string> = {}, hashMatches: Record<string, boolean> = {};
  for (const file of HASH_FILES) {
    hashes[file] = await sha(resolve(DIR, file));
    if (SHADOW) { shadowHashes[file] = await sha(resolve(SHADOW, file)); hashMatches[file] = hashes[file] === shadowHashes[file]; }
  }
  const idempotenceValid = Boolean(SHADOW) && HASH_FILES.every((file) => hashMatches[file]);
  if (!idempotenceValid) errors.push(SHADOW ? "idempotence_hash_mismatch" : "idempotence_shadow_run_missing");
  const valid = errors.length === 0, readiness = valid ? "READY" : "NOT READY";
  const validation = { canonicalization_version: CANONICAL_V2_VERSION, valid, production_readiness: readiness,
    counts: { canonical_foods: foodCount, source_mappings: mappingCount, review_candidates: reviewCount, blocked_candidates: blockedCount },
    safety: {
      automatic_mapping_errors: autoMappingErrors,
      ...metrics.safety,
      preparation_state_conflict_rate_in_automatic_merges: metrics.output.automatic_merge_reductions
        ? metrics.safety.preparation_state_conflicts_in_automatic_merges / metrics.output.automatic_merge_reductions : 0,
      nutrition_conflict_rate_in_automatic_merges: metrics.output.automatic_merge_reductions
        ? metrics.safety.nutrition_conflicts_in_automatic_merges / metrics.output.automatic_merge_reductions : 0,
      remaining_possible_missed_merge_candidates: reviewCount,
    },
    idempotence: { valid: idempotenceValid, primary_hashes: hashes, shadow_hashes: shadowHashes, matches: hashMatches },
    warnings, errors: errors.slice(0, 200) };
  await fs.writeFile(resolve(DIR, "canonicalization-validation.json"), `${JSON.stringify(validation, null, 2)}\n`);

  let audit = `# Production Readiness Audit — Canonical V2\n\n# ${readiness}\n\nCanonical-v2 was validated without importing anything into Supabase or another database. Cleaned datasets and canonical-v1 remain unchanged.\n\n## Before → after\n\n| Metric | Canonical V1 | Canonical V2 |\n|---|---:|---:|\n| Cleaned/source records | ${metrics.before.cleaned_records.toLocaleString()} | ${mappingCount.toLocaleString()} |\n| Canonical foods | ${metrics.before.canonical_foods.toLocaleString()} | ${foodCount.toLocaleString()} |\n| Automatic merge reductions | ${metrics.before.automatic_merges.toLocaleString()} | ${metrics.output.automatic_merge_reductions.toLocaleString()} |\n| Barcode merge reductions | ${metrics.before.barcode_merges.toLocaleString()} | ${metrics.output.barcode_merge_reductions.toLocaleString()} |\n| Generic merge reductions | ${metrics.before.generic_merges.toLocaleString()} | ${metrics.output.generic_merge_reductions.toLocaleString()} |\n| Blocked barcode groups | 0 | ${metrics.output.blocked_barcode_merge_groups.toLocaleString()} |\n| TR↔EN merged groups | 0 | ${metrics.output.tr_en_merged_groups.toLocaleString()} |\n| TürKomp↔USDA shared generic canonical IDs | 0 | ${metrics.output.turkomp_usda_shared_generic_canonical_ids.toLocaleString()} |\n| Review candidates | ${metrics.before.review_candidates.toLocaleString()} | ${reviewCount.toLocaleString()} |\n| Preparation/state conflicts in auto merges | not blocked structurally | ${metrics.safety.preparation_state_conflicts_in_automatic_merges} |\n| Nutrition conflicts in auto merges | not blocked structurally | ${metrics.safety.nutrition_conflicts_in_automatic_merges} |\n| CRITICAL automatic false-merge candidates | ${metrics.before.critical_barcode_risk} | ${metrics.safety.critical_automatic_false_merge_candidates} |\n| HIGH automatic false-merge candidates | ${metrics.before.high_barcode_risk} | ${metrics.safety.high_automatic_false_merge_candidates} |\n\n## Validation gates\n\n| Gate | Result |\n|---|---|\n| Source mapping integrity | ${mappingCount === metrics.input.total_cleaned_records ? "PASS" : "FAIL"} |\n| Canonical ID validity/uniqueness | ${errors.some((value) => value.includes("canonical_id")) ? "FAIL" : "PASS"} |\n| Contradictory barcode auto merge | ${metrics.safety.critical_automatic_false_merge_candidates + metrics.safety.high_automatic_false_merge_candidates === 0 ? "PASS" : "FAIL"} |\n| Preparation/state conflict | ${metrics.safety.preparation_state_conflicts_in_automatic_merges === 0 ? "PASS" : "FAIL"} |\n| Nutrition contradiction in auto merge | ${metrics.safety.nutrition_conflicts_in_automatic_merges === 0 ? "PASS" : "FAIL"} |\n| Review queue reduction | ${reviewCount < metrics.before.review_candidates ? "PASS" : "FAIL"} |\n| TR↔EN coverage increased | ${metrics.output.tr_en_merged_groups > 0 ? "PASS" : "FAIL"} |\n| Byte-level deterministic outputs | ${idempotenceValid ? "PASS" : "FAIL"} |\n\n`;
  if (!valid) audit += `## Remaining blockers\n\n${errors.map((value) => `- ${md(value)}`).join("\n")}\n\n`;
  if (warnings.length) audit += `## Non-blocking documentation warnings\n\n${warnings.map((value) => `- ${md(value)}`).join("\n")}\n\n`;
  audit += `## Decision\n\n**${readiness}**${valid ? " — all required integrity, safety, coverage, queue, and idempotence gates passed. This decision applies to the derived canonical-v2 files only; no database import was performed." : " — resolve the blockers above and rerun validation before any database promotion."}\n`;
  await fs.writeFile(AUDIT_PATH, audit);
  console.log(`${readiness}: validated ${foodCount.toLocaleString()} canonical foods, ${mappingCount.toLocaleString()} mappings, ${reviewCount.toLocaleString()} review candidates and ${blockedCount.toLocaleString()} blocked pairs.`);
  if (!valid) process.exitCode = 1;
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
