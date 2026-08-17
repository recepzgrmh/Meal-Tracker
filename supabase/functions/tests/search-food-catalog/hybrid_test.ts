import { assertEquals } from 'jsr:@std/assert@1'
import { filterGroundedRows, normalizeQuery } from '../../search-food-catalog/hybrid.ts'

Deno.test('normalizes Turkish and English query casing deterministically', () => {
  assertEquals(normalizeQuery('  BEYAZ   PEYNİR ', 'tr-TR'), 'beyaz peynir')
  assertEquals(normalizeQuery('  WHITE  Cheese ', 'en-US'), 'white cheese')
})

Deno.test('keeps lexical evidence and rejects weak vector-only candidates', () => {
  const rows = filterGroundedRows([
    { food_id: 'lexical', lexical_rank: 1, semantic_similarity: 0.1 },
    { food_id: 'strong-vector', lexical_rank: null, semantic_similarity: 0.72 },
    { food_id: 'weak-vector', lexical_rank: null, semantic_similarity: 0.2 },
  ])
  assertEquals(rows.map((row) => row.food_id), ['lexical', 'strong-vector'])
})
