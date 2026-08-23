import { NORMALIZATION_SCHEMA_VERSION, type NormalizedFood, type NormalizedNutrient } from "../normalization-schema.ts";
import { completeness, finite, text } from "./normalization-common.ts";

const MAIN_BY_MARKER: Record<string, keyof Omit<NormalizedFood["nutrition"], "nutrients">> = {
  ENERC: "kcal_100g", PROT: "protein_100g", CHO: "carbs_100g", FAT: "fat_100g", FIBT: "fiber_100g", NA: "sodium_mg_100g",
};
const SUGAR_MARKERS = new Set(["SUCS", "GLUS", "FRUS", "LACS", "MALS", "GALS"]);

export function normalizeTurkomp(record: any, datasetVersion: string): NormalizedFood | undefined {
  const name = text(record?.name), sourceId = record?.source_food_id === undefined ? undefined : String(record.source_food_id);
  if (!name || !sourceId) return undefined;
  const nutrition: NormalizedFood["nutrition"] = { nutrients: [] };
  let sugarSum = 0, sugarParts = 0;
  for (const row of record.nutrients ?? []) {
    const amount = finite(row.average), marker = text(row.marker), unit = text(row.unit);
    if (amount === undefined || !marker || !unit) continue;
    const nutrient: NormalizedNutrient = {
      source_key: String(row.component_id ?? marker), name: text(row.name) ?? marker,
      amount_100g: amount, unit, derivation_code: "TURKOMP_AVERAGE",
      derivation_description: "Published TürKomp average per 100 g edible portion",
      min: finite(row.min), max: finite(row.max),
    };
    nutrition.nutrients.push(nutrient);
    const key = MAIN_BY_MARKER[marker];
    if (key && nutrition[key] === undefined) nutrition[key] = amount;
    if (SUGAR_MARKERS.has(marker) && unit.toLowerCase() === "g") { sugarSum += amount; sugarParts++; }
  }
  if (sugarParts) {
    nutrition.sugars_100g = Number(sugarSum.toFixed(6));
    nutrition.nutrients.push({ source_key: "derived:sugars_sum", name: "Total sugars (sum of published mono/disaccharides)", amount_100g: nutrition.sugars_100g, unit: "g", derivation_code: "SUM_COMPONENTS", derivation_description: `Sum of ${sugarParts} available TürKomp sugar components; not a separately published total` });
  }
  return {
    schema_version: NORMALIZATION_SCHEMA_VERSION, name, source: "turkomp", source_id: sourceId, dataset_version: datasetVersion,
    category: { name: Array.isArray(record.food_groups) ? text(record.food_groups[0]) : undefined, hierarchy: Array.isArray(record.food_groups) ? record.food_groups : undefined },
    nutrition_basis: { amount: 100, unit: "g", description: text(record.basis?.description) ?? "edible portion" }, nutrition, portions: [],
    scientific_name: text(record.scientific_name), regional_name: text(record.regional_name), food_code: text(record.turkomp_code),
    classification_codes: Array.isArray(record.langual_codes) ? [{ system: "LanguaL", codes: record.langual_codes }] : undefined,
    quality: { nutrition_completeness: completeness(nutrition), confidence_inputs: ["published_average", "published_min_max", "per_100g_edible_portion", ...(sugarParts ? ["derived_sugar_component_sum"] : [])] },
    provenance: { source_url: text(record.source_url), nutrient_basis_note: "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.", attribution: "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı" },
    nutrient_conversion_factors: [
      { type: "nitrogen", value: finite(record.nitrogen_factor) }, { type: "fat", value: finite(record.fat_conversion_factor) },
    ].filter((x) => x.value !== undefined),
  };
}

