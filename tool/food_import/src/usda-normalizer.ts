import { NORMALIZATION_SCHEMA_VERSION, type FoodSource, type NormalizedFood, type NormalizedNutrient } from "../normalization-schema.ts";
import { completeness, finite, strings, text } from "./normalization-common.ts";

const MAIN_BY_ID: Record<number, keyof Omit<NormalizedFood["nutrition"], "nutrients">> = {
  1008: "kcal_100g", 2047: "kcal_100g", 2048: "kcal_100g",
  1003: "protein_100g", 1004: "fat_100g", 1005: "carbs_100g",
  1079: "fiber_100g", 1063: "sugars_100g", 2000: "sugars_100g", 1093: "sodium_mg_100g",
};
const MAIN_PRIORITY_BY_ID: Record<number, number> = { 1008: 30, 2048: 20, 2047: 10, 2000: 20, 1063: 10 };

const SOURCE_BY_KIND: Record<string, FoodSource> = {
  foundation: "usda_foundation", fndds: "usda_fndds",
  sr_legacy: "usda_sr_legacy", branded: "usda_branded",
};

function nutrients(record: any): NormalizedFood["nutrition"] {
  const result: NormalizedFood["nutrition"] = { nutrients: [] };
  const selectedPriority: Partial<Record<keyof Omit<NormalizedFood["nutrition"], "nutrients">, number>> = {};
  for (const row of record.foodNutrients ?? []) {
    const amount = finite(row?.amount);
    const nutrient = row?.nutrient;
    if (amount === undefined || !nutrient) continue;
    const id = finite(nutrient.id);
    const unit = text(nutrient.unitName) ?? "unknown";
    const derivation = row.foodNutrientDerivation;
    const detail: NormalizedNutrient = {
      source_key: String(nutrient.id ?? nutrient.number ?? nutrient.name),
      name: text(nutrient.name) ?? String(nutrient.id), amount_100g: amount, unit,
      derivation_code: text(derivation?.code),
      derivation_description: text(derivation?.description),
      measurement_source: text(derivation?.foodNutrientSource?.description),
      data_points: finite(row.dataPoints), min: finite(row.min), max: finite(row.max), median: finite(row.median),
    };
    result.nutrients.push(detail);
    if (amount >= 0 && id !== undefined && MAIN_BY_ID[id]) {
      const key = MAIN_BY_ID[id], priority = MAIN_PRIORITY_BY_ID[id] ?? 10;
      if ((selectedPriority[key] ?? -1) < priority) { result[key] = amount; selectedPriority[key] = priority; }
    }
  }
  return result;
}

export function normalizeUsda(record: any, kind: string, datasetVersion: string): NormalizedFood | undefined {
  const name = text(record?.description);
  const sourceId = record?.fdcId === undefined ? undefined : String(record.fdcId);
  if (!name || !sourceId) return undefined;
  const source = SOURCE_BY_KIND[kind];
  const nutrition = nutrients(record);
  const attrs = (record.foodAttributes ?? []).filter((a: any) => a && typeof a === "object");
  const extraDescriptions = attrs
    .filter((a: any) => a.foodAttributeType?.name === "Additional Description")
    .sort((a: any, b: any) => (finite(a.rank) ?? 9999) - (finite(b.rank) ?? 9999))
    .map((a: any) => text(a.value)).filter(Boolean) as string[];
  const category = record.wweiaFoodCategory ?? record.foodCategory;
  const portions = (record.foodPortions ?? []).map((p: any) => ({
    amount: finite(p.amount ?? p.value), unit: text(p.measureUnit?.abbreviation ?? p.measureUnit?.name),
    description: text(p.portionDescription) ?? [p.amount ?? p.value, p.measureUnit?.name, p.modifier].filter(Boolean).join(" "),
    gram_weight: (finite(p.gramWeight) ?? 0) > 0 ? finite(p.gramWeight) : undefined, source_portion_id: p.id === undefined ? undefined : String(p.id),
    source_modifier: text(p.modifier), sequence: finite(p.sequenceNumber), min_year_acquired: finite(p.minYearAcquired),
  })).filter((p: any) => p.description && p.gram_weight !== undefined);
  if (source === "usda_branded" && finite(record.servingSize) !== undefined) {
    portions.push({
      amount: 1, unit: "serving", description: text(record.householdServingFullText) ?? "1 serving",
      gram_weight: /^(g|grm)$/i.test(text(record.servingSizeUnit) ?? "") && (finite(record.servingSize) ?? 0) > 0 ? finite(record.servingSize) : undefined,
    });
  }
  const confidenceInputs = ["usda_fdc_id", "per_100g_nutrients"];
  if (portions.length) confidenceInputs.push("gram_portions");
  if (nutrition.nutrients.some((n) => n.data_points !== undefined)) confidenceInputs.push("nutrient_data_points");
  if (nutrition.nutrients.some((n) => n.derivation_code)) confidenceInputs.push("nutrient_derivation");
  return {
    schema_version: NORMALIZATION_SCHEMA_VERSION, name, source, source_id: sourceId, dataset_version: datasetVersion,
    category: {
      name: text(category?.description ?? category?.wweiaFoodCategoryDescription ?? record.brandedFoodCategory),
      code: category?.id !== undefined ? String(category.id) : category?.wweiaFoodCategoryCode !== undefined ? String(category.wweiaFoodCategoryCode) : undefined,
    },
    nutrition_basis: { amount: 100, unit: "g", description: "USDA FoodData Central nutrients per 100 g" },
    nutrition, portions,
    serving_size: finite(record.servingSize), serving_unit: text(record.servingSizeUnit),
    household_serving_description: text(record.householdServingFullText),
    brand: text(record.brandName) ?? text(record.brandOwner), brand_owner: text(record.brandOwner),
    barcode: text(record.gtinUpc), ingredients: text(record.ingredients), additional_descriptions: extraDescriptions,
    market_country: text(record.marketCountry), food_code: record.foodCode === undefined ? text(record.ndbNumber) : String(record.foodCode),
    package_size: text(record.packageWeight),
    quality: { nutrition_completeness: completeness(nutrition), confidence_inputs: confidenceInputs },
    provenance: {
      publication_date: text(record.publicationDate), available_date: text(record.availableDate), modified_date: text(record.modifiedDate),
      valid_from: text(record.startDate), valid_to: text(record.endDate), source_data_type: text(record.dataType),
      source_food_class: text(record.foodClass), is_historical_reference: record.isHistoricalReference === true,
      nutrient_basis_note: source === "usda_branded" ? "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields." : undefined,
      attribution: "USDA FoodData Central",
    },
    nutrient_conversion_factors: Array.isArray(record.nutrientConversionFactors) ? record.nutrientConversionFactors : undefined,
  };
}
