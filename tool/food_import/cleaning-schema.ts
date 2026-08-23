export const CLEANING_SCHEMA_VERSION = "food-cleaning-v1" as const;
export const CANONICALIZATION_SCHEMA_VERSION = "food-canonical-v1" as const;

export interface CleanedPortion {
  original_description: string;
  display_description: string;
  normalized_label: string;
  normalized_unit?: string;
}

export interface CleaningFields {
  cleaning_version: typeof CLEANING_SCHEMA_VERSION;
  original_name: string;
  display_name: string;
  normalized_name: string;
  search_aliases: string[];
  original_brand?: string;
  display_brand?: string;
  normalized_brand?: string;
  display_category?: string;
  normalized_category?: string;
  cleaned_aliases: string[];
  cleaned_ingredients?: string;
  normalized_languages: string[];
  cleaning_flags: string[];
}

export interface CanonicalFood {
  canonical_schema_version: typeof CANONICALIZATION_SCHEMA_VERSION;
  canonical_id: string;
  canonical_name_tr?: string;
  canonical_name_en?: string;
  normalized_key: string;
  food_type: "generic_food" | "branded_product";
  preparation?: string;
  category?: string;
  representative_source: string;
  representative_source_id: string;
}

export interface CanonicalSourceMapping {
  canonical_schema_version: typeof CANONICALIZATION_SCHEMA_VERSION;
  canonical_id: string;
  source: string;
  source_id: string;
  source_record_ordinal: number;
  match_method: string;
  confidence: "HIGH" | "MEDIUM" | "LOW";
  match_reasons: string[];
  canonical_match_confidence: "HIGH" | "MEDIUM" | "LOW";
  canonical_match_method: string;
  canonical_match_reasons: string[];
  needs_canonical_review: boolean;
}
