/** Versioned, source-preserving model for deterministic food normalization. */
export const NORMALIZATION_SCHEMA_VERSION = "1.0.0" as const;

export type FoodSource =
  | "usda_foundation"
  | "usda_fndds"
  | "usda_sr_legacy"
  | "usda_branded"
  | "turkomp"
  | "open_food_facts";

export interface NormalizedNutrient {
  source_key: string;
  name: string;
  amount_100g: number;
  unit: string;
  derivation_code?: string;
  derivation_description?: string;
  measurement_source?: string;
  data_points?: number;
  min?: number;
  max?: number;
  median?: number;
}

export interface NormalizedPortion {
  amount?: number;
  unit?: string;
  description: string;
  gram_weight?: number;
  source_portion_id?: string;
  source_modifier?: string;
  sequence?: number;
  min_year_acquired?: number;
}

export interface NormalizedFood {
  schema_version: typeof NORMALIZATION_SCHEMA_VERSION;
  name: string;
  source: FoodSource;
  source_id: string;
  dataset_version: string;
  category?: {
    name?: string;
    code?: string;
    hierarchy?: string[];
    tags?: string[];
  };
  nutrition_basis: { amount: 100; unit: "g"; description: string };
  nutrition: {
    kcal_100g?: number;
    protein_100g?: number;
    carbs_100g?: number;
    fat_100g?: number;
    fiber_100g?: number;
    sugars_100g?: number;
    sodium_mg_100g?: number;
    nutrients: NormalizedNutrient[];
  };
  portions: NormalizedPortion[];
  serving_size?: number;
  serving_unit?: string;
  household_serving_description?: string;
  brand?: string;
  brand_owner?: string;
  barcode?: string;
  ingredients?: string;
  aliases?: string[];
  additional_descriptions?: string[];
  language?: string;
  languages?: string[];
  countries?: string[];
  market_country?: string;
  food_code?: string;
  package_size?: string;
  scientific_name?: string;
  regional_name?: string;
  classification_codes?: { system: string; codes: string[] }[];
  quality: {
    nutrition_completeness: number;
    source_completeness?: number;
    source_quality_tags?: string[];
    source_warning_tags?: string[];
    source_error_tags?: string[];
    source_bug_tags?: string[];
    confidence_inputs: string[];
  };
  provenance: {
    publication_date?: string;
    available_date?: string;
    modified_date?: string;
    valid_from?: string;
    valid_to?: string;
    source_url?: string;
    source_data_type?: string;
    source_food_class?: string;
    is_historical_reference?: boolean;
    nutrient_basis_note?: string;
    attribution?: string;
  };
  scores?: {
    nutriscore_grade?: string;
    nutriscore_score?: number;
    nutriscore_version?: string;
    nova_group?: number;
    environmental_score_grade?: string;
    environmental_score?: number;
  };
  labels?: string[];
  allergens?: string[];
  traces?: string[];
  ingredient_analysis_tags?: string[];
  popularity?: { scans?: number; unique_scans?: number };
  nutrient_conversion_factors?: unknown[];
}

