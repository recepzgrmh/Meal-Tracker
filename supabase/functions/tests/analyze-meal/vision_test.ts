import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import {
  extractVisionWithTextFallback,
  requestVisionExtraction,
  VisionProviderError,
  VisionRefusalError,
} from '../../analyze-meal/vision.ts'

const baseOptions = {
  apiKey: 'test',
  image: 'data:image/jpeg;base64,dGVzdA==',
  locale: 'tr-TR' as const,
  userText: 'iki yumurta',
  model: 'test-model',
}

Deno.test('vision retries 429 and records the successful attempt', async () => {
  let calls = 0
  const result = await requestVisionExtraction({
    ...baseOptions,
    maxAttempts: 2,
    fetcher: (() => {
      calls += 1
      if (calls === 1) return Promise.resolve(new Response('{}', { status: 429 }))
      return Promise.resolve(providerResponse())
    }) as typeof fetch,
  })

  assertEquals(calls, 2)
  assertEquals(result.attempts, 2)
  assertEquals(result.foods[0].description, 'yumurta')
  assertEquals(result.foods[0].portionConfidence, 0.62)
  assertEquals(result.inputTokens, 25)
})

Deno.test('vision retries timeout and surfaces a typed timeout failure', async () => {
  let calls = 0
  await assertRejects(
    () =>
      requestVisionExtraction({
        ...baseOptions,
        maxAttempts: 2,
        fetcher: (() => {
          calls += 1
          return Promise.reject(new DOMException('aborted', 'AbortError'))
        }) as typeof fetch,
      }),
    VisionProviderError,
    'timed out',
  )
  assertEquals(calls, 2)
})

Deno.test('vision refusal is not retried', async () => {
  let calls = 0
  await assertRejects(
    () =>
      requestVisionExtraction({
        ...baseOptions,
        maxAttempts: 3,
        fetcher: (() => {
          calls += 1
          return Promise.resolve(Response.json({
            output: [{ content: [{ type: 'refusal', refusal: 'cannot comply' }] }],
          }))
        }) as typeof fetch,
      }),
    VisionRefusalError,
  )
  assertEquals(calls, 1)
})

Deno.test('vision success with zero foods is not retried and is not a provider failure', async () => {
  let calls = 0
  const extractor = () =>
    requestVisionExtraction({
      ...baseOptions,
      userText: '',
      maxAttempts: 3,
      fetcher: (() => {
        calls += 1
        return Promise.resolve(emptyFoodsResponse())
      }) as typeof fetch,
    })

  // Photo-only input (no user text) must not throw either: an empty answer
  // flows to no-match handling instead of a retryable provider failure.
  const attempt = await extractVisionWithTextFallback('', extractor)
  assertEquals(calls, 1)
  assertEquals(attempt, { extraction: null, fallbackReason: 'no_food_detected' })
})

Deno.test('mixed input safely falls back to text when vision fails', async () => {
  const result = await extractVisionWithTextFallback(
    'two eggs',
    () => Promise.reject(new VisionProviderError('limited', 'rate_limit', 429)),
  )
  assertEquals(result, { extraction: null, fallbackReason: 'rate_limit' })
})

Deno.test('photo-only input preserves provider failure for retryable API response', async () => {
  await assertRejects(
    () =>
      extractVisionWithTextFallback(
        ' ',
        () => Promise.reject(new VisionProviderError('limited', 'rate_limit', 429)),
      ),
    VisionProviderError,
  )
})

function emptyFoodsResponse(): Response {
  return Response.json({
    output: [{ content: [{ type: 'output_text', text: JSON.stringify({ foods: [] }) }] }],
    usage: { input_tokens: 25, output_tokens: 4 },
  })
}

function providerResponse(): Response {
  return Response.json({
    output: [{
      content: [{
        type: 'output_text',
        text: JSON.stringify({
          foods: [{
            description: 'yumurta',
            estimatedGrams: 100,
            identityConfidence: 0.9,
            portionConfidence: 0.62,
            portionBasis: 'catalog_default',
          }],
        }),
      }],
    }],
    usage: { input_tokens: 25, output_tokens: 12 },
  })
}
