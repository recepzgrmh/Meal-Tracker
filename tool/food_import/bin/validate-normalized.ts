#!/usr/bin/env node
import { createReadStream, promises as fs } from "node:fs";
import { createGunzip } from "node:zlib";
import { createInterface } from "node:readline";
import { resolve } from "node:path";
import { NORMALIZATION_SCHEMA_VERSION } from "../normalization-schema.ts";

const ROOT = resolve(import.meta.dirname, "../../..");
const DIR = resolve(ROOT, "data/normalized");
const metrics = JSON.parse(await fs.readFile(resolve(DIR, "normalization-metrics.json"), "utf8"));
const report: any = { schema_version: NORMALIZATION_SCHEMA_VERSION, valid: true, sources: [] };

for (const source of metrics.sources) {
  const errors: Record<string, number> = {}; let rows = 0;
  const reader = createInterface({ input: createReadStream(resolve(DIR, source.output_file)).pipe(createGunzip()), crlfDelay: Infinity });
  for await (const line of reader) {
    rows++; let food: any;
    try { food = JSON.parse(line); } catch { errors.invalid_json = (errors.invalid_json ?? 0) + 1; continue; }
    if (food.schema_version !== NORMALIZATION_SCHEMA_VERSION) errors.schema_version = (errors.schema_version ?? 0) + 1;
    if (!food.name || !food.source || !food.source_id || !food.dataset_version) errors.missing_identity = (errors.missing_identity ?? 0) + 1;
    if (food.nutrition_basis?.amount !== 100 || food.nutrition_basis?.unit !== "g") errors.invalid_basis = (errors.invalid_basis ?? 0) + 1;
    if (!Array.isArray(food.nutrition?.nutrients) || !Array.isArray(food.portions)) errors.invalid_collections = (errors.invalid_collections ?? 0) + 1;
    for (const key of ["kcal_100g", "protein_100g", "carbs_100g", "fat_100g", "fiber_100g", "sugars_100g", "sodium_mg_100g"]) {
      if (food.nutrition?.[key] !== undefined && (!Number.isFinite(food.nutrition[key]) || food.nutrition[key] < 0)) errors.invalid_nutrition = (errors.invalid_nutrition ?? 0) + 1;
    }
    if (food.portions?.some((p: any) => p.gram_weight !== undefined && (!Number.isFinite(p.gram_weight) || p.gram_weight <= 0))) errors.invalid_portion = (errors.invalid_portion ?? 0) + 1;
  }
  if (rows !== source.output_records) errors.count_mismatch = Math.abs(rows - source.output_records);
  const valid = Object.keys(errors).length === 0; if (!valid) report.valid = false;
  report.sources.push({ source: source.source, rows, valid, errors });
}
await fs.writeFile(resolve(DIR, "validation-report.json"), `${JSON.stringify(report, null, 2)}\n`);
if (!report.valid) { console.error(JSON.stringify(report, null, 2)); process.exitCode = 1; }
else console.log(`Validated ${report.sources.reduce((n: number, s: any) => n + s.rows, 0)} records across ${report.sources.length} sources.`);

