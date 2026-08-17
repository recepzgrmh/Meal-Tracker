import { CommitRequestValidationError, parseCommitMealRequest } from '../../commit-meal/request.ts'

const valid = {
  analysisRunId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
  commitRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f67',
  mealId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f68',
  name: 'Kahvaltı',
  occurredAt: '2026-08-17T08:30:00+03:00',
  items: [{
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
})

Deno.test('rejects forged nutrition and unknown fields', () => {
  expectValidation(() =>
    parseCommitMealRequest({
      ...valid,
      items: [{ ...valid.items[0], calories: 1 }],
    })
  )
})

Deno.test('rejects duplicate keys and invalid grams', () => {
  expectValidation(() =>
    parseCommitMealRequest({ ...valid, items: [...valid.items, valid.items[0]] })
  )
  expectValidation(() =>
    parseCommitMealRequest({ ...valid, items: [{ ...valid.items[0], grams: -1 }] })
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
