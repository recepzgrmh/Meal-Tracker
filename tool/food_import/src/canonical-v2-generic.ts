/**
 * Deterministic generic-food identity parsing and pair evaluation.
 *
 * This module deliberately does not assign canonical IDs or mutate records.  It
 * turns a name into a token-order-independent identity description, then applies
 * non-name guards (source diversity, category and nutrition) to a pair.  A name
 * match by itself can therefore never become an automatic merge.
 */

export const GENERIC_IDENTITY_ONTOLOGY_VERSION = "generic-identity-v2.2" as const;

export type GenericMatchConfidence = "VERY_HIGH" | "HIGH" | "MEDIUM" | "AMBIGUOUS";
export type QualifierDimension =
  | "preparation" | "state" | "fat" | "sweetening" | "salt"
  | "animal" | "animal_part" | "composition" | "egg_part" | "dairy"
  | "grain_processing" | "cultivar" | "flavor" | "skin" | "bone";

export type GenericQualifiers = Record<QualifierDimension, string[]>;

export interface GenericIdentityInput {
  source?: string;
  source_id?: string | number;
  name?: string;
  normalized_name?: string;
  category?: string | { name?: string } | null;
  normalized_category?: string;
  nutrition?: Record<string, unknown> | null;
}

export interface ParsedGenericIdentity {
  ontology_version: typeof GENERIC_IDENTITY_ONTOLOGY_VERSION;
  normalized_name: string;
  base_tokens: string[];
  base_key: string;
  qualifier_key: string;
  identity_key: string;
  qualifiers: GenericQualifiers;
  explicit_dimensions: QualifierDimension[];
  contradiction_flags: string[];
  ambiguous_flags: string[];
}

export interface NutritionSimilarity {
  status: "compatible" | "incompatible" | "insufficient";
  score: number | null;
  common_fields: string[];
  differences: Record<string, { left: number; right: number; absolute: number; relative: number }>;
  reasons: string[];
}

export interface CategoryCompatibility {
  status: "compatible" | "incompatible" | "unknown";
  left_family?: string;
  right_family?: string;
  reason: string;
}

export interface GenericIdentityEvaluation {
  ontology_version: typeof GENERIC_IDENTITY_ONTOLOGY_VERSION;
  identity_key?: string;
  confidence: GenericMatchConfidence;
  auto_merge: boolean;
  needs_review: boolean;
  reasons: string[];
  contradiction_flags: string[];
  guards: {
    base_identity_equal: boolean;
    explicit_qualifiers_compatible: boolean;
    source_diversity: boolean;
    nutrition_compatible: boolean;
    category_compatible: boolean;
  };
  nutrition_similarity: NutritionSimilarity;
  category_compatibility: CategoryCompatibility;
  left: ParsedGenericIdentity;
  right: ParsedGenericIdentity;
}

const DIMENSIONS: QualifierDimension[] = [
  "preparation", "state", "fat", "sweetening", "salt", "animal", "animal_part",
  "composition", "egg_part", "dairy", "grain_processing", "cultivar", "flavor", "skin", "bone",
];

type Rule = { dimension: QualifierDimension; value: string; phrases: string[]; context?: RegExp };

/* Longer phrases are consumed first. Terms are intentionally food-specific and
 * conservative; packaging, serving-size and marketing words are not qualifiers. */
const RULES: Rule[] = [
  { dimension: "preparation", value: "par_fried", phrases: ["par fried", "partially fried", "on kizartilmis"] },
  { dimension: "preparation", value: "raw", phrases: ["raw", "uncooked", "unheated", "cig"] },
  { dimension: "preparation", value: "cooked", phrases: ["cooked", "prepared", "pismis"] },
  { dimension: "preparation", value: "boiled", phrases: ["boiled", "hard boiled", "soft boiled", "haslanmis"] },
  { dimension: "preparation", value: "fried", phrases: ["fried", "deep fried", "pan fried", "kizartilmis"] },
  { dimension: "preparation", value: "roasted", phrases: ["roasted", "dry roasted", "fire roasted", "kavrulmus"] },
  { dimension: "preparation", value: "baked", phrases: ["baked", "oven baked", "firinda"] },
  { dimension: "preparation", value: "grilled", phrases: ["grilled", "charbroiled", "izgara"] },
  { dimension: "preparation", value: "steamed", phrases: ["steamed", "buharda"] },
  { dimension: "preparation", value: "poached", phrases: ["poached"] },
  { dimension: "preparation", value: "smoked", phrases: ["smoked", "isli", "tutsulenmis"] },
  { dimension: "preparation", value: "fermented", phrases: ["fermented", "fermente"] },
  { dimension: "preparation", value: "pickled", phrases: ["pickled", "turşu", "tursu"] },

  { dimension: "state", value: "fresh", phrases: ["fresh", "taze"] },
  { dimension: "state", value: "frozen", phrases: ["frozen", "dondurulmus"] },
  { dimension: "state", value: "dried", phrases: ["dried", "dehydrated", "kurutulmus", "kuru"] },
  { dimension: "state", value: "canned", phrases: ["canned", "tinned", "konserve"] },
  { dimension: "state", value: "drained", phrases: ["drained", "drained solids", "suzulmus"] },
  { dimension: "state", value: "powder", phrases: ["powder", "powdered", "toz"] },
  { dimension: "state", value: "concentrate", phrases: ["concentrate", "concentrated", "konsantre"] },
  { dimension: "state", value: "juice", phrases: ["juice", "suyu"] },
  { dimension: "state", value: "extra_virgin", phrases: ["extra virgin", "sizma"] },
  { dimension: "state", value: "virgin", phrases: ["virgin", "naturel"] },

  { dimension: "fat", value: "nonfat", phrases: ["nonfat", "fat free", "zero fat", "skim", "skimmed", "yagsiz"] },
  { dimension: "fat", value: "lowfat", phrases: ["lowfat", "low fat", "az yagli"] },
  { dimension: "fat", value: "reduced_fat", phrases: ["reduced fat", "light fat"] },
  { dimension: "fat", value: "part_skim", phrases: ["part skim", "part-skim", "yarim yagli"] },
  { dimension: "fat", value: "whole_fat", phrases: ["whole milk", "full fat", "tam yagli"], context: /\b(milk|sut|yogurt|yoghurt|cheese|peynir)\b/ },

  { dimension: "sweetening", value: "unsweetened", phrases: ["unsweetened", "no sugar added", "without added sugar", "seker ilavesiz", "sekersiz"] },
  { dimension: "sweetening", value: "sweetened", phrases: ["sweetened", "sugar added", "with sugar", "sekerli"] },
  { dimension: "salt", value: "unsalted", phrases: ["unsalted", "without salt", "no salt added", "tuzsuz"] },
  { dimension: "salt", value: "salted", phrases: ["salted", "with salt", "salt added", "tuzlu"] },

  { dimension: "animal", value: "beef", phrases: ["beef", "cow", "sığır", "sigir", "dana"] },
  { dimension: "animal", value: "pork", phrases: ["pork", "swine", "domuz"] },
  { dimension: "animal", value: "chicken", phrases: ["chicken", "tavuk", "pilic"] },
  { dimension: "animal", value: "turkey", phrases: ["turkey meat", "turkey", "hindi"] },
  { dimension: "animal", value: "lamb", phrases: ["lamb", "kuzu"] },
  { dimension: "animal", value: "goat", phrases: ["goat", "keci"] },
  { dimension: "animal", value: "duck", phrases: ["duck", "ordek"] },
  { dimension: "animal", value: "fish", phrases: ["fish", "balik"] },
  { dimension: "animal_part", value: "breast", phrases: ["breast", "gogus"] },
  { dimension: "animal_part", value: "thigh", phrases: ["thigh", "thighs", "but"] },
  { dimension: "animal_part", value: "wing", phrases: ["wing", "wings", "kanat"] },
  { dimension: "animal_part", value: "drumstick", phrases: ["drumstick", "drumsticks", "baget"] },
  { dimension: "animal_part", value: "leg", phrases: ["leg", "legs", "bacak"] },
  { dimension: "animal_part", value: "shoulder", phrases: ["shoulder", "omuz"] },
  { dimension: "animal_part", value: "liver", phrases: ["liver", "karaciger"] },
  { dimension: "animal_part", value: "heart", phrases: ["heart", "yurek"] },
  { dimension: "animal_part", value: "kidney", phrases: ["kidney", "bobrek"] },
  { dimension: "animal_part", value: "loin", phrases: ["loin", "tenderloin", "bonfile"] },
  { dimension: "animal_part", value: "rib", phrases: ["rib", "ribs", "kaburga"] },
  { dimension: "composition", value: "ground", phrases: ["ground", "minced", "kiyma"] },
  { dimension: "composition", value: "mechanically_separated", phrases: ["mechanically separated"] },
  { dimension: "composition", value: "breaded", phrases: ["breaded", "battered", "paneli"] },
  { dimension: "composition", value: "lean_only", phrases: ["lean only", "separable lean only", "yagsiz et"] },
  { dimension: "composition", value: "lean_and_fat", phrases: ["lean and fat", "separable lean and fat"] },
  { dimension: "composition", value: "meat_only", phrases: ["meat only", "et kismi"] },
  { dimension: "composition", value: "fat_added", phrases: ["fat added", "with added fat"] },
  { dimension: "composition", value: "no_added_fat", phrases: ["no added fat", "without added fat"] },
  { dimension: "composition", value: "added_solution", phrases: ["with added solution", "added solution"] },

  { dimension: "egg_part", value: "white", phrases: ["egg white", "egg whites", "white egg", "yumurta aki", "yumurta beyaz ak", "yumurta beyazi"], context: /\b(egg|yumurta)\b/ },
  { dimension: "egg_part", value: "yolk", phrases: ["egg yolk", "egg yolks", "yolk egg", "yumurta sarisi", "yumurta sari"], context: /\b(egg|yumurta)\b/ },
  { dimension: "egg_part", value: "whole", phrases: ["whole egg", "whole eggs", "egg whole", "tam yumurta", "yumurta tam"], context: /\b(egg|yumurta)\b/ },
  { dimension: "dairy", value: "cow", phrases: ["cow milk", "cows milk", "milk cow", "inek sutu", "sut inek"] },
  { dimension: "dairy", value: "goat", phrases: ["goat milk", "goats milk", "milk goat", "keci sutu", "sut keci"] },
  { dimension: "dairy", value: "sheep", phrases: ["sheep milk", "sheeps milk", "milk sheep", "koyun sutu", "sut koyun"] },
  { dimension: "dairy", value: "pasteurized", phrases: ["pasteurized", "pasteurised", "pastorize"] },
  { dimension: "dairy", value: "homogenized", phrases: ["homogenized", "homogenised", "homojenize"] },
  { dimension: "dairy", value: "uht", phrases: ["uht", "ultra pasteurized", "ultra pasteurised"] },
  { dimension: "dairy", value: "lactose_free", phrases: ["lactose free", "lactose-free", "laktozsuz"] },
  { dimension: "dairy", value: "greek", phrases: ["greek yogurt", "greek yoghurt", "yogurt greek", "yoghurt greek"] },
  { dimension: "dairy", value: "strained", phrases: ["strained yogurt", "strained yoghurt", "suzme yogurt"] },

  { dimension: "grain_processing", value: "whole_grain", phrases: ["whole grain", "wholegrain", "whole wheat", "tam tahil", "tam bugday"] },
  { dimension: "grain_processing", value: "refined", phrases: ["refined grain", "refined flour", "rafine"] },
  { dimension: "grain_processing", value: "unrefined", phrases: ["unrefined", "unrefined grain", "rafine edilmemis"] },
  { dimension: "grain_processing", value: "enriched", phrases: ["enriched", "zenginlestirilmis"] },
  { dimension: "grain_processing", value: "unenriched", phrases: ["unenriched", "not enriched", "zenginlestirilmemis"] },
  { dimension: "grain_processing", value: "white", phrases: ["white rice", "rice white", "white flour", "flour white", "beyaz pirinc", "pirinc beyaz"] },
  { dimension: "grain_processing", value: "brown", phrases: ["brown rice", "rice brown", "esmer pirinc", "pirinc esmer"] },
  { dimension: "grain_processing", value: "parboiled", phrases: ["parboiled"] },
  { dimension: "grain_processing", value: "bran", phrases: ["bran", "kepek"] },
  { dimension: "grain_processing", value: "germ", phrases: ["wheat germ", "germ"] },
  { dimension: "grain_processing", value: "sprouted", phrases: ["sprouted", "filizlendirilmis"] },
  { dimension: "grain_processing", value: "rye", phrases: ["rye", "cavdar"] },

  { dimension: "cultivar", value: "grape_tomato", phrases: ["grape tomato", "grape tomatoes"] },
  { dimension: "cultivar", value: "cherry_tomato", phrases: ["cherry tomato", "cherry tomatoes"] },
  { dimension: "cultivar", value: "granny_smith", phrases: ["granny smith"] },
  { dimension: "cultivar", value: "golden_delicious", phrases: ["golden delicious"] },
  { dimension: "cultivar", value: "red_delicious", phrases: ["red delicious"] },
  { dimension: "cultivar", value: "gala", phrases: ["gala", "gala variety", "gala cesidi"] },
  { dimension: "cultivar", value: "fuji", phrases: ["fuji", "fuji variety", "fuji cesidi"] },
  { dimension: "cultivar", value: "basmati", phrases: ["basmati"] },
  { dimension: "cultivar", value: "jasmine", phrases: ["jasmine rice"] },

  { dimension: "flavor", value: "plain", phrases: ["plain", "sade"] },
  { dimension: "flavor", value: "flavored", phrases: ["flavored", "flavoured", "aromali"] },
  { dimension: "flavor", value: "vanilla", phrases: ["vanilla", "vanilya"] },
  { dimension: "flavor", value: "chocolate", phrases: ["chocolate", "cocoa", "cikolata"] },
  { dimension: "flavor", value: "strawberry", phrases: ["strawberry", "cilek"], context: /\b(yogurt|yoghurt|milk|drink|beverage|flavor|flavored|flavoured|ice cream)\b/ },
  { dimension: "flavor", value: "banana", phrases: ["banana flavor", "banana flavoured", "muz aromali"] },

  { dimension: "skin", value: "with_skin", phrases: ["with skin", "skin on", "unpeeled", "kabuklu"] },
  { dimension: "skin", value: "without_skin", phrases: ["without skin", "skinless", "skin removed", "skin and breading removed", "peeled", "kabuksuz", "derisiz"] },
  { dimension: "bone", value: "bone_in", phrases: ["bone in", "with bone", "kemikli"] },
  { dimension: "bone", value: "boneless", phrases: ["boneless", "without bone", "kemiksiz"] },
];

const BASE_SYNONYMS: Record<string, string> = {
  eggs: "egg", yumurta: "egg", sut: "milk", yoghurt: "yogurt", yogurtu: "yogurt", ekmek: "bread", eti: "meat",
  apples: "apple", elma: "apple", bananas: "banana", muz: "banana", pirinc: "rice",
  tomatoes: "tomato", patates: "potato", potatoes: "potato", fasulye: "bean", beans: "bean",
  lentils: "lentil", mercimek: "lentil", nohut: "chickpea", chickpeas: "chickpea",
  almonds: "almond", badem: "almond", walnuts: "walnut", ceviz: "walnut",
};

const BASE_STOPWORDS = new Set(["and", "or", "with", "without", "of", "the", "from", "style", "type", "regular", "pack", "only", "unlu", "ve", "cesidi", "yazlik", "guzluk", "kislik"]);

// Some multi-token qualifiers include the food noun ("white rice", "egg
// white"). Restore that noun after phrase consumption so qualifier order never
// changes the base identity.
const CORE_ANCHORS: [string, RegExp][] = [
  ["egg", /\b(egg|eggs|yumurta)\b/], ["milk", /\b(milk|sut|sutu)\b/],
  ["yogurt", /\b(yogurt|yoghurt|yoğurt)\b/], ["rice", /\b(rice|pirinc)\b/],
  ["flour", /\b(flour|un)\b/], ["tomato", /\b(tomato|tomatoes|domates)\b/],
  ["apple", /\b(apple|apples|elma)\b/], ["grain", /\bgrain\b/], ["wheat", /\b(wheat|bugday)\b/],
];

const CONFLICT_GROUPS: Partial<Record<QualifierDimension, string[][]>> = {
  preparation: [
    ["raw", "cooked"], ["raw", "boiled"], ["raw", "fried"], ["raw", "par_fried"],
    ["raw", "roasted"], ["raw", "baked"], ["raw", "grilled"], ["raw", "steamed"], ["raw", "poached"],
    ["boiled", "fried", "par_fried", "roasted", "baked", "grilled", "steamed", "poached"],
  ],
  state: [["fresh", "frozen", "dried", "canned"]],
  fat: [["nonfat", "lowfat", "reduced_fat", "part_skim", "whole_fat"]],
  sweetening: [["sweetened", "unsweetened"]], salt: [["salted", "unsalted"]],
  egg_part: [["white", "yolk", "whole"]], grain_processing: [["whole_grain", "refined", "unrefined"], ["enriched", "unenriched"], ["white", "brown"]],
  skin: [["with_skin", "without_skin"]], bone: [["bone_in", "boneless"]],
};

function fold(value: unknown): string {
  return String(value ?? "").toLocaleLowerCase("tr-TR").replaceAll("ı", "i").replaceAll("ş", "s")
    .replaceAll("ğ", "g").replaceAll("ç", "c").replaceAll("ö", "o").replaceAll("ü", "u")
    .normalize("NFKD").replace(/[\u0300-\u036f]/g, "").replace(/[’'`´]/g, "")
    .replace(/[^a-z0-9%]+/g, " ").trim().replace(/\s+/g, " ");
}

function emptyQualifiers(): GenericQualifiers {
  return Object.fromEntries(DIMENSIONS.map((dimension) => [dimension, []])) as GenericQualifiers;
}

function phrasePattern(phrase: string): RegExp {
  return new RegExp(`(?:^|\\s)${phrase.split(/\s+/).map(escapeRegExp).join("\\s+")}(?=\\s|$)`, "g");
}

function escapeRegExp(value: string): string { return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); }

export function parseGenericIdentity(input: string | GenericIdentityInput): ParsedGenericIdentity {
  const rawName = typeof input === "string" ? input : (input.normalized_name || input.name || "");
  const normalizedName = fold(rawName);
  const qualifiers = emptyQualifiers();
  let remainder = ` ${normalizedName} `;
  const sortedRules = [...RULES].sort((a, b) => Math.max(...b.phrases.map((x) => x.length)) - Math.max(...a.phrases.map((x) => x.length)));
  for (const rule of sortedRules) {
    if (rule.context && !rule.context.test(normalizedName)) continue;
    let matched = false;
    for (const phrase of [...rule.phrases].sort((a, b) => b.length - a.length)) {
      const pattern = phrasePattern(fold(phrase));
      if (pattern.test(remainder.trim())) {
        matched = true;
        remainder = ` ${remainder.trim().replace(pattern, " ").replace(/\s+/g, " ").trim()} `;
      }
    }
    if (matched && !qualifiers[rule.dimension].includes(rule.value)) qualifiers[rule.dimension].push(rule.value);
  }

  // Dataset names commonly separate the modifier from its noun with commas or
  // intervening species tokens ("Yumurta, tavuk, sarı" / "Milk, cow, whole").
  // Context makes these otherwise ambiguous single words safe to consume.
  const contextual = (dimension: QualifierDimension, value: string, pattern: RegExp) => {
    if (!pattern.test(remainder)) return;
    if (!qualifiers[dimension].includes(value)) qualifiers[dimension].push(value);
    remainder = ` ${remainder.trim().replace(pattern, " ").replace(/\s+/g, " ").trim()} `;
  };
  if (/\b(egg|yumurta)\b/.test(normalizedName)) {
    contextual("egg_part", "white", /\b(white|beyaz|ak)\b/g);
    contextual("egg_part", "yolk", /\b(yolk|sari)\b/g);
    contextual("egg_part", "whole", /\b(whole|tam)\b/g);
  }
  if (/\b(milk|sut|yogurt|yoghurt|cheese|peynir)\b/.test(normalizedName)) {
    contextual("fat", "whole_fat", /\b(whole|full fat|tam yagli)\b/g);
  }

  // "Cooked, boiled" expresses a specific method, not two competing states.
  if (qualifiers.preparation.includes("cooked") && qualifiers.preparation.some((value) => !["cooked", "raw"].includes(value))) {
    qualifiers.preparation = qualifiers.preparation.filter((value) => value !== "cooked");
  }

  // Numeric dairy fat is explicit identity information, not a serving quantity.
  if (/\b(milk|sut|yogurt|yoghurt|cheese|peynir)\b/.test(normalizedName)) {
    for (const match of normalizedName.matchAll(/\b(\d+(?:\.\d+)?)\s*%?\s*(?:milkfat|fat|yagli|yagi)\b/g)) {
      qualifiers.fat.push(`percent_${Number(match[1]).toString().replace(".", "_")}`);
      remainder = remainder.replace(phrasePattern(match[0]), " ");
    }
  }

  for (const dimension of DIMENSIONS) qualifiers[dimension] = [...new Set(qualifiers[dimension])].sort();
  const contradictionFlags: string[] = [];
  for (const [dimension, groups] of Object.entries(CONFLICT_GROUPS) as [QualifierDimension, string[][]][]) {
    for (const group of groups) {
      const present = qualifiers[dimension].filter((value) => group.includes(value));
      if (present.length > 1) contradictionFlags.push(`internal_qualifier_conflict:${dimension}:${present.join("+")}`);
    }
  }

  let restoredAnchors = CORE_ANCHORS.filter(([, pattern]) => pattern.test(normalizedName)).map(([anchor]) => anchor);
  // In "whole-milk yogurt" / "goat-milk cheese", milk is a modifier of the
  // final food rather than a second base food.
  if (restoredAnchors.some((anchor) => anchor === "yogurt") || /\bcheese\b/.test(normalizedName)) {
    restoredAnchors = restoredAnchors.filter((anchor) => anchor !== "milk");
  }
  if (!restoredAnchors.length && qualifiers.animal.length && (qualifiers.animal_part.length || qualifiers.composition.length)) restoredAnchors.push("meat");
  const baseTokens = [...new Set([...remainder.trim().split(/\s+/).filter(Boolean)
    .map((token) => BASE_SYNONYMS[token] ?? token).filter((token) => !BASE_STOPWORDS.has(token) && !/^\d+(?:\.\d+)?%?$/.test(token)), ...restoredAnchors])].sort();
  const explicitDimensions = DIMENSIONS.filter((dimension) => qualifiers[dimension].length > 0);
  const ambiguousFlags: string[] = [];
  if (baseTokens.length === 0) ambiguousFlags.push("empty_base_identity");
  if (baseTokens.length === 1 && baseTokens[0].length < 3) ambiguousFlags.push("weak_base_identity");
  const baseKey = baseTokens.join("+");
  const qualifierKey = explicitDimensions.map((dimension) => `${dimension}=${qualifiers[dimension].join("+")}`).join("|");
  return {
    ontology_version: GENERIC_IDENTITY_ONTOLOGY_VERSION, normalized_name: normalizedName,
    base_tokens: baseTokens, base_key: baseKey, qualifier_key: qualifierKey,
    identity_key: `generic:${GENERIC_IDENTITY_ONTOLOGY_VERSION}:${baseKey}${qualifierKey ? `|${qualifierKey}` : ""}`,
    qualifiers, explicit_dimensions: explicitDimensions, contradiction_flags: contradictionFlags.sort(), ambiguous_flags: ambiguousFlags,
  };
}

function categoryText(input: GenericIdentityInput): string {
  const category = typeof input.category === "string" ? input.category : input.category?.name;
  return fold(input.normalized_category || category || "");
}

const CATEGORY_FAMILIES: [string, RegExp][] = [
  ["dairy_egg", /\b(dairy|egg|milk|cheese|yogurt)\b/], ["meat_poultry", /\b(meat|poultry|beef|pork|lamb|sausage)\b/],
  ["fish_seafood", /\b(fish|seafood|shellfish)\b/], ["fruit", /\bfruit/], ["vegetable", /\bvegetable/],
  ["grain_cereal", /\b(grain|cereal|rice|pasta|bakery|bread)\b/], ["legume", /\b(legume|bean|lentil)\b/],
  ["nut_seed", /\b(nut|seed)\b/], ["fat_oil", /\b(fat|oil)\b/], ["beverage", /\b(beverage|drink)\b/],
  ["sweets", /\b(sweet|candy|dessert|confection)\b/], ["spice_herb", /\b(spice|herb)\b/],
];

function categoryFamily(input: GenericIdentityInput): string | undefined {
  const text = categoryText(input);
  return CATEGORY_FAMILIES.find(([, pattern]) => pattern.test(text))?.[0];
}

export function compareGenericCategories(left: GenericIdentityInput, right: GenericIdentityInput): CategoryCompatibility {
  const leftFamily = categoryFamily(left), rightFamily = categoryFamily(right);
  if (!leftFamily || !rightFamily) return { status: "unknown", ...(leftFamily ? { left_family: leftFamily } : {}), ...(rightFamily ? { right_family: rightFamily } : {}), reason: "category_family_missing_or_unrecognized" };
  if (leftFamily === rightFamily) return { status: "compatible", left_family: leftFamily, right_family: rightFamily, reason: "same_category_family" };
  return { status: "incompatible", left_family: leftFamily, right_family: rightFamily, reason: "different_category_families" };
}

const NUTRIENT_LIMITS: Record<string, { floor: number; relative: number }> = {
  kcal_100g: { floor: 80, relative: 0.40 }, protein_100g: { floor: 5, relative: 0.45 },
  carbs_100g: { floor: 5, relative: 0.45 }, fat_100g: { floor: 5, relative: 0.45 },
};

export function compareGenericNutrition(left: GenericIdentityInput["nutrition"], right: GenericIdentityInput["nutrition"]): NutritionSimilarity {
  const commonFields = Object.keys(NUTRIENT_LIMITS).filter((key) => Number.isFinite(left?.[key]) && Number.isFinite(right?.[key]));
  const differences: NutritionSimilarity["differences"] = {}, reasons: string[] = [];
  let compatible = true, scoreSum = 0;
  for (const key of commonFields) {
    const a = Number(left![key]), b = Number(right![key]), absolute = Math.abs(a - b);
    const relative = absolute / Math.max(Math.abs(a), Math.abs(b), 1);
    differences[key] = { left: a, right: b, absolute, relative };
    const limit = NUTRIENT_LIMITS[key];
    if (absolute > Math.max(limit.floor, Math.max(Math.abs(a), Math.abs(b)) * limit.relative)) {
      compatible = false; reasons.push(`nutrition_difference_too_large:${key}`);
    }
    scoreSum += Math.max(0, 1 - relative);
  }
  const macroCount = commonFields.filter((key) => key !== "kcal_100g").length;
  if (macroCount < 2) return { status: "insufficient", score: commonFields.length ? scoreSum / commonFields.length : null, common_fields: commonFields, differences, reasons: ["fewer_than_two_common_macros", ...reasons] };
  return { status: compatible ? "compatible" : "incompatible", score: scoreSum / commonFields.length, common_fields: commonFields, differences, reasons: compatible ? ["macro_similarity_guard_passed"] : reasons };
}

function qualifierContradictions(left: ParsedGenericIdentity, right: ParsedGenericIdentity): string[] {
  const flags = [...left.contradiction_flags.map((x) => `left:${x}`), ...right.contradiction_flags.map((x) => `right:${x}`)];
  for (const dimension of DIMENSIONS) {
    const a = left.qualifiers[dimension], b = right.qualifiers[dimension];
    if (!a.length || !b.length) continue;
    const overlap = a.some((value) => b.includes(value));
    if (!overlap) flags.push(`explicit_qualifier_conflict:${dimension}:${a.join("+")}!=${b.join("+")}`);
  }
  return [...new Set(flags)].sort();
}

/** Evaluate a candidate pair. VERY_HIGH is automatic; HIGH is automatic only
 * because every named guard below is required. MEDIUM/AMBIGUOUS always remain
 * separate (optionally entering review). */
export function evaluateGenericIdentity(leftInput: GenericIdentityInput, rightInput: GenericIdentityInput): GenericIdentityEvaluation {
  const left = parseGenericIdentity(leftInput), right = parseGenericIdentity(rightInput);
  const nutrition = compareGenericNutrition(leftInput.nutrition, rightInput.nutrition);
  const category = compareGenericCategories(leftInput, rightInput);
  const contradictions = qualifierContradictions(left, right);
  const baseEqual = Boolean(left.base_key) && left.base_key === right.base_key;
  const sourceDiversity = Boolean(leftInput.source && rightInput.source && leftInput.source !== rightInput.source);
  // Missing-vs-explicit is not a contradiction, but is insufficient for an
  // automatic merge: an unspecified record must not silently absorb raw,
  // frozen, yolk, salted, skinless, etc.  It remains a reviewable candidate.
  const qualifiersCompatible = contradictions.length === 0 && left.qualifier_key === right.qualifier_key;
  const categoryGuard = category.status !== "incompatible";
  const guards = {
    base_identity_equal: baseEqual, explicit_qualifiers_compatible: qualifiersCompatible,
    source_diversity: sourceDiversity, nutrition_compatible: nutrition.status === "compatible", category_compatible: categoryGuard,
  };
  const reasons: string[] = [];
  if (baseEqual) reasons.push("token_order_independent_base_identity_equal"); else reasons.push("base_identity_different");
  if (sourceDiversity) reasons.push("source_diversity_guard_passed"); else reasons.push("same_or_unknown_source_blocks_merge");
  reasons.push(category.reason, ...nutrition.reasons);
  if (contradictions.length) reasons.push("explicit_qualifier_contradiction_blocks_merge");

  const allGuards = Object.values(guards).every(Boolean);
  const sameQualifierKey = left.qualifier_key === right.qualifier_key;
  const completeNutrition = nutrition.common_fields.length === 4;
  let confidence: GenericMatchConfidence;
  if (!baseEqual || contradictions.length || left.ambiguous_flags.length || right.ambiguous_flags.length) confidence = "AMBIGUOUS";
  else if (allGuards && sameQualifierKey && completeNutrition && category.status === "compatible" && (nutrition.score ?? 0) >= 0.80) confidence = "VERY_HIGH";
  else if (allGuards) confidence = "HIGH";
  else confidence = "MEDIUM";
  const autoMerge = confidence === "VERY_HIGH" || (confidence === "HIGH" && allGuards);
  if (autoMerge) reasons.push(confidence === "VERY_HIGH" ? "very_high_all_identity_guards_passed" : "high_all_required_guards_passed");
  else reasons.push("name_identity_alone_never_merges");
  return {
    ontology_version: GENERIC_IDENTITY_ONTOLOGY_VERSION,
    ...(baseEqual && sameQualifierKey ? { identity_key: left.identity_key } : baseEqual ? { identity_key: `generic:${GENERIC_IDENTITY_ONTOLOGY_VERSION}:${left.base_key}|qualifiers=unresolved` } : {}),
    confidence, auto_merge: autoMerge, needs_review: confidence === "MEDIUM" && baseEqual && qualifiersCompatible,
    reasons: [...new Set(reasons)], contradiction_flags: contradictions, guards,
    nutrition_similarity: nutrition, category_compatibility: category, left, right,
  };
}

// Explicit aliases keep integration call-sites readable while the v1 pipeline remains untouched.
export const parseGenericFoodIdentity = parseGenericIdentity;
export const evaluateGenericFoodPair = evaluateGenericIdentity;
