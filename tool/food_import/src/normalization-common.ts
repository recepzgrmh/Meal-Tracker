import { once } from "node:events";
import type { Writable } from "node:stream";
import type { NormalizedFood } from "../normalization-schema.ts";

export const CORE_NUTRIENTS = [
  "kcal_100g", "protein_100g", "carbs_100g", "fat_100g",
  "fiber_100g", "sugars_100g", "sodium_mg_100g",
] as const;

export function finite(value: unknown): number | undefined {
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) ? n : undefined;
}

export function text(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const clean = value.trim().replace(/\s+/g, " ");
  return clean || undefined;
}

export function strings(value: unknown): string[] | undefined {
  if (!Array.isArray(value)) return undefined;
  const result = [...new Set(value.map(text).filter((v): v is string => Boolean(v)))];
  return result.length ? result : undefined;
}

export function completeness(nutrition: NormalizedFood["nutrition"]): number {
  const present = CORE_NUTRIENTS.filter((key) => finite(nutrition[key]) !== undefined).length;
  return Number((present / CORE_NUTRIENTS.length).toFixed(4));
}

export function compact<T>(value: T): T {
  if (Array.isArray(value)) {
    return value.map(compact).filter((item) => item !== undefined) as T;
  }
  if (value && typeof value === "object") {
    const output: Record<string, unknown> = {};
    for (const [key, item] of Object.entries(value)) {
      if (item === undefined || item === null || item === "") continue;
      const cleaned = compact(item);
      if (Array.isArray(cleaned) && cleaned.length === 0 && key !== "portions" && key !== "nutrients") continue;
      if (cleaned && typeof cleaned === "object" && !Array.isArray(cleaned) && Object.keys(cleaned).length === 0) continue;
      output[key] = cleaned;
    }
    return output as T;
  }
  return value;
}

export async function writeJsonLine(stream: Writable, value: unknown): Promise<void> {
  if (!stream.write(`${JSON.stringify(compact(value))}\n`)) await once(stream, "drain");
}
