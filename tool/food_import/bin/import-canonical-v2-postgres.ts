#!/usr/bin/env node
import { createHash, randomBytes } from "node:crypto";
import { execFile } from "node:child_process";
import { promises as fs } from "node:fs";
import { homedir } from "node:os";
import { resolve } from "node:path";
import { promisify } from "node:util";
import pg from "pg";
import { from as copyFrom } from "pg-copy-streams";
import { readJsonlGz, normalizedText, cleanWhitespace } from "../src/cleaning-common.ts";
import { normalizeAndDedupePortions, scoreNutritionCandidate, DATABASE_CATALOG_POLICY_VERSION } from "../src/database-catalog-policy.ts";
import { classifyGtin } from "../src/canonical-v2-branded.ts";

const { Pool } = pg;
const execFileAsync = promisify(execFile);
const ROOT = resolve(import.meta.dirname, "../../..");
const CLEANED = resolve(ROOT, "data/cleaned");
const CANONICAL = resolve(ROOT, "data/canonical-v2");
const LEAN_MANIFEST = process.env.LEAN_CATALOG_MANIFEST
  ? resolve(ROOT, process.env.LEAN_CATALOG_MANIFEST)
  : null;
const LEAN_LIMIT = Math.max(0, Number(process.env.LEAN_IMPORT_LIMIT ?? 0));
const VERSION = process.env.CATALOG_VERSION ?? (LEAN_MANIFEST ? "canonical-v2-lean-60k" : "canonical-v2");
const SOURCES = ["usda-foundation", "usda-fndds", "usda-sr-legacy", "usda-branded", "turkomp", "openfoodfacts"] as const;
let EXPECTED = { foods: 1228891, records: 1242528, mappings: 1242528, reviews: 2469, blocked: 334 };
const CHUNK_SIZE = Math.max(500, Number(process.env.IMPORT_CHUNK_SIZE ?? 5000));

type LeanSelection = {
  canonical_id: string;
  representative_source: string;
  representative_source_id: string;
  representative_source_record_ordinal: number;
  tier: string;
  rank: number;
  inclusion_reasons?: string[];
};

let leanSelection: Map<string, LeanSelection> | null = null;

async function loadLeanSelection() {
  if (!LEAN_MANIFEST) return;
  const rows: LeanSelection[] = [];
  for await (const row of readJsonlGz(LEAN_MANIFEST)) rows.push(row as LeanSelection);
  rows.sort((a, b) => a.rank - b.rank || a.canonical_id.localeCompare(b.canonical_id, "en"));
  const limited = LEAN_LIMIT > 0 ? rows.slice(0, LEAN_LIMIT) : rows;
  leanSelection = new Map(limited.map((row) => [row.canonical_id, row]));
  if (leanSelection.size !== limited.length) throw new Error("lean manifest contains duplicate canonical_id values");
  for (const row of limited) {
    if (!row.representative_source || !row.representative_source_id || !Number.isInteger(row.representative_source_record_ordinal)) {
      throw new Error(`lean manifest is missing representative identity for ${row.canonical_id}`);
    }
  }
  EXPECTED = { foods: limited.length, records: limited.length, mappings: limited.length, reviews: 0, blocked: 0 };
}

async function validateLeanSelectionInputs() {
  if (!leanSelection) throw new Error("IMPORT_VALIDATE_INPUT_ONLY requires LEAN_CATALOG_MANIFEST");
  const canonicalFound = new Set<string>();
  for await (const food of readJsonlGz(resolve(CANONICAL, "canonical-foods.jsonl.gz"))) {
    if (leanSelection.has(String(food.canonical_id))) canonicalFound.add(String(food.canonical_id));
  }
  const representativeFound = new Set<string>();
  let coreMacrosComplete = 0;
  const mappingIterator = readJsonlGz(resolve(CANONICAL, "canonical-source-mappings.jsonl.gz"))[Symbol.asyncIterator]();
  for (const slug of SOURCES) {
    let ordinal = 0;
    for await (const food of readJsonlGz(resolve(CLEANED, `${slug}.jsonl.gz`))) {
      ordinal++;
      const next = await mappingIterator.next();
      if (next.done) throw new Error(`mapping stream ended at ${slug}:${ordinal}`);
      const mapping = next.value;
      if (mapping.source !== food.source || mapping.source_record_ordinal !== ordinal || String(mapping.source_id) !== String(food.source_id)) {
        throw new Error(`mapping/source misalignment at ${slug}:${ordinal}`);
      }
      const selected = leanSelection.get(String(mapping.canonical_id));
      if (!selected || selected.representative_source !== String(food.source) || selected.representative_source_id !== String(food.source_id) ||
          selected.representative_source_record_ordinal !== ordinal) continue;
      if (representativeFound.has(selected.canonical_id)) throw new Error(`multiple representative source records for ${selected.canonical_id}`);
      representativeFound.add(selected.canonical_id);
      const nutritionKeys = ["kcal_100g", "protein_100g", "carbs_100g", "fat_100g", "fiber_100g", "sugars_100g", "sodium_mg_100g"];
      if (!nutritionKeys.some((key) => Number.isFinite(food.nutrition?.[key]) && food.nutrition[key] >= 0)) {
        throw new Error(`representative source has no normalized nutrition for ${selected.canonical_id}`);
      }
      const complete = nutritionKeys.slice(0, 4).every((key) => Number.isFinite(food.nutrition?.[key]) && food.nutrition[key] >= 0);
      if (complete) coreMacrosComplete++;
      if (selected.tier !== "generic_core" && !complete) {
        throw new Error(`representative source is missing core macros for ${selected.canonical_id}`);
      }
    }
  }
  if (!(await mappingIterator.next()).done) throw new Error("mapping stream contains trailing records");
  const missingCanonical = [...leanSelection.keys()].filter((id) => !canonicalFound.has(id));
  const missingRepresentative = [...leanSelection.keys()].filter((id) => !representativeFound.has(id));
  if (missingCanonical.length || missingRepresentative.length) {
    throw new Error(`lean input validation failed: missing canonical=${missingCanonical.length}, representative=${missingRepresentative.length}`);
  }
  return { selected: leanSelection.size, canonical_found: canonicalFound.size, representative_found: representativeFound.size, core_macros_complete: coreMacrosComplete };
}

type Stage = {
  name: string;
  client: any;
  stream: any;
  columns: string[];
  count: number;
  getCopyError(): unknown;
  finishCopy(): Promise<void>;
  mergeAndCommit(): Promise<void>;
  abort(): Promise<void>;
};

const releaseId = deterministicUuid(`catalog-release|${VERSION}`);
const canonicalUuid = (canonicalId: string) => deterministicUuid(`${releaseId}|canonical|${canonicalId}`);
const sourceUuid = (source: string, ordinal: number) => deterministicUuid(`${releaseId}|source|${source}|${ordinal}`);
const nutritionUuid = (recordId: string) => deterministicUuid(`${releaseId}|nutrition|${recordId}`);

function deterministicUuid(value: string): string {
  const bytes = createHash("sha256").update(value).digest().subarray(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString("hex");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function copyValue(value: unknown): string {
  if (value === null || value === undefined) return "\\N";
  const raw = typeof value === "object" ? JSON.stringify(value) : String(value);
  return raw.replaceAll("\\", "\\\\").replaceAll("\t", "\\t").replaceAll("\n", "\\n").replaceAll("\r", "\\r");
}

function pgArray(values: unknown): string {
  const items = Array.isArray(values) ? values : [];
  return `{${items.map((value) => `"${String(value).replaceAll("\\", "\\\\").replaceAll('"', '\\"')}"`).join(",")}}`;
}

async function writeStage(stage: Stage, values: unknown[]) {
  if (values.length !== stage.columns.length) throw new Error(`${stage.name}: expected ${stage.columns.length} columns, received ${values.length}`);
  if (stage.getCopyError()) throw stage.getCopyError();
  if (!stage.stream.write(`${values.map(copyValue).join("\t")}\n`)) {
    await new Promise<void>((resolvePromise, reject) => {
      const cleanup = () => { stage.stream.off("drain", onDrain); stage.stream.off("error", onError); };
      const onDrain = () => { cleanup(); resolvePromise(); };
      const onError = (error: unknown) => { cleanup(); reject(error); };
      stage.stream.once("drain", onDrain);
      stage.stream.once("error", onError);
      if (stage.getCopyError()) { cleanup(); reject(stage.getCopyError()); }
    });
  }
  if (stage.getCopyError()) throw stage.getCopyError();
  stage.count++;
}

async function openStage(pool: any, name: string, target: string, columns: string[], conflict: string): Promise<Stage> {
  const client = await pool.connect();
  const temp = `stage_${name}_${process.pid}`;
  await client.query("begin");
  await client.query("set transaction read write");
  await client.query(`create temp table ${temp} (like public.${target} including defaults including identity) on commit drop`);
  const stream = client.query(copyFrom(`copy ${temp} (${columns.join(",")}) from stdin with (format text)`));
  let copyError: unknown;
  let closed = false;
  const onClientError = (error: unknown) => { copyError = error; };
  const releaseClient = () => { client.off("error", onClientError); client.release(); };
  client.on("error", onClientError);
  stream.on("error", (error: unknown) => { copyError = error; });
  return {
    name, client, stream, columns, count: 0,
    getCopyError() { return copyError; },
    async finishCopy() {
      if (copyError) throw copyError;
      await new Promise<void>((resolvePromise, reject) => {
        stream.once("finish", resolvePromise);
        stream.once("error", reject);
        stream.end();
      });
    },
    async mergeAndCommit() {
      await client.query(`insert into public.${target} (${columns.join(",")}) select ${columns.join(",")} from ${temp} ${conflict}`);
      await client.query("commit"); closed = true; releaseClient();
    },
    async abort() { if (closed) return; try { stream.destroy(); await client.query("rollback"); } finally { closed = true; releaseClient(); } },
  };
}

async function flushStages(stages: Record<string, Stage>, order: string[], totals: Record<string, number>) {
  await Promise.all(order.map((name) => stages[name].finishCopy()));
  for (const name of order) {
    await stages[name].mergeAndCommit();
    totals[name] = (totals[name] ?? 0) + stages[name].count;
  }
}

async function databaseConfig(): Promise<{ poolConfig: any; cleanup: () => Promise<void> }> {
  if (process.env.DATABASE_URL) return { poolConfig: { connectionString: process.env.DATABASE_URL, max: 10, options: "-c default_transaction_read_only=off" }, cleanup: async () => {} };
  const projectRef = (await fs.readFile(resolve(ROOT, "supabase/.temp/project-ref"), "utf8")).trim();
  const pooler = (await fs.readFile(resolve(ROOT, "supabase/.temp/pooler-url"), "utf8")).trim();
  let token = process.env.SUPABASE_ACCESS_TOKEN?.trim();
  if (!token) {
    try { token = (await fs.readFile(resolve(homedir(), ".supabase/access-token"), "utf8")).trim(); }
    catch { token = undefined; }
  }
  let role: string;
  let password: string;
  let cleanup = async () => {};
  if (token) {
    const response = await fetch(`https://api.supabase.com/v1/projects/${encodeURIComponent(projectRef)}/cli/login-role`, {
      method: "POST", headers: { authorization: `Bearer ${token}`, "content-type": "application/json" }, body: JSON.stringify({ read_only: false }),
    });
    if (!response.ok) throw new Error(`Could not create temporary Supabase database role: HTTP ${response.status}`);
    const login: any = await response.json();
    if (!login.role || !login.password) throw new Error("Supabase temporary database role response was incomplete");
    role = String(login.role);
    password = String(login.password);
  } else {
    role = `catalog_v2_import_${process.pid}_${Date.now()}`;
    password = randomBytes(32).toString("hex");
    const tables = [
      "catalog_v2_releases", "catalog_v2_source_records", "catalog_v2_canonical_foods",
      "catalog_v2_source_mappings", "catalog_v2_source_nutrition", "catalog_v2_food_nutrition",
      "catalog_v2_portions", "catalog_v2_aliases", "catalog_v2_branded_metadata",
      "catalog_v2_review_cases", "catalog_v2_blocked_matches",
    ].map((table) => `public.${table}`).join(", ");
    const expires = new Date(Date.now() + 12 * 60 * 60 * 1000).toISOString();
    const createSql = `create role ${role} login bypassrls password '${password}' valid until '${expires}'; ` +
      `grant connect, temporary on database postgres to ${role}; ` +
      `grant usage on schema public, extensions to ${role}; ` +
      `grant select, insert, update, delete on table ${tables} to ${role};`;
    await execFileAsync("supabase", ["db", "query", "--linked", createSql], { cwd: ROOT, maxBuffer: 1024 * 1024 });
    cleanup = async () => {
      const dropSql = `select pg_terminate_backend(pid) from pg_stat_activity where usename='${role}' and pid <> pg_backend_pid(); ` +
        `revoke connect, temporary on database postgres from ${role}; ` +
        `revoke usage on schema public, extensions from ${role}; ` +
        `revoke all privileges on table ${tables} from ${role}; ` +
        `drop role if exists ${role};`;
      await execFileAsync("supabase", ["db", "query", "--linked", dropSql], { cwd: ROOT, maxBuffer: 1024 * 1024 });
    };
  }
  const url = new URL(pooler);
  url.port = "5432";
  url.username = role.includes(".") ? role : `${role}.${projectRef}`;
  url.password = password;
  return { poolConfig: { connectionString: url.toString(), max: 10, ssl: { rejectUnauthorized: false }, options: "-c default_transaction_read_only=off" }, cleanup };
}

function recordLocale(food: any): string | null {
  const languages = [...(food.normalized_languages ?? []), ...(food.detected_languages ?? []), ...(food.languages ?? []), food.language]
    .filter(Boolean).map((value) => String(value).toLowerCase().split(/[-_]/)[0]);
  if (food.source === "turkomp" || languages.includes("tr")) return "tr-TR";
  if (String(food.source).startsWith("usda_") || languages.includes("en")) return "en-US";
  return null;
}

function categoryName(food: any): string | null {
  return cleanWhitespace(typeof food.category === "string" ? food.category : food.category?.name) ?? null;
}

function nutritionDetails(food: any) {
  const rows = Array.isArray(food.nutrition?.nutrients) ? food.nutrition.nutrients : [];
  const core = rows.filter((row: any) => /energy|enerji|protein|fat|yag|lipid|carbo|karbonhidrat|fiber|lif|sugar|seker|sodium|sodyum/i.test(String(row.name ?? row.source_key ?? "")));
  const map = (field: "min" | "max" | "median") => Object.fromEntries(core.filter((row: any) => Number.isFinite(row[field])).map((row: any) => [String(row.source_key ?? row.name), row[field]]));
  const derivations = [...new Set(core.map((row: any) => row.derivation_code).filter(Boolean))].sort();
  const measurements = [...new Set(core.map((row: any) => row.measurement_source).filter(Boolean))].sort();
  const dataPoints = core.reduce((sum: number, row: any) => sum + (Number.isFinite(row.data_points) ? Number(row.data_points) : 0), 0);
  return { rows, coreCount: core.length, min: map("min"), max: map("max"), median: map("median"), derivations, measurements, dataPoints };
}

function sourceAliases(food: any): Array<{ alias: string; normalized: string; type: string; priority: number }> {
  const candidates: Array<[unknown, string, number]> = [
    [food.display_name ?? food.name, "source_name", 90], [food.original_name, "source_name", 80],
    [food.normalized_name, "search_alias", 70],
    ...[...(food.search_aliases ?? []), ...(food.cleaned_aliases ?? [])].map((value) => [value, "search_alias", 60] as [unknown, string, number]),
  ];
  const output = new Map<string, { alias: string; normalized: string; type: string; priority: number }>();
  for (const [raw, type, priority] of candidates) {
    const alias = cleanWhitespace(raw), normalized = normalizedText(alias);
    if (!alias || normalized.length < 2) continue;
    const key = `${normalized}|${type}`;
    const existing = output.get(key); if (!existing || priority > existing.priority) output.set(key, { alias, normalized, type, priority });
  }
  return [...output.values()].sort((a, b) => a.normalized.localeCompare(b.normalized, "en") || b.priority - a.priority);
}

async function loadCanonicalFoods(pool: any) {
  const columns = ["id", "release_id", "canonical_id", "canonical_key", "food_type", "canonical_name", "canonical_name_tr", "canonical_name_en", "category", "preparation", "qualifier_identity", "status", "confidence", "representative_source_record_id", "metadata"];
  const open = () => openStage(pool, "foods", "catalog_v2_canonical_foods", columns, "on conflict (release_id, canonical_id) do nothing");
  const existingRows = await pool.query("select canonical_id from public.catalog_v2_canonical_foods where release_id=$1", [releaseId]);
  const existing = new Set(existingRows.rows.map((row: any) => row.canonical_id));
  let stage: Stage | null = null, scanned = 0, total = 0, inserted = 0;
  try {
    for await (const food of readJsonlGz(resolve(CANONICAL, "canonical-foods.jsonl.gz"))) {
      scanned++;
      if (leanSelection && !leanSelection.has(food.canonical_id)) continue;
      total++;
      if (existing.has(food.canonical_id)) continue;
      stage ??= await open();
      const display = cleanWhitespace(food.canonical_name_tr ?? food.canonical_name_en) ?? food.canonical_id;
      await writeStage(stage, [canonicalUuid(food.canonical_id), releaseId, food.canonical_id, food.normalized_key, food.food_type, display,
        food.canonical_name_tr, food.canonical_name_en, food.category, Array.isArray(food.preparation) ? food.preparation.join("|") : food.preparation,
        food.qualifiers ?? {}, "candidate", food.source_count > 1 ? "HIGH" : "AMBIGUOUS", null,
        { canonicalization_version: food.canonicalization_version, representative_source: food.representative_source, representative_source_id: food.representative_source_id, source_count: food.source_count,
          ...(leanSelection ? { lean_tier: leanSelection.get(food.canonical_id)?.tier, lean_rank: leanSelection.get(food.canonical_id)?.rank, inclusion_reasons: leanSelection.get(food.canonical_id)?.inclusion_reasons ?? [] } : {}) }]);
      if (stage.count >= CHUNK_SIZE) {
        await stage.finishCopy(); await stage.mergeAndCommit(); inserted += stage.count;
        process.stderr.write(`  canonical foods committed: ${(existing.size + inserted).toLocaleString()}\n`);
        stage = null;
      }
    }
    if (stage) { await stage.finishCopy(); await stage.mergeAndCommit(); inserted += stage.count; stage = null; }
    if (total !== EXPECTED.foods) throw new Error(`canonical food count ${total} != ${EXPECTED.foods}`);
    if (!leanSelection && scanned !== EXPECTED.foods) throw new Error(`canonical input count ${scanned} != ${EXPECTED.foods}`);
    return total;
  } catch (error) { if (stage) await stage.abort(); throw error; }
}

async function loadSources(pool: any) {
  const specs: Record<string, [string, string[], string]> = {
    records: ["catalog_v2_source_records", ["id", "release_id", "source", "source_id", "dataset_version", "source_record_ordinal", "record_hash_sha256", "original_name", "display_name", "normalized_name", "category", "locale", "food_type", "validation_status", "data_quality_score", "cleaning_flags", "provenance", "normalized_payload"], "on conflict (release_id, source, source_record_ordinal) do nothing"],
    nutrition: ["catalog_v2_source_nutrition", ["id", "release_id", "source_record_id", "kcal_100g", "protein_100g", "carbs_100g", "fat_100g", "fiber_100g", "sugars_100g", "sodium_mg_100g", "nutrient_count", "derivation_code", "measurement_type", "data_points", "min_values", "max_values", "median_values", "extra_nutrients", "provenance"], "on conflict (release_id, source_record_id) do nothing"],
    mappings: ["catalog_v2_source_mappings", ["release_id", "canonical_food_id", "source_record_id", "match_method", "confidence", "mapping_status", "identity_ontology_version", "match_reasons", "contradiction_flags", "nutrition_similarity", "category_compatibility", "is_automatic"], "on conflict (release_id, source_record_id) do nothing"],
    aliases: ["catalog_v2_aliases", ["release_id", "canonical_food_id", "source_record_id", "alias", "normalized_alias", "locale", "alias_type", "priority", "is_preferred"], "on conflict do nothing"],
    portions: ["catalog_v2_portions", ["release_id", "canonical_food_id", "source_record_id", "description", "normalized_label", "amount", "unit", "gram_weight", "household_serving_description", "locale", "resolution_method", "confidence", "is_default", "metadata"], "on conflict do nothing"],
    branded: ["catalog_v2_branded_metadata", ["release_id", "canonical_food_id", "source_record_id", "brand", "normalized_brand", "barcode", "barcode_valid", "barcode_kind", "ingredients", "detected_languages", "market_country_tags", "category_tags", "data_quality_score", "turkey_relevance_score", "english_relevance_score", "inclusion_reasons", "source_quality_flags", "metadata"], "on conflict (release_id, source_record_id) do nothing"],
  };
  const order = ["records", "nutrition", "mappings", "aliases", "portions", "branded"];
  const openAll = async () => Object.fromEntries(await Promise.all(order.map(async (name) => {
    const [target, columns, conflict] = specs[name];
    return [name, await openStage(pool, name, target, columns, conflict)];
  }))) as Record<string, Stage>;
  let stages = await openAll();
  const totals: Record<string, number> = Object.fromEntries(order.map((name) => [name, 0]));
  let recordsInChunk = 0;

  const mappingIterator = readJsonlGz(resolve(CANONICAL, "canonical-source-mappings.jsonl.gz"))[Symbol.asyncIterator]();
  try {
    for (const slug of SOURCES) {
      let ordinal = 0;
      for await (const food of readJsonlGz(resolve(CLEANED, `${slug}.jsonl.gz`))) {
        ordinal++;
        const next = await mappingIterator.next();
        if (next.done) throw new Error(`source mapping stream ended at ${slug}:${ordinal}`);
        const mapping = next.value;
        if (mapping.source !== food.source || mapping.source_record_ordinal !== ordinal || String(mapping.source_id) !== String(food.source_id)) {
          throw new Error(`mapping/source misalignment at ${slug}:${ordinal}`);
        }
        if (leanSelection) {
          const selected = leanSelection.get(String(mapping.canonical_id));
          if (!selected || selected.representative_source !== String(food.source) ||
              selected.representative_source_id !== String(food.source_id) ||
              selected.representative_source_record_ordinal !== ordinal) continue;
        }
        const recordId = sourceUuid(food.source, ordinal), foodId = canonicalUuid(mapping.canonical_id);
        const foodType = food.source === "usda_branded" || food.source === "open_food_facts" ? "branded_product" : "generic_food";
        const original = cleanWhitespace(food.original_name ?? food.name) ?? `${food.source}:${food.source_id}`;
        const display = cleanWhitespace(food.display_name ?? food.name) ?? original;
        const normalized = cleanWhitespace(food.normalized_name) ?? normalizedText(display);
        const validationStatus = (food.cleaning_flags ?? []).some((flag: string) => flag.includes("invalid") || flag.includes("out_of_range")) ? "warning" : "valid";
        const payload = { nutrition_basis: food.nutrition_basis, quality: food.quality, scores: food.scores, countries: food.countries,
          market_country_tags: food.market_country_tags, languages: food.normalized_languages ?? food.detected_languages ?? food.languages,
          serving_size: food.serving_size, serving_unit: food.serving_unit, household_serving_description: food.household_serving_description };
        await writeStage(stages.records, [recordId, releaseId, food.source, String(food.source_id), String(food.dataset_version ?? "unknown"), ordinal,
          createHash("sha256").update(JSON.stringify(food)).digest("hex"), original, display, normalized, categoryName(food), recordLocale(food), foodType,
          validationStatus, Number.isFinite(food.data_quality_score) ? food.data_quality_score : null, pgArray(food.cleaning_flags ?? []), food.provenance ?? {}, payload]);

        const details = nutritionDetails(food), nutrition = food.nutrition ?? {};
        const nutritionKeys = ["kcal_100g", "protein_100g", "carbs_100g", "fat_100g", "fiber_100g", "sugars_100g", "sodium_mg_100g"];
        if (nutritionKeys.some((key) => Number.isFinite(nutrition[key]) && nutrition[key] >= 0)) {
          const score = scoreNutritionCandidate({ ...food, source_record_ordinal: ordinal }, foodType);
          await writeStage(stages.nutrition, [nutritionUuid(recordId), releaseId, recordId, ...nutritionKeys.map((key) => Number.isFinite(nutrition[key]) && nutrition[key] >= 0 ? nutrition[key] : null),
            details.rows.length, details.derivations.join("|") || null, details.measurements.join("|") || null, details.dataPoints || null,
            details.min, details.max, details.median, { stored_detail_scope: "core_summary_only", source_nutrient_count: details.rows.length, core_detail_count: details.coreCount },
            { ...food.provenance, normalized_source_file: `data/cleaned/${slug}.jsonl.gz`, selection_score: score.total, selection_reasons: score.reasons, policy_version: DATABASE_CATALOG_POLICY_VERSION }]);
        }
        const automatic = ["verified_compatible_gtin", "generic_token_order_qualifier_guard"].includes(mapping.match_method);
        await writeStage(stages.mappings, [releaseId, foodId, recordId, mapping.match_method, mapping.match_confidence, "accepted",
          mapping.match_method.includes("generic") ? "generic-identity-v2.2" : "canonical-v2", pgArray(mapping.match_reasons ?? []), pgArray(mapping.contradiction_flags ?? []),
          mapping.compatibility_score ?? null, null, automatic]);

        const locale = recordLocale(food);
        for (const alias of sourceAliases(food)) await writeStage(stages.aliases, [releaseId, foodId, recordId, alias.alias, alias.normalized, locale, alias.type, alias.priority, alias.priority === 90]);
        for (const portion of normalizeAndDedupePortions([{ ...food, source_record_ordinal: ordinal }])) {
          if (!Number.isFinite(portion.gram_weight) || portion.gram_weight! <= 0) continue;
          await writeStage(stages.portions, [releaseId, foodId, recordId, portion.display_description, portion.normalized_label, portion.amount, portion.unit,
            portion.gram_weight, food.household_serving_description, locale, portion.conversion_method, 1, false,
            { dedupe_key: portion.dedupe_key, source_portions: portion.source_portions, description_aliases: portion.description_aliases }]);
        }
        if (foodType === "branded_product") {
          const gtin = classifyGtin(food.barcode), kind: Record<string, string> = { GTIN_8: "gtin_8", UPC_A: "upc_a", EAN_13: "ean_13", GTIN_14: "gtin_14", STRUCTURAL_ONLY: "invalid", UNKNOWN: "invalid" };
          await writeStage(stages.branded, [releaseId, foodId, recordId, food.display_brand ?? food.brand, food.normalized_brand, gtin.normalized_code ?? food.barcode,
            gtin.checksum_valid, kind[gtin.code_type], food.cleaned_ingredients ?? food.ingredients, pgArray(food.normalized_languages ?? food.detected_languages ?? food.languages ?? []),
            pgArray(food.market_country_tags ?? food.countries ?? []), pgArray(food.category?.tags ?? []), Number.isFinite(food.data_quality_score) ? food.data_quality_score : null,
            Number.isFinite(food.turkey_relevance_score) ? food.turkey_relevance_score : null, Number.isFinite(food.english_relevance_score) ? food.english_relevance_score : null,
            pgArray(food.inclusion_reasons ?? []), pgArray([...(food.cleaning_flags ?? []), ...(food.quality?.source_warning_tags ?? [])]),
            { brand_owner: food.brand_owner, serving_size: food.serving_size, serving_unit: food.serving_unit, household_serving_description: food.household_serving_description, provenance: food.provenance }]);
        }
        recordsInChunk++;
        if (recordsInChunk >= CHUNK_SIZE) {
          await flushStages(stages, order, totals);
          recordsInChunk = 0;
          if (totals.records % 50000 === 0) process.stderr.write(`  source records committed: ${totals.records.toLocaleString()}\n`);
          stages = await openAll();
        }
        if (ordinal % 100000 === 0) process.stderr.write(`  ${slug}: ${ordinal.toLocaleString()}\n`);
      }
    }
    if (!(await mappingIterator.next()).done) throw new Error("source mapping stream contains trailing records");
    await flushStages(stages, order, totals);
    if (totals.records !== EXPECTED.records || totals.mappings !== EXPECTED.mappings) throw new Error("source/mapping counts do not match expected metrics");
    return totals;
  } catch (error) { await Promise.allSettled(Object.values(stages).map((stage) => stage.abort())); throw error; }
}

async function loadCases(pool: any) {
  if (leanSelection) return { review: 0, blocked: 0 };
  const review = await openStage(pool, "review", "catalog_v2_review_cases",
    ["id", "release_id", "case_type", "severity", "status", "canonical_food_id", "left_source_record_id", "right_source_record_id", "identity_key", "reason_codes", "evidence"], "on conflict (id) do nothing");
  const blocked = await openStage(pool, "blocked", "catalog_v2_blocked_matches",
    ["id", "release_id", "left_source_record_id", "right_source_record_id", "review_case_id", "block_type", "status", "identity_key", "reason_codes", "evidence"], "on conflict do nothing");
  try {
    for await (const item of readJsonlGz(resolve(CANONICAL, "canonical-review-candidates.jsonl.gz"))) {
      await writeStage(review, [deterministicUuid(`${releaseId}|review|${item.candidate_id}`), releaseId,
        item.match_method?.includes("barcode") || item.barcode_identity_status !== "NOT_APPLICABLE" ? "barcode_group" : "generic_pair", "medium", "pending", null,
        sourceUuid(item.left.source, item.left.source_record_ordinal), sourceUuid(item.right.source, item.right.source_record_ordinal), item.identity_key ?? item.candidate_id,
        pgArray(item.match_reasons ?? []), item]);
    }
    for await (const item of readJsonlGz(resolve(CANONICAL, "canonical-blocked-merge-candidates.jsonl.gz"))) {
      await writeStage(blocked, [deterministicUuid(`${releaseId}|blocked|${item.candidate_id}`), releaseId,
        sourceUuid(item.left.source, item.left.source_record_ordinal), sourceUuid(item.right.source, item.right.source_record_ordinal), null,
        "barcode_contradiction", "active", item.candidate_id, pgArray(item.contradiction_flags ?? item.match_reasons ?? []), item]);
    }
    await Promise.all([review.finishCopy(), blocked.finishCopy()]);
    if (review.count !== EXPECTED.reviews || blocked.count !== EXPECTED.blocked) throw new Error("review/blocked counts do not match canonical-v2 metrics");
    await review.mergeAndCommit(); await blocked.mergeAndCommit();
    return { review: review.count, blocked: blocked.count };
  } catch (error) { await Promise.allSettled([review.abort(), blocked.abort()]); throw error; }
}

async function finalize(pool: any, metrics: any) {
  const client = await pool.connect();
  try {
    await client.query("begin");
    await client.query("set transaction read write");
    await client.query("update public.catalog_v2_releases set status='validating' where id=$1 and status <> 'published'", [releaseId]);
    await client.query(`
      with chosen as (
        select distinct on (mapping.canonical_food_id)
          mapping.canonical_food_id,
          mapping.source_record_id
        from public.catalog_v2_source_mappings mapping
        where mapping.release_id = $1
        order by mapping.canonical_food_id, mapping.source_record_id
      )
      update public.catalog_v2_canonical_foods food set
        representative_source_record_id = chosen.source_record_id,
        canonical_name = coalesce(food.canonical_name_tr, food.canonical_name_en, source.display_name),
        updated_at = now()
      from chosen
      join public.catalog_v2_source_records source
        on source.release_id = $1 and source.id = chosen.source_record_id
      where food.release_id = $1
        and food.id = chosen.canonical_food_id`, [releaseId]);
    await client.query(`
      insert into public.catalog_v2_food_nutrition (
        canonical_food_id, release_id, source_record_id, source_nutrition_id,
        kcal_100g, protein_100g, carbs_100g, fat_100g, fiber_100g, sugars_100g, sodium_mg_100g,
        selection_method, selection_score, selection_reasons
      )
      select distinct on (mapping.canonical_food_id)
        mapping.canonical_food_id, mapping.release_id, source.id, nutrition.id,
        nutrition.kcal_100g, nutrition.protein_100g, nutrition.carbs_100g, nutrition.fat_100g,
        nutrition.fiber_100g, nutrition.sugars_100g, nutrition.sodium_mg_100g,
        'representative_source_record',
        nullif(nutrition.provenance->>'selection_score','')::numeric,
        array(select jsonb_array_elements_text(coalesce(nutrition.provenance->'selection_reasons','[]'::jsonb)))
      from public.catalog_v2_source_mappings mapping
      join public.catalog_v2_source_records source on source.release_id=mapping.release_id and source.id=mapping.source_record_id
      join public.catalog_v2_source_nutrition nutrition on nutrition.release_id=source.release_id and nutrition.source_record_id=source.id
      where mapping.release_id=$1
      order by mapping.canonical_food_id,
        (num_nonnulls(nutrition.kcal_100g,nutrition.protein_100g,nutrition.carbs_100g,nutrition.fat_100g)=4) desc,
        nullif(nutrition.provenance->>'selection_score','')::numeric desc nulls last,
        source.source, source.source_id, source.source_record_ordinal
      on conflict (canonical_food_id) do nothing`, [releaseId]);
    await client.query(`
      insert into public.catalog_v2_aliases (release_id,canonical_food_id,source_record_id,alias,normalized_alias,locale,alias_type,priority,is_preferred)
      select food.release_id, food.id, null, food.canonical_name, public.normalize_catalog_v2_search_text(food.canonical_name), null, 'canonical_name', 100, true
      from public.catalog_v2_canonical_foods food
      where food.release_id=$1 and not exists (
        select 1 from public.catalog_v2_aliases alias where alias.release_id=food.release_id and alias.canonical_food_id=food.id
      )
      on conflict do nothing`, [releaseId]);
    await client.query(`
      insert into public.catalog_v2_portions (release_id,canonical_food_id,source_record_id,description,normalized_label,amount,unit,gram_weight,locale,resolution_method,confidence,is_default,metadata)
      select food.release_id,food.id,null,'100 g','100 g',100,'g',100,null,'nutrition_basis_100g',1,true,
        jsonb_build_object('not_estimated',true,'reason','all source nutrition is normalized per 100 g')
      from public.catalog_v2_canonical_foods food
      where food.release_id=$1 and exists (select 1 from public.catalog_v2_food_nutrition n where n.release_id=food.release_id and n.canonical_food_id=food.id)
        and not exists (select 1 from public.catalog_v2_portions existing where existing.release_id=food.release_id and existing.canonical_food_id=food.id)
      on conflict do nothing`, [releaseId]);
    await client.query(`
      update public.catalog_v2_canonical_foods food set status = case when
        exists (select 1 from public.catalog_v2_food_nutrition n where n.release_id=food.release_id and n.canonical_food_id=food.id and num_nonnulls(n.kcal_100g,n.protein_100g,n.carbs_100g,n.fat_100g)=4)
        and exists (select 1 from public.catalog_v2_aliases a where a.release_id=food.release_id and a.canonical_food_id=food.id)
        and exists (select 1 from public.catalog_v2_portions p where p.release_id=food.release_id and p.canonical_food_id=food.id and p.gram_weight>0)
        then 'active' else 'candidate' end
      where food.release_id=$1`, [releaseId]);
    const counts = await client.query(`select
      (select count(*) from public.catalog_v2_source_records where release_id=$1)::bigint records,
      (select count(*) from public.catalog_v2_canonical_foods where release_id=$1)::bigint foods,
      (select count(*) from public.catalog_v2_source_mappings where release_id=$1)::bigint mappings,
      (select count(*) from public.catalog_v2_review_cases where release_id=$1)::bigint reviews,
      (select count(*) from public.catalog_v2_blocked_matches where release_id=$1)::bigint blocked`, [releaseId]);
    const row = counts.rows[0];
    for (const [key, expected] of Object.entries(EXPECTED)) {
      const actual = Number(row[key]); if (actual !== expected) throw new Error(`database ${key} count ${actual} != ${expected}`);
    }
    await client.query(`update public.catalog_v2_releases set status='validated',validated_at=now(),record_count=$2,canonical_food_count=$3,review_case_count=$4,blocked_match_count=$5,metrics=$6 where id=$1`,
      [releaseId, EXPECTED.mappings, EXPECTED.foods, EXPECTED.reviews, EXPECTED.blocked, metrics]);
    await client.query("commit");
  } catch (error) { await client.query("rollback"); throw error; } finally { client.release(); }
}

async function main() {
  await loadLeanSelection();
  if (process.env.IMPORT_VALIDATE_INPUT_ONLY === "1") {
    console.log(JSON.stringify(await validateLeanSelectionInputs(), null, 2));
    return;
  }
  const started = Date.now(), database = await databaseConfig(), pool = new Pool(database.poolConfig);
  const metrics = JSON.parse(await fs.readFile(resolve(CANONICAL, "canonicalization-metrics.json"), "utf8"));
  try {
    if (process.env.IMPORT_CONNECTIVITY_CHECK_ONLY === "1") {
      const check = await pool.query("select current_user as current_user, to_regclass('public.catalog_v2_releases') is not null as schema_ready");
      console.log(JSON.stringify({ connectivity: "ok", schema_ready: check.rows[0].schema_ready, role: "temporary_catalog_v2_import_role" }));
      return;
    }
    const existing = await pool.query("select status from public.catalog_v2_releases where catalog_version=$1", [VERSION]);
    if (existing.rows[0]?.status === "published" && process.env.ALLOW_REIMPORT_PUBLISHED !== "1") throw new Error("Refusing to mutate an already published release");
    await pool.query(`insert into public.catalog_v2_releases (id,catalog_version,normalization_version,cleaning_version,canonicalization_version,generic_identity_ontology_version,status,source_manifest,metrics,input_checksum_sha256,output_checksum_sha256)
      values ($1,$2,'normalization-v1','cleaning-v1','canonical-v2',$3,'loading',$4,$5,$6,$7)
      on conflict (catalog_version) do update set status=case when catalog_v2_releases.status='published' then 'published' else 'loading' end, failure_detail=null, updated_at=now()`,
      [releaseId, VERSION, metrics.versions.generic_ontology, metrics.input.per_source, metrics,
        createHash("sha256").update(JSON.stringify(metrics.input)).digest("hex"), createHash("sha256").update(JSON.stringify(metrics.output)).digest("hex")]);
    process.stderr.write("1/4 canonical foods\n"); const foods = await loadCanonicalFoods(pool);
    process.stderr.write("2/4 source records, mappings, nutrition, aliases, portions and branded metadata\n"); const sources = await loadSources(pool);
    process.stderr.write("3/4 review and blocked cases\n"); const cases = await loadCases(pool);
    process.stderr.write("4/4 preferred nutrition, compatibility rows and validation\n"); await finalize(pool, metrics);
    console.log(JSON.stringify({ catalog_version: VERSION, release_id: releaseId, status: "validated", duration_seconds: Number(((Date.now()-started)/1000).toFixed(3)), foods, ...sources, ...cases }, null, 2));
  } catch (error: any) {
    try { await pool.query("update public.catalog_v2_releases set status='failed',failure_detail=$2 where id=$1 and status<>'published'", [releaseId, String(error?.message ?? error).slice(0, 4000)]); } catch {}
    throw error;
  } finally {
    await pool.end();
    await database.cleanup();
  }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
