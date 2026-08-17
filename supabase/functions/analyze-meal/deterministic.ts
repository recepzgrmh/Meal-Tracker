import type { AnalysisItem, NutritionPer100g } from '../_shared/contracts.ts'

export interface CatalogAlias {
  value: string
  priority: number
}

export interface CatalogPortion {
  label: string
  grams: number
  isDefault: boolean
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
  ...Object.keys(numberWords),
])

export function normalizeTurkishInput(input: string): string {
  return input
    .replace(/½/gu, ' yarım ')
    .normalize('NFKC')
    .toLocaleLowerCase('tr-TR')
    .replace(/[’']/gu, ' ')
    .replace(/[^\p{L}\p{N}½]+/gu, ' ')
    .replace(/\s+/gu, ' ')
    .trim()
}

export function analyzeDeterministically(
  input: string,
  catalog: CatalogFood[],
): DeterministicAnalysis {
  const normalizedInput = normalizeTurkishInput(input)
  const matches = findNonOverlappingMatches(normalizedInput, catalog)
  const items = matches.map((match, index) => toAnalysisItem(normalizedInput, match, index))

  return {
    normalizedInput,
    items,
    unmatchedText: extractUnmatchedTokens(normalizedInput, matches),
  }
}

function findNonOverlappingMatches(input: string, catalog: CatalogFood[]): PhraseMatch[] {
  const candidates: PhraseMatch[] = []

  for (const food of catalog) {
    for (const alias of food.aliases) {
      const normalizedAlias = normalizeTurkishInput(alias.value)
      if (!normalizedAlias) continue
      const matcher = new RegExp(`(?:^|\\s)(${escapeRegExp(normalizedAlias)})(?=\\s|$)`, 'gu')
      for (const result of input.matchAll(matcher)) {
        const prefixLength = result[0].length - result[1].length
        const start = (result.index ?? 0) + prefixLength
        candidates.push({
          food,
          alias,
          start,
          end: start + normalizedAlias.length,
          sourceText: input.slice(start, start + normalizedAlias.length),
        })
      }
    }
  }

  candidates.sort((a, b) => a.start - b.start || b.sourceText.length - a.sourceText.length)
  const selected: PhraseMatch[] = []
  for (const candidate of candidates) {
    if (selected.some((match) => candidate.start < match.end && candidate.end > match.start)) {
      continue
    }
    selected.push(candidate)
  }
  return selected.sort((a, b) => a.start - b.start)
}

function toAnalysisItem(input: string, match: PhraseMatch, index: number): AnalysisItem {
  const portion = resolvePortion(input, match)
  const identityAmbiguous = match.alias.priority < 80
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
    matchMethod: match.alias.priority >= 100 ? 'exact' : 'alias',
    needsClarification,
    ...(needsClarification
      ? { clarificationReason: identityAmbiguous ? 'identity' as const : 'portion' as const }
      : {}),
    nutritionPer100g: match.food.nutritionPer100g,
  }
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

  const halfMatch = before.match(/(?:^|\s)(?:yarım|yarim|½)(?:\s+(?:adet|tane))?\s*$/u)
  if (halfMatch) {
    return {
      label: scalePortionLabel(defaultPortion.label, '½'),
      grams: defaultPortion.grams / 2,
      quantity: 0.5,
      inferred: false,
    }
  }

  const countMatch = before.match(
    /(?:^|\s)(\d{1,2}|bir|iki|üç|uc|dört|dort|beş|bes)(?:\s+(?:adet|tane))?\s*$/u,
  )
  if (countMatch) {
    const quantity = Number(countMatch[1]) || numberWords[countMatch[1]]
    return {
      label: scalePortionLabel(defaultPortion.label, String(quantity)),
      grams: defaultPortion.grams * quantity,
      quantity,
      inferred: false,
    }
  }

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

  return {
    label: defaultPortion.label,
    grams: defaultPortion.grams,
    quantity: 1,
    inferred: true,
  }
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
