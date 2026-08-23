export const CANONICAL_V2_VERSION = "canonical-v2" as const;

export type MatchConfidence = "VERY_HIGH" | "HIGH" | "MEDIUM" | "AMBIGUOUS";
export type BarcodeIdentityStatus =
  | "VERIFIED_COMPATIBLE"
  | "PROBABLE_COMPATIBLE"
  | "CONTRADICTED"
  | "AMBIGUOUS"
  | "NOT_APPLICABLE";

export type GtinCodeType = "GTIN_8" | "UPC_A" | "EAN_13" | "GTIN_14" | "STRUCTURAL_ONLY" | "UNKNOWN";

export interface CanonicalV2Mapping {
  canonicalization_version: typeof CANONICAL_V2_VERSION;
  canonical_id: string;
  source: string;
  source_id: string;
  source_record_ordinal: number;
  match_method: string;
  match_confidence: MatchConfidence;
  match_reasons: string[];
  contradiction_flags: string[];
  barcode_identity_status: BarcodeIdentityStatus;
  code_type: GtinCodeType;
  needs_review: boolean;
}

export interface CanonicalV2Food {
  canonicalization_version: typeof CANONICAL_V2_VERSION;
  canonical_id: string;
  canonical_name_tr?: string;
  canonical_name_en?: string;
  normalized_key: string;
  food_type: "generic_food" | "branded_product";
  preparation?: string[];
  state?: string[];
  qualifiers?: Record<string, string[]>;
  category?: string;
  representative_source: string;
  representative_source_id: string;
  source_count: number;
}

export interface CanonicalV2Candidate {
  candidate_id: string;
  candidate_type: "HUMAN_REVIEW" | "BLOCKED_CONTRADICTION";
  left: Record<string, unknown>;
  right: Record<string, unknown>;
  match_method: string;
  match_confidence: MatchConfidence;
  match_reasons: string[];
  contradiction_flags: string[];
  barcode_identity_status: BarcodeIdentityStatus;
  needs_review: boolean;
}
