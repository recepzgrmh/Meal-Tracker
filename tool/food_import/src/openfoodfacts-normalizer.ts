import { NORMALIZATION_SCHEMA_VERSION, type NormalizedFood, type NormalizedNutrient } from "../normalization-schema.ts";
import { completeness, finite, strings, text } from "./normalization-common.ts";

export interface OffFilterConfig {
  minCoreNutrients: number;
  requireEnergy: boolean;
  requireBarcode: boolean;
  maxKcal: number;
}

export const DEFAULT_OFF_FILTER: OffFilterConfig = {
  minCoreNutrients: Number(process.env.OFF_MIN_CORE_NUTRIENTS ?? 3),
  requireEnergy: process.env.OFF_REQUIRE_ENERGY !== "false",
  requireBarcode: process.env.OFF_REQUIRE_BARCODE !== "false",
  maxKcal: Number(process.env.OFF_MAX_KCAL ?? 1000),
};

function offNumber(n: any, key: string): number | undefined { return finite(n?.[`${key}_100g`]); }

export function normalizeOff(record: any, datasetVersion: string, config = DEFAULT_OFF_FILTER): { food?: NormalizedFood; skip?: string } {
  const name = text(record?.product_name) ?? text(record?.product_name_en) ?? text(record?.generic_name);
  if (!name) return { skip: "missing_name" };
  const barcode = text(record?.code);
  if (config.requireBarcode && (!barcode || !/^\d{4,14}$/.test(barcode))) return { skip: "invalid_or_missing_barcode" };
  const n = record?.nutriments;
  if (!n || typeof n !== "object") return { skip: "missing_nutriments" };
  const kcal = offNumber(n, "energy-kcal") ?? (() => { const kj = offNumber(n, "energy"); return kj === undefined ? undefined : kj / 4.184; })();
  const nutrition: NormalizedFood["nutrition"] = {
    kcal_100g: kcal === undefined ? undefined : Number(kcal.toFixed(6)), protein_100g: offNumber(n, "proteins"),
    carbs_100g: offNumber(n, "carbohydrates"), fat_100g: offNumber(n, "fat"), fiber_100g: offNumber(n, "fiber"),
    sugars_100g: offNumber(n, "sugars"), sodium_mg_100g: offNumber(n, "sodium") === undefined ? undefined : Number((offNumber(n, "sodium")! * 1000).toFixed(6)),
    nutrients: [],
  };
  const coreValues = [nutrition.kcal_100g, nutrition.protein_100g, nutrition.carbs_100g, nutrition.fat_100g, nutrition.fiber_100g, nutrition.sugars_100g, nutrition.sodium_mg_100g];
  if (config.requireEnergy && nutrition.kcal_100g === undefined) return { skip: "missing_energy" };
  if (coreValues.filter((v) => v !== undefined).length < config.minCoreNutrients) return { skip: "insufficient_core_nutrition" };
  if ((nutrition.kcal_100g ?? 0) < 0 || (nutrition.kcal_100g ?? 0) > config.maxKcal ||
      [nutrition.protein_100g, nutrition.carbs_100g, nutrition.fat_100g, nutrition.fiber_100g, nutrition.sugars_100g].some((v) => v !== undefined && (v < 0 || v > 100)) ||
      (nutrition.sodium_mg_100g !== undefined && (nutrition.sodium_mg_100g < 0 || nutrition.sodium_mg_100g > 100000))) return { skip: "implausible_core_nutrition" };
  for (const [key, value] of Object.entries(n)) {
    if (!key.endsWith("_100g")) continue;
    const amount = finite(value); if (amount === undefined) continue;
    const base = key.slice(0, -5);
    const displayUnit = text(n[`${base}_unit`]);
    const canonicalUnit = base === "energy" ? "kJ" : base === "energy-kcal" ? "kcal" : displayUnit === "%" ? "%" : "g";
    nutrition.nutrients.push({ source_key: base, name: base.replaceAll("-", " "), amount_100g: amount, unit: canonicalUnit, derivation_code: "OFF_CONTRIBUTED", derivation_description: displayUnit && displayUnit !== canonicalUnit ? `OFF *_100g standardized value; source display unit: ${displayUnit}` : "OFF *_100g standardized value" });
  }
  const servingSize = finite(record.serving_quantity);
  const servingUnit = text(record.serving_quantity_unit);
  const portionGram = servingSize !== undefined && servingSize > 0 && (!servingUnit || /^g$/i.test(servingUnit)) ? servingSize : undefined;
  const portions = text(record.serving_size) ? [{ amount: 1, unit: "serving", description: text(record.serving_size)!, gram_weight: portionGram }] : [];
  const languages = record.languages_codes && typeof record.languages_codes === "object" ? Object.keys(record.languages_codes).sort() : strings(record.languages_tags);
  const sourceQualityTags = strings(record.data_quality_tags);
  const food: NormalizedFood = {
    schema_version: NORMALIZATION_SCHEMA_VERSION, name, source: "open_food_facts", source_id: barcode ?? String(record._id), dataset_version: datasetVersion,
    category: { name: text(record.categories), tags: strings(record.categories_tags) },
    nutrition_basis: { amount: 100, unit: "g", description: "Open Food Facts nutriments *_100g fields" }, nutrition, portions,
    serving_size: servingSize, serving_unit: servingUnit, household_serving_description: text(record.serving_size),
    brand: text(record.brands), barcode, ingredients: text(record.ingredients_text) ?? text(record.ingredients_text_en),
    aliases: [text(record.generic_name), text(record.product_name_en)].filter((v): v is string => Boolean(v) && v !== name),
    language: text(record.lang ?? record.lc), languages, countries: strings(record.countries_tags), package_size: text(record.quantity),
    quality: {
      nutrition_completeness: completeness(nutrition), source_completeness: finite(record.completeness), source_quality_tags: sourceQualityTags,
      source_warning_tags: strings(record.data_quality_warnings_tags), source_error_tags: strings(record.data_quality_errors_tags), source_bug_tags: strings(record.data_quality_bugs_tags),
      confidence_inputs: ["barcode", "per_100g_nutrients", ...(text(record.serving_size) ? ["serving_text"] : []), ...(finite(record.completeness) !== undefined ? ["off_completeness"] : []), ...(sourceQualityTags ? ["off_quality_tags"] : [])],
    },
    provenance: { modified_date: record.last_modified_t ? new Date(Number(record.last_modified_t) * 1000).toISOString() : undefined, source_url: barcode ? `https://world.openfoodfacts.org/product/${barcode}` : undefined, source_data_type: text(record.product_type), attribution: "Open Food Facts contributors" },
    scores: { nutriscore_grade: text(record.nutriscore_grade), nutriscore_score: finite(record.nutriscore_score), nutriscore_version: text(record.nutriscore_version), nova_group: finite(record.nova_group), environmental_score_grade: text(record.environmental_score_grade), environmental_score: finite(record.environmental_score_score) },
    labels: strings(record.labels_tags), allergens: strings(record.allergens_tags), traces: strings(record.traces_tags), ingredient_analysis_tags: strings(record.ingredients_analysis_tags),
    popularity: { scans: finite(record.scans_n), unique_scans: finite(record.unique_scans_n) },
  };
  return { food };
}
