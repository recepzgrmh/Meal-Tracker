import { test } from 'vitest'
import { assertEquals, assertRejects } from '../assert.ts'
import {
  buildFoodEmbeddingDocument,
  createEmbeddings,
  EMBEDDING_DIMENSIONS,
  sha256,
} from '../../src/shared/embeddings.ts'

test('embedding document is normalized, localized, and deterministic', () => {
  const food = {
    id: 'food-1',
    canonical_name: '  Beyaz   PEYNİR ',
    locale: 'tr-TR',
    embedding_model: null,
    embedding_source_hash: null,
  }
  const first = buildFoodEmbeddingDocument(food, [
    { food_id: 'food-1', alias: 'Peynir', locale: 'tr-TR' },
    { food_id: 'food-1', alias: 'White Cheese', locale: 'en-US' },
  ])
  const second = buildFoodEmbeddingDocument(food, [
    { food_id: 'food-1', alias: 'White Cheese', locale: 'en-US' },
    { food_id: 'food-1', alias: 'Peynir', locale: 'tr-TR' },
  ])
  assertEquals(first, second)
  assertEquals(first, 'locale:tr-TR\nfood:beyaz peynir\naliases:en-US:white cheese|tr-TR:peynir')
})

test('sha256 is stable', async () => {
  assertEquals(await sha256('meal-clarity'), await sha256('meal-clarity'))
})

test('embedding provider retries 429 then preserves response order', async () => {
  let calls = 0
  const vectorA = Array(EMBEDDING_DIMENSIONS).fill(0.1)
  const vectorB = Array(EMBEDDING_DIMENSIONS).fill(0.2)
  const result = await createEmbeddings(['a', 'b'], {
    apiKey: 'test-key',
    maxAttempts: 2,
    fetcher: (() => {
      calls += 1
      if (calls === 1) return Promise.resolve(new Response('{}', { status: 429 }))
      return Promise.resolve(Response.json({
        data: [
          { index: 1, embedding: vectorB },
          { index: 0, embedding: vectorA },
        ],
        usage: { prompt_tokens: 4 },
      }))
    }) as typeof fetch,
  })
  assertEquals(result.vectors, [vectorA, vectorB])
  assertEquals(result.promptTokens, 4)
  assertEquals(result.attempts, 2)
})

test('embedding provider refuses malformed vectors', async () => {
  await assertRejects(
    () =>
      createEmbeddings(['a'], {
        apiKey: 'test-key',
        maxAttempts: 1,
        fetcher: (() =>
          Promise.resolve(Response.json({
            data: [{ index: 0, embedding: [0.1] }],
          }))) as typeof fetch,
      }),
    Error,
    // Bound to the constant rather than a literal: the dimension is a storage
    // decision that has already changed once, and the behaviour under test is
    // "rejects a vector of the wrong width", not "is 1536 wide".
    `${EMBEDDING_DIMENSIONS} dimensions`,
  )
})
