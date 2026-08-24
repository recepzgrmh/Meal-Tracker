import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import {
  type ExtractedFood,
  extractFoodsFromText,
  extractionPhrases,
  renderExtractedFood,
  TextExtractionError,
  TextExtractionRefusalError,
} from '../../analyze-meal/text-extraction.ts'
import { analyzeDeterministically, type CatalogFood } from '../../analyze-meal/deterministic.ts'

const baseOptions = {
  apiKey: 'test',
  locale: 'tr-TR' as const,
  input: '2 yumurta yedim kanka',
  model: 'test-model',
}

const eggCatalog: CatalogFood[] = [{
  id: 'food-egg',
  canonicalName: 'Yumurta',
  nutritionPer100g: { calories: 155, protein: 13, carbs: 1.1, fat: 11 },
  aliases: [{ value: 'yumurta', priority: 100 }],
  portions: [{ label: '1 adet', grams: 50, isDefault: true }],
}]

Deno.test('conversational filler never becomes a food', async () => {
  const result = await extractFoodsFromText({
    ...baseOptions,
    fetcher: (() =>
      Promise.resolve(providerResponse([foodPayload('yumurta', 2, 'adet')]))) as typeof fetch,
  })

  assertEquals(result.foods.length, 1)
  assertEquals(result.foods[0].name, 'yumurta')
  assertEquals(result.foods[0].quantity, 2)
  assertEquals(result.foods[0].unit, 'adet')
})

Deno.test('an extracted food re-enters the deterministic matcher with its amount', () => {
  const food: ExtractedFood = { name: 'yumurta', quantity: 2, unit: 'adet', components: [] }
  assertEquals(renderExtractedFood(food), '2 adet yumurta')

  // The whole point of rendering back into a clean phrase: the existing portion
  // resolver reads the amount, so "2 yumurta yedim kanka" ends as 2 x 50 g with
  // nothing left over.
  const analysis = analyzeDeterministically(renderExtractedFood(food), eggCatalog)
  assertEquals(analysis.items.length, 1)
  assertEquals(analysis.items[0].foodId, 'food-egg')
  assertEquals(analysis.items[0].grams, 100)
  assertEquals(analysis.items[0].quantity, 2)
  assertEquals(analysis.unmatchedText, [])
})

Deno.test('a stated amount is never invented when the sentence omits it', async () => {
  const result = await extractFoodsFromText({
    ...baseOptions,
    input: 'yumurta yedim',
    fetcher: (() =>
      Promise.resolve(providerResponse([foodPayload('yumurta', null, null)]))) as typeof fetch,
  })

  assertEquals(result.foods[0].quantity, null)
  assertEquals(result.foods[0].unit, null)
  assertEquals(renderExtractedFood(result.foods[0]), 'yumurta')
})

Deno.test('a composite dish is matched through its components, not its adjectives', () => {
  const dish: ExtractedFood = {
    name: 'kaşarlı tavuklu makarna',
    quantity: 1,
    unit: 'porsiyon',
    components: [
      { name: 'makarna', grams: 100 },
      { name: 'tavuk göğsü', grams: 80 },
      { name: 'kaşar peyniri', grams: 30 },
    ],
  }

  assertEquals(extractionPhrases(dish), [
    { matchPhrase: '100 g makarna', name: 'makarna' },
    { matchPhrase: '80 g tavuk göğsü', name: 'tavuk göğsü' },
    { matchPhrase: '30 g kaşar peyniri', name: 'kaşar peyniri' },
  ])
})

Deno.test('a plain food carries the amount for matching but the bare name for search', () => {
  const food: ExtractedFood = { name: 'yumurta', quantity: 2, unit: 'adet', components: [] }
  // The amount helps the portion resolver and hurts retrieval, so the two
  // consumers get different strings.
  assertEquals(extractionPhrases(food), [{ matchPhrase: '2 adet yumurta', name: 'yumurta' }])
})

Deno.test('a sentence with no food is an answer, not a failure', async () => {
  const result = await extractFoodsFromText({
    ...baseOptions,
    input: 'kanka naber',
    fetcher: (() => Promise.resolve(providerResponse([]))) as typeof fetch,
  })
  assertEquals(result.foods, [])
})

Deno.test('malformed and duplicate rows are dropped instead of reaching the catalog', async () => {
  const result = await extractFoodsFromText({
    ...baseOptions,
    fetcher: (() =>
      Promise.resolve(providerResponse([
        foodPayload('yumurta', 2, 'adet'),
        foodPayload('YUMURTA', 1, 'adet'),
        { name: '   ', quantity: 1, unit: 'adet', components: [] },
        { name: 'ekmek', quantity: -3, unit: 'dilim', components: [] },
      ]))) as typeof fetch,
  })

  assertEquals(result.foods.map((food) => food.name), ['yumurta', 'ekmek'])
  // A nonsense quantity is discarded rather than trusted.
  assertEquals(result.foods[1].quantity, null)
})

Deno.test('components with impossible grams are discarded', async () => {
  const result = await extractFoodsFromText({
    ...baseOptions,
    input: 'kaşarlı tavuklu makarna',
    fetcher: (() =>
      Promise.resolve(providerResponse([{
        name: 'kaşarlı tavuklu makarna',
        quantity: 1,
        unit: 'porsiyon',
        components: [
          { name: 'makarna', grams: 100 },
          { name: 'tavuk', grams: 99999 },
          { name: '', grams: 30 },
        ],
      }]))) as typeof fetch,
  })

  assertEquals(result.foods[0].components, [{ name: 'makarna', grams: 100 }])
})

Deno.test('text extraction retries 429 and records the successful attempt', async () => {
  let calls = 0
  const result = await extractFoodsFromText({
    ...baseOptions,
    maxAttempts: 2,
    fetcher: (() => {
      calls += 1
      if (calls === 1) return Promise.resolve(new Response('{}', { status: 429 }))
      return Promise.resolve(providerResponse([foodPayload('yumurta', 2, 'adet')]))
    }) as typeof fetch,
  })

  assertEquals(calls, 2)
  assertEquals(result.attempts, 2)
  assertEquals(result.inputTokens, 25)
})

Deno.test('text extraction refusal is not retried', async () => {
  let calls = 0
  await assertRejects(
    () =>
      extractFoodsFromText({
        ...baseOptions,
        maxAttempts: 3,
        fetcher: (() => {
          calls += 1
          return Promise.resolve(
            new Response(
              JSON.stringify({ output: [{ content: [{ type: 'refusal', refusal: 'no' }] }] }),
              { status: 200, headers: { 'content-type': 'application/json' } },
            ),
          )
        }) as typeof fetch,
      }),
    TextExtractionRefusalError,
  )
  assertEquals(calls, 1)
})

Deno.test('text extraction surfaces a typed timeout failure', async () => {
  let calls = 0
  await assertRejects(
    () =>
      extractFoodsFromText({
        ...baseOptions,
        maxAttempts: 2,
        fetcher: (() => {
          calls += 1
          return Promise.reject(new DOMException('aborted', 'AbortError'))
        }) as typeof fetch,
      }),
    TextExtractionError,
    'timed out',
  )
  assertEquals(calls, 2)
})

function foodPayload(name: string, quantity: number | null, unit: string | null) {
  return { name, quantity, unit, components: [] }
}

function providerResponse(foods: unknown[]): Response {
  return new Response(
    JSON.stringify({
      output: [{ content: [{ type: 'output_text', text: JSON.stringify({ foods }) }] }],
      usage: { input_tokens: 25, output_tokens: 12 },
    }),
    { status: 200, headers: { 'content-type': 'application/json' } },
  )
}
