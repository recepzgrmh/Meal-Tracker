/**
 * Deterministic Turkish/English vocabulary used by canonicalization v2.
 *
 * This module only identifies a base food concept and preserves every observed
 * qualifier/residual token. A shared `base_identity` is evidence for candidate
 * generation, never sufficient evidence for an automatic merge. In particular,
 * `yumurta` and `fried egg` both have the `egg` base, but their qualifier
 * signatures differ (`[]` versus `["fried"]`).
 */

export const CANONICAL_V2_BILINGUAL_VERSION = "canonical-v2-bilingual-2026-08-23.2" as const;

export type VocabularyProvenance = "curated_tr_en_translation" | "canonical_audit_generic_vocabulary";

export type BaseIdentityDefinition = Readonly<{
  identity: string;
  aliases: readonly string[];
  provenance: readonly VocabularyProvenance[];
  note: string;
  emitted_qualifiers?: readonly string[];
}>;

/**
 * Intentionally narrow. Entries are food identities observed in the generic
 * audit vocabulary or conservative one-to-one TR/EN translations of them.
 */
export const BASE_IDENTITY_DICTIONARY: readonly BaseIdentityDefinition[] = [
  { identity: "egg", aliases: ["egg", "eggs", "yumurta"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Whole/white/yolk and preparation remain qualifiers." },
  { identity: "egg", aliases: ["chicken egg", "tavuk yumurtasi", "yumurta tavuk"], emitted_qualifiers: ["species_chicken"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Compound phrase preserves chicken species." },
  { identity: "milk", aliases: ["milk", "sut", "sutu"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Animal source and fat class remain qualifiers." },
  { identity: "milk", aliases: ["whole milk", "tam yagli sut", "sut tam yagli"], emitted_qualifiers: ["full_fat"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Compound phrase preserves full-fat class." },
  { identity: "milk", aliases: ["skim milk", "skimmed milk", "nonfat milk", "yagsiz sut", "sut yagsiz"], emitted_qualifiers: ["nonfat"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Compound phrase preserves nonfat class." },
  { identity: "yogurt", aliases: ["yogurt", "yoghurt"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Turkish ASCII folding makes yoğurt -> yogurt." },
  { identity: "apple", aliases: ["apple", "apples", "elma"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Variety, form, and preparation are preserved." },
  { identity: "banana", aliases: ["banana", "bananas", "muz"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Variety and preparation are preserved." },
  { identity: "olive_oil", aliases: ["olive oil", "zeytin yagi", "zeytinyagi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Oil type such as extra virgin remains a qualifier/residual." },
  { identity: "olive", aliases: ["olive", "olives", "zeytin"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color, curing, and filling remain qualifiers/residuals." },
  { identity: "bread", aliases: ["bread", "breads", "ekmek"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Grain, style, and toasted state remain qualifiers/residuals." },
  { identity: "rice", aliases: ["rice", "pirinc"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color, variety, flour form, and cooked state remain qualifiers/residuals." },
  { identity: "potato", aliases: ["potato", "potatoes", "patates"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Variety, form, and preparation are preserved." },
  { identity: "chicken", aliases: ["chicken", "chickens", "pilic", "tavuk"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Cut, skin, bone, and preparation remain qualifiers/residuals." },
  { identity: "cheese", aliases: ["cheese", "cheeses", "peynir"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Cheese variety and fat class are never discarded." },
  { identity: "tomato", aliases: ["tomato", "tomatoes", "domates"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Variety and processed form are preserved." },
  { identity: "onion", aliases: ["onion", "onions", "sogan"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color, part, and preparation are preserved." },
  { identity: "cucumber", aliases: ["cucumber", "cucumbers", "salatalik"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Peel, pickling, and preparation are preserved." },
  { identity: "carrot", aliases: ["carrot", "carrots", "havuc"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color and preparation are preserved." },
  { identity: "lentil", aliases: ["lentil", "lentils", "mercimek"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color and preparation are preserved." },
  { identity: "bean", aliases: ["bean", "beans", "fasulye"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Bean variety and preparation are preserved." },
  { identity: "chickpea", aliases: ["chickpea", "chickpeas", "garbanzo", "garbanzo bean", "nohut"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Preparation and product form are preserved." },
  { identity: "pea", aliases: ["pea", "peas", "bezelye"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color, cultivar and preparation remain qualifiers." },
  { identity: "spinach", aliases: ["spinach", "ispanak"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Preparation and form remain qualifiers." },
  { identity: "cabbage", aliases: ["cabbage", "lahana"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Variety and preparation remain qualifiers." },
  { identity: "cauliflower", aliases: ["cauliflower", "karnabahar"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Preparation remains a qualifier." },
  { identity: "broccoli", aliases: ["broccoli", "brokoli"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Preparation remains a qualifier." },
  { identity: "garlic", aliases: ["garlic", "sarimsak"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Preparation and form remain qualifiers." },
  { identity: "pepper", aliases: ["pepper", "peppers", "biber"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color, cultivar and preparation remain qualifiers." },
  { identity: "orange", aliases: ["orange", "oranges", "portakal"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form and cultivar remain qualifiers." },
  { identity: "pear", aliases: ["pear", "pears", "armut"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form and cultivar remain qualifiers." },
  { identity: "peach", aliases: ["peach", "peaches", "seftali"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form and cultivar remain qualifiers." },
  { identity: "grape", aliases: ["grape", "grapes", "uzum"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color, form and cultivar remain qualifiers." },
  { identity: "strawberry", aliases: ["strawberry", "strawberries", "cilek"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form and preparation remain qualifiers." },
  { identity: "watermelon", aliases: ["watermelon", "karpuz"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Cultivar remains a qualifier." },
  { identity: "melon", aliases: ["melon", "kavun"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Cultivar remains a qualifier." },
  { identity: "lemon", aliases: ["lemon", "lemons", "limon"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form remains a qualifier." },
  { identity: "butter", aliases: ["butter", "tereyagi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Salt and animal source remain qualifiers." },
  { identity: "beef", aliases: ["beef", "sigir eti", "dana eti"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Cut, fat, state and preparation remain qualifiers." },
  { identity: "lamb", aliases: ["lamb", "kuzu eti"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Cut, fat, state and preparation remain qualifiers." },
  { identity: "fish", aliases: ["fish", "balik"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Species, cut and preparation remain residual qualifiers." },
  { identity: "almond", aliases: ["almond", "almonds", "badem"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form and preparation remain qualifiers." },
  { identity: "walnut", aliases: ["walnut", "walnuts", "ceviz"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form and preparation remain qualifiers." },
  { identity: "hazelnut", aliases: ["hazelnut", "hazelnuts", "findik"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form and preparation remain qualifiers." },
  { identity: "sunflower_oil", aliases: ["sunflower oil", "aycicek yagi", "aycicek yagi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Refinement remains a qualifier." },
  { identity: "canola_oil", aliases: ["canola oil", "rapeseed oil", "kanola yagi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Refinement remains a qualifier." },
  { identity: "corn_oil", aliases: ["corn oil", "misir yagi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Compound identity prevents corn products from collapsing into one class." },
  { identity: "hazelnut_oil", aliases: ["hazelnut oil", "findik yagi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Compound identity distinguishes the oil from whole hazelnuts." },
  { identity: "barley_flour", aliases: ["barley flour", "barley meal", "arpa unu"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Flour is part of the food identity, not discarded." },
  { identity: "rye_flour", aliases: ["rye flour", "cavdar unu"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color and extraction grade remain residual qualifiers." },
  { identity: "wheat_bran", aliases: ["wheat bran", "bugday kepegi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Bran is distinct from flour and whole grain." },
  { identity: "wheat_starch", aliases: ["wheat starch", "bugday nisastasi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Starch is distinct from flour and grain." },
  { identity: "wheat_germ", aliases: ["wheat germ", "bugday ruseymi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Germ is distinct from bran and flour." },
  { identity: "corn_bread", aliases: ["corn bread", "cornbread", "ekmek misir", "misir ekmegi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Compound identity preserves product form." },
  { identity: "corn_starch", aliases: ["corn starch", "cornstarch", "misir nisastasi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Starch is distinct from corn flour." },
  { identity: "corn_flour", aliases: ["corn flour", "misir unu"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color, whole-grain and masa qualifiers remain residual." },
  { identity: "rice_flour", aliases: ["rice flour", "pirinc unu"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Rice color and enrichment remain residual qualifiers." },
  { identity: "oat_bran", aliases: ["oat bran", "yulaf kepegi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Bran remains distinct from oat flour and cereal." },
  { identity: "oat_flour", aliases: ["oat flour", "yulaf unu"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Processing qualifiers remain residual." },
  { identity: "potato_starch", aliases: ["potato starch", "patates nisastasi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Starch remains distinct from whole potato." },
  { identity: "okra", aliases: ["okra", "bamya"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Preparation and preservation state remain qualifiers." },
  { identity: "artichoke", aliases: ["artichoke", "artichokes", "enginar"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Jerusalem artichoke remains distinct through residual identity." },
  { identity: "eggplant", aliases: ["eggplant", "aubergine", "patlican"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Cultivar and preparation remain qualifiers." },
  { identity: "zucchini", aliases: ["zucchini", "courgette", "kabak sakiz"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Pumpkin and winter squash are not aliases." },
  { identity: "lettuce", aliases: ["lettuce", "marul"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Cultivar remains residual." },
  { identity: "parsley", aliases: ["parsley", "maydanoz"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form and preparation remain qualifiers." },
  { identity: "dill", aliases: ["dill", "dereotu"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form and preparation remain qualifiers." },
  { identity: "celery", aliases: ["celery", "kereviz"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Root, stalk and leaves remain residual qualifiers." },
  { identity: "leek", aliases: ["leek", "leeks", "pirasa"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Preparation remains a qualifier." },
  { identity: "radish", aliases: ["radish", "radishes", "turp"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color and cultivar remain qualifiers." },
  { identity: "beet", aliases: ["beet", "beets", "beetroot", "pancar"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Sugar beet remains distinct through its residual qualifier." },
  { identity: "mushroom", aliases: ["mushroom", "mushrooms", "mantar"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Species and preparation remain residual qualifiers." },
  { identity: "avocado", aliases: ["avocado", "avocados", "avokado"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Cultivar and preparation remain qualifiers." },
  { identity: "pineapple", aliases: ["pineapple", "ananas"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Preservation and sweetening remain qualifiers." },
  { identity: "plum", aliases: ["plum", "plums", "erik"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Color, cultivar and drying remain qualifiers." },
  { identity: "cherry", aliases: ["cherry", "cherries", "kiraz"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Sour cherry is not silently collapsed." },
  { identity: "apricot", aliases: ["apricot", "apricots", "kayisi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Drying and cultivar remain qualifiers." },
  { identity: "fig", aliases: ["fig", "figs", "incir"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Drying and cultivar remain qualifiers." },
  { identity: "pomegranate", aliases: ["pomegranate", "pomegranates", "nar"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Juice and cultivar remain qualifiers." },
  { identity: "quince", aliases: ["quince", "ayva"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Preparation remains a qualifier." },
  { identity: "date_fruit", aliases: ["date fruit", "dates", "hurma"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Explicit fruit identity avoids collision with calendar-date vocabulary." },
  { identity: "sesame_seed", aliases: ["sesame seed", "sesame seeds", "susam tohumu"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Seed remains distinct from sesame paste and oil." },
  { identity: "peanut", aliases: ["peanut", "peanuts", "yer fistigi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Form, salt and preparation remain qualifiers." },
  { identity: "pistachio", aliases: ["pistachio", "pistachios", "antep fistigi"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Cultivar, salt and preparation remain qualifiers." },
  { identity: "chestnut", aliases: ["chestnut", "chestnuts", "kestane"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Candied products remain distinct through residual qualifiers." },
  { identity: "instant_coffee", aliases: ["instant coffee", "soluble coffee", "kahve cozunebilir", "cozunebilir kahve"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Instant coffee remains distinct from brewed and Turkish coffee." },
  { identity: "table_salt", aliases: ["table salt", "tuz sofra", "sofra tuzu"], provenance: ["curated_tr_en_translation", "canonical_audit_generic_vocabulary"], note: "Iodized state remains a qualifier/residual." },
] as const;

export type QualifierDefinition = Readonly<{
  token: string;
  aliases: readonly string[];
  dimension: "preparation" | "state" | "part" | "fat_class" | "animal_source" | "skin_bone" | "form" | "addition" | "color";
}>;

/** Qualifiers translate vocabulary; they do not remove semantic distinctions. */
export const QUALIFIER_DICTIONARY: readonly QualifierDefinition[] = [
  { token: "raw", aliases: ["raw", "cig"], dimension: "preparation" },
  { token: "cooked", aliases: ["cooked", "pismis"], dimension: "preparation" },
  { token: "boiled", aliases: ["boiled", "haslanmis"], dimension: "preparation" },
  { token: "fried", aliases: ["fried", "kizartilmis", "kizarmis", "sahanda"], dimension: "preparation" },
  { token: "roasted", aliases: ["roasted", "kavrulmus"], dimension: "preparation" },
  { token: "grilled", aliases: ["grilled", "izgara"], dimension: "preparation" },
  { token: "baked", aliases: ["baked", "firinlanmis", "firinda"], dimension: "preparation" },
  { token: "steamed", aliases: ["steamed", "buharda"], dimension: "preparation" },
  { token: "extra_virgin", aliases: ["extra virgin", "sizma"], dimension: "state" },
  { token: "virgin", aliases: ["virgin", "natürel", "naturel"], dimension: "state" },
  { token: "dried", aliases: ["dried", "dry", "kuru", "kurutulmus"], dimension: "state" },
  { token: "frozen", aliases: ["frozen", "dondurulmus"], dimension: "state" },
  { token: "canned", aliases: ["canned", "konserve"], dimension: "state" },
  { token: "pasteurized", aliases: ["pasteurized", "pasteurised", "pastorize"], dimension: "state" },
  { token: "drained", aliases: ["drained", "suzulmus"], dimension: "state" },
  { token: "whole", aliases: ["whole", "tam"], dimension: "part" },
  { token: "white", aliases: ["white", "beyaz"], dimension: "color" },
  { token: "egg_white", aliases: ["aki", "ak"], dimension: "part" },
  { token: "yolk", aliases: ["yolk", "sarisi"], dimension: "part" },
  { token: "yellow", aliases: ["yellow", "sari"], dimension: "color" },
  { token: "breast", aliases: ["breast", "gogus"], dimension: "part" },
  { token: "thigh", aliases: ["thigh", "but"], dimension: "part" },
  { token: "wing", aliases: ["wing", "kanat"], dimension: "part" },
  { token: "drumstick", aliases: ["drumstick", "baget"], dimension: "part" },
  { token: "full_fat", aliases: ["full fat", "full-fat", "tam yagli", "whole milkfat"], dimension: "fat_class" },
  { token: "reduced_fat", aliases: ["reduced fat", "reduced-fat", "yarim yagli"], dimension: "fat_class" },
  { token: "low_fat", aliases: ["low fat", "low-fat", "lowfat", "az yagli"], dimension: "fat_class" },
  { token: "nonfat", aliases: ["nonfat", "non fat", "non-fat", "fat free", "fat-free", "skim", "skimmed", "yagsiz"], dimension: "fat_class" },
  { token: "species_cow", aliases: ["cow", "inek"], dimension: "animal_source" },
  { token: "species_goat", aliases: ["goat", "keci"], dimension: "animal_source" },
  { token: "species_sheep", aliases: ["sheep", "koyun"], dimension: "animal_source" },
  { token: "species_buffalo", aliases: ["buffalo", "manda"], dimension: "animal_source" },
  { token: "species_human", aliases: ["human", "insan"], dimension: "animal_source" },
  { token: "skinless", aliases: ["skinless", "derisiz"], dimension: "skin_bone" },
  { token: "with_skin", aliases: ["with skin", "skin on", "derili"], dimension: "skin_bone" },
  { token: "boneless", aliases: ["boneless", "kemiksiz"], dimension: "skin_bone" },
  { token: "with_bone", aliases: ["with bone", "bone in", "bone-in", "kemikli"], dimension: "skin_bone" },
  { token: "flour", aliases: ["flour", "unu", "un"], dimension: "form" },
  { token: "juice", aliases: ["juice", "suyu"], dimension: "form" },
  { token: "paste", aliases: ["paste", "salcasi", "ezmesi"], dimension: "form" },
  { token: "powder", aliases: ["powder", "tozu"], dimension: "form" },
  { token: "grated", aliases: ["grated", "rendelenmis"], dimension: "form" },
  { token: "sliced", aliases: ["sliced", "dilimlenmis"], dimension: "form" },
  { token: "meat", aliases: ["meat", "eti"], dimension: "form" },
  { token: "salted", aliases: ["salted", "with salt", "tuzlu"], dimension: "addition" },
  { token: "unsalted", aliases: ["unsalted", "without salt", "tuzsuz"], dimension: "addition" },
  { token: "sweetened", aliases: ["sweetened", "sekerli"], dimension: "addition" },
  { token: "unsweetened", aliases: ["unsweetened", "without sugar", "sekersiz"], dimension: "addition" },
  { token: "white_color", aliases: ["white color"], dimension: "color" },
  { token: "red", aliases: ["red", "kirmizi"], dimension: "color" },
  { token: "green", aliases: ["green", "yesil"], dimension: "color" },
  { token: "black", aliases: ["black", "siyah"], dimension: "color" },
  { token: "brown", aliases: ["brown", "kahverengi"], dimension: "color" },
] as const;

export type IdentityEvidence = Readonly<{
  kind: "base_phrase" | "emitted_qualifier" | "qualifier_phrase";
  input_phrase: string;
  normalized_value: string;
  provenance?: readonly VocabularyProvenance[];
  dimension?: QualifierDefinition["dimension"];
}>;

export type BilingualIdentityResult = Readonly<{
  version: typeof CANONICAL_V2_BILINGUAL_VERSION;
  normalized_input: string;
  base_identity?: string;
  base_match_status: "none" | "unique" | "ambiguous";
  base_candidates: readonly string[];
  qualifier_tokens: readonly string[];
  qualifier_signature: string;
  residual_tokens: readonly string[];
  residual_signature: string;
  is_lossless: boolean;
  evidence: readonly IdentityEvidence[];
}>;

export function normalizeBilingualText(value: unknown): string {
  if (typeof value !== "string") return "";
  return value.normalize("NFC").toLocaleLowerCase("tr-TR")
    .replaceAll("ı", "i").replaceAll("ş", "s").replaceAll("ğ", "g")
    .replaceAll("ç", "c").replaceAll("ö", "o").replaceAll("ü", "u")
    .normalize("NFKD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[’'`´]/g, "").replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim().replace(/\s+/g, " ");
}

type PhraseMatch<T> = { start: number; end: number; phrase: string; definition: T };

function phraseMatches<T extends { aliases: readonly string[] }>(tokens: readonly string[], definitions: readonly T[]): PhraseMatch<T>[] {
  const matches: PhraseMatch<T>[] = [];
  for (const definition of definitions) for (const rawAlias of definition.aliases) {
    const alias = normalizeBilingualText(rawAlias), words = alias.split(" ").filter(Boolean);
    if (!words.length || words.length > tokens.length) continue;
    for (let start = 0; start <= tokens.length - words.length; start++) {
      if (words.every((word, offset) => tokens[start + offset] === word)) matches.push({ start, end: start + words.length, phrase: alias, definition });
    }
  }
  return matches.sort((a, b) => (b.end - b.start) - (a.end - a.start) || a.start - b.start || a.phrase.localeCompare(b.phrase, "en"));
}

function selectNonOverlapping<T>(matches: readonly PhraseMatch<T>[], unavailable: Set<number>): PhraseMatch<T>[] {
  const selected: PhraseMatch<T>[] = [];
  for (const match of matches) {
    let overlaps = false;
    for (let index = match.start; index < match.end; index++) if (unavailable.has(index)) { overlaps = true; break; }
    if (overlaps) continue;
    selected.push(match);
    for (let index = match.start; index < match.end; index++) unavailable.add(index);
  }
  return selected.sort((a, b) => a.start - b.start || a.end - b.end);
}

function qualifierForBase(token: string, baseCandidates: readonly string[]): string {
  if (baseCandidates.length !== 1) return token;
  if (baseCandidates[0] === "egg") {
    if (token === "white") return "egg_white";
    if (token === "yellow") return "yolk";
    if (token === "whole") return "whole_part";
  }
  if (baseCandidates[0] === "milk" && token === "whole") return "full_fat";
  return token;
}

/**
 * Parse bilingual identity evidence without making a merge decision. Consumers
 * must compare qualifier and residual signatures plus their other guards.
 */
export function resolveBilingualIdentity(value: unknown): BilingualIdentityResult {
  const normalizedInput = normalizeBilingualText(value);
  const tokens = normalizedInput ? normalizedInput.split(" ") : [];
  const consumed = new Set<number>();
  const baseMatches = selectNonOverlapping(phraseMatches(tokens, BASE_IDENTITY_DICTIONARY), consumed);
  const baseCandidates = [...new Set(baseMatches.map((match) => match.definition.identity))].sort();
  const qualifierMatches = selectNonOverlapping(phraseMatches(tokens, QUALIFIER_DICTIONARY), consumed);
  const qualifierTokens = [...new Set([
    ...baseMatches.flatMap((match) => match.definition.emitted_qualifiers ?? []),
    ...qualifierMatches.map((match) => qualifierForBase(match.definition.token, baseCandidates)),
  ])].sort();
  const residualTokens = tokens.filter((_token, index) => !consumed.has(index));
  const evidence: IdentityEvidence[] = [
    ...baseMatches.map((match) => ({ kind: "base_phrase" as const, input_phrase: match.phrase, normalized_value: match.definition.identity, provenance: match.definition.provenance })),
    ...baseMatches.flatMap((match) => (match.definition.emitted_qualifiers ?? []).map((qualifier) => ({ kind: "emitted_qualifier" as const, input_phrase: match.phrase, normalized_value: qualifier, provenance: match.definition.provenance }))),
    ...qualifierMatches.map((match) => ({ kind: "qualifier_phrase" as const, input_phrase: match.phrase, normalized_value: qualifierForBase(match.definition.token, baseCandidates), dimension: match.definition.dimension })),
  ];
  const status = baseCandidates.length === 0 ? "none" : baseCandidates.length === 1 ? "unique" : "ambiguous";
  return {
    version: CANONICAL_V2_BILINGUAL_VERSION,
    normalized_input: normalizedInput,
    ...(status === "unique" ? { base_identity: baseCandidates[0] } : {}),
    base_match_status: status,
    base_candidates: baseCandidates,
    qualifier_tokens: qualifierTokens,
    qualifier_signature: qualifierTokens.join("|"),
    residual_tokens: residualTokens,
    residual_signature: [...residualTokens].sort().join("|"),
    is_lossless: status === "unique" && residualTokens.length === 0,
    evidence,
  };
}

export const canonicalBaseIdentity = resolveBilingualIdentity;
