#!/usr/bin/env node
import { promises as fs } from "node:fs";
import { resolve } from "node:path";
import { readJsonlGz } from "../src/cleaning-common.ts";
const ROOT = resolve(import.meta.dirname, "../../.."), DIR = resolve(ROOT, "data/canonical");

async function main() {
  const metrics = JSON.parse(await fs.readFile(resolve(DIR, "canonicalization-metrics.json"), "utf8"));
  const ids = new Set<string>(); let foods = 0, mappings = 0, reviews = 0; const errors: string[] = [];
  for await (const food of readJsonlGz(resolve(DIR, "canonical-foods.jsonl.gz"))) {
    foods++; if (!/^cf_[0-9a-f]{24}$/.test(food.canonical_id) || ids.has(food.canonical_id)) errors.push(`invalid_or_duplicate_canonical_id:${food.canonical_id}`); ids.add(food.canonical_id);
  }
  for await (const mapping of readJsonlGz(resolve(DIR, "canonical-source-mappings.jsonl.gz"))) {
    mappings++; if (!ids.has(mapping.canonical_id)) errors.push(`mapping_missing_canonical:${mapping.canonical_id}`);
    if (mapping.confidence !== "HIGH" || mapping.needs_canonical_review !== false || !Number.isInteger(mapping.source_record_ordinal) || mapping.source_record_ordinal < 1) errors.push(`unsafe_or_untraceable_automatic_mapping:${mapping.source}:${mapping.source_id}`);
    if (mapping.match_method === "exact_valid_gtin" && !mapping.match_reasons.includes("valid_gtin_checksum")) errors.push(`barcode_mapping_without_validation:${mapping.source}:${mapping.source_id}`);
  }
  for await (const candidate of readJsonlGz(resolve(DIR, "canonical-review-candidates.jsonl.gz"))) {
    reviews++; if (candidate.canonical_match_confidence !== "MEDIUM" || candidate.needs_canonical_review !== true) errors.push(`invalid_review_candidate:${candidate.candidate_id}`);
  }
  if (foods !== metrics.canonical_food_count) errors.push(`food_count:${foods}!=${metrics.canonical_food_count}`);
  if (mappings !== metrics.total_source_records) errors.push(`mapping_count:${mappings}!=${metrics.total_source_records}`);
  if (reviews !== metrics.review_candidate_count) errors.push(`review_count:${reviews}!=${metrics.review_candidate_count}`);
  const report = { valid: errors.length === 0, canonical_foods: foods, source_mappings: mappings, review_candidates: reviews, errors: errors.slice(0, 100) };
  await fs.writeFile(resolve(DIR, "canonicalization-validation.json"), `${JSON.stringify(report, null, 2)}\n`);
  if (errors.length) throw new Error(`${errors.length} canonical validation errors; first: ${errors[0]}`);
  console.log(`Validated ${foods.toLocaleString()} canonical foods, ${mappings.toLocaleString()} mappings and ${reviews.toLocaleString()} review candidates.`);
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
