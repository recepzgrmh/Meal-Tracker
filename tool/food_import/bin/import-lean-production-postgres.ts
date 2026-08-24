#!/usr/bin/env node
import { createHash } from "node:crypto";
import { resolve } from "node:path";
import pg from "pg";
import { from as copyFrom } from "pg-copy-streams";
import { readJsonlGz, cleanWhitespace } from "../src/cleaning-common.ts";
import { normalizeAndDedupePortions } from "../src/database-catalog-policy.ts";

const { Pool } = pg;
const ROOT = resolve(import.meta.dirname, "../../..");
const CLEANED = resolve(ROOT, "data/cleaned");
const CANONICAL = resolve(ROOT, "data/canonical-v2");
const MANIFEST = resolve(ROOT, process.env.LEAN_CATALOG_MANIFEST ?? "data/lean-catalog/selected-canonical-foods.jsonl.gz");
const LIMIT = Math.max(0, Number(process.env.LEAN_IMPORT_LIMIT ?? 0));
const CHUNK_SIZE = Math.max(250, Number(process.env.IMPORT_CHUNK_SIZE ?? 1000));
const CATALOG_VERSION = process.env.CATALOG_VERSION ?? "canonical-v2-lean-60k";
const SOURCES = ["usda-foundation", "usda-fndds", "usda-sr-legacy", "usda-branded", "turkomp", "openfoodfacts"] as const;

type Selection = {
  canonical_id: string;
  tier: string;
  rank: number;
  representative_source: string;
  representative_source_id: string;
  representative_source_record_ordinal: number;
  selection_score: number;
  turkey_relevance_score: number;
  english_relevance_score: number;
  inclusion_reasons: string[];
};

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

async function loadSelection(): Promise<Map<string, Selection>> {
  const rows: Selection[] = [];
  for await (const row of readJsonlGz(MANIFEST)) rows.push(row as Selection);
  rows.sort((a, b) => a.rank - b.rank || a.canonical_id.localeCompare(b.canonical_id, "en"));
  const limited = LIMIT > 0 ? rows.slice(0, LIMIT) : rows;
  const selected = new Map(limited.map((row) => [row.canonical_id, row]));
  if (selected.size !== limited.length) throw new Error("lean manifest contains duplicate canonical IDs");
  return selected;
}

async function loadCanonical(selected: Map<string, Selection>) {
  const output = new Map<string, any>();
  for await (const food of readJsonlGz(resolve(CANONICAL, "canonical-foods.jsonl.gz"))) {
    if (selected.has(String(food.canonical_id))) output.set(String(food.canonical_id), food);
  }
  if (output.size !== selected.size) throw new Error(`canonical metadata ${output.size} != selected ${selected.size}`);
  return output;
}

function localeOf(food: any): string {
  const languages = [...(food.normalized_languages ?? []), ...(food.detected_languages ?? []), ...(food.languages ?? []), food.language]
    .filter(Boolean).map((value) => String(value).toLowerCase().split(/[-_]/)[0]);
  return food.source === "turkomp" || languages.includes("tr") ? "tr-TR" : "en-US";
}

function categoryOf(food: any): string | null {
  return cleanWhitespace(typeof food.category === "string" ? food.category : food.display_category ?? food.category?.name) ?? null;
}

function preferredPortion(food: any): { label: string; grams: number } {
  const portions = normalizeAndDedupePortions([food]).filter((portion) => Number.isFinite(portion.gram_weight) && portion.gram_weight! >= 0.01 && portion.gram_weight! <= 10_000);
  const preferred = portions.find((portion) => !/^100\s*g$/i.test(portion.normalized_label)) ?? portions[0];
  return preferred ? { label: preferred.display_description, grams: Number(preferred.gram_weight) } : { label: "100 g", grams: 100 };
}

async function openCopy(client: any, temp: string, target: string, columns: string[]) {
  await client.query(`create temp table ${temp} (like public.${target} including defaults including identity) on commit drop`);
  const stream = client.query(copyFrom(`copy ${temp} (${columns.join(",")}) from stdin with (format text)`));
  let streamError: unknown;
  stream.on("error", (error: unknown) => { streamError = error; });
  return {
    stream,
    async write(values: unknown[]) {
      if (streamError) throw streamError;
      if (!stream.write(`${values.map(copyValue).join("\t")}\n`)) await new Promise<void>((resolveDrain, reject) => {
        stream.once("drain", resolveDrain); stream.once("error", reject);
      });
    },
    async finish() {
      if (streamError) throw streamError;
      await new Promise<void>((resolveFinish, reject) => { stream.once("finish", resolveFinish); stream.once("error", reject); stream.end(); });
    },
  };
}

async function flush(pool: any, rows: any[]) {
  if (!rows.length) return;
  const client = await pool.connect();
  try {
    await client.query("begin");
    await client.query("set transaction read write");
    const suffix = `${process.pid}_${Date.now()}`;
    const foodColumns = ["id", "canonical_name", "locale", "source", "source_food_id", "calories_per_100g", "protein_per_100g", "carbs_per_100g", "fat_per_100g", "metadata", "is_active"];
    const aliasColumns = ["food_id", "alias", "locale", "priority"];
    const portionColumns = ["food_id", "label", "grams", "locale", "is_default", "size_class", "household_measure"];
    const foods = await openCopy(client, `stage_lean_foods_${suffix}`, "foods", foodColumns);
    for (const row of rows) await foods.write(row.food);
    await foods.finish();
    const aliases = await openCopy(client, `stage_lean_aliases_${suffix}`, "food_aliases", aliasColumns);
    for (const row of rows) for (const alias of row.aliases) await aliases.write(alias);
    await aliases.finish();
    const portions = await openCopy(client, `stage_lean_portions_${suffix}`, "food_portions", portionColumns);
    for (const row of rows) for (const portion of row.portions) await portions.write(portion);
    await portions.finish();
    await client.query(`insert into public.foods (${foodColumns.join(",")}) select ${foodColumns.join(",")} from stage_lean_foods_${suffix}
      on conflict (source,source_food_id) do update set canonical_name=excluded.canonical_name,locale=excluded.locale,
      calories_per_100g=excluded.calories_per_100g,protein_per_100g=excluded.protein_per_100g,carbs_per_100g=excluded.carbs_per_100g,
      fat_per_100g=excluded.fat_per_100g,metadata=excluded.metadata,is_active=true,updated_at=now()`);
    await client.query(`insert into public.food_aliases (${aliasColumns.join(",")}) select ${aliasColumns.join(",")} from stage_lean_aliases_${suffix} on conflict do nothing`);
    await client.query(`insert into public.food_portions (${portionColumns.join(",")}) select ${portionColumns.join(",")} from stage_lean_portions_${suffix} on conflict do nothing`);
    await client.query("commit");
  } catch (error) {
    await client.query("rollback");
    throw error;
  } finally {
    client.release();
  }
}

async function main() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) throw new Error("DATABASE_URL is required");
  const selected = await loadSelection();
  const canonical = await loadCanonical(selected);
  const found = new Set<string>();
  const pool = new Pool({ connectionString, max: 2, ssl: { rejectUnauthorized: false }, options: "-c default_transaction_read_only=off" });
  const mappingIterator = readJsonlGz(resolve(CANONICAL, "canonical-source-mappings.jsonl.gz"))[Symbol.asyncIterator]();
  let buffer: any[] = [];
  try {
    for (const slug of SOURCES) {
      let ordinal = 0;
      for await (const sourceFood of readJsonlGz(resolve(CLEANED, `${slug}.jsonl.gz`))) {
        ordinal++;
        const next = await mappingIterator.next();
        if (next.done) throw new Error(`mapping stream ended at ${slug}:${ordinal}`);
        const mapping = next.value;
        if (mapping.source !== sourceFood.source || mapping.source_record_ordinal !== ordinal || String(mapping.source_id) !== String(sourceFood.source_id)) {
          throw new Error(`mapping/source misalignment at ${slug}:${ordinal}`);
        }
        const selection = selected.get(String(mapping.canonical_id));
        if (!selection || selection.representative_source !== String(sourceFood.source) || selection.representative_source_id !== String(sourceFood.source_id) ||
            selection.representative_source_record_ordinal !== ordinal) continue;
        if (found.has(selection.canonical_id)) throw new Error(`duplicate representative ${selection.canonical_id}`);
        found.add(selection.canonical_id);
        const canonicalFood = canonical.get(selection.canonical_id);
        const nutrition = sourceFood.nutrition ?? {};
        const macroKeys = ["kcal_100g", "protein_100g", "carbs_100g", "fat_100g"];
        if (!macroKeys.every((key) => Number.isFinite(nutrition[key]) && nutrition[key] >= 0)) throw new Error(`incomplete macros ${selection.canonical_id}`);
        const id = deterministicUuid(`production-lean|${selection.canonical_id}`);
        const name = cleanWhitespace(canonicalFood.canonical_name_tr ?? canonicalFood.canonical_name_en ?? sourceFood.display_name ?? sourceFood.name) ?? selection.canonical_id;
        const locale = localeOf(sourceFood);
        const portion = preferredPortion({ ...sourceFood, source_record_ordinal: ordinal });
        const metadata = {
          catalog_version: CATALOG_VERSION,
          canonical_id: selection.canonical_id,
          tier: selection.tier,
          rank: selection.rank,
          category: categoryOf(sourceFood) ?? canonicalFood.category ?? null,
          brand: cleanWhitespace(sourceFood.display_brand ?? sourceFood.brand) ?? null,
          barcode: cleanWhitespace(sourceFood.barcode) ?? null,
          dataset_version: sourceFood.dataset_version ?? null,
          turkey_relevance_score: selection.turkey_relevance_score,
          english_relevance_score: selection.english_relevance_score,
          inclusion_reasons: selection.inclusion_reasons,
        };
        const alias = cleanWhitespace(sourceFood.display_name ?? sourceFood.name) ?? name;
        buffer.push({
          food: [id, name, locale, "canonical_v2_lean", selection.canonical_id, ...macroKeys.map((key) => nutrition[key]), metadata, true],
          aliases: [[id, alias, "tr-TR", 90], [id, alias, "en-US", 90]],
          portions: [[id, portion.label, portion.grams, "tr-TR", true, "regular", portion.label], [id, portion.label, portion.grams, "en-US", true, "regular", portion.label]],
        });
        if (buffer.length >= CHUNK_SIZE) {
          await flush(pool, buffer); buffer = [];
          process.stderr.write(`lean production foods committed: ${found.size.toLocaleString()}\n`);
        }
      }
    }
    if (!(await mappingIterator.next()).done) throw new Error("mapping stream contains trailing records");
    await flush(pool, buffer);
    if (found.size !== selected.size) throw new Error(`representatives found ${found.size} != selected ${selected.size}`);
    const counts = await pool.query(`select
      (select count(*) from public.foods where source='canonical_v2_lean')::bigint foods,
      (select count(*) from public.food_aliases a join public.foods f on f.id=a.food_id where f.source='canonical_v2_lean')::bigint aliases,
      (select count(*) from public.food_portions p join public.foods f on f.id=p.food_id where f.source='canonical_v2_lean')::bigint portions`);
    console.log(JSON.stringify({ catalog_version: CATALOG_VERSION, selected: selected.size, found: found.size,
      database_counts: Object.fromEntries(Object.entries(counts.rows[0]).map(([key, value]) => [key, Number(value)])) }, null, 2));
  } finally {
    await pool.end();
  }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
