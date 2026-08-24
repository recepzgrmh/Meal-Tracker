#!/usr/bin/env node
import { promises as fs } from "node:fs";
import { resolve } from "node:path";
import { cleanFood, readJsonlGz, atomicGzip, writeLine, cleanWhitespace, normalizedText, normalizeUnit } from "../src/cleaning-common.ts";

const ROOT = resolve(import.meta.dirname, "../../..");
const OUTPUT_DIR = resolve(ROOT, "data/cleaned");
const METRICS_PATH = resolve(OUTPUT_DIR, "cleaning-metrics.json");
const REPORT_PATH = resolve(ROOT, "cleaning-report.md");
const SOURCES = [
  ["usda-foundation", "data/normalized/usda-foundation.jsonl.gz"],
  ["usda-fndds", "data/normalized/usda-fndds.jsonl.gz"],
  ["usda-sr-legacy", "data/normalized/usda-sr-legacy.jsonl.gz"],
  ["usda-branded", "data/normalized/usda-branded.jsonl.gz"],
  ["turkomp", "data/normalized/turkomp.jsonl.gz"],
  ["openfoodfacts", "data/catalog/openfoodfacts-production.jsonl.gz"],
] as const;

function changed(a: unknown, b: unknown) { return (typeof a === "string" ? a : "") !== (typeof b === "string" ? b : ""); }
function md(value: unknown) { return String(value ?? "—").replaceAll("|", "/").replace(/\s+/g, " "); }

async function main() {
  await fs.mkdir(OUTPUT_DIR, { recursive: true });
  const metrics: any = { cleaning_version: "food-cleaning-v1", generated_at: new Date().toISOString(), sources: {}, totals: {}, before_after_examples: [] };
  const exampleSourceCounts = new Map<string, number>();
  const totals: Record<string, number> = { input: 0, output: 0, cleaned_name_count: 0, cleaned_brand_count: 0, weak_name_count: 0, nutrition_warning_count: 0, portion_cleanup_count: 0, duplicate_candidates: 0 };
  for (const [slug, relativeInput] of SOURCES) {
    const input = resolve(ROOT, relativeInput), output = resolve(OUTPUT_DIR, `${slug}.jsonl.gz`), writer = await atomicGzip(output);
    const row: Record<string, number> = { input: 0, output: 0, cleaned_name_count: 0, cleaned_brand_count: 0, weak_name_count: 0, nutrition_warning_count: 0, portion_cleanup_count: 0, duplicate_candidates: 0 };
    const identityCounts = new Map<string, number>();
    process.stderr.write(`Cleaning ${slug}\n`);
    try {
      for await (const raw of readJsonlGz(input)) {
        row.input++;
        const food = cleanFood(raw);
        row.output++;
        if (changed(raw.name, food.display_name) || normalizedText(raw.name) !== raw.name) row.cleaned_name_count++;
        if (raw.brand !== undefined && (changed(raw.brand, food.display_brand) || normalizedText(raw.brand) !== raw.brand)) row.cleaned_brand_count++;
        if (food.cleaning_flags.includes("weak_product_name")) row.weak_name_count++;
        if (food.cleaning_flags.some((flag: string) => flag.startsWith("nutrition_") || flag.startsWith("macro_") || flag.startsWith("kcal_") || flag.startsWith("possible_"))) row.nutrition_warning_count++;
        for (let index = 0; index < (raw.portions ?? []).length; index++) {
          const before = raw.portions[index], after = food.portions[index];
          if ((cleanWhitespace(before.description) ?? "") !== before.description || normalizeUnit(before.unit) !== before.unit || after.normalized_label !== before.description?.toLowerCase()) row.portion_cleanup_count++;
        }
        const identity = `${food.normalized_brand ?? ""}|${food.normalized_name}`;
        identityCounts.set(identity, (identityCounts.get(identity) ?? 0) + 1);
        if ((exampleSourceCounts.get(slug) ?? 0) < 5 && (raw.name !== food.display_name || raw.name !== food.normalized_name || (raw.brand && raw.brand !== food.display_brand))) {
          metrics.before_after_examples.push({ source: raw.source, source_id: raw.source_id, original_name: raw.name, display_name: food.display_name, normalized_name: food.normalized_name, original_brand: raw.brand ?? null, display_brand: food.display_brand ?? null, normalized_brand: food.normalized_brand ?? null });
          exampleSourceCounts.set(slug, (exampleSourceCounts.get(slug) ?? 0) + 1);
        }
        await writeLine(writer.stream, food);
        if (row.input % 100000 === 0) process.stderr.write(`  ${row.input.toLocaleString()} rows\n`);
      }
      await writer.finish();
    } catch (error) { await writer.abort(); throw error; }
    for (const count of identityCounts.values()) if (count > 1) row.duplicate_candidates += count - 1;
    metrics.sources[slug] = row;
    for (const key of Object.keys(totals)) totals[key] += row[key];
  }
  metrics.totals = totals;
  await fs.writeFile(METRICS_PATH, `${JSON.stringify(metrics, null, 2)}\n`);
  let report = `# Nutrition Data Cleaning Report\n\nGenerated: ${metrics.generated_at}\n\nThe cleaning stage is deterministic and source-preserving. Existing normalized fields are not overwritten; display/search fields and flags are appended. Nutrition values are never repaired or imputed.\n\n## Metrics\n\n| Source | Input | Output | Cleaned names | Cleaned brands | Weak names | Nutrition warnings | Portion cleanups | Duplicate candidates |\n|---|---:|---:|---:|---:|---:|---:|---:|---:|\n`;
  for (const [source, row] of Object.entries(metrics.sources) as any) report += `| ${source} | ${row.input.toLocaleString()} | ${row.output.toLocaleString()} | ${row.cleaned_name_count.toLocaleString()} | ${row.cleaned_brand_count.toLocaleString()} | ${row.weak_name_count.toLocaleString()} | ${row.nutrition_warning_count.toLocaleString()} | ${row.portion_cleanup_count.toLocaleString()} | ${row.duplicate_candidates.toLocaleString()} |\n`;
  report += `| **Total** | **${totals.input.toLocaleString()}** | **${totals.output.toLocaleString()}** | **${totals.cleaned_name_count.toLocaleString()}** | **${totals.cleaned_brand_count.toLocaleString()}** | **${totals.weak_name_count.toLocaleString()}** | **${totals.nutrition_warning_count.toLocaleString()}** | **${totals.portion_cleanup_count.toLocaleString()}** | **${totals.duplicate_candidates.toLocaleString()}** |\n\n`;
  report += `## Rules and decisions\n\n- NFC Unicode normalization, control-character removal and whitespace collapse are applied to derived display/search fields.\n- ASCII-folded search aliases preserve a separate native-diacritic alias. Source names and brands remain unchanged.\n- Placeholder or brand-only names are flagged with \`weak_product_name\` and \`needs_name_review\`; records are retained.\n- Portion labels and common units are standardized only in appended fields. Unknown gram weights are not inferred.\n- Negative/non-finite values, macros over 100 g, macro sum over 105 g, large kcal-vs-macro differences and suspicious sodium scale are flags only.\n- Duplicate candidates are exact \`normalized_brand + normalized_name\` collisions inside each source; they are not deleted.\n\n## 30 before → after examples\n\n| # | Source / ID | Original name | Display name | Normalized name | Original brand | Display / normalized brand |\n|---:|---|---|---|---|---|---|\n`;
  metrics.before_after_examples.forEach((item: any, index: number) => { report += `| ${index + 1} | ${md(item.source)} / ${md(item.source_id)} | ${md(item.original_name)} | ${md(item.display_name)} | ${md(item.normalized_name)} | ${md(item.original_brand)} | ${md(item.display_brand)} / ${md(item.normalized_brand)} |\n`; });
  await fs.writeFile(REPORT_PATH, report);
  process.stderr.write(`Cleaned ${totals.output.toLocaleString()} records\n`);
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
