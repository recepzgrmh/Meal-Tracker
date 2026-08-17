import {
  analyzeDeterministically,
  type CatalogFood,
  normalizeTurkishInput,
} from '../../analyze-meal/deterministic.ts'

const catalog: CatalogFood[] = [
  {
    id: 'egg',
    canonicalName: 'Tavuk Yumurtası, Haşlanmış',
    nutritionPer100g: { calories: 155, protein: 12.6, carbs: 1.1, fat: 10.6 },
    aliases: [
      { value: 'haşlanmış yumurta', priority: 100 },
      { value: 'yumurta', priority: 100 },
    ],
    portions: [{ label: '1 adet', grams: 50, isDefault: true }],
  },
  {
    id: 'cheese',
    canonicalName: 'Beyaz Peynir, Tam Yağlı',
    nutritionPer100g: { calories: 289, protein: 16, carbs: 2.5, fat: 24 },
    aliases: [
      { value: 'beyaz peynir', priority: 100 },
      { value: 'peynir', priority: 30 },
    ],
    portions: [
      { label: 'az', grams: 15, isDefault: false },
      { label: '1 porsiyon', grams: 30, isDefault: true },
    ],
  },
  {
    id: 'simit',
    canonicalName: 'Simit',
    nutritionPer100g: { calories: 340, protein: 10, carbs: 57, fat: 8 },
    aliases: [{ value: 'simit', priority: 100 }],
    portions: [{ label: '1 adet', grams: 100, isDefault: true }],
  },
]

Deno.test('normalizes Turkish casing, punctuation, and whitespace', () => {
  assertEquals(normalizeTurkishInput('  İKİ  Yumurta,\nPEYNİR! '), 'iki yumurta peynir')
})

Deno.test('extracts explicit counts and fractions without hallucinating foods', () => {
  const result = analyzeDeterministically(
    '2 yumurta, biraz beyaz peynir ve yarım simit',
    catalog,
  )

  assertEquals(result.items.map((item) => item.foodId), ['egg', 'cheese', 'simit'])
  assertEquals(result.items.map((item) => item.grams), [100, 15, 50])
  assertEquals(result.items.map((item) => item.portionLabel), ['2 adet', 'az', '½ adet'])
  assertEquals(result.items[0].needsClarification, false)
  assertEquals(result.items[1].clarificationReason, 'portion')
  assertEquals(result.unmatchedText, [])
})

Deno.test('prefers the longest alias and flags generic identity ambiguity', () => {
  const result = analyzeDeterministically('30 gram beyaz peynir', catalog)

  assertEquals(result.items.length, 1)
  assertEquals(result.items[0].foodId, 'cheese')
  assertEquals(result.items[0].grams, 30)
  assertEquals(result.items[0].needsClarification, false)

  const generic = analyzeDeterministically('peynir', catalog)
  assertEquals(generic.items[0].clarificationReason, 'identity')
  assertEquals(generic.items[0].confidence, 0.72)
})

Deno.test('returns unknown tokens instead of inventing a catalog match', () => {
  const result = analyzeDeterministically('bir tabak menemen ve avokado', catalog)

  assertEquals(result.items, [])
  assertEquals(result.unmatchedText, ['tabak', 'menemen', 'avokado'])
})

Deno.test('does not leak a neighboring item quantity across matches', () => {
  const result = analyzeDeterministically('2 yumurta, 30 g beyaz peynir', catalog)
  assertEquals(result.items.map((item) => item.grams), [100, 30])
})

Deno.test('preserves the half symbol before Unicode normalization', () => {
  const result = analyzeDeterministically('½ simit', catalog)
  assertEquals(result.items[0].grams, 50)
})

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, received ${JSON.stringify(actual)}`)
  }
}
