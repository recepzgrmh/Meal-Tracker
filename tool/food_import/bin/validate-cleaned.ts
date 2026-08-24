#!/usr/bin/env node
import { promises as fs } from "node:fs";
import { resolve } from "node:path";
import { readJsonlGz } from "../src/cleaning-common.ts";

const ROOT = resolve(import.meta.dirname, "../../..");
const SLUGS = ["usda-foundation", "usda-fndds", "usda-sr-legacy", "usda-branded", "turkomp", "openfoodfacts"];

async function main() {
  const metrics = JSON.parse(await fs.readFile(resolve(ROOT, "data/cleaned/cleaning-metrics.json"), "utf8"));
  const report: any = { valid: true, sources: {}, errors: [] };
  for (const slug of SLUGS) {
    let rows = 0, errors = 0;
    for await (const food of readJsonlGz(resolve(ROOT, `data/cleaned/${slug}.jsonl.gz`))) {
      rows++;
      if (food.cleaning_version !== "food-cleaning-v1" || typeof food.original_name !== "string" || typeof food.display_name !== "string" || typeof food.normalized_name !== "string" || !Array.isArray(food.search_aliases) || !Array.isArray(food.cleaning_flags)) errors++;
      if (food.name !== food.original_name) errors++;
      for (const portion of food.portions ?? []) if (typeof portion.original_description !== "string" || typeof portion.normalized_label !== "string") errors++;
    }
    if (rows !== metrics.sources[slug].output) report.errors.push(`${slug}: row count ${rows} != metrics ${metrics.sources[slug].output}`);
    if (errors) report.errors.push(`${slug}: ${errors} schema/source-preservation errors`);
    report.sources[slug] = { rows, errors };
  }
  report.valid = report.errors.length === 0;
  await fs.writeFile(resolve(ROOT, "data/cleaned/cleaning-validation.json"), `${JSON.stringify(report, null, 2)}\n`);
  if (!report.valid) throw new Error(report.errors.join("\n"));
  console.log(`Validated ${Object.values(report.sources).reduce((sum: number, item: any) => sum + item.rows, 0).toLocaleString()} cleaned records.`);
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
