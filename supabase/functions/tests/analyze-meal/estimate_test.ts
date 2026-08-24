import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { EstimateRefusalError, estimateUnmatchedFoods } from '../../analyze-meal/estimate.ts'

const baseOptions = {
  apiKey: 'test',
  locale: 'tr-TR' as const,
  foods: ['ayran'],
  model: 'test-model',
}

Deno.test('estimator accepts a bounds-checked, Atwater-consistent estimate', async () => {
  const result = await estimateUnmatchedFoods({
    ...baseOptions,
    maxAttempts: 1,
    fetcher: (() =>
      Promise.resolve(providerResponse({
        estimates: [{
          sourceText: 'ayran',
          displayName: 'Ayran',
          estimatedGrams: 200,
          confidence: 0.45,
          // 4×1.7 + 4×2.9 + 9×1.8 = 34.6, within 30% of 38.
          caloriesPer100g: 38,
          proteinPer100g: 1.7,
          carbsPer100g: 2.9,
          fatPer100g: 1.8,
        }],
      }))) as typeof fetch,
  })

  assertEquals(result.estimates.length, 1)
  assertEquals(result.estimates[0].displayName, 'Ayran')
  assertEquals(result.estimates[0].nutritionPer100g.calories, 38)
  assertEquals(result.inputTokens, 10)
  assertEquals(result.attempts, 1)
})

Deno.test('estimator rejects Atwater-inconsistent macros', async () => {
  const result = await estimateUnmatchedFoods({
    ...baseOptions,
    maxAttempts: 1,
    fetcher: (() =>
      Promise.resolve(providerResponse({
        estimates: [{
          sourceText: 'ayran',
          displayName: 'Ayran',
          estimatedGrams: 200,
          confidence: 0.9,
          // 4×1 + 4×1 + 9×1 = 17 kcal, nowhere near the stated 500.
          caloriesPer100g: 500,
          proteinPer100g: 1,
          carbsPer100g: 1,
          fatPer100g: 1,
        }],
      }))) as typeof fetch,
  })

  assertEquals(result.estimates, [])
})

Deno.test('estimator drops texts outside the request and clamps grams', async () => {
  const result = await estimateUnmatchedFoods({
    ...baseOptions,
    foods: ['ayran', 'menemen'],
    maxAttempts: 1,
    fetcher: (() =>
      Promise.resolve(providerResponse({
        estimates: [{
          sourceText: 'baklava',
          displayName: 'Baklava',
          estimatedGrams: 100,
          confidence: 0.9,
          caloriesPer100g: 428,
          proteinPer100g: 6,
          carbsPer100g: 60,
          fatPer100g: 18,
        }, {
          sourceText: 'ayran',
          displayName: 'Ayran',
          estimatedGrams: 5000,
          confidence: 0.4,
          caloriesPer100g: 38,
          proteinPer100g: 1.7,
          carbsPer100g: 2.9,
          fatPer100g: 1.8,
        }],
      }))) as typeof fetch,
  })

  assertEquals(result.estimates.length, 1)
  assertEquals(result.estimates[0].sourceText, 'ayran')
  assertEquals(result.estimates[0].estimatedGrams, 3000)
})

Deno.test('estimator surfaces model refusal without retrying', async () => {
  let calls = 0
  await assertRejects(
    () =>
      estimateUnmatchedFoods({
        ...baseOptions,
        maxAttempts: 3,
        fetcher: (() => {
          calls += 1
          return Promise.resolve(Response.json({
            output: [{ content: [{ type: 'refusal', refusal: 'cannot comply' }] }],
          }))
        }) as typeof fetch,
      }),
    EstimateRefusalError,
  )
  assertEquals(calls, 1)
})

function providerResponse(value: unknown): Response {
  return Response.json({
    output: [{ content: [{ type: 'output_text', text: JSON.stringify(value) }] }],
    usage: { input_tokens: 10, output_tokens: 5 },
  })
}
