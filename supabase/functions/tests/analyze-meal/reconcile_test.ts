import type { DeterministicAnalysis } from '../../analyze-meal/deterministic.ts'
import { reconcileModalities } from '../../analyze-meal/reconcile.ts'
import type { AnalysisItem } from '../../_shared/contracts.ts'

Deno.test('explicit text wins when vision detects the same catalog food', () => {
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

Deno.test('vision contributes foods missing from explicit text', () => {
  const result = reconcileModalities(
    analysis([item('egg', 100)]),
    analysis([item('egg', 120), item('cheese', 30)]),
  )

  assertEquals(result.items.map((candidate) => candidate.foodId), ['egg', 'cheese'])
  assertEquals(result.items.map((candidate) => candidate.grams), [100, 30])
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
