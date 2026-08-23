#!/usr/bin/env node
import { createReadStream, createWriteStream, promises as fs } from "node:fs";
import { createGunzip, createGzip } from "node:zlib";
import { createInterface } from "node:readline";
import { once } from "node:events";
import { dirname, resolve } from "node:path";
import { pipeline } from "node:stream/promises";
import type { Writable } from "node:stream";

const ROOT = resolve(import.meta.dirname, "../../..");
const INPUT = resolve(ROOT, "data/normalized/openfoodfacts.jsonl.gz");
const OUTPUT_DIR = resolve(ROOT, "data/catalog");
const SCORED_OUTPUT = resolve(OUTPUT_DIR, "openfoodfacts-scored.jsonl.gz");
const PRODUCTION_OUTPUT = resolve(OUTPUT_DIR, "openfoodfacts-production.jsonl.gz");
const METRICS_OUTPUT = resolve(OUTPUT_DIR, "openfoodfacts-catalog-metrics.json");
const REPORT_OUTPUT = resolve(ROOT, "openfoodfacts-catalog-report.md");
const SCORING_VERSION = "off-catalog-v1";
const PRODUCTION_THRESHOLD = Number(process.env.OFF_CATALOG_QUALITY_THRESHOLD ?? 80);
const REPORT_THRESHOLDS = [40, 50, 60, 70, 80, 90];

const TURKEY_TAGS = new Set(["en:turkey", "en:turkiye"]);
const ENGLISH_MARKETS = new Set([
  "en:united-states", "en:united-kingdom", "en:canada", "en:australia",
  "en:new-zealand", "en:ireland", "en:south-africa",
]);
const PLACEHOLDER_NAMES = new Set(["null", "unknown", "product", "food", "?", "-", "none", "n/a"]);
const TURKISH_TERMS = [
  "ayran", "baklava", "biskuvi", "bisküvi", "borek", "börek", "bulgur", "cikolata", "çikolata",
  "doner", "döner", "ekmek", "findik", "fındık", "helva", "kasar", "kaşar", "kaymak", "kefir",
  "kofte", "köfte", "lokum", "mercimek", "nohut", "pastirma", "pastırma", "pekmez", "peynir",
  "recel", "reçel", "salca", "salça", "salgam", "şalgam", "simit", "sucuk", "sut", "süt", "tahin",
  "tarhana", "tereyag", "tereyağ", "ulker", "ülker", "yogurt", "yoğurt", "zeytin",
];
const ENGLISH_TERMS = new Set([
  "and", "bread", "butter", "cheese", "chicken", "chocolate", "coffee", "cream", "flavor", "flavoured",
  "milk", "organic", "rice", "salt", "sauce", "sugar", "tea", "water", "with", "yogurt",
]);

type StringMap = Map<string, number>;
type ScoredFood = Record<string, any> & {
  scoring_version: string;
  data_quality_score: number;
  turkey_relevance_score: number;
  english_relevance_score: number;
  detected_languages: string[];
  market_country_tags: string[];
  inclusion_reasons: string[];
  exclusion_reasons: string[];
  production_eligible: boolean;
  production_quality_threshold: number;
};

function cleanText(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const clean = value.trim().replace(/\s+/g, " ");
  return clean || undefined;
}

function normalizeToken(value: string): string {
  return value.toLowerCase().replaceAll("ı", "i").replaceAll("ş", "s").replaceAll("ğ", "g").replaceAll("ç", "c")
    .replaceAll("ö", "o").replaceAll("ü", "u").normalize("NFKD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ").trim();
}

function brandTokens(value: unknown): string[] {
  const brand = cleanText(value); if (!brand) return [];
  return [...new Set(brand.split(/[,;|/]+/).map(normalizeToken).filter((v) => v.length >= 2 && v !== "unknown"))];
}

function increment(map: StringMap, key: string, amount = 1) { map.set(key, (map.get(key) ?? 0) + amount); }
function percent(value: number, total: number): string { return `${((value / Math.max(total, 1)) * 100).toFixed(2)}%`; }

async function* readJsonlGz(path: string): AsyncGenerator<any> {
  const reader = createInterface({ input: createReadStream(path).pipe(createGunzip()), crlfDelay: Infinity });
  for await (const line of reader) if (line.trim()) yield JSON.parse(line);
}

async function atomicGzip(path: string) {
  await fs.mkdir(dirname(path), { recursive: true });
  const temp = `${path}.tmp`; await fs.rm(temp, { force: true });
  const gzip = createGzip({ level: 6 }); const output = createWriteStream(temp); const done = pipeline(gzip, output);
  return {
    stream: gzip,
    finish: async () => { gzip.end(); await done; await fs.rename(temp, path); },
  };
}

async function writeLine(stream: Writable, value: unknown) {
  if (!stream.write(`${JSON.stringify(value)}\n`)) await once(stream, "drain");
}

function validGtin(value: unknown): boolean {
  const code = cleanText(value); if (!code || !/^(?:\d{8}|\d{12}|\d{13}|\d{14})$/.test(code)) return false;
  const digits = [...code].map(Number); const expected = digits.pop()!;
  let sum = 0, position = 0;
  for (let i = digits.length - 1; i >= 0; i--, position++) sum += digits[i] * (position % 2 === 0 ? 3 : 1);
  return (10 - (sum % 10)) % 10 === expected;
}

function structuralBarcode(value: unknown): boolean {
  const code = cleanText(value); return Boolean(code && /^\d{4,14}$/.test(code));
}

function meaningfulName(value: unknown): boolean {
  const name = cleanText(value); return Boolean(name && name.length >= 3 && !PLACEHOLDER_NAMES.has(name.toLowerCase()) && /[\p{L}\p{N}]/u.test(name));
}

function hasCategory(food: any): boolean {
  const name = cleanText(food.category?.name);
  const tags = Array.isArray(food.category?.tags) ? food.category.tags.filter((v: unknown) => cleanText(v) && v !== "en:null") : [];
  return Boolean((name && name.toLowerCase() !== "null") || tags.length);
}

function metadataText(food: any): string {
  return [food.name, food.brand, food.ingredients, ...(Array.isArray(food.aliases) ? food.aliases : [])]
    .map(cleanText).filter(Boolean).join(" ").toLowerCase();
}

function turkishMetadata(text: string): boolean {
  if (/[çğış]/u.test(text)) return true;
  const normalized = ` ${text.normalize("NFKC").toLowerCase()} `;
  return TURKISH_TERMS.some((term) => normalized.includes(` ${term} `) || normalized.includes(`${term},`) || normalized.includes(`${term}.`));
}

function englishMetadata(text: string): boolean {
  const words = normalizeToken(text).split(" ").filter(Boolean);
  return new Set(words.filter((word) => ENGLISH_TERMS.has(word))).size >= 2;
}

function declaredLanguages(food: any): Set<string> {
  const result = new Set<string>();
  for (const value of [food.language, ...(Array.isArray(food.languages) ? food.languages : [])]) {
    const code = cleanText(value)?.toLowerCase().split(/[-_]/)[0]; if (code && /^[a-z]{2,3}$/.test(code)) result.add(code);
  }
  return result;
}

function sample(food: ScoredFood, extra: Record<string, unknown> = {}) {
  return {
    name: food.name, brand: food.brand ?? null, barcode: food.barcode ?? food.source_id,
    data_quality_score: food.data_quality_score, turkey_relevance_score: food.turkey_relevance_score,
    english_relevance_score: food.english_relevance_score, detected_languages: food.detected_languages,
    market_country_tags: food.market_country_tags, inclusion_reasons: food.inclusion_reasons,
    exclusion_reasons: food.exclusion_reasons, ...extra,
  };
}

function keepTop<T>(items: T[], candidate: T, limit: number, compare: (a: T, b: T) => number) {
  items.push(candidate); items.sort(compare); if (items.length > limit) items.length = limit;
}

function scoreFood(food: any, turkeyBrands: Set<string>): { food: ScoredFood; suspicionReasons: string[]; signalFlags: Record<string, boolean> } {
  const inclusion: string[] = [], negative: string[] = [];
  let quality = 0;
  const gtin = validGtin(food.barcode);
  const structural = structuralBarcode(food.barcode);
  if (gtin) { quality += 15; inclusion.push("valid_gtin_checksum"); }
  else if (structural) { quality += 7; inclusion.push("structural_barcode"); negative.push("barcode_nonstandard_length_or_checksum"); }
  else negative.push("missing_or_invalid_barcode");

  const name = meaningfulName(food.name);
  if (name) { quality += 15; inclusion.push("meaningful_product_name"); }
  else if (cleanText(food.name)) { quality += 5; inclusion.push("weak_product_name"); negative.push("weak_product_name"); }
  else negative.push("missing_product_name");

  const nutritionWeights: Record<string, number> = { kcal_100g: 15, protein_100g: 10, carbs_100g: 10, fat_100g: 10 };
  for (const [key, weight] of Object.entries(nutritionWeights)) {
    if (Number.isFinite(food.nutrition?.[key])) { quality += weight; inclusion.push(`${key}_present`); }
    else negative.push(`${key}_missing`);
  }

  const brand = brandTokens(food.brand).length > 0;
  if (brand) { quality += 10; inclusion.push("brand_present"); } else negative.push("brand_missing");
  const servingAmount = Number.isFinite(food.serving_size) && food.serving_size > 0;
  const servingText = Boolean(cleanText(food.household_serving_description));
  if (servingAmount && servingText) { quality += 8; inclusion.push("serving_amount_and_text_present"); }
  else if (servingAmount || servingText) { quality += 5; inclusion.push("partial_serving_present"); negative.push("serving_partial"); }
  else negative.push("serving_missing");
  const category = hasCategory(food);
  if (category) { quality += 7; inclusion.push("category_present"); } else negative.push("category_missing");

  const sourceErrors = Array.isArray(food.quality?.source_error_tags) ? food.quality.source_error_tags : [];
  const sourceBugs = Array.isArray(food.quality?.source_bug_tags) ? food.quality.source_bug_tags : [];
  if (sourceErrors.length) { quality -= Math.min(30, sourceErrors.length * 10); negative.push("source_quality_errors"); }
  if (sourceBugs.length) { quality -= Math.min(15, sourceBugs.length * 5); negative.push("source_quality_bugs"); }
  quality = Math.max(0, Math.min(100, Math.round(quality)));

  const countries = [...new Set(Array.isArray(food.countries) ? food.countries.map(String).filter(Boolean) : [])].sort();
  const countryTurkey = countries.some((tag) => TURKEY_TAGS.has(tag));
  const barcodeTurkey = cleanText(food.barcode)?.startsWith("869") === true;
  const text = metadataText(food), metadataTr = turkishMetadata(text), metadataEn = englishMetadata(text);
  const brands = brandTokens(food.brand), turkeyBrand = brands.some((token) => turkeyBrands.has(token));
  let turkeyScore = 0;
  if (countryTurkey) { turkeyScore += 45; inclusion.push("turkey_country_tag"); }
  if (barcodeTurkey) { turkeyScore += 30; inclusion.push("turkey_869_barcode_prefix"); }
  if (metadataTr) { turkeyScore += 15; inclusion.push("turkish_metadata_detected"); }
  if (turkeyBrand) { turkeyScore += 10; inclusion.push("turkey_associated_brand"); }
  turkeyScore = Math.min(100, turkeyScore);

  const declared = declaredLanguages(food); const detected = new Set(declared);
  if (metadataTr) detected.add("tr"); if (metadataEn) detected.add("en");
  const primary = cleanText(food.language)?.toLowerCase().split(/[-_]/)[0];
  const englishMarket = countries.some((tag) => ENGLISH_MARKETS.has(tag));
  let englishScore = 0;
  if (primary === "en") { englishScore += 50; inclusion.push("english_primary_language"); }
  else if (declared.has("en")) { englishScore += 40; inclusion.push("english_declared_language"); }
  if (metadataEn) { englishScore += 20; inclusion.push("english_metadata_detected"); }
  if (englishMarket) { englishScore += 30; inclusion.push("english_market_tag"); }
  englishScore = Math.min(100, englishScore);

  const eligible = quality >= PRODUCTION_THRESHOLD;
  const exclusion = eligible ? [] : [`data_quality_score_below_${PRODUCTION_THRESHOLD}`, ...negative];
  const scored: ScoredFood = {
    ...food, scoring_version: SCORING_VERSION, data_quality_score: quality,
    turkey_relevance_score: turkeyScore, english_relevance_score: englishScore,
    detected_languages: [...detected].sort(), market_country_tags: countries,
    inclusion_reasons: [...new Set(inclusion)], exclusion_reasons: [...new Set(exclusion)],
    production_eligible: eligible, production_quality_threshold: PRODUCTION_THRESHOLD,
  };
  const macroSum = [food.nutrition?.protein_100g, food.nutrition?.carbs_100g, food.nutrition?.fat_100g]
    .filter(Number.isFinite).reduce((sum: number, value: number) => sum + value, 0);
  const suspicionReasons: string[] = [];
  if (sourceErrors.length) suspicionReasons.push(...sourceErrors.slice(0, 3));
  if (sourceBugs.length) suspicionReasons.push(...sourceBugs.slice(0, 3));
  if (macroSum > 105) suspicionReasons.push("macro_sum_over_105g");
  if (!gtin) suspicionReasons.push("gtin_checksum_or_length_invalid");
  if (!name) suspicionReasons.push("weak_or_placeholder_name");
  if (countryTurkey && !barcodeTurkey && !metadataTr && !turkeyBrand) suspicionReasons.push("turkey_tag_without_other_turkey_signal");
  return { food: scored, suspicionReasons: [...new Set(suspicionReasons)], signalFlags: { gtin, name, brand, serving: servingAmount || servingText, category, countryTurkey, barcodeTurkey, metadataTr, turkeyBrand, metadataEn, englishMarket } };
}

async function buildTurkeyBrandLexicon() {
  const total = new Map<string, number>(), turkeySeed = new Map<string, number>(); let records = 0;
  for await (const food of readJsonlGz(INPUT)) {
    records++;
    const tags = Array.isArray(food.countries) ? food.countries : [];
    const seed = tags.some((tag: string) => TURKEY_TAGS.has(tag)) || cleanText(food.barcode)?.startsWith("869") === true;
    for (const brand of brandTokens(food.brand)) { increment(total, brand); if (seed) increment(turkeySeed, brand); }
  }
  const selected = new Set<string>();
  for (const [brand, seedCount] of turkeySeed) {
    const totalCount = total.get(brand) ?? 0;
    if (seedCount >= 3 && seedCount / totalCount >= 0.25) selected.add(brand);
  }
  return { selected, total, turkeySeed, records };
}

function sortEntries(map: StringMap, limit = 20) {
  return [...map.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0])).slice(0, limit).map(([key, count]) => ({ key, count }));
}

function tableExamples(items: any[], includeSuspicion = false) {
  let md = `| # | Ürün | Marka | Barcode | Quality | TR | EN${includeSuspicion ? " | Şüphe nedenleri" : ""} |\n|---:|---|---|---|---:|---:|---:${includeSuspicion ? "|---" : ""}|\n`;
  items.forEach((item, index) => {
    const suffix = includeSuspicion ? ` | ${(item.suspicion_reasons ?? []).join(", ").replaceAll("|", "/")} |` : " |";
    md += `| ${index + 1} | ${String(item.name ?? "—").replaceAll("|", "/")} | ${String(item.brand ?? "—").replaceAll("|", "/")} | \`${item.barcode}\` | ${item.data_quality_score} | ${item.turkey_relevance_score} | ${item.english_relevance_score}${suffix}\n`;
  });
  return md;
}

async function main() {
  if (!Number.isFinite(PRODUCTION_THRESHOLD) || PRODUCTION_THRESHOLD < 0 || PRODUCTION_THRESHOLD > 100) throw new Error("OFF_CATALOG_QUALITY_THRESHOLD must be 0..100");
  process.stderr.write("Pass 1/2: deriving Turkey-associated brands from country/869 seed products\n");
  const lexicon = await buildTurkeyBrandLexicon();
  process.stderr.write(`Derived ${lexicon.selected.size} Turkey-associated brand tokens from ${lexicon.records} products\n`);

  const allWriter = await atomicGzip(SCORED_OUTPUT), productionWriter = await atomicGzip(PRODUCTION_OUTPUT);
  const thresholds = Object.fromEntries(REPORT_THRESHOLDS.map((value) => [value, 0])) as Record<string, number>;
  const scoreDistribution = new Map<string, number>(), languageCounts = new Map<string, number>(), marketCounts = new Map<string, number>();
  const exclusionCounts = new Map<string, number>(), signalCounts = new Map<string, number>();
  const highQualityTr: any[] = [], highQualityEn: any[] = [], suspicious: any[] = [];
  let total = 0, eligible = 0, qualitySum = 0, turkeySum = 0, englishSum = 0;
  const trCompare = (a: any, b: any) => b.data_quality_score - a.data_quality_score || b.turkey_relevance_score - a.turkey_relevance_score || String(a.barcode).localeCompare(String(b.barcode));
  const enCompare = (a: any, b: any) => b.data_quality_score - a.data_quality_score || b.english_relevance_score - a.english_relevance_score || String(a.barcode).localeCompare(String(b.barcode));
  const suspiciousCompare = (a: any, b: any) => b.suspicion_score - a.suspicion_score || a.data_quality_score - b.data_quality_score || String(a.barcode).localeCompare(String(b.barcode));
  try {
    process.stderr.write("Pass 2/2: scoring and streaming catalog outputs\n");
    for await (const raw of readJsonlGz(INPUT)) {
      total++; const result = scoreFood(raw, lexicon.selected), food = result.food;
      await writeLine(allWriter.stream, food);
      if (food.production_eligible) { eligible++; await writeLine(productionWriter.stream, food); }
      qualitySum += food.data_quality_score; turkeySum += food.turkey_relevance_score; englishSum += food.english_relevance_score;
      increment(scoreDistribution, String(food.data_quality_score));
      for (const threshold of REPORT_THRESHOLDS) if (food.data_quality_score >= threshold) thresholds[String(threshold)]++;
      for (const language of food.detected_languages) increment(languageCounts, language);
      for (const market of food.market_country_tags) increment(marketCounts, market);
      for (const reason of food.exclusion_reasons) increment(exclusionCounts, reason);
      for (const [signal, present] of Object.entries(result.signalFlags)) if (present) increment(signalCounts, signal);
      if (food.data_quality_score >= 80 && food.turkey_relevance_score >= 45) keepTop(highQualityTr, sample(food), 50, trCompare);
      if (food.data_quality_score >= 80 && food.english_relevance_score >= 60 && food.turkey_relevance_score < 45) keepTop(highQualityEn, sample(food), 50, enCompare);
      if (result.suspicionReasons.length) {
        const suspicionScore = result.suspicionReasons.length * 20 + (100 - food.data_quality_score);
        keepTop(suspicious, { ...sample(food), suspicion_score: suspicionScore, suspicion_reasons: result.suspicionReasons }, 20, suspiciousCompare);
      }
      if (total % 100000 === 0) process.stderr.write(`${total} scored, ${eligible} production-eligible\n`);
    }
    await allWriter.finish(); await productionWriter.finish();
  } catch (error) { allWriter.stream.destroy(); productionWriter.stream.destroy(); throw error; }

  const topTurkeyBrands = [...lexicon.selected].map((brand) => ({ brand, seed_products: lexicon.turkeySeed.get(brand) ?? 0, total_products: lexicon.total.get(brand) ?? 0 }))
    .sort((a, b) => b.seed_products - a.seed_products || a.brand.localeCompare(b.brand)).slice(0, 30);
  const metrics = {
    scoring_version: SCORING_VERSION, input_file: "data/normalized/openfoodfacts.jsonl.gz", total_products: total,
    production_quality_threshold: PRODUCTION_THRESHOLD, production_eligible_products: eligible,
    production_excluded_low_quality_products: total - eligible,
    thresholds: Object.fromEntries(REPORT_THRESHOLDS.map((value) => [value, { count: thresholds[String(value)], coverage: Number((thresholds[String(value)] / total).toFixed(6)) }])),
    average_scores: { data_quality: Number((qualitySum / total).toFixed(2)), turkey_relevance: Number((turkeySum / total).toFixed(2)), english_relevance: Number((englishSum / total).toFixed(2)) },
    signal_coverage: Object.fromEntries(sortEntries(signalCounts, 100).map(({ key, count }) => [key, { count, coverage: Number((count / total).toFixed(6)) }])),
    detected_language_counts: sortEntries(languageCounts, 100), top_market_country_tags: sortEntries(marketCounts, 30),
    exclusion_reason_counts: sortEntries(exclusionCounts, 100), turkey_associated_brand_tokens: lexicon.selected.size,
    top_turkey_associated_brands: topTurkeyBrands, high_quality_tr_examples: highQualityTr,
    high_quality_en_global_examples: highQualityEn, suspicious_examples: suspicious,
    output_files: { scored_all: "data/catalog/openfoodfacts-scored.jsonl.gz", production_candidates: "data/catalog/openfoodfacts-production.jsonl.gz" },
  };
  await fs.writeFile(METRICS_OUTPUT, `${JSON.stringify(metrics, null, 2)}\n`);

  let md = `# Open Food Facts Global Bilingual Catalog Scoring Report\n\n`;
  md += `Input değiştirilmeden streaming olarak skorlandı. Türkiye veya İngilizce relevance hiçbir kaydın elenmesinde kullanılmadı; production candidate seçimi yalnız \`data_quality_score >= ${PRODUCTION_THRESHOLD}\` koşuludur.\n\n`;
  md += `## Özet\n\n| Metrik | Değer |\n|---|---:|\n| Toplam scored ürün | ${total.toLocaleString("tr-TR")} |\n| Production candidate | ${eligible.toLocaleString("tr-TR")} (${percent(eligible, total)}) |\n| Yalnız düşük quality nedeniyle excluded | ${(total - eligible).toLocaleString("tr-TR")} (${percent(total - eligible, total)}) |\n| Ortalama data quality | ${metrics.average_scores.data_quality} / 100 |\n| Ortalama Turkey relevance | ${metrics.average_scores.turkey_relevance} / 100 |\n| Ortalama English relevance | ${metrics.average_scores.english_relevance} / 100 |\n| Derived Turkey-associated brand token | ${lexicon.selected.size.toLocaleString("tr-TR")} |\n\n`;
  md += `## Quality threshold senaryoları\n\n| Minimum quality | Kalan ürün | Coverage |\n|---:|---:|---:|\n`;
  for (const threshold of REPORT_THRESHOLDS) md += `| ${threshold} | ${thresholds[String(threshold)].toLocaleString("tr-TR")} | ${percent(thresholds[String(threshold)], total)} |\n`;
  md += `\n## Scoring özeti\n\nData quality: valid GTIN 15, anlamlı ad 15, calories 15, protein/carbs/fat 10'ar, brand 10, serving 8 ve category 7 puandır. Standard dışı fakat numeric barcode 7 puan alır. OFF source error tag'leri hata başına 10 (maksimum 30), bug tag'leri hata başına 5 (maksimum 15) puan düşürür.\n\nTurkey relevance: Turkey country tag 45, 869 prefix 30, Türkçe metadata 15 ve dataset içinden türetilen Turkey-associated brand 10 puandır. English relevance: primary/declared English language, English metadata ve English-market tag sinyallerinden oluşur. Relevance yalnız ranking içindir.\n\n`;
  md += `## Yüksek kaliteli 50 TR ürün\n\n${tableExamples(highQualityTr)}\n`;
  md += `## Yüksek kaliteli 50 EN/global ürün\n\n${tableExamples(highQualityEn)}\n`;
  md += `## 20 şüpheli kayıt\n\n${tableExamples(suspicious, true)}\n`;
  md += `## Çıktılar\n\n- Tüm scored kayıtlar: \`data/catalog/openfoodfacts-scored.jsonl.gz\`\n- Quality ${PRODUCTION_THRESHOLD}+ production candidates: \`data/catalog/openfoodfacts-production.jsonl.gz\`\n- Metrikler ve örnekler: \`data/catalog/openfoodfacts-catalog-metrics.json\`\n\nDatabase import yapılmadı. Normalize input değiştirilmedi.\n`;
  await fs.writeFile(REPORT_OUTPUT, md);
  console.log(`Scored ${total}; production eligible ${eligible}; report ${REPORT_OUTPUT}`);
}

await main();
