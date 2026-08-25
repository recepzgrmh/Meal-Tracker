import type { AnalysisItem, NutritionPer100g } from '../../shared/contracts.ts'

export interface CatalogAlias {
  value: string
  priority: number
}

export interface CatalogPortion {
  label: string
  grams: number
  isDefault: boolean
  sizeClass?: 'small' | 'regular' | 'large' | 'custom'
  imageUrl?: string
}

export interface CatalogFood {
  id: string
  canonicalName: string
  nutritionPer100g: NutritionPer100g
  aliases: CatalogAlias[]
  portions: CatalogPortion[]
}

export interface DeterministicAnalysis {
  normalizedInput: string
  items: AnalysisItem[]
  unmatchedText: string[]
  /**
   * True when two matches sit directly against each other with no word between
   * them, which is what one dish looks like after the matcher has taken it
   * apart: "kremalı tavuklu makarna" as "kremalı" + "tavuklu makarna". A real
   * list of foods carries a separator the normalizer keeps — a count, a
   * quantity word, "ve" — so the absence of one is the signal.
   *
   * Callers use it to refuse a result that covers the whole sentence but only
   * by fragmenting it, and send the sentence to the language model instead.
   *
   * Only `analyzeDeterministically` sets it. Analyses assembled downstream —
   * merged modalities, the model path's per-phrase results — carry no single
   * phrase for it to describe, so there it is absent rather than false.
   */
  fragmentedPhrase?: boolean
}

interface PhraseMatch {
  food: CatalogFood
  alias: CatalogAlias
  start: number
  end: number
  sourceText: string
}

interface PortionResolution {
  label: string
  grams: number
  quantity: number
  inferred: boolean
}

const numberWords: Record<string, number> = {
  bir: 1,
  iki: 2,
  üç: 3,
  uc: 3,
  dört: 4,
  dort: 4,
  beş: 5,
  bes: 5,
  one: 1,
  two: 2,
  three: 3,
  four: 4,
  five: 5,
}

const ignoredTokens = new Set([
  've',
  'ile',
  'biraz',
  'az',
  'adet',
  'tane',
  'porsiyon',
  'dilim',
  'yarım',
  'yarim',
  'gram',
  'gr',
  'g',
  'and',
  'with',
  'a',
  'an',
  'piece',
  'pieces',
  'serving',
  'slice',
  'kase',
  'tabak',
  'bardak',
  'fincan',
  'kaşık',
  'kasik',
  'yemek',
  'tatlı',
  'tatli',
  'çay',
  'cay',
  'bowl',
  'plate',
  'cup',
  'tablespoon',
  'teaspoon',
  'half',
  'buçuk',
  'bucuk',
  'yarısı',
  'yarisi',
  'grams',
  ...Object.keys(numberWords),
])

// Mirrors the single optional suffix group in inflectedAliasPattern, so a key
// generated here matches exactly the aliases the matcher can still resolve.
const inflectionSuffixes = [
  'lar',
  'ler',
  'yı',
  'yi',
  'yu',
  'yü',
  'ya',
  'ye',
  'ın',
  'in',
  'un',
  'ün',
  'dan',
  'den',
  'tan',
  'ten',
  'da',
  'de',
  'ta',
  'te',
  'es',
  'ı',
  'i',
  'u',
  'ü',
  'a',
  'e',
  's',
]

const MAX_ALIAS_WORDS = 5
const MAX_LOOKUP_KEYS = 500

/**
 * Every catalog alias that could still match `input` once inflection and
 * consonant softening are undone. The catalog is far too large to load whole,
 * so these keys scope the alias query to the phrases actually typed.
 */
export function aliasLookupKeys(
  inputs: string[],
  locale: 'tr-TR' | 'en-US' = 'tr-TR',
): string[] {
  const keys = new Set<string>()
  for (const input of inputs) {
    const words = normalizeTurkishInput(input, locale).split(' ').filter(Boolean)
    for (let start = 0; start < words.length; start += 1) {
      const limit = Math.min(words.length, start + MAX_ALIAS_WORDS)
      for (let end = start + 1; end <= limit; end += 1) {
        const prefix = words.slice(start, end - 1).join(' ')
        for (const variant of deinflect(words[end - 1])) {
          keys.add(prefix ? `${prefix} ${variant}` : variant)
          if (keys.size >= MAX_LOOKUP_KEYS) return [...keys]
        }
      }
    }
  }
  return [...keys]
}

// The suffixes that are a single bare vowel. Stripping one of these is the only
// way deinflect can turn a derivational form into a stem that was never a word.
const bareVowelSuffixes = new Set(['ı', 'i', 'u', 'ü', 'a', 'e'])

function deinflect(word: string): string[] {
  const stems = new Set<string>([word])
  for (const suffix of inflectionSuffixes) {
    if (!word.endsWith(suffix)) continue
    const stem = word.slice(0, -suffix.length)
    if (stem.length < 2) continue
    // `-lI` is derivational, not inflectional: "kremalı" is the adjective "with
    // cream", not a case form of a noun "kremal". Stripping the bare vowel
    // invents an `-l` final stem, and an invented stem only ever matches by
    // accident — the Open Food Facts brand row "Kremal" is how "kremalı tavuklu
    // makarna" turned into two foods. The whole word stays a lookup key, so a
    // catalog entry genuinely spelled that way is still reachable.
    if (bareVowelSuffixes.has(suffix) && stem.endsWith('l')) continue
    stems.add(stem)
  }
  const variants = new Set<string>(stems)
  for (const stem of stems) {
    if (stem.endsWith('d')) variants.add(`${stem.slice(0, -1)}t`)
    if (stem.endsWith('ğ') || stem.endsWith('g')) variants.add(`${stem.slice(0, -1)}k`)
  }
  return [...variants]
}

/**
 * The only point where Turkish and English lowercasing disagree is the
 * dotted/dotless i, and getting it wrong silently costs a match rather than
 * raising anything: lowercasing English with Turkish rules turned "Ice cream"
 * into "ıce cream", which matches no alias at all. Phones capitalise the first
 * letter of a sentence by default, so that was the normal case for an English
 * user, not an edge one.
 *
 * The two capitals are mapped explicitly and everything else goes through a
 * locale-independent `toLowerCase`. Using `toLocaleLowerCase('en-US')` instead
 * would not do: it lowercases "İ" to "i" plus a combining dot above, which is
 * a different string from the "i" every alias is stored with.
 */
export function normalizeTurkishInput(
  input: string,
  locale: 'tr-TR' | 'en-US' = 'tr-TR',
): string {
  const composed = input.replace(/½/gu, ' yarım ').normalize('NFKC')
  const foldedI = locale === 'tr-TR'
    ? composed.replace(/I/gu, 'ı').replace(/İ/gu, 'i')
    : composed.replace(/[Iİ]/gu, 'i')
  return foldedI
    .toLowerCase()
    .replace(/[’']/gu, ' ')
    .replace(/[^\p{L}\p{N}½]+/gu, ' ')
    .replace(/\s+/gu, ' ')
    .trim()
}

export function analyzeDeterministically(
  input: string,
  catalog: CatalogFood[],
  locale: 'tr-TR' | 'en-US' = 'tr-TR',
): DeterministicAnalysis {
  // Input and aliases must be folded the same way or they stop meeting.
  const normalizedInput = normalizeTurkishInput(input, locale)
  const matches = findNonOverlappingMatches(normalizedInput, catalog, locale)
  const items = matches.map((match, index) => toAnalysisItem(normalizedInput, match, index))

  return {
    normalizedInput,
    items,
    unmatchedText: extractUnmatchedTokens(normalizedInput, matches),
    fragmentedPhrase: hasAdjacentMatches(normalizedInput, matches),
  }
}

function hasAdjacentMatches(input: string, matches: PhraseMatch[]): boolean {
  for (let index = 1; index < matches.length; index += 1) {
    const between = input.slice(matches[index - 1].end, matches[index].start)
    if (between.trim().length === 0) return true
  }
  return false
}

function findNonOverlappingMatches(
  input: string,
  catalog: CatalogFood[],
  locale: 'tr-TR' | 'en-US',
): PhraseMatch[] {
  const candidates: PhraseMatch[] = []

  for (const food of catalog) {
    for (const alias of food.aliases) {
      const normalizedAlias = normalizeTurkishInput(alias.value, locale)
      if (!normalizedAlias) continue
      const matcher = new RegExp(
        `(?:^|\\s)(${inflectedAliasPattern(normalizedAlias)})(?=\\s|$)`,
        'gu',
      )
      for (const result of input.matchAll(matcher)) {
        const prefixLength = result[0].length - result[1].length
        const start = (result.index ?? 0) + prefixLength
        candidates.push({
          food,
          alias,
          start,
          end: start + result[1].length,
          sourceText: result[1],
        })
      }
    }
  }

  // Position first, then longest match — those decide which reading of the
  // sentence wins. The last two decide between readings that are equally good
  // by those measures, and both had to be added:
  //
  // Priority, because it was not consulted at all. Two aliases of the same
  // length for the same word are ordered by nothing, so a machine-generated
  // alias could beat a curated one purely on the order the catalog query
  // returned rows — and since the ambiguity threshold is 80, the wrong winner
  // also reported confidence 0.98 and asked no question. Higher priority means
  // a more specific, more curated alias, so it should win.
  //
  // Food id last, because "the order the catalog query returned rows" is not a
  // rule at all: the same sentence could resolve differently between two runs.
  // An accuracy system whose evals are supposed to be comparable cannot have a
  // nondeterministic matcher.
  candidates.sort((a, b) =>
    a.start - b.start ||
    b.sourceText.length - a.sourceText.length ||
    b.alias.priority - a.alias.priority ||
    (a.food.id < b.food.id ? -1 : a.food.id > b.food.id ? 1 : 0)
  )
  const selected: PhraseMatch[] = []
  for (const candidate of candidates) {
    if (selected.some((match) => candidate.start < match.end && candidate.end > match.start)) {
      continue
    }
    selected.push(candidate)
  }
  return selected.sort((a, b) => a.start - b.start)
}

function toAnalysisItem(input: string, match: PhraseMatch, index: number, locale: 'tr-TR' | 'en-US' = 'tr-TR'): AnalysisItem {
  const portion = resolvePortion(input, match)
  const normalizedSource = normalizeTurkishInput(match.sourceText, locale)
  const normalizedCanonical = normalizeTurkishInput(match.food.canonicalName, locale)
  const isCanonicalMatch = normalizedSource === normalizedCanonical || match.alias.priority >= 80

  const identityAmbiguous = !isCanonicalMatch && match.alias.priority < 80
  const needsClarification = identityAmbiguous || portion.inferred

  return {
    itemKey: `item-${index + 1}`,
    sourceText: match.sourceText,
    foodId: match.food.id,
    canonicalName: match.food.canonicalName,
    portionLabel: portion.label,
    grams: round(portion.grams, 2),
    quantity: portion.quantity,
    confidence: identityAmbiguous ? 0.72 : portion.inferred ? 0.84 : 0.98,
    matchMethod: match.alias.priority >= 100 || isCanonicalMatch ? 'exact' : 'alias',
    needsClarification,
    ...(needsClarification
      ? { clarificationReason: identityAmbiguous ? 'identity' as const : 'portion' as const }
      : {}),
    portionOptions: match.food.portions
      .slice()
      .sort((left, right) => left.grams - right.grams)
      .map((option) => ({
        label: option.label,
        grams: option.grams,
        ...(option.sizeClass ? { sizeClass: option.sizeClass } : {}),
        ...(option.imageUrl ? { imageUrl: option.imageUrl } : {}),
      })),
    nutritionPer100g: match.food.nutritionPer100g,
  }
}

/**
 * True when a portion label states a mass rather than one unit of the food.
 *
 * "100 g" and "28 g" are the basis the nutrition is expressed in; "1 adet",
 * "1 dilim", "1 porsiyon", "1 cup" name a thing you can count. The imported
 * catalog is overwhelmingly the former — of 120,013 portion rows the most
 * common labels are "100 g", "1 ONZ (28 g)" and "3 undetermined oz" — so a
 * counted food usually has nothing countable to multiply.
 */
/**
 * True when a label names a countable unit: a leading quantity and a unit word.
 *
 * Distinguishes "1 adet" and "2 dilim" from the size variants that sit beside
 * them in the same list — "yarım", "az", "fazla" are how much of one, not how
 * many, and multiplying a count by "yarım" is how "1 simit" became 50 g.
 */
function isCountableUnitLabel(label: string): boolean {
  return /^\s*\d+(?:[.,]\d+)?\s+(?:adet|tane|dilim|porsiyon|piece|pieces|slice|serving|portion)\b/iu
    .test(label)
}

function isMassBasisLabel(label: string, grams: number): boolean {
  if (/^\s*1\s+(?:adet|tane|dilim|porsiyon|piece|pieces|slice|serving|portion)\b/iu.test(label)) {
    return false
  }
  if (/^\s*\d+(?:[.,]\d+)?\s*(?:g|gr|gram|ml|mL)\s*$/u.test(label)) return true

  // The importer also wrote mass bases as fake units: "1.65 portion (100 g)",
  // "1 ONZ (28 g)". The parenthetical is the giveaway — when it restates exactly
  // the portion's own weight, the label is describing that weight, not a thing you can hold.
  const parenthetical = /\(\s*(\d+(?:[.,]\d+)?)\s*(?:g|gr|gram|ml|mL)\s*\)/u.exec(label)
  if (parenthetical) {
    return Math.abs(Number(parenthetical[1].replace(',', '.')) - grams) < 0.01
  }
  return false
}

function parseQuantity(token: string): number | null {
  const numeric = Number(token)
  if (Number.isFinite(numeric)) return numeric
  const word = numberWords[token]
  return word !== undefined ? word : null
}

function resolvePortion(input: string, match: PhraseMatch): PortionResolution {
  const before = input.slice(Math.max(0, match.start - 28), match.start).trim()
  const after = input.slice(match.end, Math.min(input.length, match.end + 20)).trim()
  const defaultPortion = match.food.portions.find((portion) => portion.isDefault) ??
    match.food.portions[0]
  if (!defaultPortion) {
    throw new Error(`Catalog food ${match.food.id} has no portion`)
  }

  const gramsBefore = before.match(
    /(?:^|\s)(\d{1,4}(?:[.,]\d{1,2})?)\s*(?:g|gr|gram)\s*$/u,
  )
  const gramsMatch = gramsBefore
  if (gramsMatch) {
    const grams = Number(gramsMatch[1].replace(',', '.'))
    if (grams > 0 && grams <= 10000) {
      return { label: `${grams} g`, grams, quantity: 1, inferred: false }
    }
  }

  const halfMatch = before.match(
    /(?:^|\s)(?:yarım|yarim|½|half)(?:\s+(?:adet|tane|piece))?\s*$/u,
  )
  if (halfMatch) {
    return {
      label: scalePortionLabel(defaultPortion.label, '½'),
      grams: defaultPortion.grams / 2,
      quantity: 0.5,
      inferred: false,
    }
  }

  const oneAndHalfMatch = before.match(/(?:^|\s)(?:bir|one)\s+(?:buçuk|bucuk|and a half)\s*$/u)
  if (oneAndHalfMatch) {
    return {
      label: scalePortionLabel(defaultPortion.label, '1.5'),
      grams: defaultPortion.grams * 1.5,
      quantity: 1.5,
      inferred: false,
    }
  }

  const countMatch = before.match(
    /(?:^|\s)(\d{1,2}|bir|iki|üç|uc|dört|dort|beş|bes|one|two|three|four|five)(?:\s+(?:adet|tane|piece|pieces))?\s*$/u,
  )
  if (countMatch) {
    const quantity = parseQuantity(countMatch[1])
    if (quantity !== null && quantity > 0) {
      const countable = !isMassBasisLabel(defaultPortion.label, defaultPortion.grams)
        ? defaultPortion
        : match.food.portions.find((portion) => isCountableUnitLabel(portion.label)) ??
          defaultPortion
      return {
        label: scalePortionLabel(countable.label, String(quantity)),
        grams: countable.grams * quantity,
        quantity,
        inferred: isMassBasisLabel(countable.label, countable.grams),
      }
    }
  }

  const householdPortion = resolveHouseholdPortion(
    before,
    after,
    match.food.portions,
  )
  if (householdPortion) return householdPortion

  const vagueLabel = before.match(/(?:^|\s)(biraz|az|fazla)\s*$/u)?.[1]
  if (vagueLabel) {
    const catalogLabel = vagueLabel === 'biraz' ? 'az' : vagueLabel
    const vaguePortion = match.food.portions.find((portion) =>
      normalizeTurkishInput(portion.label) === catalogLabel
    )
    if (vaguePortion) {
      return {
        label: vaguePortion.label,
        grams: vaguePortion.grams,
        quantity: 1,
        inferred: true,
      }
    }
  }

  const gramsAfter = after.match(
    /^(\d{1,4}(?:[.,]\d{1,2})?)\s*(?:g|gr|gram)(?:\s|$)/u,
  )
  if (gramsAfter) {
    const grams = Number(gramsAfter[1].replace(',', '.'))
    if (grams > 0 && grams <= 10000) {
      return { label: `${grams} g`, grams, quantity: 1, inferred: false }
    }
  }

  const countAfter = after.match(
    /^(\d{1,2}|bir|iki|üç|uc|dört|dort|beş|bes|one|two|three|four|five)\s+(?:adet|tane|piece|pieces)(?:\s|$)/u,
  )
  if (countAfter) {
    const quantity = parseQuantity(countAfter[1])
    if (quantity !== null && quantity > 0) {
      return {
        label: scalePortionLabel(defaultPortion.label, String(quantity)),
        grams: defaultPortion.grams * quantity,
        quantity,
        inferred: false,
      }
    }
  }

  if (/^(?:yarısı|yarisi|half)(?:\s|$)/u.test(after)) {
    return {
      label: scalePortionLabel(defaultPortion.label, '½'),
      grams: defaultPortion.grams / 2,
      quantity: 0.5,
      inferred: false,
    }
  }

  return {
    label: defaultPortion.label,
    grams: defaultPortion.grams,
    quantity: 1,
    inferred: true,
  }
}

function resolveHouseholdPortion(
  before: string,
  after: string,
  portions: CatalogPortion[],
): PortionResolution | null {
  const quantityPattern = '(\\d{1,2}|bir|iki|üç|uc|dört|dort|beş|bes|one|two|three|four|five)'
  for (const portion of portions) {
    const normalized = normalizeTurkishInput(portion.label)
    const unit = normalized.replace(/^(?:1|bir|one)\s+/u, '').trim()
    if (!unit || /^(?:g|gr|gram|az|fazla|small|large)$/u.test(unit)) continue
    const escapedUnit = escapeRegExp(unit)
    const beforeMatch = before.match(
      new RegExp(`(?:^|\\s)${quantityPattern}\\s+${escapedUnit}\\s*$`, 'u'),
    )
    const afterMatch = after.match(
      new RegExp(`^${quantityPattern}\\s+${escapedUnit}(?:\\s|$)`, 'u'),
    )
    const token = beforeMatch?.[1] ?? afterMatch?.[1]
    if (!token) continue
    const quantity = parseQuantity(token)
    if (quantity === null || quantity <= 0) continue
    return {
      label: `${quantity} ${unit}`,
      grams: portion.grams * quantity,
      quantity,
      inferred: false,
    }
  }
  return null
}

function extractUnmatchedTokens(input: string, matches: PhraseMatch[]): string[] {
  let remainder = input
  for (const match of [...matches].sort((a, b) => b.start - a.start)) {
    remainder = `${remainder.slice(0, match.start)} ${remainder.slice(match.end)}`
  }

  return [
    ...new Set(
      remainder
        .split(/\s+/u)
        .filter(Boolean)
        .filter((token) => !ignoredTokens.has(token))
        .filter((token) => !/^\d+(?:[.,]\d+)?$/u.test(token)),
    ),
  ]
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/gu, '\\$&')
}

function inflectedAliasPattern(alias: string): string {
  const separator = alias.lastIndexOf(' ')
  const prefix = separator < 0 ? '' : `${escapeRegExp(alias.slice(0, separator + 1))}`
  const finalWord = separator < 0 ? alias : alias.slice(separator + 1)
  const escaped = escapeRegExp(finalWord)
  // The mirror of the `-lI` rule in deinflect, and it has to stay one: keys and
  // patterns that disagree either miss aliases the query fetched or match ones
  // it never asked for. An `l`-final alias plus a bare vowel is the adjective
  // form of some other word ("kremal" + "ı" reads the "kremalı" in "kremalı
  // tavuklu makarna"), so that one branch is dropped. Everything else — the
  // buffer `y`, genitive, locative, plural, softening — is unchanged, and an
  // alias that genuinely ends in `l` still matches itself.
  const bareVowel = finalWord.endsWith('l') ? '' : '(?:y?[ıiuüae])|'
  const suffix = `(?:${bareVowel}(?:[ıiuü]n)|(?:d|t)(?:a|e|an|en)|(?:lar|ler))?`
  const softened = finalWord.endsWith('t')
    ? `${escapeRegExp(finalWord.slice(0, -1))}d${suffix}`
    : finalWord.endsWith('k')
    ? `${escapeRegExp(finalWord.slice(0, -1))}(?:ğ|g)${suffix}`
    : null
  const finalPattern = softened
    ? `(?:${escaped}${suffix}|${softened}|${escaped}(?:s|es))`
    : `(?:${escaped}${suffix}|${escaped}(?:s|es))`
  return `${prefix}${finalPattern}`
}

function round(value: number, digits: number): number {
  const factor = 10 ** digits
  return Math.round((value + Number.EPSILON) * factor) / factor
}

function scalePortionLabel(label: string, quantity: string): string {
  const normalized = label.trim()
  return /^1(?:[.,]0+)?\s+/u.test(normalized)
    ? normalized.replace(/^1(?:[.,]0+)?/u, quantity)
    : `${quantity} × ${normalized}`
}
