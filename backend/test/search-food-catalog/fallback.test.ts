import { expect, test } from 'vitest'
import { hybridSearch } from '../../src/routes/search-food-catalog/hybrid.ts'

/**
 * The semantic arm degrading to lexical used to be a bare `catch {}`. Search
 * kept returning rows, so nothing looked broken — the results just quietly got
 * worse, and an expired key or a dimension mismatch after a catalog migration
 * could sit there indefinitely. These pin that the degradation is now named.
 */

/**
 * Supabase's builder chains a different set of methods per call site, so the
 * stub answers any method by returning itself and resolves to an empty result
 * when awaited. Only the two things under test are asserted explicitly.
 */
function chainable(): any {
  const target: any = function () {}
  return new Proxy(target, {
    get(_t, prop) {
      if (prop === 'then') {
        return (resolve: (v: unknown) => void) =>
          resolve({ data: [], count: 0, error: null })
      }
      return () => chainable()
    },
    apply() {
      return chainable()
    },
  })
}

function fakeClients() {
  const logs: string[] = []
  const originalError = console.error
  console.error = (line: string) => logs.push(String(line))

  const userClient = {
    rpc: async (_name: string, args: Record<string, unknown>) => {
      // The lexical path is the one that runs with no embedding.
      expect(args.p_query_embedding).toBeNull()
      return { data: [{ food_id: 'f1', canonical_name: 'Beyaz Peynir' }], error: null }
    },
  }
  const adminClient = chainable()
  return { userClient, adminClient, logs, restore: () => (console.error = originalError) }
}

test('a failing embedding call is reported, not swallowed', async () => {
  const { userClient, adminClient, logs, restore } = fakeClients()
  try {
    const result = await hybridSearch(
      userClient as never,
      adminClient as never,
      {
        query: 'beyaz peynir',
        locale: 'tr-TR',
        limit: 5,
        // No network: createEmbeddings is given a fetcher-less key and fails.
        openAiApiKey: '',
      },
    )

    expect(result.fallback).toBe(true)
    expect(result.fallbackReason).toBeTruthy()
    expect(result.rows).toHaveLength(1)

    const logged = logs.join('\n')
    expect(logged).toContain('catalog_semantic_fallback')
    expect(logged).toContain(result.fallbackReason as string)
  } finally {
    restore()
  }
})

test('the log carries no query text or key material', async () => {
  const { userClient, adminClient, logs, restore } = fakeClients()
  try {
    await hybridSearch(userClient as never, adminClient as never, {
      query: 'çok özel bir arama',
      locale: 'tr-TR',
      limit: 5,
      openAiApiKey: 'sk-should-never-appear',
    })

    const logged = logs.join('\n')
    expect(logged).not.toContain('sk-should-never-appear')
    expect(logged).not.toContain('çok özel bir arama')
  } finally {
    restore()
  }
})
