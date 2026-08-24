import {
  aliasLookupKeys,
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
  assertEquals(result.unmatchedText, ['menemen', 'avokado'])
})

Deno.test('does not leak a neighboring item quantity across matches', () => {
  const result = analyzeDeterministically('2 yumurta, 30 g beyaz peynir', catalog)
  assertEquals(result.items.map((item) => item.grams), [100, 30])
})

Deno.test('preserves the half symbol before Unicode normalization', () => {
  const result = analyzeDeterministically('½ simit', catalog)
  assertEquals(result.items[0].grams, 50)
})

Deno.test('matches Turkish case suffixes and consonant softening', () => {
  const result = analyzeDeterministically('2 yumurtayı ve simidi yedim', catalog)
  assertEquals(result.items.map((item) => item.foodId), ['egg', 'simit'])
  assertEquals(result.items[0].grams, 100)
})

Deno.test('understands English counts with localized aliases', () => {
  const englishCatalog = catalog.map((food) => ({
    ...food,
    aliases: food.id === 'egg' ? [{ value: 'boiled egg', priority: 100 }] : [],
  }))
  const result = analyzeDeterministically('two boiled eggs', englishCatalog)
  assertEquals(result.items.length, 1)
  assertEquals(result.items[0].grams, 100)
})

Deno.test('resolves quantities written after an inflected food name', () => {
  const egg = analyzeDeterministically('yumurta 2 adet', catalog)
  const cheese = analyzeDeterministically('beyaz peynirden 20 g', catalog)
  assertEquals(egg.items[0].grams, 100)
  assertEquals(cheese.items[0].grams, 20)
})

Deno.test('resolves Turkish genitive halves and one-and-a-half portions', () => {
  const half = analyzeDeterministically('simitin yarısı', catalog)
  const oneAndHalf = analyzeDeterministically('bir buçuk simit', catalog)
  assertEquals(half.items[0].grams, 50)
  assertEquals(oneAndHalf.items[0].grams, 150)
})

Deno.test('resolves catalog household measures without leaking unit tokens', () => {
  const yogurtCatalog: CatalogFood[] = [{
    id: 'yogurt',
    canonicalName: 'Yoğurt',
    nutritionPer100g: { calories: 61, protein: 3.5, carbs: 4.7, fat: 3.3 },
    aliases: [{ value: 'yoğurt', priority: 100 }],
    portions: [{ label: '1 kase', grams: 200, isDefault: true }],
  }]

  const result = analyzeDeterministically('iki kase yoğurt', yogurtCatalog)
  assertEquals(result.items[0].grams, 400)
  assertEquals(result.items[0].portionLabel, '2 kase')
  assertEquals(result.items[0].needsClarification, false)
  assertEquals(result.unmatchedText, [])
})

Deno.test('alias lookup keys recover every alias the matcher can still resolve', () => {
  // The catalog is too large to load whole, so these keys are what scopes the
  // alias query. Anything the matcher would accept must appear here, otherwise
  // the food is never fetched and the match silently disappears.
  const cases: Array<[string, string]> = [
    ['2 yumurta', 'yumurta'],
    ['3 yumurtayı yedim', 'yumurta'],
    ['simitler', 'simit'],
    ['biraz beyaz peynir', 'beyaz peynir'],
    ['yoğurdu bitirdim', 'yoğurt'],
    ['kahvaltıda yumurtadan yedim', 'yumurta'],
    ['peynirler', 'peynir'],
  ]
  for (const [input, expected] of cases) {
    const keys = aliasLookupKeys([input])
    if (!keys.includes(expected)) {
      throw new Error(`"${input}" did not yield "${expected}": ${JSON.stringify(keys)}`)
    }
  }
})

Deno.test('alias lookup keys stay bounded and cover multi-word aliases', () => {
  // Only the final word of a multi-word alias carries an inflection, matching
  // inflectedAliasPattern. Turkish possessive forms such as "çorbası" are out of
  // scope for the matcher too, so they are deliberately not de-inflected here.
  const keys = aliasLookupKeys(['iki dilim beyaz peynirler ve yarım ekmek'])
  assertEquals(keys.includes('beyaz peynir'), true)
  assertEquals(keys.includes('ekmek'), true)
  assertEquals(keys.length <= 500, true)
  assertEquals(aliasLookupKeys(['']), [])
})

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, received ${JSON.stringify(actual)}`)
  }
}
