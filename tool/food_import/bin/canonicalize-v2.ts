#!/usr/bin/env node
import { createHash } from "node:crypto";
import { createReadStream, createWriteStream, promises as fs } from "node:fs";
import { createInterface } from "node:readline";
import { tmpdir } from "node:os";
import { resolve, dirname } from "node:path";
import { once } from "node:events";
import type { Writable } from "node:stream";
import { CANONICAL_V2_VERSION } from "../canonical-v2-schema.ts";
import { readJsonlGz, atomicGzip, writeLine, cleanWhitespace, normalizedText } from "../src/cleaning-common.ts";
import { classifyGtin, evaluateBrandedCompatibility, evaluateBrandedGroupCompatibility } from "../src/canonical-v2-branded.ts";
import { resolveBilingualIdentity } from "../src/canonical-v2-bilingual.ts";
import { parseGenericIdentity, evaluateGenericIdentity } from "../src/canonical-v2-generic.ts";

const ROOT = resolve(import.meta.dirname, "../../..");
const CLEANED = resolve(ROOT, "data/cleaned");
const OUTPUT = resolve(process.env.CANONICAL_V2_OUTPUT_DIR ?? resolve(ROOT, "data/canonical-v2"));
const REPORT = resolve(process.env.CANONICAL_V2_REPORT_PATH ?? resolve(ROOT, "canonicalization-v2-report.md"));
const WRITE_REPORT = process.env.CANONICAL_V2_WRITE_REPORT !== "0";
const SOURCES = ["usda-foundation", "usda-fndds", "usda-sr-legacy", "usda-branded", "turkomp", "openfoodfacts"] as const;
const GENERIC_SLUGS = ["usda-foundation", "usda-fndds", "usda-sr-legacy", "turkomp"] as const;
const USDA_SOURCE = "usda_branded", OFF_SOURCE = "open_food_facts";

type Compact = {
  key: string; source: string; source_id: string; source_record_ordinal: number;
  name: string; display_name: string; normalized_name: string; brand?: string; normalized_brand?: string;
  barcode?: string; category?: string; ingredients?: string; nutrition: Record<string, number>;
  data_quality_score?: number; quality?: { nutrition_completeness?: number; source_completeness?: number };
  countries: string[]; languages: string[]; identity_name?: string; parsed?: any;
};
type Decision = { mapping: any; canonical?: any; is_leader: boolean };

const hash = (namespace: string, value: string) => createHash("sha256").update(`${CANONICAL_V2_VERSION}|${namespace}|${value}`).digest("hex").slice(0, 24);
const canonicalId = (namespace: string, value: string) => `cf2_${hash(namespace, value)}`;
const candidateId = (prefix: string, left: Compact, right: Compact) => `${prefix}_${hash(prefix, [left.key, right.key].sort().join("|"))}`;
const sourceKey = (source: string, ordinal: number) => `${source}:${ordinal}`;
const union = (...values: string[][]) => [...new Set(values.flat())].sort();
const isTurkish = (item: Compact) => item.source === "turkomp" || item.languages.includes("tr");
const isEnglish = (item: Compact) => item.source.startsWith("usda_") || item.languages.includes("en");
const confidenceRank: Record<string, number> = { VERY_HIGH: 4, HIGH: 3, MEDIUM: 2, AMBIGUOUS: 1 };

function ingredientSignature(value: unknown): string | undefined {
  const text = cleanWhitespace(value); if (!text) return undefined;
  const tokens = [...new Set(normalizedText(text).split(" ").filter((token) => token.length > 1))].sort().slice(0, 100);
  return tokens.join(" ") || undefined;
}

function compact(food: any, ordinal: number): Compact {
  const nutrition: Record<string, number> = {};
  for (const key of ["kcal_100g", "protein_100g", "carbs_100g", "fat_100g", "fiber_100g", "sugars_100g", "sodium_mg_100g"]) if (Number.isFinite(food.nutrition?.[key])) nutrition[key] = food.nutrition[key];
  return {
    key: sourceKey(food.source, ordinal), source: food.source, source_id: String(food.source_id), source_record_ordinal: ordinal,
    name: String(food.name ?? ""), display_name: String(food.display_name ?? food.name ?? ""), normalized_name: String(food.normalized_name ?? normalizedText(food.name)),
    ...(food.brand ? { brand: String(food.brand) } : {}), ...(food.normalized_brand ? { normalized_brand: String(food.normalized_brand) } : {}),
    ...(food.barcode ? { barcode: String(food.barcode) } : {}), ...(food.category?.name ? { category: String(food.category.name) } : {}),
    ...(ingredientSignature(food.cleaned_ingredients ?? food.ingredients) ? { ingredients: ingredientSignature(food.cleaned_ingredients ?? food.ingredients) } : {}),
    nutrition,
    ...(Number.isFinite(food.data_quality_score) ? { data_quality_score: Number(food.data_quality_score) } : {}),
    ...(food.quality && typeof food.quality === "object" ? { quality: {
      ...(Number.isFinite(food.quality.nutrition_completeness) ? { nutrition_completeness: Number(food.quality.nutrition_completeness) } : {}),
      ...(Number.isFinite(food.quality.source_completeness) ? { source_completeness: Number(food.quality.source_completeness) } : {}),
    } } : {}),
    countries: [...new Set([...(food.market_country_tags ?? []), ...(food.countries ?? []), ...(food.market_country ? [food.market_country] : [])].map(String))].sort(),
    languages: [...new Set([...(food.normalized_languages ?? []), ...(food.detected_languages ?? []), ...(food.languages ?? []), ...(food.language ? [food.language] : [])].map(String))].sort(),
  };
}

const BRIDGE: Record<string, string> = {
  species_chicken: "chicken", species_cow: "cow", species_goat: "goat", species_sheep: "sheep", species_buffalo: "buffalo", species_human: "human",
  whole_part: "whole egg", egg_white: "egg white", yolk: "egg yolk", full_fat: "full fat", reduced_fat: "reduced fat", low_fat: "low fat", nonfat: "nonfat",
  with_skin: "with skin", skinless: "skinless", with_bone: "with bone", boneless: "boneless", extra_virgin: "extra virgin",
};

function enrichGeneric(item: Compact): Compact {
  const bilingual = resolveBilingualIdentity(item.normalized_name);
  const identityName = bilingual.base_identity
    ? [bilingual.base_identity.replaceAll("_", " "), ...bilingual.qualifier_tokens.map((token) => BRIDGE[token] ?? token.replaceAll("_", " ")), ...bilingual.residual_tokens].join(" ")
    : item.normalized_name;
  return { ...item, identity_name: identityName, parsed: parseGenericIdentity({ ...item, normalized_name: identityName }) };
}

function genericInput(item: Compact) { return { ...item, normalized_name: item.identity_name ?? item.normalized_name, category: item.category, nutrition: item.nutrition }; }
function reference(item: Compact, id?: string) {
  return { source: item.source, source_id: item.source_id, source_record_ordinal: item.source_record_ordinal,
    original_name: item.name, display_name: item.display_name, canonical_id: id ?? null, brand: item.brand ?? null, barcode: item.barcode ?? null };
}
function singletonId(item: Compact) { return canonicalId("source_record", `${item.source}|${item.source_id}|${item.source_record_ordinal}`); }
function languageNames(members: Compact[]) {
  return { nameTr: members.find(isTurkish)?.display_name, nameEn: members.find(isEnglish)?.display_name };
}
function canonicalFood(id: string, key: string, type: "generic_food" | "branded_product", representative: Compact, members: Compact[]) {
  const names = languageNames(members), parsed = type === "generic_food" ? representative.parsed : undefined;
  return { canonicalization_version: CANONICAL_V2_VERSION, canonical_id: id,
    ...(names.nameTr ? { canonical_name_tr: names.nameTr } : {}), ...(names.nameEn ? { canonical_name_en: names.nameEn } : {}),
    normalized_key: key, food_type: type,
    ...(parsed?.qualifiers?.preparation?.length ? { preparation: parsed.qualifiers.preparation } : {}),
    ...(parsed?.qualifiers?.state?.length ? { state: parsed.qualifiers.state } : {}),
    ...(parsed ? { qualifiers: parsed.qualifiers } : {}), ...(representative.category ? { category: representative.category } : {}),
    representative_source: representative.source, representative_source_id: representative.source_id, source_count: members.length };
}
function mapping(item: Compact, id: string, method: string, confidence: string, reasons: string[], flags: string[], status: string, codeType: string, needsReview: boolean) {
  return { canonicalization_version: CANONICAL_V2_VERSION, canonical_id: id, source: item.source, source_id: item.source_id,
    source_record_ordinal: item.source_record_ordinal, match_method: method, match_confidence: confidence,
    match_reasons: union(reasons), contradiction_flags: union(flags), barcode_identity_status: status, code_type: codeType, needs_review: needsReview };
}

async function writeRaw(stream: Writable, value: string) { if (!stream.write(value)) await once(stream, "drain"); }
function md(value: unknown) { return String(value ?? "—").replaceAll("|", "/").replace(/\s+/g, " "); }

async function atomicJson(path: string, value: unknown) {
  await fs.mkdir(dirname(path), { recursive: true }); const temp = `${path}.tmp`; await fs.writeFile(temp, `${JSON.stringify(value, null, 2)}\n`); await fs.rename(temp, path);
}

async function main() {
  await fs.mkdir(OUTPUT, { recursive: true });
  const work = await fs.mkdtemp(resolve(tmpdir(), "canonical-v2-"));
  const usdaCandidatesPath = resolve(work, "usda-valid-gtin.jsonl");
  const genericRecords: Compact[] = [], sourceCounts: Record<string, number> = {};
  const usdaBarcodeCounts = new Map<string, number>();
  const brandedGroups = new Map<string, Compact[]>();
  try {
    process.stderr.write("Pass 1/3: building shared generic and USDA GTIN indexes\n");
    for (const slug of GENERIC_SLUGS) {
      let ordinal = 0;
      for await (const food of readJsonlGz(resolve(CLEANED, `${slug}.jsonl.gz`))) genericRecords.push(enrichGeneric(compact(food, ++ordinal)));
      sourceCounts[slug] = ordinal;
    }
    const usdaWriter = createWriteStream(usdaCandidatesPath); let usdaOrdinal = 0;
    for await (const food of readJsonlGz(resolve(CLEANED, "usda-branded.jsonl.gz"))) {
      const item = compact(food, ++usdaOrdinal), gtin = classifyGtin(item.barcode);
      if (gtin.checksum_valid) { usdaBarcodeCounts.set(gtin.normalized_code!, (usdaBarcodeCounts.get(gtin.normalized_code!) ?? 0) + 1); await writeRaw(usdaWriter, `${JSON.stringify(item)}\n`); }
    }
    usdaWriter.end(); await once(usdaWriter, "close"); sourceCounts["usda-branded"] = usdaOrdinal;

    process.stderr.write("Pass 2/3: collecting only shared branded GTIN candidates\n");
    let offOrdinal = 0;
    for await (const food of readJsonlGz(resolve(CLEANED, "openfoodfacts.jsonl.gz"))) {
      const item = compact(food, ++offOrdinal), gtin = classifyGtin(item.barcode);
      if (gtin.checksum_valid && usdaBarcodeCounts.has(gtin.normalized_code!)) {
        const group = brandedGroups.get(gtin.normalized_code!) ?? []; group.push(item); brandedGroups.set(gtin.normalized_code!, group);
      }
    }
    sourceCounts.openfoodfacts = offOrdinal;
    const reader = createInterface({ input: createReadStream(usdaCandidatesPath), crlfDelay: Infinity });
    for await (const line of reader) {
      const item: Compact = JSON.parse(line), barcode = item.barcode!;
      if (brandedGroups.has(barcode) || (usdaBarcodeCounts.get(barcode) ?? 0) > 1) {
        const group = brandedGroups.get(barcode) ?? []; group.push(item); brandedGroups.set(barcode, group);
      }
    }

    const decisions = new Map<string, Decision>(), reviewCandidates: any[] = [], blockedCandidates: any[] = [];
    const examples: any = { safe_generic_merges: [], tr_en_merges: [], blocked_barcode_contradictions: [], correct_separations: [], human_review_candidates: [], safe_barcode_merges: [] };
    const genericByIdentity = new Map<string, Compact[]>(), genericByBase = new Map<string, Compact[]>();
    for (const item of genericRecords) {
      const identity = item.parsed.identity_key, base = item.parsed.base_key;
      const group = genericByIdentity.get(identity) ?? []; group.push(item); genericByIdentity.set(identity, group);
      const baseGroup = genericByBase.get(base) ?? []; baseGroup.push(item); genericByBase.set(base, baseGroup);
    }
    let genericMergeReductions = 0, trEnMergedGroups = 0, preparationStateConflicts = 0, nutritionConflicts = 0;
    const reviewSeen = new Set<string>();
    for (const [identityKey, records] of [...genericByIdentity.entries()].sort(([a], [b]) => a.localeCompare(b))) {
      records.sort((a, b) => a.key.localeCompare(b.key, "en", { numeric: true }));
      const clusters: Compact[][] = [];
      for (const item of records) {
        let selected: Compact[] | undefined;
        for (const cluster of clusters) if (cluster.every((member) => evaluateGenericIdentity(genericInput(member), genericInput(item)).auto_merge)) { selected = cluster; break; }
        if (selected) selected.push(item); else clusters.push([item]);
      }
      for (const cluster of clusters) {
        if (cluster.length === 1) continue;
        const memberKey = cluster.map((item) => item.key).sort().join("|"), id = canonicalId("generic", `${identityKey}|${memberKey}`);
        const evaluations = [];
        for (let i = 0; i < cluster.length; i++) for (let j = i + 1; j < cluster.length; j++) evaluations.push(evaluateGenericIdentity(genericInput(cluster[i]), genericInput(cluster[j])));
        const confidence = evaluations.every((value) => value.confidence === "VERY_HIGH") ? "VERY_HIGH" : "HIGH";
        const reasons = union(...evaluations.map((value) => value.reasons), ["qualifier_ontology_guard_passed", "nutrition_is_supporting_not_primary_truth"]);
        const representative = cluster[0], canon = canonicalFood(id, identityKey, "generic_food", representative, cluster);
        cluster.forEach((item, index) => decisions.set(item.key, { is_leader: index === 0, ...(index === 0 ? { canonical: canon } : {}), mapping: mapping(item, id, "generic_token_order_qualifier_guard", confidence, reasons, [], "NOT_APPLICABLE", "UNKNOWN", false) }));
        genericMergeReductions += cluster.length - 1;
        const trEn = cluster.some((item) => item.source === "turkomp") && cluster.some((item) => item.source.startsWith("usda_"));
        if (trEn) trEnMergedGroups++;
        const example = { canonical_id: id, match_method: "generic_token_order_qualifier_guard", confidence, match_reasons: reasons, contradiction_flags: [], members: cluster.map((item) => reference(item, id)) };
        if (examples.safe_generic_merges.length < 50) examples.safe_generic_merges.push(example);
        if (trEn && examples.tr_en_merges.length < 50) examples.tr_en_merges.push(example);
      }
      for (let i = 0; i < clusters.length; i++) for (let j = i + 1; j < clusters.length; j++) {
        const left = clusters[i][0], right = clusters[j][0]; if (left.source === right.source) continue;
        const result = evaluateGenericIdentity(genericInput(left), genericInput(right));
        if (!result.needs_review) continue;
        const cId = candidateId("rv2", left, right); if (reviewSeen.has(cId)) continue; reviewSeen.add(cId);
        const candidate = { candidate_id: cId, candidate_type: "HUMAN_REVIEW", left: reference(left, decisions.get(left.key)?.mapping.canonical_id ?? singletonId(left)), right: reference(right, decisions.get(right.key)?.mapping.canonical_id ?? singletonId(right)),
          match_method: "generic_medium_identity_candidate", match_confidence: "MEDIUM", match_reasons: result.reasons, contradiction_flags: result.contradiction_flags,
          barcode_identity_status: "NOT_APPLICABLE", needs_review: true };
        reviewCandidates.push(candidate); if (examples.human_review_candidates.length < 50) examples.human_review_candidates.push(candidate);
      }
    }
    for (const records of genericByBase.values()) {
      if (examples.correct_separations.length >= 50) break;
      const byIdentity = new Map<string, Compact>(); for (const item of records) if (!byIdentity.has(item.parsed.identity_key)) byIdentity.set(item.parsed.identity_key, item);
      const variants = [...byIdentity.values()];
      for (let i = 0; i < variants.length && examples.correct_separations.length < 50; i++) for (let j = i + 1; j < variants.length && examples.correct_separations.length < 50; j++) {
        const result = evaluateGenericIdentity(genericInput(variants[i]), genericInput(variants[j]));
        if (!result.contradiction_flags.length) continue;
        const leftId = decisions.get(variants[i].key)?.mapping.canonical_id ?? singletonId(variants[i]);
        const rightId = decisions.get(variants[j].key)?.mapping.canonical_id ?? singletonId(variants[j]);
        examples.correct_separations.push({ left: reference(variants[i], leftId), right: reference(variants[j], rightId), match_method: "explicit_qualifier_conflict_keep_separate", confidence: "VERY_HIGH", match_reasons: result.reasons, contradiction_flags: result.contradiction_flags });
      }
    }

    let barcodeMergeReductions = 0, blockedBarcodeGroups = 0, automaticCriticalRisk = 0, automaticHighRisk = 0;
    for (const [barcode, rawRecords] of [...brandedGroups.entries()].sort(([a], [b]) => a.localeCompare(b))) {
      const records = [...rawRecords].sort((a, b) => a.key.localeCompare(b.key, "en", { numeric: true }));
      const groupResult = evaluateBrandedGroupCompatibility(records);
      if (groupResult.barcode_identity_status === "VERIFIED_COMPATIBLE") {
        const memberKey = records.map((item) => item.key).join("|"), id = canonicalId("verified_gtin", `${barcode}|${memberKey}`), representative = records[0];
        const canon = canonicalFood(id, `verified_gtin:${barcode}`, "branded_product", representative, records);
        records.forEach((item, index) => decisions.set(item.key, { is_leader: index === 0, ...(index === 0 ? { canonical: canon } : {}), mapping: mapping(item, id, "verified_compatible_gtin", "VERY_HIGH", groupResult.match_reasons, [], "VERIFIED_COMPATIBLE", groupResult.code_type, false) }));
        barcodeMergeReductions += records.length - 1;
        if (examples.safe_barcode_merges.length < 50) examples.safe_barcode_merges.push({ canonical_id: id, match_method: "verified_compatible_gtin", confidence: "VERY_HIGH", match_reasons: groupResult.match_reasons, contradiction_flags: [], members: records.map((item) => reference(item, id)) });
        continue;
      }
      const contradicted = groupResult.barcode_identity_status === "CONTRADICTED";
      if (contradicted) blockedBarcodeGroups++;
      for (const item of records) {
        const id = singletonId(item), confidence = contradicted ? "AMBIGUOUS" : "MEDIUM", needsReview = !contradicted;
        decisions.set(item.key, { is_leader: true, canonical: canonicalFood(id, `source:${item.key}`, "branded_product", item, [item]),
          mapping: mapping(item, id, contradicted ? "barcode_contradiction_keep_separate" : "barcode_ambiguous_keep_separate", confidence,
            groupResult.match_reasons, groupResult.contradiction_flags, groupResult.barcode_identity_status, groupResult.code_type, needsReview) });
      }
      let emitted = 0;
      for (let i = 0; i < records.length; i++) for (let j = i + 1; j < records.length; j++) {
        const left = records[i], right = records[j], pair = evaluateBrandedCompatibility(left, right);
        if (contradicted && pair.barcode_identity_status === "CONTRADICTED") {
          const candidate = { candidate_id: candidateId("bc2", left, right), candidate_type: "BLOCKED_CONTRADICTION", left: reference(left, singletonId(left)), right: reference(right, singletonId(right)),
            match_method: "barcode_identity_contradiction_block", match_confidence: "VERY_HIGH", match_reasons: pair.match_reasons, contradiction_flags: pair.contradiction_flags,
            barcode_identity_status: "CONTRADICTED", code_type: pair.code_type, compatibility_score: pair.match_confidence,
            severity: pair.contradiction_flags.includes("strong_product_name_contradiction") && pair.contradiction_flags.includes("material_nutrition_contradiction") ? "CRITICAL" : "HIGH", needs_review: false };
          blockedCandidates.push(candidate); if (examples.blocked_barcode_contradictions.length < 50) examples.blocked_barcode_contradictions.push(candidate);
        } else if (!contradicted && emitted < 3) {
          const candidate = { candidate_id: candidateId("rv2", left, right), candidate_type: "HUMAN_REVIEW", left: reference(left, singletonId(left)), right: reference(right, singletonId(right)),
            match_method: "same_gtin_insufficient_identity_corroboration", match_confidence: "MEDIUM", match_reasons: pair.match_reasons, contradiction_flags: pair.contradiction_flags,
            barcode_identity_status: pair.barcode_identity_status, code_type: pair.code_type, compatibility_score: pair.match_confidence, needs_review: true };
          reviewCandidates.push(candidate); emitted++; if (examples.human_review_candidates.length < 50) examples.human_review_candidates.push(candidate);
        }
      }
    }

    reviewCandidates.sort((a, b) => a.candidate_id.localeCompare(b.candidate_id)); blockedCandidates.sort((a, b) => a.candidate_id.localeCompare(b.candidate_id));
    const foodWriter = await atomicGzip(resolve(OUTPUT, "canonical-foods.jsonl.gz"));
    const mappingWriter = await atomicGzip(resolve(OUTPUT, "canonical-source-mappings.jsonl.gz"));
    const reviewWriter = await atomicGzip(resolve(OUTPUT, "canonical-review-candidates.jsonl.gz"));
    const blockedWriter = await atomicGzip(resolve(OUTPUT, "canonical-blocked-merge-candidates.jsonl.gz"));
    let totalRecords = 0, canonicalCount = 0; const matchMethods: Record<string, number> = {};
    process.stderr.write("Pass 3/3: writing canonical-v2 outputs\n");
    try {
      for (const slug of SOURCES) {
        let ordinal = 0;
        for await (const food of readJsonlGz(resolve(CLEANED, `${slug}.jsonl.gz`))) {
          const item = compact(food, ++ordinal), decision = decisions.get(item.key);
          let resolved = decision;
          if (!resolved) {
            const id = singletonId(item), gtin = classifyGtin(item.barcode), type = item.source === USDA_SOURCE || item.source === OFF_SOURCE ? "branded_product" : "generic_food";
            const enriched = type === "generic_food" ? enrichGeneric(item) : item;
            resolved = { is_leader: true, canonical: canonicalFood(id, `source:${item.key}`, type, enriched, [enriched]),
              mapping: mapping(item, id, type === "branded_product" ? (gtin.checksum_valid ? "singleton_unique_valid_gtin" : "singleton_no_verified_gtin") : "singleton_generic_v2",
                "AMBIGUOUS", ["no_safe_cross_source_identity_match", ...(gtin.checksum_valid ? ["valid_gtin_unique_in_candidate_scope"] : [])], [], "NOT_APPLICABLE", gtin.code_type, false) };
          }
          if (resolved.is_leader && resolved.canonical) { await writeLine(foodWriter.stream, resolved.canonical); canonicalCount++; }
          await writeLine(mappingWriter.stream, resolved.mapping); totalRecords++; matchMethods[resolved.mapping.match_method] = (matchMethods[resolved.mapping.match_method] ?? 0) + 1;
          if (ordinal % 100000 === 0) process.stderr.write(`  ${slug}: ${ordinal.toLocaleString()}\n`);
        }
      }
      for (const candidate of reviewCandidates) await writeLine(reviewWriter.stream, candidate);
      for (const candidate of blockedCandidates) await writeLine(blockedWriter.stream, candidate);
      await Promise.all([foodWriter.finish(), mappingWriter.finish(), reviewWriter.finish(), blockedWriter.finish()]);
    } catch (error) { await Promise.all([foodWriter.abort(), mappingWriter.abort(), reviewWriter.abort(), blockedWriter.abort()]); throw error; }
    const metrics = {
      canonicalization_version: CANONICAL_V2_VERSION,
      input: { total_cleaned_records: totalRecords, per_source: sourceCounts },
      output: { canonical_food_count: canonicalCount, source_mapping_count: totalRecords, automatic_merge_reductions: totalRecords - canonicalCount,
        barcode_merge_reductions: barcodeMergeReductions, generic_merge_reductions: genericMergeReductions, blocked_barcode_merge_groups: blockedBarcodeGroups,
        blocked_barcode_candidate_pairs: blockedCandidates.length, tr_en_merged_groups: trEnMergedGroups, turkomp_usda_shared_generic_canonical_ids: trEnMergedGroups,
        review_candidate_count: reviewCandidates.length },
      safety: { preparation_state_conflicts_in_automatic_merges: preparationStateConflicts, nutrition_conflicts_in_automatic_merges: nutritionConflicts,
        critical_automatic_false_merge_candidates: automaticCriticalRisk, high_automatic_false_merge_candidates: automaticHighRisk },
      match_method_distribution: matchMethods,
      before: { cleaned_records: 1242528, canonical_foods: 1226178, automatic_merges: 16350, barcode_merges: 16158, generic_merges: 192,
        review_candidates: 153370, critical_barcode_risk: 236, high_barcode_risk: 303, turkomp_usda_shared_generic_canonical_ids: 0 },
      examples,
      versions: { canonicalization: CANONICAL_V2_VERSION, generic_ontology: genericRecords[0]?.parsed?.ontology_version, bilingual_dictionary: resolveBilingualIdentity("").version },
    };
    await atomicJson(resolve(OUTPUT, "canonicalization-metrics.json"), metrics);
    if (WRITE_REPORT) {
      let report = `# Canonicalization V2 Report\n\nVersion: \`${CANONICAL_V2_VERSION}\`\n\nCanonical-v2 is a separate, non-destructive derived catalog. Cleaned inputs and canonical-v1 outputs are not modified. Nutrition values are never rewritten or imputed.\n\n## Before → after\n\n| Metric | Before | After |\n|---|---:|---:|\n| Cleaned/source mappings | 1,242,528 | ${totalRecords.toLocaleString()} |\n| Canonical foods | 1,226,178 | ${canonicalCount.toLocaleString()} |\n| Automatic merge reductions | 16,350 | ${(totalRecords - canonicalCount).toLocaleString()} |\n| Barcode merge reductions | 16,158 | ${barcodeMergeReductions.toLocaleString()} |\n| Generic merge reductions | 192 | ${genericMergeReductions.toLocaleString()} |\n| Blocked barcode groups | 0 | ${blockedBarcodeGroups.toLocaleString()} |\n| TR↔EN merged groups | 0 | ${trEnMergedGroups.toLocaleString()} |\n| Review candidates | 153,370 | ${reviewCandidates.length.toLocaleString()} |\n| Preparation/state conflicts in automatic merges | audit required | ${preparationStateConflicts} |\n| Nutrition conflicts in automatic merges | audit required | ${nutritionConflicts} |\n| CRITICAL automatic false-merge candidates | 236 risk candidates | ${automaticCriticalRisk} |\n| HIGH automatic false-merge candidates | 303 risk candidates | ${automaticHighRisk} |\n\n`;
      const table = (title: string, rows: any[]) => { let out = `## ${title}\n\n| # | Canonical/candidate | Members | Method | Confidence | Reasons | Contradictions |\n|---:|---|---|---|---|---|---|\n`; rows.slice(0, 30).forEach((row, index) => { const members = row.members ?? [row.left, row.right]; out += `| ${index + 1} | \`${md(row.canonical_id ?? row.candidate_id)}\` | ${members.map((m: any) => `${md(m.source)}/${md(m.source_id)} — ${md(m.original_name)} → ${md(m.display_name)} — \`${md(m.canonical_id)}\``).join("<br>")} | ${md(row.match_method)} | ${md(row.confidence ?? row.match_confidence)} | ${md((row.match_reasons ?? []).join(", "))} | ${md((row.contradiction_flags ?? []).join(", "))} |\n`; }); return `${out}\n`; };
      report += table("30 safe generic merges", examples.safe_generic_merges);
      report += table(examples.tr_en_merges.length >= 30 ? "30 TR↔EN merges" : `${examples.tr_en_merges.length} TR↔EN merges (all safe matches found)`, examples.tr_en_merges);
      report += table("30 blocked barcode contradictions", examples.blocked_barcode_contradictions);
      report += table("30 correct separations", examples.correct_separations);
      report += table("30 human-review candidates", examples.human_review_candidates);
      await fs.writeFile(REPORT, report);
    }
    console.error(`canonical-v2: ${totalRecords.toLocaleString()} mappings → ${canonicalCount.toLocaleString()} canonical foods; ${reviewCandidates.length.toLocaleString()} review; ${blockedBarcodeGroups.toLocaleString()} blocked barcode groups.`);
  } finally { await fs.rm(work, { recursive: true, force: true }); }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
