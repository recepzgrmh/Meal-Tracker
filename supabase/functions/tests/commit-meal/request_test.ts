import { CommitRequestValidationError, parseCommitMealRequest } from '../../commit-meal/request.ts'

const valid = {
  analysisRunId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
  commitRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f67',
  mealId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f68',
  name: 'Kahvaltı',
  occurredAt: '2026-08-17T08:30:00+03:00',
  items: [{
    itemId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f69',
    itemKey: 'item-1',
    foodId: '10000000-0000-0000-0000-000000000001',
    sourceText: '2 yumurta',
    portionLabel: '2 adet',
    grams: 100,
  }],
}

Deno.test('accepts and normalizes a grounded commit request', () => {
  const request = parseCommitMealRequest(valid)
  assertEquals(request.occurredAt, '2026-08-17T05:30:00.000Z')
  assertEquals(request.items[0].grams, 100)
  assertEquals(request.items[0].itemId, valid.items[0].itemId)
})

Deno.test('rejects forged nutrition and unknown fields', () => {
  expectValidation(() =>
    parseCommitMealRequest({
      ...valid,
      items: [{ ...valid.items[0], calories: 1 }],
    })
  )
  // Estimate-backed items cannot smuggle nutrition either.
  expectValidation(() =>
    parseCommitMealRequest({
      ...valid,
      items: [{
        ...estimateItem(),
        caloriesPer100g: 900,
      }],
    })
  )
})

Deno.test('accepts an estimate-backed item and enforces food/estimate exclusivity', () => {
  const request = parseCommitMealRequest({ ...valid, items: [estimateItem()] })
  assertEquals(request.items[0].estimateId, '20000000-0000-0000-0000-000000000001')
  assertEquals(request.items[0].foodId, undefined)

  // Both ids, or neither, must be rejected: nutrition provenance is singular.
  expectValidation(() =>
    parseCommitMealRequest({
      ...valid,
      items: [{ ...valid.items[0], estimateId: '20000000-0000-0000-0000-000000000001' }],
    })
  )
  expectValidation(() =>
    parseCommitMealRequest({
      ...valid,
      items: [(() => {
        const { foodId: _foodId, ...rest } = valid.items[0]
        return rest
      })()],
    })
  )
})

function estimateItem(): Record<string, unknown> {
  const { foodId: _foodId, ...rest } = valid.items[0]
  return { ...rest, estimateId: '20000000-0000-0000-0000-000000000001' }
}

Deno.test('rejects duplicate keys and invalid grams', () => {
  expectValidation(() =>
    parseCommitMealRequest({ ...valid, items: [...valid.items, valid.items[0]] })
  )
  expectValidation(() =>
    parseCommitMealRequest({ ...valid, items: [{ ...valid.items[0], grams: -1 }] })
  )
  expectValidation(() =>
    parseCommitMealRequest({
      ...valid,
      items: [valid.items[0], { ...valid.items[0], itemKey: 'item-2' }],
    })
  )
})

function expectValidation(action: () => unknown): void {
  try {
    action()
  } catch (error) {
    if (error instanceof CommitRequestValidationError) return
    throw error
  }
  throw new Error('Expected CommitRequestValidationError')
}

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) throw new Error(`Expected ${expected}, received ${actual}`)
}
