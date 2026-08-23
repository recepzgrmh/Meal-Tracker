#!/usr/bin/env node
import { promises as fs } from "node:fs";
import { createHash } from "node:crypto";
import { resolve } from "node:path";
import { CANONICALIZATION_SCHEMA_VERSION } from "../cleaning-schema.ts";
import { readJsonlGz, atomicGzip, writeLine, validGtin } from "../src/cleaning-common.ts";

const ROOT = resolve(import.meta.dirname, "../../..");
const CLEANED = resolve(ROOT, "data/cleaned"), OUTPUT = resolve(ROOT, "data/canonical");
const METRICS = resolve(OUTPUT, "canonicalization-metrics.json"), REPORT = resolve(ROOT, "canonicalization-report.md");
const SOURCES = ["usda-foundation", "usda-fndds", "usda-sr-legacy", "usda-branded", "turkomp", "openfoodfacts"] as const;
const GENERIC = new Set(["usda_foundation", "usda_fndds", "usda_sr_legacy", "turkomp"]);
const REVIEW_LIMIT_PER_KEY = 3;

type Ref = { source: string; source_id: string; name: string; display_name: string; normalized_name: string; normalized_brand?: string; brand?: string; barcode?: string; language?: string; nutrition: any; category?: any };
type Group = { key: string; leader: string; representative: Ref; members: Ref[]; nameTr?: string; nameEn?: string; method: string };

const BILINGUAL_EXACT: Record<string, string> = {
  "egg": "egg_whole_unspecified", "whole egg": "egg_whole_unspecified", "yumurta": "egg_whole_unspecified", "tavuk yumurtasi": "egg_whole_unspecified",
  "raw egg": "egg_whole_raw", "whole egg raw": "egg_whole_raw", "cig yumurta": "egg_whole_raw",
  "boiled egg": "egg_whole_boiled", "hard boiled egg": "egg_whole_boiled", "haslanmis yumurta": "egg_whole_boiled",
  "fried egg": "egg_whole_fried", "sahanda yumurta": "egg_whole_fried",
  "egg white": "egg_white_unspecified", "yumurta aki": "egg_white_unspecified",
  "egg yolk": "egg_yolk_unspecified", "yumurta sarisi": "egg_yolk_unspecified",
  "whole milk": "milk_cow_whole", "tam yagli sut": "milk_cow_whole", "inek sutu tam yagli": "milk_cow_whole",
  "skim milk": "milk_cow_skim", "yagsiz sut": "milk_cow_skim",
  "plain yogurt": "yogurt_plain", "sade yogurt": "yogurt_plain", "yogurt": "yogurt_plain",
  "apple": "apple_raw_unspecified", "elma": "apple_raw_unspecified", "banana": "banana_raw", "muz": "banana_raw",
  "white rice cooked": "rice_white_cooked", "cooked white rice": "rice_white_cooked", "pismis beyaz pirinc": "rice_white_cooked",
};

function id(namespace: string, key: string) { return `cf_${createHash("sha256").update(`${namespace}|${key}`).digest("hex").slice(0, 24)}`; }
function ref(food: any): Ref {
  const nutrition = Object.fromEntries(["kcal_100g", "protein_100g", "carbs_100g", "fat_100g"].map((key) => [key, food.nutrition?.[key]]).filter(([, value]) => value !== undefined));
  return { source: food.source, source_id: String(food.source_id), name: food.name, display_name: food.display_name, normalized_name: food.normalized_name, normalized_brand: food.normalized_brand, brand: food.brand, barcode: food.barcode, language: food.language, nutrition, category: food.category?.name ? { name: food.category.name } : undefined };
}
function refKey(item: Ref) { return `${item.source}:${item.source_id}`; }
function semanticKey(food: any) { return BILINGUAL_EXACT[food.normalized_name] ?? `exact:${food.normalized_name}`; }
function isTurkish(food: any) { return food.source === "turkomp" || food.normalized_languages?.includes("tr") || food.detected_languages?.includes("tr"); }
function isEnglish(food: any) { return food.source.startsWith("usda_") || food.normalized_languages?.includes("en") || food.detected_languages?.includes("en"); }
function nutritionSimilar(a: any, b: any): boolean {
  const keys = ["protein_100g", "carbs_100g", "fat_100g"], common = keys.filter((key) => Number.isFinite(a?.[key]) && Number.isFinite(b?.[key]));
  if (common.length < 2) return false;
  for (const key of common) {
    const x = a[key], y = b[key];
    if (Math.abs(x - y) > Math.max(5, Math.max(Math.abs(x), Math.abs(y)) * 0.45)) return false;
  }
  if (Number.isFinite(a?.kcal_100g) && Number.isFinite(b?.kcal_100g) && Math.abs(a.kcal_100g - b.kcal_100g) > Math.max(80, Math.max(a.kcal_100g, b.kcal_100g) * 0.4)) return false;
  return true;
}
function preparation(key: string): string | undefined { return ["raw", "boiled", "fried", "cooked", "skim", "whole"].find((token) => key.split(/[_: ]/).includes(token)); }
function md(value: unknown) { return String(value ?? "—").replaceAll("|", "/").replace(/\s+/g, " "); }

async function buildGenericGroups() {
  const groupsBySemantic = new Map<string, Group[]>(), assignment = new Map<string, Group>(), incompatible: any[] = [];
  for (const slug of ["usda-foundation", "usda-fndds", "usda-sr-legacy", "turkomp"]) {
    for await (const food of readJsonlGz(resolve(CLEANED, `${slug}.jsonl.gz`))) {
      const item = ref(food), key = semanticKey(food), groups = groupsBySemantic.get(key) ?? [];
      let group = groups.find((candidate) => candidate.members.every((member) => member.source !== item.source) && nutritionSimilar(candidate.representative.nutrition, item.nutrition));
      if (!group) {
        if (groups.length && incompatible.length < 200) incompatible.push({ left: groups[0].representative, right: item, reason: "same_identity_key_but_nutrition_or_same_source_incompatible" });
        group = { key, leader: refKey(item), representative: item, members: [], method: key.startsWith("exact:") ? "exact_normalized_generic_name_with_nutrition_guard" : "curated_bilingual_identity_with_state_guard" };
        groups.push(group); groupsBySemantic.set(key, groups);
      }
      group.members.push(item); assignment.set(refKey(item), group);
      if (isTurkish(food) && !group.nameTr) group.nameTr = food.display_name;
      if (isEnglish(food) && !group.nameEn) group.nameEn = food.display_name;
    }
  }
  return { assignment, groups: [...groupsBySemantic.values()].flat(), incompatible };
}

async function buildUsdaBarcodeOwners() {
  const owners = new Map<string, string>();
  for await (const food of readJsonlGz(resolve(CLEANED, "usda-branded.jsonl.gz"))) {
    if (!validGtin(food.barcode)) continue;
    const prior = owners.get(food.barcode);
    if (!prior || String(food.source_id).localeCompare(prior, "en", { numeric: true }) < 0) owners.set(food.barcode, String(food.source_id));
  }
  return owners;
}

async function buildOffTurkeyNames(usdaOwners: Map<string, string>) {
  const names = new Map<string, string>();
  for await (const food of readJsonlGz(resolve(CLEANED, "openfoodfacts.jsonl.gz"))) {
    const barcode = validGtin(food.barcode) ? String(food.barcode) : undefined;
    if (barcode && usdaOwners.has(barcode) && isTurkish(food) && !names.has(barcode)) names.set(barcode, food.display_name);
  }
  return names;
}

async function main() {
  await fs.mkdir(OUTPUT, { recursive: true });
  process.stderr.write("Pass 1: grouping conservative generic identities\n");
  const generic = await buildGenericGroups();
  process.stderr.write(`Generic groups: ${generic.groups.length.toLocaleString()}\nPass 2: indexing USDA valid GTIN owners\n`);
  const usdaBarcodeOwners = await buildUsdaBarcodeOwners();
  process.stderr.write(`USDA valid GTIN owners: ${usdaBarcodeOwners.size.toLocaleString()}\nPass 3: collecting Turkish OFF names for shared GTINs\n`);
  const offTurkeyNames = await buildOffTurkeyNames(usdaBarcodeOwners);
  process.stderr.write(`Shared-GTIN Turkish names: ${offTurkeyNames.size.toLocaleString()}\nPass 4: writing canonical outputs\n`);
  const foodsWriter = await atomicGzip(resolve(OUTPUT, "canonical-foods.jsonl.gz"));
  const mappingsWriter = await atomicGzip(resolve(OUTPUT, "canonical-source-mappings.jsonl.gz"));
  const reviewWriter = await atomicGzip(resolve(OUTPUT, "canonical-review-candidates.jsonl.gz"));
  const metrics: any = { canonicalization_version: CANONICALIZATION_SCHEMA_VERSION, generated_at: new Date().toISOString(), total_source_records: 0, canonical_food_count: 0, automatic_high_confidence_merge_count: 0, review_candidate_count: 0, unmerged_record_count: 0, tr_en_canonical_match_count: 0, barcode_merged_branded_product_count: 0, match_method_distribution: {}, per_source: {}, correct_merge_examples: [], non_merge_examples: [], review_examples: [] };
  const brandedIdentityFirst = new Map<string, Ref>(), brandedReviewEmitted = new Map<string, number>(), brandFirst = new Map<string, Ref>();
  const genericWritten = new Set<string>();
  const offCanonicalGtins = new Set<string>(), mergedCanonicalIds = new Set<string>(), trEnCanonicalIds = new Set<string>();
  let reviewSequence = 0;
  const writeReview = async (left: Ref, right: Ref, method: string, reasons: string[]) => {
    const candidate = { candidate_id: `cr_${String(++reviewSequence).padStart(9, "0")}`, left: { source: left.source, source_id: left.source_id, name: left.name, brand: left.brand, barcode: left.barcode }, right: { source: right.source, source_id: right.source_id, name: right.name, brand: right.brand, barcode: right.barcode }, canonical_match_confidence: "MEDIUM", canonical_match_method: method, canonical_match_reasons: reasons, needs_canonical_review: true };
    await writeLine(reviewWriter.stream, candidate); metrics.review_candidate_count++;
    if (metrics.review_examples.length < 30) metrics.review_examples.push(candidate);
  };
  for (const item of generic.incompatible) await writeReview(item.left, item.right, "generic_identity_collision", [item.reason, "not_automatically_merged"]);
  try {
    for (const slug of SOURCES) {
      let sourceCount = 0;
      for await (const food of readJsonlGz(resolve(CLEANED, `${slug}.jsonl.gz`))) {
        metrics.total_source_records++; sourceCount++;
        const item = ref(food), key = refKey(item);
        let canonicalId: string, method: string, reasons: string[], writeCanonical = true, canonicalKey: string, foodType: "generic_food" | "branded_product", nameTr: string | undefined, nameEn: string | undefined;
        if (GENERIC.has(food.source)) {
          const group = generic.assignment.get(key)!;
          canonicalKey = group.key; canonicalId = id("generic", `${group.key}|${group.leader}`); method = group.members.length > 1 ? group.method : "singleton_generic_record";
          reasons = group.members.length > 1 ? [group.key.startsWith("exact:") ? "exact_normalized_name" : "curated_bilingual_identity", "preparation_state_preserved", "nutrition_similarity_guard_passed"] : ["no_safe_cross_source_match"];
          writeCanonical = group.leader === key && !genericWritten.has(canonicalId); foodType = "generic_food"; nameTr = group.nameTr; nameEn = group.nameEn;
          if (writeCanonical) genericWritten.add(canonicalId);
          if (group.members.length > 1 && group.leader !== key) {
            metrics.automatic_high_confidence_merge_count++;
            mergedCanonicalIds.add(canonicalId);
            if (metrics.correct_merge_examples.length < 30) metrics.correct_merge_examples.push({ canonical_id: canonicalId, left: group.representative, right: item, method, reasons });
          }
        } else {
          foodType = "branded_product"; const barcode = validGtin(food.barcode) ? String(food.barcode) : undefined;
          if (barcode) {
            canonicalKey = `gtin:${barcode}`; canonicalId = id("branded_gtin", barcode); method = "exact_valid_gtin"; reasons = ["valid_gtin_checksum", "exact_barcode_equality"];
            const usdaOwner = usdaBarcodeOwners.get(barcode);
            const priorOff = food.source === "open_food_facts" && offCanonicalGtins.has(barcode);
            writeCanonical = food.source === "usda_branded" ? usdaOwner === String(food.source_id) : !usdaOwner && !priorOff;
            const merged = food.source === "usda_branded" ? usdaOwner !== String(food.source_id) : Boolean(usdaOwner) || priorOff;
            if (food.source === "open_food_facts" && !usdaOwner) offCanonicalGtins.add(barcode);
            if (merged) {
              metrics.automatic_high_confidence_merge_count++; metrics.barcode_merged_branded_product_count++;
              mergedCanonicalIds.add(canonicalId);
              if (usdaOwner && isTurkish(food)) trEnCanonicalIds.add(canonicalId);
              if (metrics.correct_merge_examples.length < 30) metrics.correct_merge_examples.push({ canonical_id: canonicalId, left: { source: "usda_branded", source_id: usdaOwner, barcode }, right: item, method, reasons });
            }
          } else {
            canonicalKey = `source:${key}`; canonicalId = id("source_record", key); method = "singleton_no_safe_identity"; reasons = ["missing_or_invalid_gtin", "name_or_brand_similarity_not_sufficient"]; writeCanonical = true;
          }
          const validBarcode = validGtin(food.barcode) ? String(food.barcode) : undefined;
          nameTr = isTurkish(food) ? food.display_name : (food.source === "usda_branded" && validBarcode ? offTurkeyNames.get(validBarcode) : undefined);
          nameEn = isEnglish(food) ? food.display_name : undefined;
          const identity = `${food.normalized_brand ?? ""}|${food.normalized_name}`;
          const first = brandedIdentityFirst.get(identity);
          if (first && first.barcode !== item.barcode && (brandedReviewEmitted.get(identity) ?? 0) < REVIEW_LIMIT_PER_KEY) {
            await writeReview(first, item, "same_brand_and_name_different_barcode", ["same_normalized_brand", "same_normalized_product_name", "different_or_invalid_gtin", "barcode_conflict_prevents_automatic_merge"]);
            brandedReviewEmitted.set(identity, (brandedReviewEmitted.get(identity) ?? 0) + 1);
          } else if (!first) brandedIdentityFirst.set(identity, item);
          if (item.normalized_brand) {
            const sameBrand = brandFirst.get(item.normalized_brand);
            if (sameBrand && sameBrand.normalized_name !== item.normalized_name && metrics.non_merge_examples.length < 30) metrics.non_merge_examples.push({ left: sameBrand, right: item, reason: "same_brand_alone_is_not_product_identity" });
            else if (!sameBrand) brandFirst.set(item.normalized_brand, item);
          }
        }
        if (writeCanonical) {
          await writeLine(foodsWriter.stream, { canonical_schema_version: CANONICALIZATION_SCHEMA_VERSION, canonical_id: canonicalId, ...(nameTr ? { canonical_name_tr: nameTr } : {}), ...(nameEn ? { canonical_name_en: nameEn } : {}), normalized_key: canonicalKey, food_type: foodType, ...(preparation(canonicalKey) ? { preparation: preparation(canonicalKey) } : {}), ...(food.category?.name ? { category: food.category.name } : {}), representative_source: food.source, representative_source_id: String(food.source_id) });
          metrics.canonical_food_count++;
          if (nameTr && nameEn) trEnCanonicalIds.add(canonicalId);
        }
        const needsReview = false;
        const mapping = { canonical_schema_version: CANONICALIZATION_SCHEMA_VERSION, canonical_id: canonicalId, source: food.source, source_id: String(food.source_id), source_record_ordinal: sourceCount, match_method: method, confidence: "HIGH", match_reasons: reasons, canonical_match_confidence: "HIGH", canonical_match_method: method, canonical_match_reasons: reasons, needs_canonical_review: needsReview };
        await writeLine(mappingsWriter.stream, mapping);
        metrics.match_method_distribution[method] = (metrics.match_method_distribution[method] ?? 0) + 1;
        if (sourceCount % 100000 === 0) process.stderr.write(`  ${slug}: ${sourceCount.toLocaleString()}\n`);
  }
  metrics.unmerged_record_count = metrics.canonical_food_count - mergedCanonicalIds.size;
  metrics.tr_en_canonical_match_count = trEnCanonicalIds.size;
      metrics.per_source[slug] = sourceCount;
    }
    await Promise.all([foodsWriter.finish(), mappingsWriter.finish(), reviewWriter.finish()]);
  } catch (error) { await Promise.all([foodsWriter.abort(), mappingsWriter.abort(), reviewWriter.abort()]); throw error; }
  await fs.writeFile(METRICS, `${JSON.stringify(metrics, null, 2)}\n`);
  let report = `# Canonicalization Report\n\nGenerated: ${metrics.generated_at}\n\nThis stage is deliberately conservative. Every source record receives a reversible mapping. Branded products are automatically merged only by an identical checksum-valid GTIN. Generic foods require an exact normalized or curated bilingual identity, preserved preparation/state, different source, and compatible macro profile.\n\n## Metrics\n\n| Metric | Count |\n|---|---:|\n| Total source records | ${metrics.total_source_records.toLocaleString()} |\n| Canonical foods | ${metrics.canonical_food_count.toLocaleString()} |\n| Automatic high-confidence merges | ${metrics.automatic_high_confidence_merge_count.toLocaleString()} |\n| Review candidates | ${metrics.review_candidate_count.toLocaleString()} |\n| Unmerged singleton records | ${metrics.unmerged_record_count.toLocaleString()} |\n| TR ↔ EN canonical matches | ${metrics.tr_en_canonical_match_count.toLocaleString()} |\n| Barcode-merged branded mappings | ${metrics.barcode_merged_branded_product_count.toLocaleString()} |\n\n## Match methods\n\n| Method | Mappings |\n|---|---:|\n`;
  for (const [method, count] of Object.entries(metrics.match_method_distribution).sort((a: any, b: any) => b[1] - a[1])) report += `| ${method} | ${(count as number).toLocaleString()} |\n`;
  report += `\n## Important decisions\n\n- Canonical IDs are SHA-256-derived deterministic identifiers; reruns with unchanged inputs are stable.\n- Same brand or similar name never triggers an automatic branded merge.\n- A checksum-invalid barcode is not treated as identity.\n- Preparation/state remains in the generic semantic key (raw, boiled, fried, cooked, white/yolk, whole/skim).\n- Nutrition is only a compatibility guard; it is never averaged or rewritten.\n- Review candidates are capped at ${REVIEW_LIMIT_PER_KEY} per repeated branded identity key to prevent a single noisy product family from exploding the file.\n- Medium candidates are never added to automatic source mappings; each source remains a high-confidence singleton until reviewed.\n\n`;
  const pairTable = (title: string, items: any[], reasonField: string) => { let out = `## ${title}\n\n| # | Left | Right | Method / reason |\n|---:|---|---|---|\n`; items.slice(0, 30).forEach((x: any, index: number) => { const left = x.left ?? x.representative, right = x.right; out += `| ${index + 1} | ${md(left?.source)}/${md(left?.source_id)} — ${md(left?.name)} | ${md(right?.source)}/${md(right?.source_id)} — ${md(right?.name)} | ${md(x[reasonField] ?? x.canonical_match_reasons?.join(", "))} |\n`; }); return `${out}\n`; };
  report += pairTable("30 correct automatic merge examples", metrics.correct_merge_examples, "method");
  report += pairTable("30 examples that must not be merged", metrics.non_merge_examples, "reason");
  report += pairTable("30 review-required suspicious examples", metrics.review_examples, "canonical_match_method");
  await fs.writeFile(REPORT, report);
  console.error(`Canonicalized ${metrics.total_source_records.toLocaleString()} mappings into ${metrics.canonical_food_count.toLocaleString()} canonical foods.`);
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
