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
  const food: ExtractedFood = {
    name: 'yumurta',
    nameEn: 'egg',
    quantity: 2,
    unit: 'adet',
    components: [],
  }
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
    nameEn: 'pasta with cheese and chicken',
    quantity: 1,
    unit: 'porsiyon',
    components: [
      { name: 'makarna', grams: 100 },
      { name: 'tavuk göğsü', grams: 80 },
      { name: 'kaşar peyniri', grams: 30 },
    ],
  }

  assertEquals(extractionPhrases(dish), [
    { matchPhrase: '100 g makarna', name: 'makarna', nameEn: null },
    { matchPhrase: '80 g tavuk göğsü', name: 'tavuk göğsü', nameEn: null },
    { matchPhrase: '30 g kaşar peyniri', name: 'kaşar peyniri', nameEn: null },
  ])
})

Deno.test('a plain food carries the amount for matching but the bare name for search', () => {
  const food: ExtractedFood = {
    name: 'yumurta',
    nameEn: 'egg',
    quantity: 2,
    unit: 'adet',
    components: [],
  }
  // The amount helps the portion resolver and hurts retrieval, so the two
  // consumers get different strings.
  assertEquals(extractionPhrases(food), [
    { matchPhrase: '2 adet yumurta', name: 'yumurta', nameEn: 'egg' },
  ])
})

Deno.test('a fragment match leaves the rest of the phrase unexplained', () => {
  // The real failure this guards: a single-word Open Food Facts brand row
  // ("Kremal", Romanian barcode, Turkey relevance 30) is an exact alias, so the
  // matcher claimed "kremalı" out of "kremalı tavuklu makarna" and reported
  // 0.98 confidence on a Romanian package. `resolveTextAnalysis` only accepts a
  // deterministic match when it explains the whole phrase, so what this asserts
  // is that a fragment match is *detectable* — non-empty items alongside
  // non-empty unmatchedText — and therefore routed to hybrid search instead.
  const junkCatalog: CatalogFood[] = [{
    id: 'food-kremal',
    canonicalName: 'Kremal',
    nutritionPer100g: { calories: 485, protein: 3, carbs: 40, fat: 34 },
    aliases: [{ value: 'kremal', priority: 100 }],
    portions: [{ label: '100 g', grams: 100, isDefault: true }],
  }]

  const analysis = analyzeDeterministically(
    '1 porsiyon kremalı tavuklu makarna',
    junkCatalog,
  )

  assertEquals(analysis.items.length, 1)
  assertEquals(analysis.items[0].foodId, 'food-kremal')
  // The tokens the brand row could not account for are exactly what makes this
  // a fragment rather than an answer.
  assertEquals(analysis.unmatchedText, ['tavuklu', 'makarna'])
})

Deno.test('a whole-phrase match is accepted as explained', () => {
  const analysis = analyzeDeterministically('2 adet yumurta', eggCatalog)
  assertEquals(analysis.items.length, 1)
  assertEquals(analysis.unmatchedText, [])
})

Deno.test('an English name is kept as a second retrieval handle', async () => {
  // ~14k catalog rows are USDA generic foods with English-only names, so the
  // right row for "kremalı tavuklu makarna" is unreachable from Turkish. The
  // English name is what gets it in front of the selector.
  const result = await extractFoodsFromText({
    ...baseOptions,
    input: 'kremalı tavuklu makarna',
    fetcher: (() =>
      Promise.resolve(providerResponse([
        foodPayload('kremalı tavuklu makarna', 1, 'porsiyon', 'pasta with cream sauce and chicken'),
      ]))) as typeof fetch,
  })

  assertEquals(result.foods[0].nameEn, 'pasta with cream sauce and chicken')
  assertEquals(extractionPhrases(result.foods[0])[0].nameEn, 'pasta with cream sauce and chicken')
})

Deno.test('a transliteration is not accepted as an English name', async () => {
  // Echoing the Turkish name back retrieves the same nothing, so it is dropped
  // rather than paid for as a second embedding and search.
  const result = await extractFoodsFromText({
    ...baseOptions,
    input: 'menemen',
    fetcher: (() =>
      Promise.resolve(providerResponse([
        foodPayload('menemen', null, null, 'Menemen'),
      ]))) as typeof fetch,
  })

  assertEquals(result.foods[0].nameEn, null)
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

function foodPayload(
  name: string,
  quantity: number | null,
  unit: string | null,
  nameEn: string | null = null,
) {
  return { name, nameEn, quantity, unit, components: [] }
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
