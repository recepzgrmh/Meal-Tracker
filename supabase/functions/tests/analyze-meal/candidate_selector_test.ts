import { assertEquals, assertRejects, assertStringIncludes } from 'jsr:@std/assert@1'
import {
  providerErrorDetail,
  ProviderRefusalError,
  type RetrievalCandidate,
  selectCatalogCandidates,
} from '../../analyze-meal/candidate-selector.ts'

const candidate: RetrievalCandidate = {
  foodId: '10000000-0000-0000-0000-000000000002',
  canonicalName: 'Beyaz Peynir, Tam Yağlı',
  matchedAlias: 'beyaz peynir',
  score: 0.8,
  defaultGrams: 30,
  defaultPortionLabel: '1 porsiyon',
  nutritionPer100g: { calories: 289, protein: 16, carbs: 2.5, fat: 24 },
}

Deno.test('selector retries 429 and accepts only allow-listed candidate IDs', async () => {
  let calls = 0
  const result = await selectCatalogCandidates({
    apiKey: 'test',
    locale: 'tr-TR',
    input: 'beyaz peynr',
    model: 'test-model',
    candidates: [candidate],
    maxAttempts: 2,
    fetcher: (() => {
      calls += 1
      if (calls === 1) return Promise.resolve(new Response('{}', { status: 429 }))
      return Promise.resolve(providerResponse({
        selections: [{
          candidateId: candidate.foodId,
          sourceText: 'beyaz peynr',
          estimatedGrams: 30,
          confidence: 0.91,
        }],
        noMatch: false,
      }))
    }) as typeof fetch,
  })
  assertEquals(result.selections.length, 1)
  assertEquals(result.attempts, 2)
})

Deno.test('selector drops IDs outside the server allow-list', async () => {
  const result = await selectCatalogCandidates({
    apiKey: 'test',
    locale: 'tr-TR',
    input: 'uydurma',
    model: 'test-model',
    candidates: [candidate],
    maxAttempts: 1,
    fetcher: (() =>
      Promise.resolve(providerResponse({
        selections: [{
          candidateId: '00000000-0000-0000-0000-000000000000',
          sourceText: 'uydurma',
          estimatedGrams: 50,
          confidence: 0.99,
        }],
        noMatch: false,
      }))) as typeof fetch,
  })
  assertEquals(result.selections, [])
  assertEquals(result.noMatch, true)
})

Deno.test('selector surfaces model refusal for deterministic fallback', async () => {
  await assertRejects(
    () =>
      selectCatalogCandidates({
        apiKey: 'test',
        locale: 'tr-TR',
        input: 'test',
        model: 'test-model',
        candidates: [candidate],
        maxAttempts: 1,
        fetcher: (() =>
          Promise.resolve(Response.json({
            output: [{ content: [{ type: 'refusal', refusal: 'cannot comply' }] }],
          }))) as typeof fetch,
      }),
    ProviderRefusalError,
  )
})

// A bare status told us nothing when the provider retired a parameter value:
// every rejection read as "failed with 400" until the body reached telemetry.
Deno.test('a rejected request carries the provider explanation', async () => {
  const error = await assertRejects(() =>
    selectCatalogCandidates({
      apiKey: 'test',
      locale: 'tr-TR',
      input: 'beyaz peynir',
      candidates: [candidate],
      model: 'test-model',
      maxAttempts: 1,
      fetcher: (() =>
        Promise.resolve(
          Response.json({
            error: { message: "Unsupported value: 'minimal' is not supported with this model." },
          }, { status: 400 }),
        )) as typeof fetch,
    })
  )
  assertStringIncludes((error as Error).message, '400')
  assertStringIncludes((error as Error).message, 'Unsupported value')
})

Deno.test('provider error detail prefers the message and stays bounded', () => {
  assertEquals(providerErrorDetail(''), '')
  assertEquals(
    providerErrorDetail(JSON.stringify({ error: { message: 'model_not_found' } })),
    'model_not_found',
  )
  // Non-JSON gateway bodies still help once collapsed and truncated.
  assertEquals(providerErrorDetail('<html>\n  bad gateway\n</html>'), '<html> bad gateway </html>')
  assertEquals(providerErrorDetail('x'.repeat(400)).length, 300)
})

function providerResponse(value: unknown): Response {
  return Response.json({
    output: [{ content: [{ type: 'output_text', text: JSON.stringify(value) }] }],
    usage: { input_tokens: 10, output_tokens: 5 },
  })
}
