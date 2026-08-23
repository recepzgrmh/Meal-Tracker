import { createReadStream, createWriteStream, promises as fs } from "node:fs";
import { createGunzip, createGzip } from "node:zlib";
import { createInterface } from "node:readline";
import { once } from "node:events";
import { dirname } from "node:path";
import { pipeline } from "node:stream/promises";
import type { Writable } from "node:stream";
import { CLEANING_SCHEMA_VERSION } from "../cleaning-schema.ts";

export const PLACEHOLDER_NAMES = new Set([
  "?", "-", "n a", "na", "none", "null", "unknown", "unnamed", "product", "food", "gg",
  "test", "todo", "no name", "not available", "sans nom", "inconnu",
]);

const UNIT_MAP: Record<string, string> = {
  g: "g", gr: "g", gram: "g", grams: "g", gramme: "g", grammes: "g",
  kg: "kg", kilogram: "kg", kilograms: "kg",
  mg: "mg", milligram: "mg", milligrams: "mg",
  ml: "ml", milliliter: "ml", milliliters: "ml", millilitre: "ml", millilitres: "ml",
  l: "l", liter: "l", liters: "l", litre: "l", litres: "l",
  cup: "cup", cups: "cup", tbsp: "tbsp", tablespoon: "tbsp", tablespoons: "tbsp",
  tsp: "tsp", teaspoon: "tsp", teaspoons: "tsp", oz: "oz", ounce: "oz", ounces: "oz",
  slice: "slice", slices: "slice", piece: "piece", pieces: "piece", serving: "serving", servings: "serving",
};

export function cleanWhitespace(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const result = value.normalize("NFC").replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/gu, " ").trim();
  return result || undefined;
}

export function asciiFold(value: string): string {
  return value.toLocaleLowerCase("tr-TR").replaceAll("ı", "i").replaceAll("ş", "s").replaceAll("ğ", "g")
    .replaceAll("ç", "c").replaceAll("ö", "o").replaceAll("ü", "u")
    .normalize("NFKD").replace(/[\u0300-\u036f]/g, "");
}

export function normalizedText(value: unknown, fold = true): string {
  const clean = cleanWhitespace(value) ?? "";
  const lower = fold ? asciiFold(clean) : clean.toLocaleLowerCase("tr-TR");
  return lower.replace(/[’'`´]/g, "").replace(/[^\p{L}\p{N}]+/gu, " ").trim().replace(/\s+/g, " ");
}

function titleToken(token: string, locale: string): string {
  if (!token) return token;
  if (/^\d/.test(token)) return token;
  return token[0].toLocaleUpperCase(locale) + token.slice(1).toLocaleLowerCase(locale);
}

export function displayText(value: unknown, language?: string): string {
  const clean = cleanWhitespace(value) ?? "";
  if (!clean) return clean;
  const letters = clean.replace(/[^\p{L}]/gu, "");
  const allUpper = letters.length > 1 && letters === letters.toLocaleUpperCase(language === "tr" ? "tr-TR" : undefined);
  if (!allUpper) return clean;
  const locale = language === "tr" ? "tr-TR" : "en-US";
  return clean.split(/(\s+|[-/])/).map((token) => /[\p{L}\p{N}]/u.test(token) ? titleToken(token, locale) : token).join("");
}

export function normalizeUnit(value: unknown): string | undefined {
  const token = normalizedText(value);
  return UNIT_MAP[token] ?? (token || undefined);
}

export function validGtin(value: unknown): boolean {
  const code = cleanWhitespace(value);
  if (!code || !/^(?:\d{8}|\d{12}|\d{13}|\d{14})$/.test(code)) return false;
  const digits = [...code].map(Number), expected = digits.pop()!;
  let sum = 0, position = 0;
  for (let index = digits.length - 1; index >= 0; index--, position++) sum += digits[index] * (position % 2 === 0 ? 3 : 1);
  return (10 - (sum % 10)) % 10 === expected;
}

export function nutritionFlags(food: any): string[] {
  const result = new Set<string>();
  const nutrition = food.nutrition ?? {};
  const core = ["kcal_100g", "protein_100g", "carbs_100g", "fat_100g", "fiber_100g", "sugars_100g", "sodium_mg_100g"];
  for (const key of core) {
    const value = nutrition[key];
    if (value === undefined || value === null) continue;
    if (typeof value !== "number" || !Number.isFinite(value)) result.add(`nutrition_non_finite:${key}`);
    else if (value < 0) result.add(`nutrition_negative:${key}`);
  }
  for (const key of ["protein_100g", "carbs_100g", "fat_100g", "fiber_100g", "sugars_100g"]) {
    if (Number.isFinite(nutrition[key]) && nutrition[key] > 100) result.add(`nutrition_over_100g:${key}`);
  }
  const macros = [nutrition.protein_100g, nutrition.carbs_100g, nutrition.fat_100g];
  if (macros.every(Number.isFinite)) {
    const macroSum = macros.reduce((sum: number, value: number) => sum + value, 0);
    if (macroSum > 105) result.add("macro_sum_over_105g");
    if (Number.isFinite(nutrition.kcal_100g)) {
      const derived = nutrition.protein_100g * 4 + nutrition.carbs_100g * 4 + nutrition.fat_100g * 9;
      const difference = Math.abs(nutrition.kcal_100g - derived);
      if (difference > 120 && difference / Math.max(nutrition.kcal_100g, derived, 1) > 0.35) result.add("kcal_macro_energy_large_difference");
    }
  }
  if (Number.isFinite(nutrition.sodium_mg_100g) && nutrition.sodium_mg_100g > 100000) result.add("possible_sodium_unit_error");
  return [...result].sort();
}

export function cleanFood(food: any): any {
  const originalName = typeof food.name === "string" ? food.name : "";
  const likelyTurkish = food.source === "turkomp" || food.language === "tr" || /[ÇĞİÖŞÜçğıöşü]/u.test(originalName);
  const displayName = displayText(originalName, likelyTurkish ? "tr" : food.language);
  const normalizedName = normalizedText(originalName);
  const originalBrand = cleanWhitespace(food.brand);
  const displayBrand = originalBrand ? displayText(originalBrand, likelyTurkish ? "tr" : food.language) : undefined;
  const normalizedBrand = originalBrand ? normalizedText(originalBrand) : undefined;
  const normalizedNameNative = normalizedText(displayName, false);
  const aliases = Array.isArray(food.aliases) ? food.aliases : [];
  const cleanedAliases = [...new Set(aliases.map(cleanWhitespace).filter(Boolean) as string[])].sort();
  const searchAliases = [...new Set([normalizedNameNative, normalizedName, ...cleanedAliases.flatMap((v) => [normalizedText(v, false), normalizedText(v)])].filter(Boolean))].sort();
  const categoryName = cleanWhitespace(food.category?.name);
  const languages = [...new Set([food.language, ...(Array.isArray(food.languages) ? food.languages : []), ...(Array.isArray(food.detected_languages) ? food.detected_languages : [])]
    .map((value) => cleanWhitespace(value)?.toLowerCase().split(/[-_]/)[0]).filter((value) => value && /^[a-z]{2,3}$/.test(value)) as string[])].sort();
  const flags = new Set(nutritionFlags(food));
  if (!normalizedName || normalizedName.length < 3 || PLACEHOLDER_NAMES.has(normalizedName)) flags.add("weak_product_name");
  if (normalizedBrand && normalizedName === normalizedBrand) { flags.add("brand_only_product_name"); flags.add("weak_product_name"); }
  if (flags.has("weak_product_name") || flags.has("brand_only_product_name")) flags.add("needs_name_review");
  const portions = (Array.isArray(food.portions) ? food.portions : []).map((portion: any) => {
    const originalDescription = typeof portion.description === "string" ? portion.description : "";
    const displayDescription = cleanWhitespace(originalDescription) ?? "";
    const normalizedUnit = normalizeUnit(portion.unit);
    return { ...portion, original_description: originalDescription, display_description: displayDescription,
      normalized_label: normalizedText(displayDescription), ...(normalizedUnit ? { normalized_unit: normalizedUnit } : {}) };
  });
  const cleanedIngredients = cleanWhitespace(food.ingredients);
  return {
    ...food,
    portions,
    cleaning_version: CLEANING_SCHEMA_VERSION,
    original_name: originalName,
    display_name: displayName,
    normalized_name: normalizedName,
    search_aliases: searchAliases,
    ...(originalBrand ? { original_brand: originalBrand, display_brand: displayBrand, normalized_brand: normalizedBrand } : {}),
    ...(categoryName ? { display_category: displayText(categoryName, food.language), normalized_category: normalizedText(categoryName) } : {}),
    cleaned_aliases: cleanedAliases,
    ...(cleanedIngredients ? { cleaned_ingredients: cleanedIngredients } : {}),
    normalized_languages: languages,
    cleaning_flags: [...flags].sort(),
  };
}

export async function* readJsonlGz(path: string): AsyncGenerator<any> {
  const reader = createInterface({ input: createReadStream(path).pipe(createGunzip()), crlfDelay: Infinity });
  for await (const line of reader) if (line.trim()) yield JSON.parse(line);
}

export async function atomicGzip(path: string) {
  await fs.mkdir(dirname(path), { recursive: true });
  const temp = `${path}.tmp`; await fs.rm(temp, { force: true });
  const gzip = createGzip({ level: 6 }), output = createWriteStream(temp), done = pipeline(gzip, output);
  return { stream: gzip, finish: async () => { gzip.end(); await done; await fs.rename(temp, path); }, abort: async () => { gzip.destroy(); await fs.rm(temp, { force: true }); } };
}

export async function writeLine(stream: Writable, value: unknown) {
  if (!stream.write(`${JSON.stringify(value)}\n`)) await once(stream, "drain");
}
