/**
 * Pure, deterministic projection policy from canonical/source records to the
 * database catalog. This module never mutates source records, averages
 * nutrition, translates names, infers density, or calls an LLM.
 */
import { cleanWhitespace, displayText, normalizedText, validGtin } from "./cleaning-common.ts";

export const DATABASE_CATALOG_POLICY_VERSION = "database-catalog-policy-2026-08-23.1" as const;

export const CORE_NUTRIENT_KEYS = [
  "kcal_100g", "protein_100g", "carbs_100g", "fat_100g", "fiber_100g", "sugars_100g", "sodium_mg_100g",
] as const;

export type CoreNutrientKey = typeof CORE_NUTRIENT_KEYS[number];
export type CatalogFoodType = "generic_food" | "branded_product";

export interface CatalogPolicyRecord {
  source: string;
  source_id: string | number;
  source_record_ordinal?: number;
  name?: string;
  original_name?: string;
  display_name?: string;
  normalized_name?: string;
  canonical_name_tr?: string;
  canonical_name_en?: string;
  language?: string;
  languages?: string[];
  normalized_languages?: string[];
  detected_languages?: string[];
  aliases?: string[];
  cleaned_aliases?: string[];
  search_aliases?: string[];
  additional_descriptions?: string[];
  regional_name?: string;
  scientific_name?: string;
  brand?: string;
  original_brand?: string;
  display_brand?: string;
  normalized_brand?: string;
  brand_owner?: string;
  barcode?: string;
  ingredients?: string;
  cleaned_ingredients?: string;
  category?: string | { name?: string; code?: string; tags?: string[] };
  display_category?: string;
  package_size?: string;
  portions?: CatalogPortionInput[];
  serving_size?: number;
  serving_unit?: string;
  household_serving_description?: string;
  countries?: string[];
  market_country?: string;
  market_country_tags?: string[];
  labels?: string[];
  allergens?: string[];
  traces?: string[];
  ingredient_analysis_tags?: string[];
  nutrition?: Partial<Record<CoreNutrientKey, number>> & { nutrients?: NutrientDetail[] };
  quality?: {
    nutrition_completeness?: number;
    source_completeness?: number;
    source_warning_tags?: string[];
    source_error_tags?: string[];
    source_bug_tags?: string[];
    confidence_inputs?: string[];
  };
  data_quality_score?: number;
  cleaning_flags?: string[];
  provenance?: {
    publication_date?: string;
    modified_date?: string;
    is_historical_reference?: boolean;
    source_data_type?: string;
    attribution?: string;
  };
}

export interface NutrientDetail {
  source_key?: string;
  derivation_code?: string;
  derivation_description?: string;
  measurement_source?: string;
  data_points?: number;
  min?: number;
  max?: number;
  median?: number;
}

export interface SourceReference {
  source: string;
  source_id: string;
  source_record_ordinal?: number;
}

function sourceRef(record: CatalogPolicyRecord): SourceReference {
  return {
    source: record.source,
    source_id: String(record.source_id),
    ...(Number.isInteger(record.source_record_ordinal) ? { source_record_ordinal: record.source_record_ordinal } : {}),
  };
}

const GENERIC_NUTRITION_SOURCE_RANK: Readonly<Record<string, number>> = {
  usda_foundation: 90,
  turkomp: 85,
  usda_fndds: 75,
  usda_sr_legacy: 65,
  usda_branded: 45,
  open_food_facts: 35,
};

const BRANDED_NUTRITION_SOURCE_RANK: Readonly<Record<string, number>> = {
  usda_branded: 90,
  open_food_facts: 70,
  usda_foundation: 55,
  turkomp: 55,
  usda_fndds: 50,
  usda_sr_legacy: 45,
};

export interface NutritionCandidateScore {
  reference: SourceReference;
  total: number;
  core_nutrient_count: number;
  macro_count: number;
  detail_count: number;
  analytical_detail_count: number;
  source_rank: number;
  penalties: number;
  reasons: string[];
}

export interface PreferredNutritionSelection {
  policy_version: typeof DATABASE_CATALOG_POLICY_VERSION;
  preferred?: CatalogPolicyRecord;
  preferred_reference?: SourceReference;
  score?: number;
  reasons: string[];
  candidates: NutritionCandidateScore[];
}

const finite = (value: unknown): value is number => typeof value === "number" && Number.isFinite(value);
const clamp = (value: number, low: number, high: number) => Math.min(high, Math.max(low, value));

/** Score completeness/provenance before source rank; source rank is a tie-break-strength signal, not truth. */
export function scoreNutritionCandidate(record: CatalogPolicyRecord, foodType: CatalogFoodType): NutritionCandidateScore {
  const nutrition = record.nutrition ?? {};
  const present = CORE_NUTRIENT_KEYS.filter((key) => finite(nutrition[key]) && nutrition[key]! >= 0);
  const macros = ["kcal_100g", "protein_100g", "carbs_100g", "fat_100g"] as const;
  const macroCount = macros.filter((key) => finite(nutrition[key]) && nutrition[key]! >= 0).length;
  const details = Array.isArray(nutrition.nutrients) ? nutrition.nutrients : [];
  const analytical = details.filter((row) => {
    const text = normalizedText(`${row.derivation_description ?? ""} ${row.measurement_source ?? ""}`);
    return text.includes("analytical") || (finite(row.data_points) && row.data_points! > 0);
  });
  const ranged = details.filter((row) => finite(row.min) || finite(row.max) || finite(row.median));
  const sourceRanks = foodType === "branded_product" ? BRANDED_NUTRITION_SOURCE_RANK : GENERIC_NUTRITION_SOURCE_RANK;
  const sourceRank = sourceRanks[record.source] ?? 20;
  const qualityCompleteness = finite(record.quality?.nutrition_completeness)
    ? clamp(record.quality!.nutrition_completeness!, 0, 1)
    : present.length / CORE_NUTRIENT_KEYS.length;
  const warningTags = record.quality?.source_warning_tags?.length ?? 0;
  const errorTags = record.quality?.source_error_tags?.length ?? 0;
  const bugTags = record.quality?.source_bug_tags?.length ?? 0;
  const nutritionFlags = (record.cleaning_flags ?? []).filter((flag) => /^(nutrition_|macro_|kcal_|possible_sodium)/.test(flag)).length;
  const penalties = Math.min(300, errorTags * 100) + Math.min(180, bugTags * 60) + Math.min(50, warningTags * 10)
    + Math.min(225, nutritionFlags * 75) + (record.provenance?.is_historical_reference ? 25 : 0);
  const total = present.length * 100 + macroCount * 80 + (macroCount === 4 ? 120 : 0)
    + Math.round(qualityCompleteness * 100) + Math.min(100, details.length * 2)
    + Math.min(60, analytical.length * 4) + Math.min(30, ranged.length * 2) + sourceRank - penalties;
  const reasons = [
    `core_nutrients:${present.length}/7`, `meal_logging_macros:${macroCount}/4`, `source_rank:${sourceRank}`,
    ...(macroCount === 4 ? ["complete_kcal_protein_carbs_fat"] : []),
    ...(analytical.length ? [`analytical_or_datapoint_details:${analytical.length}`] : []),
    ...(ranged.length ? [`min_max_median_details:${ranged.length}`] : []),
    ...(record.source === "turkomp" ? ["published_turkomp_average_per_100g_edible_food"] : []),
    ...(record.source === "usda_foundation" ? ["foundation_analytical_priority"] : []),
    ...(penalties ? [`quality_penalties:${penalties}`] : []),
  ];
  return { reference: sourceRef(record), total, core_nutrient_count: present.length, macro_count: macroCount,
    detail_count: details.length, analytical_detail_count: analytical.length, source_rank: sourceRank, penalties, reasons };
}

function compareReference(a: SourceReference, b: SourceReference): number {
  return a.source.localeCompare(b.source, "en") || a.source_id.localeCompare(b.source_id, "en", { numeric: true })
    || (a.source_record_ordinal ?? 0) - (b.source_record_ordinal ?? 0);
}

export function selectPreferredNutritionSource(records: readonly CatalogPolicyRecord[], foodType: CatalogFoodType): PreferredNutritionSelection {
  const scored = records.map((record) => ({ record, score: scoreNutritionCandidate(record, foodType) }))
    .filter(({ score }) => score.core_nutrient_count > 0)
    .sort((a, b) => b.score.total - a.score.total || b.score.macro_count - a.score.macro_count
      || b.score.core_nutrient_count - a.score.core_nutrient_count || compareReference(a.score.reference, b.score.reference));
  const winner = scored[0];
  return {
    policy_version: DATABASE_CATALOG_POLICY_VERSION,
    ...(winner ? { preferred: winner.record, preferred_reference: winner.score.reference, score: winner.score.total } : {}),
    reasons: winner ? ["single_source_nutrition_selected_without_averaging_or_imputation", ...winner.score.reasons] : ["no_usable_nonnegative_core_nutrition"],
    candidates: scored.map(({ score }) => score),
  };
}

export interface CatalogPortionInput {
  amount?: number;
  unit?: string;
  normalized_unit?: string;
  description?: string;
  original_description?: string;
  display_description?: string;
  normalized_label?: string;
  gram_weight?: number;
  source_portion_id?: string;
  source_modifier?: string;
  sequence?: number;
}

export interface CatalogPortion {
  amount?: number;
  unit?: string;
  display_description: string;
  normalized_label: string;
  gram_weight?: number;
  description_aliases: string[];
  source_portions: Array<SourceReference & { source_portion_id?: string }>;
  conversion_method: "explicit_gram_weight" | "exact_mass_unit_conversion" | "unresolved";
  dedupe_key: string;
}

const UNIT_ALIASES: Readonly<Record<string, string>> = {
  g: "g", gr: "g", grm: "g", gram: "g", grams: "g", gramme: "g", grammes: "g",
  kg: "kg", kilogram: "kg", kilograms: "kg",
  mg: "mg", milligram: "mg", milligrams: "mg",
  ml: "ml", milliliter: "ml", milliliters: "ml", millilitre: "ml", millilitres: "ml",
  l: "l", liter: "l", liters: "l", litre: "l", litres: "l",
  oz: "oz", ounce: "oz", ounces: "oz", lb: "lb", pound: "lb", pounds: "lb",
  cup: "cup", cups: "cup", tbsp: "tbsp", tablespoon: "tbsp", tablespoons: "tbsp",
  tsp: "tsp", teaspoon: "tsp", teaspoons: "tsp", serving: "serving", servings: "serving",
  piece: "piece", pieces: "piece", slice: "slice", slices: "slice",
};

const MASS_TO_GRAMS: Readonly<Record<string, number>> = { mg: 0.001, g: 1, kg: 1000, oz: 28.349523125, lb: 453.59237 };
const rounded = (value: number) => Number(value.toFixed(6));

export function normalizeCatalogUnit(value: unknown): string | undefined {
  const key = normalizedText(value);
  return UNIT_ALIASES[key] ?? (key || undefined);
}

function parseLeadingMeasure(description: string): { amount: number; unit: string } | undefined {
  const match = description.trim().match(/^(?:(\d+)\s+)?(\d+)\s*\/\s*(\d+)\s+([\p{L}]+)|^(\d+(?:[.,]\d+)?)\s+([\p{L}]+)/u);
  if (!match) return undefined;
  const amount = match[2]
    ? Number(match[1] ?? 0) + Number(match[2]) / Number(match[3])
    : Number(match[5].replace(",", "."));
  const unit = normalizeCatalogUnit(match[4] ?? match[6]);
  return finite(amount) && amount > 0 && unit ? { amount: rounded(amount), unit } : undefined;
}

function normalizePortion(record: CatalogPolicyRecord, portion: CatalogPortionInput): CatalogPortion | undefined {
  const originalDescription = cleanWhitespace(portion.display_description ?? portion.description ?? portion.original_description) ?? "";
  const parsed = originalDescription ? parseLeadingMeasure(originalDescription) : undefined;
  const suppliedUnit = normalizeCatalogUnit(portion.normalized_unit ?? portion.unit);
  let amount = finite(portion.amount) && portion.amount! > 0 ? rounded(portion.amount!) : parsed?.amount;
  let unit = suppliedUnit ?? parsed?.unit;
  // Normalizers commonly store a household measure under unit=serving. Prefer
  // an explicit parsed household unit, while retaining the original text.
  if (unit === "serving" && parsed?.unit && parsed.unit !== "serving") { unit = parsed.unit; amount = parsed.amount; }
  let gramWeight: number | undefined;
  let conversion: CatalogPortion["conversion_method"] = "unresolved";
  if (finite(portion.gram_weight) && portion.gram_weight! > 0) {
    gramWeight = rounded(portion.gram_weight!); conversion = "explicit_gram_weight";
  } else if (amount && unit && MASS_TO_GRAMS[unit]) {
    gramWeight = rounded(amount * MASS_TO_GRAMS[unit]); conversion = "exact_mass_unit_conversion";
  }
  const label = normalizedText(originalDescription || [amount, unit].filter((value) => value !== undefined).join(" "));
  if (!label && !gramWeight) return undefined;
  const displayDescription = originalDescription || [amount, unit].filter((value) => value !== undefined).join(" ");
  const gramsKey = gramWeight === undefined ? "no-g" : gramWeight.toFixed(6);
  const measureKey = amount && unit && unit !== "serving" ? `${amount}:${unit}` : undefined;
  const dedupeKey = measureKey ? `measure:${measureKey}:${gramsKey}` : `label:${label}:${gramsKey}`;
  return {
    ...(amount ? { amount } : {}), ...(unit ? { unit } : {}), display_description: displayDescription,
    normalized_label: label, ...(gramWeight ? { gram_weight: gramWeight } : {}), description_aliases: [displayDescription],
    source_portions: [{ ...sourceRef(record), ...(portion.source_portion_id ? { source_portion_id: String(portion.source_portion_id) } : {}) }],
    conversion_method: conversion, dedupe_key: dedupeKey,
  };
}

function recordPortions(record: CatalogPolicyRecord): CatalogPortionInput[] {
  const portions = Array.isArray(record.portions) ? [...record.portions] : [];
  const servingAmount = finite(record.serving_size) && record.serving_size! > 0 ? record.serving_size : undefined;
  const servingUnit = normalizeCatalogUnit(record.serving_unit);
  const household = cleanWhitespace(record.household_serving_description);
  if ((servingAmount || household) && !portions.some((portion) => cleanWhitespace(portion.description ?? portion.display_description) === household
    && finite(portion.gram_weight) && servingAmount && servingUnit === "g" && rounded(portion.gram_weight!) === rounded(servingAmount))) {
    portions.push({ amount: servingAmount, unit: servingUnit, description: household ?? [servingAmount, servingUnit].filter(Boolean).join(" "),
      gram_weight: servingAmount && servingUnit === "g" ? servingAmount : undefined });
  }
  return portions;
}

/** Dedupes exact semantic measures only; close gram weights are not fuzzy-merged. */
export function normalizeAndDedupePortions(records: readonly CatalogPolicyRecord[]): CatalogPortion[] {
  const groups = new Map<string, CatalogPortion>();
  const orderedRecords = [...records].sort((a, b) => compareReference(sourceRef(a), sourceRef(b)));
  for (const record of orderedRecords) for (const input of recordPortions(record)) {
    const portion = normalizePortion(record, input); if (!portion) continue;
    const existing = groups.get(portion.dedupe_key);
    if (!existing) { groups.set(portion.dedupe_key, portion); continue; }
    existing.description_aliases = [...new Set([...existing.description_aliases, ...portion.description_aliases])].sort((a, b) => a.localeCompare(b, "en"));
    existing.source_portions = [...existing.source_portions, ...portion.source_portions]
      .sort((a, b) => compareReference(a, b) || String(a.source_portion_id ?? "").localeCompare(String(b.source_portion_id ?? ""), "en", { numeric: true }));
    if (portion.display_description.length > existing.display_description.length) existing.display_description = portion.display_description;
  }
  return [...groups.values()].sort((a, b) => (a.gram_weight ?? Number.POSITIVE_INFINITY) - (b.gram_weight ?? Number.POSITIVE_INFINITY)
    || a.normalized_label.localeCompare(b.normalized_label, "en") || a.dedupe_key.localeCompare(b.dedupe_key, "en"));
}

const WEAK_NAMES = new Set(["", "food", "product", "unknown", "unnamed", "none", "null", "n a", "na", "test", "todo", "no name"]);

function meaningfulName(value: unknown): value is string {
  const text = cleanWhitespace(value), normalized = normalizedText(text);
  return Boolean(text && normalized.length >= 3 && !WEAK_NAMES.has(normalized));
}

function recordLanguages(record: CatalogPolicyRecord): string[] {
  const explicit = [record.language, ...(record.normalized_languages ?? []), ...(record.detected_languages ?? []), ...(record.languages ?? [])]
    .map((value) => cleanWhitespace(value)?.toLowerCase().split(/[-_]/)[0]).filter((value): value is string => Boolean(value));
  if (record.source === "turkomp") explicit.push("tr");
  if (record.source.startsWith("usda_")) explicit.push("en");
  return [...new Set(explicit)].sort();
}

function displaySourceRank(source: string, locale: "tr" | "en"): number {
  if (locale === "tr") return source === "turkomp" ? 100 : source === "open_food_facts" ? 80 : 40;
  if (source === "usda_foundation") return 100;
  if (source === "usda_fndds") return 95;
  if (source === "usda_sr_legacy") return 90;
  if (source === "usda_branded") return 85;
  if (source === "open_food_facts") return 80;
  return 40;
}

interface DisplayCandidate { value: string; locale?: "tr" | "en"; score: number; reference: SourceReference }

function displayCandidates(records: readonly CatalogPolicyRecord[]): DisplayCandidate[] {
  const candidates: DisplayCandidate[] = [];
  for (const record of records) {
    const reference = sourceRef(record), languages = recordLanguages(record);
    const add = (value: unknown, locale: "tr" | "en" | undefined, explicit: boolean) => {
      if (!meaningfulName(value)) return;
      const clean = cleanWhitespace(value)!;
      const sourceRank = locale ? displaySourceRank(record.source, locale) : 30;
      const weakPenalty = (record.cleaning_flags ?? []).some((flag) => flag === "weak_product_name" || flag === "brand_only_product_name") ? 100 : 0;
      candidates.push({ value: displayText(clean, locale), locale, score: sourceRank + (explicit ? 25 : 0) + (clean.length <= 160 ? 10 : 0) - weakPenalty, reference });
    };
    add(record.canonical_name_tr, "tr", true); add(record.canonical_name_en, "en", true);
    const declared = languages.length === 1 && (languages[0] === "tr" || languages[0] === "en") ? languages[0] as "tr" | "en" : undefined;
    add(record.display_name ?? record.name ?? record.original_name, declared, Boolean(declared));
  }
  return candidates.sort((a, b) => b.score - a.score || a.value.localeCompare(b.value, "en") || compareReference(a.reference, b.reference));
}

export interface CatalogNameProjection {
  policy_version: typeof DATABASE_CATALOG_POLICY_VERSION;
  original_names: Array<SourceReference & { value: string }>;
  display_name_tr?: string;
  display_name_en?: string;
  display_name_default?: string;
  display_fallback_language?: "tr" | "en" | "source";
  search_aliases: string[];
  reasons: string[];
}

function nativeSearchText(value: string): string {
  return value.normalize("NFC").toLocaleLowerCase("tr-TR").replace(/[’'`´]/g, "")
    .replace(/[^\p{L}\p{N}]+/gu, " ").trim().replace(/\s+/g, " ");
}

/** Generates aliases from published/source strings only; it performs no translation. */
export function projectCatalogNames(records: readonly CatalogPolicyRecord[], foodType: CatalogFoodType): CatalogNameProjection {
  const originalNames = records.flatMap((record) => {
    const value = cleanWhitespace(record.original_name ?? record.name);
    return value ? [{ ...sourceRef(record), value }] : [];
  }).sort((a, b) => compareReference(a, b));
  const candidates = displayCandidates(records);
  const tr = candidates.find((candidate) => candidate.locale === "tr");
  const en = candidates.find((candidate) => candidate.locale === "en");
  const fallback = tr ?? en ?? candidates[0];
  const sourceStrings: string[] = [];
  for (const record of records) {
    sourceStrings.push(...[
      record.original_name, record.name, record.display_name, record.canonical_name_tr, record.canonical_name_en,
      record.regional_name, record.scientific_name, ...(record.aliases ?? []), ...(record.cleaned_aliases ?? []), ...(record.search_aliases ?? []),
      ...(record.additional_descriptions ?? []),
    ].filter(meaningfulName));
    if (foodType === "branded_product" && meaningfulName(record.display_brand ?? record.brand) && meaningfulName(record.display_name ?? record.name)) {
      sourceStrings.push(`${record.display_brand ?? record.brand} ${record.display_name ?? record.name}`);
    }
  }
  if (tr) sourceStrings.push(tr.value); if (en) sourceStrings.push(en.value); if (fallback) sourceStrings.push(fallback.value);
  const aliases = [...new Set(sourceStrings.flatMap((value) => [nativeSearchText(value), normalizedText(value)]).filter((value) => value.length >= 2))].sort((a, b) => a.localeCompare(b, "en"));
  return {
    policy_version: DATABASE_CATALOG_POLICY_VERSION,
    original_names: originalNames,
    ...(tr ? { display_name_tr: tr.value } : {}), ...(en ? { display_name_en: en.value } : {}),
    ...(fallback ? { display_name_default: fallback.value, display_fallback_language: tr ? "tr" : en ? "en" : "source" } : {}),
    search_aliases: aliases,
    reasons: ["original_names_retained_verbatim", "display_names_selected_without_translation", "search_aliases_derived_only_from_source_strings", "no_llm_or_probabilistic_generation"],
  };
}

export interface SelectedMetadataField<T> {
  value: T;
  reference: SourceReference;
  selection_reason: string;
}

export interface BrandedMetadataProjection {
  policy_version: typeof DATABASE_CATALOG_POLICY_VERSION;
  barcode?: SelectedMetadataField<string>;
  brand?: SelectedMetadataField<string>;
  brand_owner?: SelectedMetadataField<string>;
  ingredients?: SelectedMetadataField<string>;
  category?: SelectedMetadataField<string>;
  package_size?: SelectedMetadataField<string>;
  countries: string[];
  languages: string[];
  labels: string[];
  allergens: string[];
  traces: string[];
  ingredient_analysis_tags: string[];
  contradiction_flags: string[];
  reasons: string[];
}

function fieldSourceRank(source: string): number {
  return source === "usda_branded" ? 100 : source === "open_food_facts" ? 85 : source === "usda_foundation" ? 70
    : source === "turkomp" ? 65 : source === "usda_fndds" ? 60 : source === "usda_sr_legacy" ? 55 : 30;
}

function selectTextField(records: readonly CatalogPolicyRecord[], getter: (record: CatalogPolicyRecord) => unknown,
  reason: string, preferLonger = false): SelectedMetadataField<string> | undefined {
  const values = records.flatMap((record) => {
    const value = cleanWhitespace(getter(record)); if (!value) return [];
    const qualityPenalty = (record.quality?.source_error_tags?.length ?? 0) * 40 + (record.quality?.source_bug_tags?.length ?? 0) * 20;
    const lengthScore = preferLonger ? Math.min(40, Math.floor(value.length / 10)) : 0;
    return [{ value, reference: sourceRef(record), score: fieldSourceRank(record.source) + lengthScore - qualityPenalty }];
  }).sort((a, b) => b.score - a.score || (preferLonger ? b.value.length - a.value.length : 0)
    || a.value.localeCompare(b.value, "en") || compareReference(a.reference, b.reference));
  return values[0] ? { value: values[0].value, reference: values[0].reference, selection_reason: reason } : undefined;
}

const unionText = (records: readonly CatalogPolicyRecord[], getter: (record: CatalogPolicyRecord) => unknown[]): string[] =>
  [...new Set(records.flatMap((record) => getter(record)).map(cleanWhitespace).filter((value): value is string => Boolean(value)))].sort((a, b) => a.localeCompare(b, "en"));

/** Selects fields independently; ingredient lists are never concatenated. */
export function selectBrandedMetadata(records: readonly CatalogPolicyRecord[]): BrandedMetadataProjection {
  const observedCodes = [...new Set(records.map((record) => cleanWhitespace(record.barcode)).filter((code): code is string => Boolean(code)))].sort();
  const validCodes = observedCodes.filter(validGtin);
  const contradictionFlags: string[] = [];
  if (validCodes.length > 1) contradictionFlags.push("multiple_distinct_valid_gtins");
  if (observedCodes.some((code) => !validGtin(code))) contradictionFlags.push("invalid_or_structural_barcode_present");
  const normalizedBrands = [...new Set(records.map((record) => normalizedText(record.normalized_brand ?? record.display_brand ?? record.brand)).filter(Boolean))];
  if (normalizedBrands.length > 1) contradictionFlags.push("multiple_distinct_normalized_brands");
  const barcodeRecord = validCodes.length === 1 ? records.find((record) => cleanWhitespace(record.barcode) === validCodes[0]) : undefined;
  const brand = selectTextField(records, (record) => record.display_brand ?? record.brand, "preferred_nonempty_brand_by_source_quality");
  const brandOwner = selectTextField(records, (record) => record.brand_owner, "preferred_nonempty_brand_owner_by_source_quality");
  const ingredients = selectTextField(records, (record) => record.cleaned_ingredients ?? record.ingredients,
    "single_ingredients_statement_selected_by_source_quality_and_specificity_without_concatenation", true);
  const category = selectTextField(records, (record) => typeof record.category === "string" ? record.category : record.category?.name ?? record.display_category,
    "preferred_nonempty_category_by_source_quality_and_specificity", true);
  const packageSize = selectTextField(records, (record) => record.package_size, "preferred_nonempty_package_size_by_source_quality");
  return {
    policy_version: DATABASE_CATALOG_POLICY_VERSION,
    ...(barcodeRecord ? { barcode: { value: validCodes[0], reference: sourceRef(barcodeRecord), selection_reason: "single_checksum_valid_gtin_shared_by_group" } } : {}),
    ...(brand ? { brand } : {}), ...(brandOwner ? { brand_owner: brandOwner } : {}), ...(ingredients ? { ingredients } : {}),
    ...(category ? { category } : {}), ...(packageSize ? { package_size: packageSize } : {}),
    countries: unionText(records, (record) => [...(record.market_country_tags ?? []), ...(record.countries ?? []), ...(record.market_country ? [record.market_country] : [])]),
    languages: [...new Set(records.flatMap(recordLanguages))].sort(),
    labels: unionText(records, (record) => record.labels ?? []), allergens: unionText(records, (record) => record.allergens ?? []),
    traces: unionText(records, (record) => record.traces ?? []), ingredient_analysis_tags: unionText(records, (record) => record.ingredient_analysis_tags ?? []),
    contradiction_flags: contradictionFlags,
    reasons: ["metadata_fields_selected_independently", "source_values_preserved_with_field_provenance", "set_like_tags_union_deduplicated", "no_llm_or_generated_metadata"],
  };
}
