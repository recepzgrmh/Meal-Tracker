import { test } from 'vitest'
import { assertEquals } from '../assert.ts'
import {
  deduplicateRetrievalCandidates,
  isExactCanonicalMatch,
  toAnalysisItems,
} from '../../src/routes/analyze-meal/index.ts'
import type { CandidateSelectionResult, RetrievalCandidate } from '../../src/routes/analyze-meal/candidate-selector.ts'

const createCandidate = (
  foodId: string,
  canonicalName: string,
  matchedAlias: string,
  score: number,
): RetrievalCandidate => ({
  foodId,
  canonicalName,
  matchedAlias,
  score,
  defaultGrams: 50,
  defaultPortionLabel: '1 adet',
  nutritionPer100g: { calories: 150, protein: 12, carbs: 1, fat: 10 },
})

test('deduplicateRetrievalCandidates merges candidates with identical canonical names', () => {
  const candidates: RetrievalCandidate[] = [
    createCandidate('food-1', 'Yumurta', 'yumurta', 0.95),
    createCandidate('food-2', 'Yumurta', 'yumurta', 0.94),
    createCandidate('food-3', 'Yumurta', 'haşlanmış yumurta', 0.90),
    createCandidate('food-4', 'Yumurta Akı', 'yumurta akı', 0.88),
  ]

  const result = deduplicateRetrievalCandidates(candidates, 'yumurta')

  // Should keep only the best 'Yumurta' entry and the 'Yumurta Akı' entry
  assertEquals(result.length, 2)
  assertEquals(result[0].foodId, 'food-1')
  assertEquals(result[1].foodId, 'food-4')
})

test('deduplicateRetrievalCandidates prefers exact alias/canonical matches when query is supplied', () => {
  const candidates: RetrievalCandidate[] = [
    createCandidate('food-branded', 'Yumurta', 'marka yumurta', 0.96),
    createCandidate('food-canonical', 'Yumurta', 'yumurta', 0.94),
  ]

  const result = deduplicateRetrievalCandidates(candidates, 'yumurta')

  assertEquals(result.length, 1)
  assertEquals(result[0].foodId, 'food-canonical')
})

test('isExactCanonicalMatch identifies exact matches regardless of casing or diacritics', () => {
  const candidate = createCandidate('food-1', 'Beyaz Peynir', 'beyaz peynir', 0.90)

  assertEquals(isExactCanonicalMatch('beyaz peynir', candidate), true)
  assertEquals(isExactCanonicalMatch('Beyaz Peynir', candidate), true)
  assertEquals(isExactCanonicalMatch('BEYAZ PEYNİR', candidate), true)
  assertEquals(isExactCanonicalMatch('kaşar peyniri', candidate), false)
})

test('toAnalysisItems sets needsClarification to false for exact canonical matches', () => {
  const candidates: RetrievalCandidate[] = [
    createCandidate('food-1', 'Yumurta', 'yumurta', 0.95),
    createCandidate('food-2', 'Yumurta', 'yumurta', 0.94),
    createCandidate('food-3', 'Yumurta Akı', 'yumurta akı', 0.93),
  ]

  const selection: CandidateSelectionResult = {
    selections: [{
      candidateId: 'food-1',
      sourceText: '2 yumurta',
      estimatedGrams: 100,
      confidence: 0.92,
    }],
    noMatch: false,
    model: 'test',
    promptVersion: 'candidate-allow-list-v1',
    inputTokens: 10,
    outputTokens: 5,
    attempts: 1,
    cacheHit: false,
  }

  const items = toAnalysisItems(selection, candidates, new Map(), 'yumurta')

  assertEquals(items.length, 1)
  assertEquals(items[0].foodId, 'food-1')
  assertEquals(items[0].needsClarification, false)
  assertEquals(items[0].alternativeFoodIds, undefined)
})

test('toAnalysisItems triggers identity clarification for vague non-exact queries with close scores', () => {
  const candidates: RetrievalCandidate[] = [
    createCandidate('food-1', 'Süt, Tam Yağlı', 'süt', 0.85),
    createCandidate('food-2', 'Badem Sütü', 'badem sütü', 0.83),
  ]

  const selection: CandidateSelectionResult = {
    selections: [{
      candidateId: 'food-1',
      sourceText: 'sütlü bir şey',
      estimatedGrams: 200,
      confidence: 0.80,
    }],
    noMatch: false,
    model: 'test',
    promptVersion: 'candidate-allow-list-v1',
    inputTokens: 10,
    outputTokens: 5,
    attempts: 1,
    cacheHit: false,
  }

  const items = toAnalysisItems(selection, candidates, new Map(), 'sütlü bir şey')

  assertEquals(items.length, 1)
  assertEquals(items[0].foodId, 'food-1')
  assertEquals(items[0].needsClarification, true)
  assertEquals(items[0].clarificationReason, 'identity')
  assertEquals(items[0].alternativeFoodIds, ['food-2'])
})
