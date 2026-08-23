/**
 * Pure, deterministic safety rules for canonical-v2 branded identities.
 *
 * The caller remains responsible for deciding whether PROBABLE_COMPATIBLE is
 * eligible for automatic promotion. This module deliberately treats an exact
 * GTIN as identity evidence, not identity proof.
 */

export type GtinCodeType = "GTIN_8" | "UPC_A" | "EAN_13" | "GTIN_14" | "STRUCTURAL_ONLY" | "UNKNOWN";
export type BarcodeIdentityStatus = "VERIFIED_COMPATIBLE" | "PROBABLE_COMPATIBLE" | "CONTRADICTED" | "AMBIGUOUS";

export type BrandedNutrition = Partial<Record<
  "kcal_100g" | "protein_100g" | "carbs_100g" | "fat_100g" | "fiber_100g" | "sugars_100g" | "sodium_mg_100g",
  number | null
>>;

export interface BrandedIdentityRecord {
  source?: string;
  source_id?: string | number;
  barcode?: string | number | null;
  name?: string | null;
  display_name?: string | null;
  normalized_name?: string | null;
  brand?: string | null;
  display_brand?: string | null;
  normalized_brand?: string | null;
  category?: string | { name?: string | null } | null;
  normalized_category?: string | null;
  ingredients?: string | null;
  cleaned_ingredients?: string | null;
  market_country_tags?: string[] | null;
  country_tags?: string[] | null;
  countries?: string[] | null;
  nutrition?: BrandedNutrition | null;
  data_quality_score?: number | null;
  quality?: { nutrition_completeness?: number | null; source_completeness?: number | null } | null;
}

export interface GtinClassification {
  normalized_code?: string;
  code_type: GtinCodeType;
  structurally_valid: boolean;
  checksum_valid: boolean;
  is_short_or_private_risk: boolean;
}

export interface BrandedCompatibilityResult {
  code_type: GtinCodeType;
  barcode_identity_status: BarcodeIdentityStatus;
  /** Stable number in [0, 1], expressing compatibility rather than data quality. */
  match_confidence: number;
  match_reasons: string[];
  contradiction_flags: string[];
}

export interface BrandedGroupCompatibilityResult extends BrandedCompatibilityResult {
  pair_count: number;
  compatible_pair_count: number;
  contradicted_pair_count: number;
  ambiguous_pair_count: number;
}

const STOP = new Set([
  "a", "an", "and", "the", "with", "of", "for", "from", "in", "to", "ve", "ile", "bir", "icin",
  "brand", "brands", "product", "food", "foods", "original", "classic",
]);

const CATEGORY_FAMILIES: Record<string, string[]> = {
  beverage: ["beverage", "drink", "juice", "tea", "coffee", "water", "soda", "icecek", "meyve suyu"],
  dairy: ["milk", "yogurt", "cheese", "cream", "butter", "sut", "yogurt", "peynir", "tereyagi"],
  meat: ["meat", "beef", "pork", "chicken", "turkey", "sausage", "et", "tavuk", "hindi", "sosis"],
  seafood: ["fish", "seafood", "shrimp", "tuna", "salmon", "balik", "deniz urunu"],
  produce: ["fruit", "vegetable", "produce", "meyve", "sebze"],
  cereal: ["cereal", "breakfast cereal", "grain", "tahil", "gevrek"],
  bakery: ["bread", "bakery", "cake", "pastry", "cookie", "ekmek", "kek", "kurabiye"],
  confectionery: ["candy", "chocolate", "confection", "sweet", "seker", "cikolata"],
  condiment: ["sauce", "dressing", "mustard", "ketchup", "condiment", "sos", "hardal"],
  snack: ["snack", "chips", "crisps", "cracker", "cerez", "kraker"],
  prepared_meal: ["meal", "salad", "soup", "pizza", "sandwich", "yemek", "corba", "salata"],
};

function clean(value: unknown): string {
  return typeof value === "string" || typeof value === "number" ? String(value).normalize("NFKC").trim() : "";
}

function fold(value: unknown): string {
  return clean(value).toLocaleLowerCase("tr-TR").replaceAll("ı", "i").replaceAll("ş", "s").replaceAll("ğ", "g")
    .replaceAll("ç", "c").replaceAll("ö", "o").replaceAll("ü", "u").normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "").replace(/[^\p{L}\p{N}]+/gu, " ").trim().replace(/\s+/g, " ");
}

function tokens(value: unknown): Set<string> {
  return new Set(fold(value).split(" ").filter((token) => token.length > 1 && !STOP.has(token)));
}

function similarity(a: unknown, b: unknown): number | undefined {
  const left = tokens(a), right = tokens(b);
  if (!left.size || !right.size) return undefined;
  let common = 0;
  for (const token of left) if (right.has(token)) common++;
  const jaccard = common / (left.size + right.size - common);
  const containment = common / Math.min(left.size, right.size);
  return Math.max(jaccard, containment * 0.85);
}

function gtinChecksum(code: string): boolean {
  const body = [...code].map(Number), expected = body.pop();
  if (expected === undefined) return false;
  let sum = 0, position = 0;
  for (let index = body.length - 1; index >= 0; index--, position++) sum += body[index] * (position % 2 === 0 ? 3 : 1);
  return (10 - (sum % 10)) % 10 === expected;
}

/** Classifies without padding: leading zeroes are part of the identifier. */
export function classifyGtin(value: unknown): GtinClassification {
  const code = clean(value);
  if (!code || !/^\d+$/.test(code)) return { code_type: "UNKNOWN", structurally_valid: false, checksum_valid: false, is_short_or_private_risk: false };
  const type: GtinCodeType = code.length === 8 ? "GTIN_8" : code.length === 12 ? "UPC_A" : code.length === 13 ? "EAN_13" : code.length === 14 ? "GTIN_14" : "STRUCTURAL_ONLY";
  const standardLength = type !== "STRUCTURAL_ONLY";
  const checksumValid = standardLength && gtinChecksum(code);
  return {
    normalized_code: code,
    code_type: checksumValid ? type : "STRUCTURAL_ONLY",
    structurally_valid: code.length >= 4 && code.length <= 14,
    checksum_valid: checksumValid,
    is_short_or_private_risk: code.length === 8 || (code.length < 12 && code.length !== 8),
  };
}

/** Compatibility alias for callers that only need the checksum decision. */
export function isChecksumValidGtin(value: unknown): boolean { return classifyGtin(value).checksum_valid; }

function nameOf(record: BrandedIdentityRecord): string { return fold(record.normalized_name || record.display_name || record.name); }
function brandOf(record: BrandedIdentityRecord): string { return fold(record.normalized_brand || record.display_brand || record.brand); }
function categoryOf(record: BrandedIdentityRecord): string {
  return fold(record.normalized_category || (typeof record.category === "string" ? record.category : record.category?.name));
}
function ingredientsOf(record: BrandedIdentityRecord): string { return fold(record.cleaned_ingredients || record.ingredients); }

function sourceQuality(record: BrandedIdentityRecord): number | undefined {
  if (Number.isFinite(record.data_quality_score)) return Math.max(0, Math.min(1, Number(record.data_quality_score) / 100));
  const components = [record.quality?.nutrition_completeness, record.quality?.source_completeness].filter(Number.isFinite).map(Number);
  return components.length ? components.reduce((sum, value) => sum + value, 0) / components.length : undefined;
}

function countrySet(record: BrandedIdentityRecord): Set<string> {
  const values = [...(record.market_country_tags ?? []), ...(record.country_tags ?? []), ...(record.countries ?? [])];
  return new Set(values.map((value) => fold(value).replace(/^en /, "")).filter(Boolean));
}

function categoryFamilies(record: BrandedIdentityRecord): Set<string> {
  const haystack = ` ${categoryOf(record)} ${nameOf(record)} `;
  const result = new Set<string>();
  for (const [family, terms] of Object.entries(CATEGORY_FAMILIES)) if (terms.some((term) => haystack.includes(` ${term} `))) result.add(family);
  return result;
}

function disjointNonEmpty(a: Set<string>, b: Set<string>): boolean {
  if (!a.size || !b.size) return false;
  for (const value of a) if (b.has(value)) return false;
  return true;
}

function nutritionConflict(a: BrandedIdentityRecord, b: BrandedIdentityRecord): { conflict: boolean; comparable: number } {
  const left = a.nutrition ?? {}, right = b.nutrition ?? {};
  const limits: Record<string, [number, number]> = {
    kcal_100g: [150, 0.45], protein_100g: [12, 0.65], carbs_100g: [25, 0.60], fat_100g: [15, 0.65], sodium_mg_100g: [800, 0.80],
  };
  let comparable = 0, conflicts = 0;
  for (const [key, [absolute, relative]] of Object.entries(limits)) {
    const x = left[key as keyof BrandedNutrition], y = right[key as keyof BrandedNutrition];
    if (!Number.isFinite(x) || !Number.isFinite(y)) continue;
    comparable++;
    const difference = Math.abs(Number(x) - Number(y));
    if (difference > absolute && difference / Math.max(Math.abs(Number(x)), Math.abs(Number(y)), 1) > relative) conflicts++;
  }
  return { conflict: conflicts >= 2 || (comparable >= 3 && conflicts / comparable >= 0.6), comparable };
}

function sorted(values: Iterable<string>): string[] { return [...new Set(values)].sort(); }
function round(value: number): number { return Number(Math.max(0, Math.min(1, value)).toFixed(4)); }

export function evaluateBrandedCompatibility(left: BrandedIdentityRecord, right: BrandedIdentityRecord): BrandedCompatibilityResult {
  const aCode = classifyGtin(left.barcode), bCode = classifyGtin(right.barcode);
  const reasons = new Set<string>(), flags = new Set<string>();
  const nameScore = similarity(nameOf(left), nameOf(right));
  const brandScore = similarity(brandOf(left), brandOf(right));
  const ingredientScore = similarity(ingredientsOf(left), ingredientsOf(right));
  const aCategories = categoryFamilies(left), bCategories = categoryFamilies(right);
  const categoryConflict = disjointNonEmpty(aCategories, bCategories);
  const marketConflict = disjointNonEmpty(countrySet(left), countrySet(right));
  const nutrition = nutritionConflict(left, right);
  const leftQuality = sourceQuality(left), rightQuality = sourceQuality(right);

  if (aCode.checksum_valid && bCode.checksum_valid && aCode.normalized_code !== bCode.normalized_code) {
    return {
      code_type: aCode.code_type === bCode.code_type ? aCode.code_type : "STRUCTURAL_ONLY",
      barcode_identity_status: "CONTRADICTED", match_confidence: 1,
      match_reasons: ["different_checksum_valid_gtin", "deterministic_keep_separate_no_human_review"],
      contradiction_flags: ["different_valid_gtin"],
    };
  }

  const sameValid = aCode.checksum_valid && bCode.checksum_valid && aCode.normalized_code === bCode.normalized_code;
  const shortRisk = sameValid && (aCode.code_type === "GTIN_8" || aCode.is_short_or_private_risk || bCode.is_short_or_private_risk);
  if (sameValid) reasons.add("exact_checksum_valid_gtin");
  else if (aCode.normalized_code && aCode.normalized_code === bCode.normalized_code) reasons.add("same_structural_barcode_not_verified");
  else reasons.add("barcode_identity_not_shared_and_verified");

  if (nameScore !== undefined) {
    if (nameScore >= 0.72) reasons.add("strong_product_name_compatibility");
    else if (nameScore >= 0.42) reasons.add("moderate_product_name_compatibility");
    else if (nameScore < 0.16) flags.add("strong_product_name_contradiction");
  }
  if (brandScore !== undefined) {
    if (brandScore >= 0.72) reasons.add("strong_brand_compatibility");
    else if (brandScore < 0.2) flags.add("strong_brand_contradiction");
  }
  if (categoryConflict) flags.add("category_family_contradiction");
  else if (aCategories.size && bCategories.size) reasons.add("category_family_compatible");
  if (ingredientScore !== undefined) {
    if (ingredientScore >= 0.55) reasons.add("ingredients_support_identity");
    else if (ingredientScore < 0.08 && ingredientsOf(left).length >= 20 && ingredientsOf(right).length >= 20) flags.add("ingredients_materially_different");
  }
  if (nutrition.comparable >= 2 && !nutrition.conflict) reasons.add("nutrition_supports_compatibility");
  if (nutrition.conflict) flags.add("material_nutrition_contradiction");
  if (marketConflict) flags.add("market_country_disjoint");
  if (shortRisk) reasons.add("short_gtin_requires_strict_corroboration");
  if (leftQuality !== undefined || rightQuality !== undefined) reasons.add("source_quality_context_compared");
  const lowSourceQuality = [leftQuality, rightQuality].some((value) => value !== undefined && value < 0.35);
  if (lowSourceQuality) flags.add("low_source_quality_limits_identity_confidence");

  const identityContradictions = ["strong_product_name_contradiction", "strong_brand_contradiction", "category_family_contradiction"]
    .filter((flag) => flags.has(flag)).length;
  const supportingIdentity = (nameScore !== undefined && nameScore >= 0.42) || (brandScore !== undefined && brandScore >= 0.72) || reasons.has("category_family_compatible") || reasons.has("ingredients_support_identity");
  const hardContradiction = identityContradictions >= 2
    || (flags.has("strong_product_name_contradiction") && flags.has("material_nutrition_contradiction"))
    || (flags.has("category_family_contradiction") && flags.has("material_nutrition_contradiction"))
    || (shortRisk && (identityContradictions > 0 || marketConflict))
    || (flags.has("strong_product_name_contradiction") && !supportingIdentity && (flags.has("ingredients_materially_different") || brandScore === undefined));

  if (sameValid && hardContradiction) {
    reasons.add("exact_gtin_overruled_by_identity_contradictions");
    return { code_type: aCode.code_type, barcode_identity_status: "CONTRADICTED", match_confidence: round(0.9 + Math.min(identityContradictions, 2) * 0.04), match_reasons: sorted(reasons), contradiction_flags: sorted(flags) };
  }

  if (sameValid && shortRisk && !supportingIdentity) {
    flags.add("short_gtin_insufficient_market_and_identity_corroboration");
    return { code_type: aCode.code_type, barcode_identity_status: "AMBIGUOUS", match_confidence: 0.35, match_reasons: sorted(reasons), contradiction_flags: sorted(flags) };
  }

  if (sameValid) {
    const strongSignals = [nameScore !== undefined && nameScore >= 0.72, brandScore !== undefined && brandScore >= 0.72,
      reasons.has("category_family_compatible"), reasons.has("ingredients_support_identity")].filter(Boolean).length;
    if (strongSignals >= (shortRisk ? 2 : 1) && !identityContradictions && !nutrition.conflict && !lowSourceQuality) {
      reasons.add("identity_evidence_corroborates_gtin");
      return { code_type: aCode.code_type, barcode_identity_status: "VERIFIED_COMPATIBLE", match_confidence: round(0.91 + Math.min(strongSignals, 3) * 0.025), match_reasons: sorted(reasons), contradiction_flags: sorted(flags) };
    }
    reasons.add("exact_gtin_without_full_identity_corroboration");
    return { code_type: aCode.code_type, barcode_identity_status: "PROBABLE_COMPATIBLE", match_confidence: round(shortRisk ? 0.58 : 0.74), match_reasons: sorted(reasons), contradiction_flags: sorted(flags) };
  }

  if (aCode.normalized_code && aCode.normalized_code === bCode.normalized_code) flags.add("barcode_checksum_or_length_not_verified");
  return { code_type: aCode.code_type === bCode.code_type ? aCode.code_type : "UNKNOWN", barcode_identity_status: "AMBIGUOUS", match_confidence: round(supportingIdentity ? 0.35 : 0.12), match_reasons: sorted(reasons), contradiction_flags: sorted(flags) };
}

/** Every pair must pass; a group inherits the least-safe pair result. */
export function evaluateBrandedGroupCompatibility(records: readonly BrandedIdentityRecord[]): BrandedGroupCompatibilityResult {
  if (records.length < 2) return { code_type: classifyGtin(records[0]?.barcode).code_type, barcode_identity_status: "AMBIGUOUS", match_confidence: 0,
    match_reasons: ["group_requires_at_least_two_records"], contradiction_flags: [], pair_count: 0, compatible_pair_count: 0, contradicted_pair_count: 0, ambiguous_pair_count: 0 };
  const pairs: BrandedCompatibilityResult[] = [];
  for (let i = 0; i < records.length; i++) for (let j = i + 1; j < records.length; j++) pairs.push(evaluateBrandedCompatibility(records[i], records[j]));
  const contradicted = pairs.filter((pair) => pair.barcode_identity_status === "CONTRADICTED").length;
  const ambiguous = pairs.filter((pair) => pair.barcode_identity_status === "AMBIGUOUS").length;
  const probable = pairs.filter((pair) => pair.barcode_identity_status === "PROBABLE_COMPATIBLE").length;
  const status: BarcodeIdentityStatus = contradicted ? "CONTRADICTED" : ambiguous ? "AMBIGUOUS" : probable ? "PROBABLE_COMPATIBLE" : "VERIFIED_COMPATIBLE";
  return {
    code_type: pairs.every((pair) => pair.code_type === pairs[0].code_type) ? pairs[0].code_type : "STRUCTURAL_ONLY",
    barcode_identity_status: status,
    match_confidence: round(Math.min(...pairs.map((pair) => pair.match_confidence))),
    match_reasons: sorted(pairs.flatMap((pair) => pair.match_reasons)), contradiction_flags: sorted(pairs.flatMap((pair) => pair.contradiction_flags)),
    pair_count: pairs.length, compatible_pair_count: pairs.length - contradicted - ambiguous, contradicted_pair_count: contradicted, ambiguous_pair_count: ambiguous,
  };
}
