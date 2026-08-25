import { test } from 'vitest'
import type { DeterministicAnalysis } from '../../src/routes/analyze-meal/deterministic.ts'
import {
  applyVisionEvidence,
  reconcileModalities,
  remainingUnmatchedText,
} from '../../src/routes/analyze-meal/reconcile.ts'
import type { AnalysisItem } from '../../src/shared/contracts.ts'

test('explicit text wins when vision detects the same catalog food', () => {
  const result = reconcileModalities(
    analysis([item('egg', 100), item('cheese', 15), item('simit', 50)]),
    analysis([item('egg', 156), item('cheese', 80), item('simit', 90)]),
  )

  assertEquals(result.items.map((candidate) => candidate.foodId), [
    'egg',
    'cheese',
    'simit',
  ])
  assertEquals(result.items.map((candidate) => candidate.grams), [100, 15, 50])
  assertEquals(result.items.map((candidate) => candidate.itemKey), [
    'item-1',
    'item-2',
    'item-3',
  ])
})

test('vision contributes foods missing from explicit text', () => {
  const result = reconcileModalities(
    analysis([item('egg', 100)]),
    analysis([item('egg', 120), item('cheese', 30)]),
  )

  assertEquals(result.items.map((candidate) => candidate.foodId), ['egg', 'cheese'])
  assertEquals(result.items.map((candidate) => candidate.grams), [100, 30])
})

test('vision cannot promote a catalog-default portion to high confidence', () => {
  const result = applyVisionEvidence(
    analysis([item('pilav', 180)]),
    [{
      description: 'pilav',
      estimatedGrams: 180,
      identityConfidence: 0.94,
      portionConfidence: 0.48,
      portionBasis: 'catalog_default',
    }],
  )

  assertEquals(result.items[0].needsClarification, true)
  assertEquals(result.items[0].clarificationReason, 'portion')
  assertEquals(result.items[0].confidence, 0.48)
})

test('confident vision evidence cannot clear a flag the parser raised', () => {
  // A weak catalog alias (priority < 80) makes the parser flag identity. Vision
  // is confident about what is in the photo, but it never saw the catalog rows,
  // so it has no standing to decide which pilav row is right. Its confidence
  // may lower the score, never dismiss the question.
  const ambiguous = {
    ...item('pilav', 180),
    confidence: 0.72,
    needsClarification: true,
    clarificationReason: 'identity' as const,
  }

  const result = applyVisionEvidence(
    { normalizedInput: 'meal', items: [ambiguous], unmatchedText: [] },
    [{
      description: 'pilav',
      estimatedGrams: 180,
      identityConfidence: 0.97,
      portionConfidence: 0.95,
      portionBasis: 'visible_scale',
    }],
  )

  assertEquals(result.items[0].needsClarification, true)
  assertEquals(result.items[0].clarificationReason, 'identity')
  assertEquals(result.items[0].confidence, 0.72)
})

test('vision still raises a flag the parser did not', () => {
  const result = applyVisionEvidence(
    analysis([item('pilav', 180)]),
    [{
      description: 'pilav',
      estimatedGrams: 180,
      identityConfidence: 0.5,
      portionConfidence: 0.95,
      portionBasis: 'visible_scale',
    }],
  )

  assertEquals(result.items[0].needsClarification, true)
  assertEquals(result.items[0].clarificationReason, 'identity')
})

test('a confident item with confident vision evidence is left unflagged', () => {
  const result = applyVisionEvidence(
    analysis([item('pilav', 180)]),
    [{
      description: 'pilav',
      estimatedGrams: 180,
      identityConfidence: 0.95,
      portionConfidence: 0.9,
      portionBasis: 'visible_scale',
    }],
  )

  assertEquals(result.items[0].needsClarification, false)
  assertEquals(result.items[0].clarificationReason, undefined)
})

test('vision evidence attaches by name, not by array position', () => {
  // Vision saw two foods but only the second one parsed into an item. The
  // surviving item must carry ITS OWN low confidence, not the first food's.
  const result = applyVisionEvidence(
    analysis([item('ayran', 200)]),
    [{
      description: 'menemen',
      estimatedGrams: 250,
      identityConfidence: 0.95,
      portionConfidence: 0.9,
      portionBasis: 'visible_scale',
    }, {
      description: 'ayran',
      estimatedGrams: 200,
      identityConfidence: 0.5,
      portionConfidence: 0.5,
      portionBasis: 'catalog_default',
    }],
  )

  assertEquals(result.items[0].confidence, 0.5)
  assertEquals(result.items[0].needsClarification, true)
  assertEquals(result.items[0].clarificationReason, 'identity')
})

test('unmatched tokens survive when only a sibling item resolves', () => {
  const grounded = { ...item('menemen', 250), sourceText: 'menemen' }
  assertEquals(remainingUnmatchedText(['menemen', 'ayran'], [grounded]), ['ayran'])
  assertEquals(remainingUnmatchedText(['ayran'], []), ['ayran'])
})

function analysis(items: AnalysisItem[]): DeterministicAnalysis {
  return { normalizedInput: 'meal', items, unmatchedText: [] }
}

function item(foodId: string, grams: number): AnalysisItem {
  return {
    itemKey: 'item-1',
    sourceText: foodId,
    foodId,
    canonicalName: foodId,
    portionLabel: `${grams} g`,
    grams,
    quantity: 1,
    confidence: 0.9,
    matchMethod: 'exact',
    needsClarification: false,
    nutritionPer100g: { calories: 100, protein: 1, carbs: 1, fat: 1 },
  }
}

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, received ${JSON.stringify(actual)}`)
  }
}
