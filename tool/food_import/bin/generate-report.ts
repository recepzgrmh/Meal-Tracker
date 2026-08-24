#!/usr/bin/env node
import { promises as fs } from "node:fs";
import { resolve } from "node:path";
import { DEFAULT_OFF_FILTER } from "../src/openfoodfacts-normalizer.ts";

const ROOT = resolve(import.meta.dirname, "../../.."); const DIR = resolve(ROOT, "data/normalized");
const metrics = JSON.parse(await fs.readFile(resolve(DIR, "normalization-metrics.json"), "utf8"));
const pct = (v: number) => `${(v * 100).toFixed(2)}%`;
let md = `# Nutrition Normalization Report\n\nThis report is generated deterministically from \`normalization-metrics.json\`. No source records are merged, overwritten, or imported into Supabase.\n\n`;
md += `## Schema decisions\n\nCore identity, seven meal-logging nutrients, and the 100 g basis are directly queryable. Source-specific nutrient rows are also retained with their stable source key, unit, derivation, measurement source, data points, and min/max/median when published. Portions remain one-to-many gram conversions. Empty optional values are omitted rather than imputed. USDA kcal precedence is explicit (1008, then 2048, then 2047), so source array order cannot change the selected core value. Negative analytical values remain in the source nutrient detail but are not promoted to meal-logging core fields; zero/non-positive gram conversions are rejected.\n\n`;
md += `## Summary\n\n| Source | Input | Output | Skipped | Nutrition completeness | Portion coverage | Barcode coverage |\n|---|---:|---:|---:|---:|---:|---:|\n`;
for (const s of metrics.sources) md += `| ${s.source} | ${s.input_records.toLocaleString("en-US")} | ${s.output_records.toLocaleString("en-US")} | ${s.skipped_records.toLocaleString("en-US")} | ${pct(s.nutrition_completeness)} | ${pct(s.portion_coverage)} | ${pct(s.barcode_coverage)} |\n`;
md += `\n## Added fields\n\n| Field | Why useful | Sources | Status |\n|---|---|---|---|\n`;
md += `| \`nutrition.nutrients[]\` with source key, unit and derivation/statistics | Preserves micronutrients and evidence needed for accuracy/confidence without flattening unstable source vocabularies | USDA, TürKomp, OFF | Core container; row metadata optional |\n`;
md += `| \`additional_descriptions\`, \`aliases\` | Improves food matching for synonyms and USDA additional descriptions | USDA FNDDS; OFF | Optional |\n`;
md += `| category code/tags/hierarchy and classification codes | Supports category-aware search, WWEIA analysis and LanguaL matching | USDA, TürKomp, OFF | Optional |\n`;
md += `| language(s), countries, market_country | Enables locale-aware ranking and market filtering | OFF; USDA Branded | Optional |\n`;
md += `| package_size, food_code, scientific/regional names | Helps package/portion resolution and exact source matching | USDA, TürKomp, OFF | Optional |\n`;
md += `| quality tags, source completeness and confidence_inputs | Retains source quality signals without inventing a cross-source confidence score | OFF; derived presence signals for all | Core quality object; individual signals optional |\n`;
md += `| Nutri-Score, NOVA and environmental score | Useful for future product insights; not used to alter nutrition values | OFF | Optional |\n`;
md += `| labels, allergens, traces, ingredient analysis | Useful for dietary filters and warnings | OFF | Optional |\n`;
md += `| nutrient conversion factors | Preserves protein/fat calculation context | USDA Foundation/SR; TürKomp | Optional |\n`;
md += `| publication/availability/modification and validity dates | Enables freshness checks and reproducible release selection | USDA; OFF modification date | Optional |\n\n`;
md += `## Open Food Facts filtering\n\nThe gzip is streamed line-by-line and output is simultaneously gzip-compressed. It is never fully decompressed or loaded into memory. Defaults are: \`${JSON.stringify(DEFAULT_OFF_FILTER)}\`. They can be changed with \`OFF_MIN_CORE_NUTRIENTS\`, \`OFF_REQUIRE_ENERGY\`, \`OFF_REQUIRE_BARCODE\`, and \`OFF_MAX_KCAL\`. Skip reasons are counted below. OFF sodium uses the export's standardized \`sodium_100g\` value in grams and is converted to mg; the display-unit field is not used for that conversion.\n\n`;
for (const s of metrics.sources) {
  md += `## ${s.source}\n\n- Dataset version: ${s.dataset_version}\n- Input/output/skipped: ${s.input_records.toLocaleString("en-US")} / ${s.output_records.toLocaleString("en-US")} / ${s.skipped_records.toLocaleString("en-US")}\n- Skip reasons: ${Object.keys(s.skip_reasons).length ? Object.entries(s.skip_reasons).map(([k,v]) => `\`${k}\`: ${(v as number).toLocaleString("en-US")}`).join(", ") : "none"}\n- Nutrition completeness: ${pct(s.nutrition_completeness)}\n- Portion coverage: ${pct(s.portion_coverage)}\n- Barcode coverage: ${pct(s.barcode_coverage)}\n\n### 10 normalized examples\n\n\`\`\`json\n${JSON.stringify(s.sample_records, null, 2)}\n\`\`\`\n\n`;
}
await fs.writeFile(resolve(ROOT, "normalization-report.md"), md);
console.log(`Wrote ${resolve(ROOT, "normalization-report.md")}`);
