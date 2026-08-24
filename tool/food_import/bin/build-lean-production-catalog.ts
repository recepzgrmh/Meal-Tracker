#!/usr/bin/env node
import { createWriteStream } from "node:fs";
import { promises as fs } from "node:fs";
import { resolve } from "node:path";
import { createGzip } from "node:zlib";
import { once } from "node:events";
import { readJsonlGz, cleanWhitespace } from "../src/cleaning-common.ts";
import { classifyGtin } from "../src/canonical-v2-branded.ts";

const ROOT = resolve(import.meta.dirname, "../../..");
const CLEANED = resolve(ROOT, "data/cleaned");
const CANONICAL = resolve(ROOT, "data/canonical-v2");
const OUTPUT = resolve(ROOT, "data/lean-catalog");
const TARGET = Math.max(10_000, Number(process.env.LEAN_CATALOG_TARGET ?? 60_000));
const TR_TARGET = Math.max(0, Number(process.env.LEAN_TR_BRANDED_TARGET ?? 12_000));
const OFF_GLOBAL_TARGET = Math.max(0, Number(process.env.LEAN_OFF_GLOBAL_TARGET ?? 18_000));
const USDA_BRANDED_TARGET = Math.max(0, Number(process.env.LEAN_USDA_BRANDED_TARGET ?? 12_000));
const QUALITY_THRESHOLD = Math.max(0, Number(process.env.LEAN_BRANDED_QUALITY_THRESHOLD ?? 75));
const SOURCES = ["usda-foundation", "usda-fndds", "usda-sr-legacy", "usda-branded", "turkomp", "openfoodfacts"] as const;

type Candidate = {
  canonical_id: string;
  name: string;
  source: string;
  source_id: string;
  source_record_ordinal: number;
  quality: number;
  source_quality: number | null;
  turkey: number;
  english: number;
  has_off: boolean;
  has_usda_branded: boolean;
  barcode_valid: boolean;
  has_brand: boolean;
  has_serving: boolean;
  has_category: boolean;
  has_ingredients: boolean;
};

function present(value: unknown): boolean {
  return typeof value === "string" ? value.trim().length > 0 : value !== null && value !== undefined;
}

function completeMacros(food: any): boolean {
  return ["kcal_100g", "protein_100g", "carbs_100g", "fat_100g"]
    .every((key) => Number.isFinite(food.nutrition?.[key]) && food.nutrition[key] >= 0);
}

function portionAvailable(food: any): boolean {
  return (food.portions ?? []).some((portion: any) => Number.isFinite(portion.gram_weight) && portion.gram_weight > 0)
    || (Number.isFinite(food.serving_size) && food.serving_size > 0 && String(food.serving_unit ?? "").toLowerCase() === "g");
}

function textHasTurkish(value: unknown): boolean {
  return /[çğıöşüÇĞİÖŞÜ]/.test(String(value ?? ""));
}

function brandedScore(food: any, sourceRecordOrdinal: number): Candidate | null {
  const name = cleanWhitespace(food.display_name ?? food.name);
  if (!name || name.length < 3 || !completeMacros(food)) return null;
  const barcode = classifyGtin(food.barcode);
  const hasBrand = present(food.display_brand ?? food.brand);
  const serving = portionAvailable(food);
  const category = present(food.display_category ?? food.category?.name);
  const ingredients = present(food.cleaned_ingredients ?? food.ingredients);
  const sourceQuality = Number.isFinite(food.data_quality_score) ? Number(food.data_quality_score) : null;
  const quality = 45 + 5 + (barcode.checksum_valid ? 10 : 0) + (hasBrand ? 10 : 0) +
    (serving ? 8 : 0) + (category ? 7 : 0) + (ingredients ? 5 : 0) +
    (sourceQuality === null ? 0 : Math.min(10, Math.max(0, sourceQuality / 10)));
  if (quality < QUALITY_THRESHOLD) return null;

  const countries = [...(food.market_country_tags ?? []), ...(food.countries ?? [])].map(String);
  const languages = [...(food.normalized_languages ?? []), ...(food.detected_languages ?? []), ...(food.languages ?? [])].map(String);
  const barcodeText = String(barcode.normalized_code ?? food.barcode ?? "");
  const computedTurkey = (countries.some((value) => /(^|:)turk(ey|iye)$/i.test(value)) ? 40 : 0) +
    (barcodeText.startsWith("869") ? 30 : 0) + (languages.some((value) => /^tr([_-]|$)/i.test(value)) ? 20 : 0) +
    (textHasTurkish(name) || textHasTurkish(food.ingredients) ? 10 : 0);
  const computedEnglish = (languages.some((value) => /^en([_-]|$)/i.test(value)) ? 35 : 0) +
    (countries.some((value) => /united-states|united-kingdom|canada|australia|ireland/i.test(value)) ? 25 : 0) +
    (food.source === "usda_branded" ? 30 : 0) + (/^[\x00-\x7F]+$/.test(name) ? 10 : 0);

  return {
    canonical_id: "",
    name,
    source: String(food.source),
    source_id: String(food.source_id),
    source_record_ordinal: sourceRecordOrdinal,
    quality: Number(quality.toFixed(3)),
    source_quality: sourceQuality,
    turkey: Math.max(Number(food.turkey_relevance_score ?? 0), computedTurkey),
    english: Math.max(Number(food.english_relevance_score ?? 0), computedEnglish),
    has_off: food.source === "open_food_facts",
    has_usda_branded: food.source === "usda_branded",
    barcode_valid: barcode.checksum_valid,
    has_brand: hasBrand,
    has_serving: serving,
    has_category: category,
    has_ingredients: ingredients,
  };
}

function betterRepresentative(next: Candidate, current: Candidate): boolean {
  return next.quality > current.quality ||
    (next.quality === current.quality && next.source_quality !== null && (current.source_quality === null || next.source_quality > current.source_quality)) ||
    (next.quality === current.quality && next.source === current.source && next.source_id.localeCompare(current.source_id, "en") < 0);
}

function mergeCandidate(current: Candidate | undefined, next: Candidate): Candidate {
  if (!current) return next;
  const representative = betterRepresentative(next, current) ? next : current;
  return {
    ...representative,
    canonical_id: current.canonical_id,
    quality: Math.max(current.quality, next.quality),
    source_quality: Math.max(current.source_quality ?? -1, next.source_quality ?? -1) < 0 ? null : Math.max(current.source_quality ?? -1, next.source_quality ?? -1),
    turkey: Math.max(current.turkey, next.turkey),
    english: Math.max(current.english, next.english),
    has_off: current.has_off || next.has_off,
    has_usda_branded: current.has_usda_branded || next.has_usda_branded,
    barcode_valid: current.barcode_valid || next.barcode_valid,
    has_brand: current.has_brand || next.has_brand,
    has_serving: current.has_serving || next.has_serving,
    has_category: current.has_category || next.has_category,
    has_ingredients: current.has_ingredients || next.has_ingredients,
  };
}

function compareCandidates(a: Candidate, b: Candidate, relevance: "turkey" | "english" | "max"): number {
  const ar = relevance === "max" ? Math.max(a.turkey, a.english) : a[relevance];
  const br = relevance === "max" ? Math.max(b.turkey, b.english) : b[relevance];
  return b.quality - a.quality || br - ar || b.english - a.english || b.turkey - a.turkey || a.canonical_id.localeCompare(b.canonical_id, "en");
}

async function writeGzipJsonl(path: string, rows: any[]) {
  const temporary = `${path}.tmp-${process.pid}`;
  const gzip = createGzip({ level: 9, mtime: 0 } as any);
  const output = createWriteStream(temporary);
  gzip.pipe(output);
  for (const row of rows) if (!gzip.write(`${JSON.stringify(row)}\n`)) await once(gzip, "drain");
  gzip.end();
  await once(output, "close");
  await fs.rename(temporary, path);
}

async function main() {
  await fs.mkdir(OUTPUT, { recursive: true });
  const generic = new Map<string, Candidate>();
  const branded = new Map<string, Candidate>();
  const mappingIterator = readJsonlGz(resolve(CANONICAL, "canonical-source-mappings.jsonl.gz"))[Symbol.asyncIterator]();
  let inputRecords = 0;

  for (const slug of SOURCES) {
    let ordinal = 0;
    for await (const food of readJsonlGz(resolve(CLEANED, `${slug}.jsonl.gz`))) {
      ordinal++; inputRecords++;
      const nextMapping = await mappingIterator.next();
      if (nextMapping.done) throw new Error(`mapping stream ended at ${slug}:${ordinal}`);
      const mapping = nextMapping.value;
      if (mapping.source !== food.source || mapping.source_record_ordinal !== ordinal || String(mapping.source_id) !== String(food.source_id)) {
        throw new Error(`mapping/source misalignment at ${slug}:${ordinal}`);
      }
      const canonicalId = String(mapping.canonical_id);
      const isBranded = food.source === "usda_branded" || food.source === "open_food_facts";
      if (!isBranded) {
        if (!completeMacros(food)) continue;
        const name = cleanWhitespace(food.display_name ?? food.name) ?? `${food.source}:${food.source_id}`;
        const candidate: Candidate = { canonical_id: canonicalId, name, source: food.source, source_id: String(food.source_id), source_record_ordinal: ordinal, quality: 100,
          source_quality: null, turkey: food.source === "turkomp" ? 100 : 0, english: food.source === "turkomp" ? 0 : 100,
          has_off: false, has_usda_branded: false, barcode_valid: false, has_brand: false, has_serving: portionAvailable(food),
          has_category: present(food.display_category ?? food.category?.name), has_ingredients: false };
        generic.set(canonicalId, mergeCandidate(generic.get(canonicalId), candidate));
      } else {
        const candidate = brandedScore(food, ordinal);
        if (candidate) {
          candidate.canonical_id = canonicalId;
          branded.set(canonicalId, mergeCandidate(branded.get(canonicalId), candidate));
        }
      }
      if (ordinal % 100_000 === 0) process.stderr.write(`  ${slug}: ${ordinal.toLocaleString()}\n`);
    }
  }
  if (!(await mappingIterator.next()).done) throw new Error("mapping stream contains trailing records");

  const selected = new Map<string, { candidate: Candidate; tier: string; rank: number }>();
  const genericRows = [...generic.values()].sort((a, b) => a.canonical_id.localeCompare(b.canonical_id, "en"));
  for (const candidate of genericRows) selected.set(candidate.canonical_id, { candidate, tier: "generic_core", rank: selected.size + 1 });
  const remaining = () => Math.max(0, TARGET - selected.size);

  const tr = [...branded.values()].filter((candidate) => candidate.turkey >= 25).sort((a, b) => compareCandidates(a, b, "turkey"));
  for (const candidate of tr.slice(0, Math.min(TR_TARGET, remaining()))) selected.set(candidate.canonical_id, { candidate, tier: "tr_branded", rank: selected.size + 1 });

  const offGlobal = [...branded.values()].filter((candidate) => candidate.has_off && candidate.english >= 25 && !selected.has(candidate.canonical_id))
    .sort((a, b) => compareCandidates(a, b, "english"));
  for (const candidate of offGlobal.slice(0, Math.min(OFF_GLOBAL_TARGET, remaining()))) selected.set(candidate.canonical_id, { candidate, tier: "off_en_global", rank: selected.size + 1 });

  const usdaBranded = [...branded.values()].filter((candidate) => candidate.has_usda_branded && !selected.has(candidate.canonical_id))
    .sort((a, b) => compareCandidates(a, b, "english"));
  for (const candidate of usdaBranded.slice(0, Math.min(USDA_BRANDED_TARGET, remaining()))) selected.set(candidate.canonical_id, { candidate, tier: "usda_branded_quality", rank: selected.size + 1 });

  const global = [...branded.values()].filter((candidate) => !selected.has(candidate.canonical_id)).sort((a, b) => compareCandidates(a, b, "max"));
  for (const candidate of global.slice(0, remaining())) selected.set(candidate.canonical_id, { candidate, tier: "quality_global", rank: selected.size + 1 });

  const rows = [...selected.values()].map(({ candidate, tier, rank }) => ({
    canonical_id: candidate.canonical_id,
    tier,
    rank,
    name: candidate.name,
    representative_source: candidate.source,
    representative_source_id: candidate.source_id,
    representative_source_record_ordinal: candidate.source_record_ordinal,
    selection_score: candidate.quality,
    source_quality_score: candidate.source_quality,
    turkey_relevance_score: candidate.turkey,
    english_relevance_score: candidate.english,
    inclusion_reasons: [tier, "meaningful_name", ...(candidate.quality >= QUALITY_THRESHOLD ? ["quality_threshold_passed"] : []),
      ...(tier !== "generic_core" ? ["complete_core_macros"] : []), ...(candidate.barcode_valid ? ["valid_barcode"] : []),
      ...(candidate.has_brand ? ["brand_present"] : []), ...(candidate.has_serving ? ["serving_present"] : []), ...(candidate.has_category ? ["category_present"] : [])],
  }));
  await writeGzipJsonl(resolve(OUTPUT, "selected-canonical-foods.jsonl.gz"), rows);

  const tiers = Object.fromEntries([...new Set(rows.map((row) => row.tier))].sort().map((tier) => [tier, rows.filter((row) => row.tier === tier).length]));
  const projectedRows = { foods: rows.length, nutrition: rows.length, aliases: rows.length, portions: rows.length,
    branded_metadata: rows.length - (tiers.generic_core ?? 0) };
  const observedCanonicalBytesPerRow = 716 * 1024 * 1024 / 755_000;
  const baseBytes = projectedRows.foods * observedCanonicalBytesPerRow + projectedRows.nutrition * 500 + projectedRows.aliases * 800 +
    projectedRows.portions * 600 + projectedRows.branded_metadata * 900;
  const metrics = {
    schema_version: "lean-catalog-selection-v1",
    policy: { target: TARGET, tr_branded_target: TR_TARGET, off_global_target: OFF_GLOBAL_TARGET, usda_branded_target: USDA_BRANDED_TARGET, branded_quality_threshold: QUALITY_THRESHOLD },
    input: { source_records: inputRecords, generic_canonical_candidates: generic.size, eligible_branded_canonical_candidates: branded.size },
    output: { selected_canonical_foods: rows.length, tiers, projected_rows: projectedRows,
      projected_postgres_bytes_base: Math.round(baseBytes), projected_postgres_bytes_with_50_percent_safety: Math.round(baseBytes * 1.5) },
  };
  await fs.writeFile(resolve(OUTPUT, "lean-catalog-metrics.json"), `${JSON.stringify(metrics, null, 2)}\n`);
  console.log(JSON.stringify(metrics, null, 2));
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
