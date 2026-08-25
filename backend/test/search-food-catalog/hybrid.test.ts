import { test } from 'vitest'
import { assertEquals } from '../assert.ts'
import { filterGroundedRows, normalizeQuery } from '../../src/routes/search-food-catalog/hybrid.ts'

test('normalizes Turkish and English query casing deterministically', () => {
  assertEquals(normalizeQuery('  BEYAZ   PEYNİR ', 'tr-TR'), 'beyaz peynir')
  assertEquals(normalizeQuery('  WHITE  Cheese ', 'en-US'), 'white cheese')
})

test('keeps lexical evidence and rejects weak vector-only candidates', () => {
  const rows = filterGroundedRows([
    { food_id: 'lexical', lexical_rank: 1, semantic_similarity: 0.1 },
    { food_id: 'strong-vector', lexical_rank: null, semantic_similarity: 0.72 },
    // A vector index always returns its nearest neighbours, so a middling score
    // is what an unrelated word looks like — not what a match looks like.
    { food_id: 'middling-vector', lexical_rank: null, semantic_similarity: 0.45 },
    { food_id: 'weak-vector', lexical_rank: null, semantic_similarity: 0.2 },
  ])
  assertEquals(rows.map((row) => row.food_id), ['lexical', 'strong-vector'])
})
