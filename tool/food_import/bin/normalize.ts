#!/usr/bin/env node
import { createReadStream, createWriteStream, promises as fs } from "node:fs";
import { createGunzip, createGzip } from "node:zlib";
import { createInterface } from "node:readline";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { basename, dirname, resolve } from "node:path";
import { pipeline } from "node:stream/promises";
import { normalizeUsda } from "../src/usda-normalizer.ts";
import { normalizeTurkomp } from "../src/turkomp-normalizer.ts";
import { DEFAULT_OFF_FILTER, normalizeOff } from "../src/openfoodfacts-normalizer.ts";
import { writeJsonLine } from "../src/normalization-common.ts";
import type { NormalizedFood } from "../normalization-schema.ts";

const ROOT = resolve(import.meta.dirname, "../../..");
const OUTPUT_DIR = resolve(ROOT, "data/normalized");
const METRICS_PATH = resolve(OUTPUT_DIR, "normalization-metrics.json");

interface SourceSpec { key: string; kind: string; artifactId: string; output: string; zipMember?: string }
const SPECS: SourceSpec[] = [
  { key: "usda-foundation", kind: "foundation", artifactId: "usda-fdc-foundation-2026-04-30", output: "usda-foundation.jsonl.gz" },
  { key: "usda-fndds", kind: "fndds", artifactId: "usda-fdc-survey-fndds-2024-10-31", output: "usda-fndds.jsonl.gz" },
  { key: "usda-sr-legacy", kind: "sr_legacy", artifactId: "usda-fdc-sr-legacy-2018-04", output: "usda-sr-legacy.jsonl.gz" },
  { key: "usda-branded", kind: "branded", artifactId: "usda-fdc-branded-2026-04-30", output: "usda-branded.jsonl.gz" },
  { key: "turkomp", kind: "turkomp", artifactId: "turkomp-snapshot-2026-08-22-processed", output: "turkomp.jsonl.gz", zipMember: "data/processed/turkomp/foods.json" },
  { key: "openfoodfacts", kind: "off", artifactId: "open-food-facts-jsonl-2026-08-22", output: "openfoodfacts.jsonl.gz" },
];

type Metrics = {
  source: string; dataset_version: string; input_records: number; output_records: number; skipped_records: number;
  skip_reasons: Record<string, number>; nutrition_completeness: number; portion_coverage: number; barcode_coverage: number;
  output_file: string; sample_records: NormalizedFood[]; filter_config?: unknown;
};

function bump(map: Record<string, number>, key: string) { map[key] = (map[key] ?? 0) + 1; }

async function* zipJsonArray(zipPath: string, member?: string): AsyncGenerator<unknown> {
  const args = member ? ["-p", zipPath, member] : ["-p", zipPath];
  const child = spawn("unzip", args, { stdio: ["ignore", "pipe", "pipe"] });
  const closed = once(child, "close") as Promise<[number]>;
  child.stderr.setEncoding("utf8"); let stderr = ""; child.stderr.on("data", (chunk) => { stderr += chunk; });
  child.stdout.setEncoding("utf8");
  let arrayStarted = false, inString = false, escaped = false, depth = 0, object = "", primitive = "";
  for await (const chunk of child.stdout) {
    for (const char of chunk as string) {
      if (!arrayStarted) { if (char === "[") arrayStarted = true; continue; }
      if (depth === 0) {
        if (primitive) {
          if (char === "," || char === "]" || /\s/.test(char)) {
            if (primitive === "null") yield null;
            primitive = "";
            if (char === "]") arrayStarted = false;
          } else primitive += char;
          continue;
        }
        if (char === "]") { arrayStarted = false; continue; }
        if (char === "{") { depth = 1; object = "{"; inString = false; escaped = false; continue; }
        if (char === "n") primitive = "n";
        continue;
      }
      object += char;
      if (inString) {
        if (escaped) escaped = false;
        else if (char === "\\") escaped = true;
        else if (char === '"') inString = false;
      } else {
        if (char === '"') inString = true;
        else if (char === "{") depth++;
        else if (char === "}") {
          depth--;
          if (depth === 0) { yield JSON.parse(object); object = ""; }
        }
      }
    }
  }
  const [code] = await closed;
  if (code !== 0) throw new Error(`unzip failed (${code}) for ${zipPath}: ${stderr}`);
}

async function* offLines(path: string): AsyncGenerator<{ value?: any; error?: string }> {
  const input = createReadStream(path); const gunzip = createGunzip(); input.pipe(gunzip);
  const reader = createInterface({ input: gunzip, crlfDelay: Infinity });
  for await (const line of reader) {
    if (!line.trim()) { yield { error: "blank_line" }; continue; }
    try { yield { value: JSON.parse(line) }; } catch { yield { error: "invalid_json" }; }
  }
}

async function createAtomicGzip(path: string) {
  const temp = `${path}.tmp`; await fs.mkdir(dirname(path), { recursive: true });
  await fs.rm(temp, { force: true });
  const gzip = createGzip({ level: 6 }); const file = createWriteStream(temp);
  const completion = pipeline(gzip, file);
  return { stream: gzip, finish: async () => { gzip.end(); await completion; await fs.rename(temp, path); } };
}

function newMetrics(source: string, version: string, output: string): Metrics {
  return { source, dataset_version: version, input_records: 0, output_records: 0, skipped_records: 0, skip_reasons: {}, nutrition_completeness: 0, portion_coverage: 0, barcode_coverage: 0, output_file: output, sample_records: [] };
}

function recordOutput(metrics: Metrics, food: NormalizedFood, sums: { completeness: number; portions: number; barcodes: number }) {
  metrics.output_records++; sums.completeness += food.quality.nutrition_completeness;
  if (food.portions.length) sums.portions++; if (food.barcode) sums.barcodes++;
  if (metrics.sample_records.length < 10) metrics.sample_records.push(food);
}

function finishMetrics(metrics: Metrics, sums: { completeness: number; portions: number; barcodes: number }) {
  metrics.skipped_records = metrics.input_records - metrics.output_records;
  const n = metrics.output_records || 1;
  metrics.nutrition_completeness = Number((sums.completeness / n).toFixed(4));
  metrics.portion_coverage = Number((sums.portions / n).toFixed(4));
  metrics.barcode_coverage = Number((sums.barcodes / n).toFixed(4));
}

async function normalizeSource(spec: SourceSpec, artifact: any, limit?: number): Promise<Metrics> {
  const inputPath = resolve(ROOT, artifact.path), outputPath = resolve(OUTPUT_DIR, spec.output);
  const version = String(artifact.sourceRelease); const metrics = newMetrics(spec.key, version, spec.output);
  const sums = { completeness: 0, portions: 0, barcodes: 0 }; const writer = await createAtomicGzip(outputPath);
  if (spec.kind === "off") metrics.filter_config = DEFAULT_OFF_FILTER;
  try {
    if (spec.kind === "off") {
      for await (const item of offLines(inputPath)) {
        metrics.input_records++; if (item.error) { bump(metrics.skip_reasons, item.error); }
        else { const result = normalizeOff(item.value, version); if (result.food) { await writeJsonLine(writer.stream, result.food); recordOutput(metrics, result.food, sums); } else bump(metrics.skip_reasons, result.skip ?? "unknown"); }
        if (limit && metrics.input_records >= limit) break;
        if (metrics.input_records % 100000 === 0) process.stderr.write(`${spec.key}: ${metrics.input_records} input, ${metrics.output_records} output\n`);
      }
    } else {
      for await (const record of zipJsonArray(inputPath, spec.zipMember)) {
        metrics.input_records++;
        let food: NormalizedFood | undefined;
        if (!record || typeof record !== "object") bump(metrics.skip_reasons, "null_or_non_object");
        else if (spec.kind === "turkomp") food = normalizeTurkomp(record, version);
        else food = normalizeUsda(record, spec.kind, version);
        if (food) { await writeJsonLine(writer.stream, food); recordOutput(metrics, food, sums); }
        else if (record && typeof record === "object") bump(metrics.skip_reasons, "missing_required_identity");
        if (limit && metrics.input_records >= limit) break;
        if (metrics.input_records % 100000 === 0) process.stderr.write(`${spec.key}: ${metrics.input_records} input, ${metrics.output_records} output\n`);
      }
    }
    await writer.finish(); finishMetrics(metrics, sums); return metrics;
  } catch (error) { writer.stream.destroy(); throw error; }
}

async function main() {
  const args = process.argv.slice(2); const sourceArg = args.includes("--source") ? args[args.indexOf("--source") + 1] : "all";
  const limit = args.includes("--limit") ? Number(args[args.indexOf("--limit") + 1]) : undefined;
  const sources = JSON.parse(await fs.readFile(resolve(ROOT, "data/sources.json"), "utf8"));
  let existing: Metrics[] = []; try { existing = JSON.parse(await fs.readFile(METRICS_PATH, "utf8")).sources ?? []; } catch {}
  const selected = sourceArg === "all" ? SPECS : SPECS.filter((s) => s.key === sourceArg);
  if (!selected.length) throw new Error(`Unknown --source ${sourceArg}; choose ${SPECS.map((s) => s.key).join(", ")}`);
  for (const spec of selected) {
    const artifact = sources.artifacts.find((a: any) => a.id === spec.artifactId); if (!artifact) throw new Error(`Missing artifact ${spec.artifactId}`);
    process.stderr.write(`Normalizing ${spec.key} from ${basename(artifact.path)}\n`);
    const metrics = await normalizeSource(spec, artifact, limit);
    existing = existing.filter((m) => m.source !== spec.key); existing.push(metrics);
    existing.sort((a, b) => SPECS.findIndex((s) => s.key === a.source) - SPECS.findIndex((s) => s.key === b.source));
    await fs.writeFile(METRICS_PATH, `${JSON.stringify({ schema_version: 1, sources: existing }, null, 2)}\n`);
    process.stderr.write(`${spec.key}: done (${metrics.output_records}/${metrics.input_records})\n`);
  }
}

await main();
