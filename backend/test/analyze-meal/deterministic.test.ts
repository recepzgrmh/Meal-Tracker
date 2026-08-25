import { test } from 'vitest'
import {
  aliasLookupKeys,
  analyzeDeterministically,
  type CatalogFood,
  normalizeTurkishInput,
} from '../../src/routes/analyze-meal/deterministic.ts'

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

test('normalizes Turkish casing, punctuation, and whitespace', () => {
  assertEquals(normalizeTurkishInput('  İKİ  Yumurta,\nPEYNİR! '), 'iki yumurta peynir')
})

test('extracts explicit counts and fractions without hallucinating foods', () => {
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

test('prefers the longest alias and flags generic identity ambiguity', () => {
  const result = analyzeDeterministically('30 gram beyaz peynir', catalog)

  assertEquals(result.items.length, 1)
  assertEquals(result.items[0].foodId, 'cheese')
  assertEquals(result.items[0].grams, 30)
  assertEquals(result.items[0].needsClarification, false)

  const generic = analyzeDeterministically('peynir', catalog)
  assertEquals(generic.items[0].clarificationReason, 'identity')
  assertEquals(generic.items[0].confidence, 0.72)
})

test('returns unknown tokens instead of inventing a catalog match', () => {
  const result = analyzeDeterministically('bir tabak menemen ve avokado', catalog)

  assertEquals(result.items, [])
  assertEquals(result.unmatchedText, ['menemen', 'avokado'])
})

test('does not leak a neighboring item quantity across matches', () => {
  const result = analyzeDeterministically('2 yumurta, 30 g beyaz peynir', catalog)
  assertEquals(result.items.map((item) => item.grams), [100, 30])
})

test('preserves the half symbol before Unicode normalization', () => {
  const result = analyzeDeterministically('½ simit', catalog)
  assertEquals(result.items[0].grams, 50)
})

test('matches Turkish case suffixes and consonant softening', () => {
  const result = analyzeDeterministically('2 yumurtayı ve simidi yedim', catalog)
  assertEquals(result.items.map((item) => item.foodId), ['egg', 'simit'])
  assertEquals(result.items[0].grams, 100)
})

test('understands English counts with localized aliases', () => {
  const englishCatalog = catalog.map((food) => ({
    ...food,
    aliases: food.id === 'egg' ? [{ value: 'boiled egg', priority: 100 }] : [],
  }))
  const result = analyzeDeterministically('two boiled eggs', englishCatalog)
  assertEquals(result.items.length, 1)
  assertEquals(result.items[0].grams, 100)
})

test('resolves quantities written after an inflected food name', () => {
  const egg = analyzeDeterministically('yumurta 2 adet', catalog)
  const cheese = analyzeDeterministically('beyaz peynirden 20 g', catalog)
  assertEquals(egg.items[0].grams, 100)
  assertEquals(cheese.items[0].grams, 20)
})

test('resolves Turkish genitive halves and one-and-a-half portions', () => {
  const half = analyzeDeterministically('simitin yarısı', catalog)
  const oneAndHalf = analyzeDeterministically('bir buçuk simit', catalog)
  assertEquals(half.items[0].grams, 50)
  assertEquals(oneAndHalf.items[0].grams, 150)
})

test('resolves catalog household measures without leaking unit tokens', () => {
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

test('alias lookup keys recover every alias the matcher can still resolve', () => {
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

test('alias lookup keys stay bounded and cover multi-word aliases', () => {
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

test('English input is not lowercased with Turkish rules', () => {
  // Phones capitalise the first letter of a sentence, so "Ice cream" was the
  // normal English case — and tr-TR lowercasing turned its I into a dotless ı,
  // which matches no alias. The failure was silent: a no-match, not an error.
  const englishCatalog: CatalogFood[] = [{
    id: 'ice-cream',
    canonicalName: 'Ice Cream, Vanilla',
    nutritionPer100g: { calories: 207, protein: 3.5, carbs: 23.6, fat: 11 },
    aliases: [{ value: 'ice cream', priority: 100 }],
    portions: [{ label: '1 scoop', grams: 66, isDefault: true }],
  }]

  for (const input of ['Ice cream', 'ICE CREAM', 'ice cream']) {
    const result = analyzeDeterministically(input, englishCatalog, 'en-US')
    assertEquals(result.items.map((item) => item.foodId), ['ice-cream'])
  }

  assertEquals(normalizeTurkishInput('I had Italian sausage', 'en-US'), 'i had italian sausage')
})

test('Turkish keeps its own casing rules and stays the default', () => {
  // Turkish must still fold I to the dotless ı and İ to i — "Izgara" is
  // "ızgara", not "izgara".
  assertEquals(normalizeTurkishInput('Izgara Köfte'), 'ızgara köfte')
  assertEquals(normalizeTurkishInput('İki YUMURTA'), 'iki yumurta')
  // The default is tr-TR, so every existing caller keeps its behaviour.
  assertEquals(normalizeTurkishInput('Izgara'), normalizeTurkishInput('Izgara', 'tr-TR'))
})

test('an alias is folded the same way as the input that must reach it', () => {
  // Input and aliases go through one function; folding them differently would
  // reintroduce the same silent miss from the other side.
  const catalogWithCapitalAlias: CatalogFood[] = [{
    id: 'italian-sausage',
    canonicalName: 'Italian Sausage',
    nutritionPer100g: { calories: 344, protein: 19, carbs: 2.5, fat: 29 },
    aliases: [{ value: 'Italian Sausage', priority: 100 }],
    portions: [{ label: '1 link', grams: 80, isDefault: true }],
  }]

  const result = analyzeDeterministically('Italian sausage', catalogWithCapitalAlias, 'en-US')
  assertEquals(result.items.map((item) => item.foodId), ['italian-sausage'])
})

// The catalog rows behind the "kremalı tavuklu makarna" regression, as they
// actually exist: an Open Food Facts brand row whose name is one word, and the
// English pasta row that commit 45f6700 gave a Turkish alias. Neither carries a
// turkey_relevance_score, so the retrieval floor added for this exact bug never
// applied to them — the defect had to be fixed in the matcher instead.
const compoundDishCatalog: CatalogFood[] = [
  {
    id: 'food-kremal',
    canonicalName: 'Kremal',
    nutritionPer100g: { calories: 485, protein: 3, carbs: 40, fat: 34 },
    aliases: [{ value: 'kremal', priority: 90 }],
    portions: [{ label: '100 g', grams: 100, isDefault: true }],
  },
  {
    id: 'food-pasta-en',
    canonicalName: 'Turkey Pasta',
    nutritionPer100g: { calories: 133, protein: 8, carbs: 16, fat: 4 },
    aliases: [{ value: 'tavuklu makarna', priority: 85 }],
    portions: [{ label: '1 porsiyon', grams: 279, isDefault: true }],
  },
]

test('a derivational -lI adjective is not stemmed into a one-word brand row', () => {
  // "kremalı" is "with cream", not a case form of a noun "kremal". Stripping the
  // bare vowel used to invent that noun and hand it the brand row.
  assertEquals(aliasLookupKeys(['kremalı']).includes('kremal'), false)
  assertEquals(aliasLookupKeys(['kremalı']).includes('kremalı'), true)

  const result = analyzeDeterministically('kremalı tavuklu makarna', compoundDishCatalog)
  assertEquals(result.items.map((item) => item.foodId), ['food-pasta-en'])
  assertEquals(result.items.map((item) => item.canonicalName).includes('Kremal'), false)
})

test('the -lI guard costs the bare-vowel case of an l-final noun', () => {
  // Turkish cannot tell these apart: "balı" is bal + accusative, "kremalı" is
  // krema + the adjective suffix, and both are an l-final string plus one vowel.
  // Refusing the pair is therefore the only rule that can guarantee the invented
  // stem never matches, and this test states the price rather than hiding it.
  //
  // The price is bounded. "bal", "baldan" and "ballar" all still resolve here,
  // and "balı" is not lost — it becomes leftover text, which is precisely the
  // signal that sends the sentence to the model and then to hybrid search. It
  // costs a provider call on that phrasing, not a match.
  const bal: CatalogFood[] = [{
    id: 'honey',
    canonicalName: 'Bal',
    nutritionPer100g: { calories: 304, protein: 0.3, carbs: 82, fat: 0 },
    aliases: [{ value: 'bal', priority: 100 }],
    portions: [{ label: '1 tatlı kaşığı', grams: 15, isDefault: true }],
  }]
  assertEquals(analyzeDeterministically('bal', bal).items.map((i) => i.foodId), ['honey'])
  assertEquals(analyzeDeterministically('baldan 20 g', bal).items.map((i) => i.foodId), ['honey'])

  const inflected = analyzeDeterministically('balı yedim', bal)
  assertEquals(inflected.items, [])
  assertEquals(inflected.unmatchedText, ['balı', 'yedim'])
})

test('one dish cut into touching pieces is reported as fragmented, not explained', () => {
  // Both fragments are catalog rows and together they leave no leftover text, so
  // the leftover test alone would call this understood and skip the model.
  const fragmented = analyzeDeterministically(
    'kremalı tavuklu makarna',
    [...compoundDishCatalog, {
      id: 'food-krema',
      canonicalName: 'Krema',
      nutritionPer100g: { calories: 340, protein: 2, carbs: 3, fat: 36 },
      aliases: [{ value: 'kremalı', priority: 90 }],
      portions: [{ label: '100 g', grams: 100, isDefault: true }],
    }],
  )
  assertEquals(fragmented.items.length, 2)
  assertEquals(fragmented.unmatchedText, [])
  assertEquals(fragmented.fragmentedPhrase, true)
})

test('a genuine list separated by counts and "ve" is not fragmented', () => {
  const result = analyzeDeterministically('2 yumurta, biraz beyaz peynir ve yarım simit', catalog)
  assertEquals(result.items.length, 3)
  assertEquals(result.fragmentedPhrase, false)
})

test('a higher-priority alias wins over an equally long lower-priority one', () => {
  // The matcher used to order equal-length matches by nothing at all, so the
  // winner was whichever row the catalog query happened to return first. That
  // is how a machine-generated alias on a branded row could beat the curated
  // Turkish food for the same word — and, being priority 85, report confidence
  // 0.98 and ask no clarification question.
  const competing: CatalogFood[] = [
    {
      id: 'branded',
      canonicalName: 'Imitation butter flavor popcorn seasoning salt',
      nutritionPer100g: { calories: 0, protein: 0, carbs: 0, fat: 0 },
      aliases: [{ value: 'badem', priority: 85 }],
      portions: [{ label: '1 porsiyon', grams: 10, isDefault: true }],
    },
    {
      id: 'curated',
      canonicalName: 'Badem, iç, kavrulmuş',
      nutritionPer100g: { calories: 600, protein: 21, carbs: 22, fat: 50 },
      aliases: [{ value: 'badem', priority: 100 }],
      portions: [{ label: '1 porsiyon', grams: 30, isDefault: true }],
    },
  ]

  assertEquals(analyzeDeterministically('badem', competing).items[0].foodId, 'curated')
  // Same catalog, opposite order: the answer must not depend on row order.
  assertEquals(
    analyzeDeterministically('badem', [...competing].reverse()).items[0].foodId,
    'curated',
  )
})

test('an equal-priority tie resolves the same way every run', () => {
  // Two legitimate curated foods can share a word. Which one wins is a product
  // question the clarification sheet answers, but it must at least be stable:
  // an eval whose score moves because Postgres returned rows in a different
  // order is measuring nothing.
  const tied: CatalogFood[] = [
    {
      id: 'bbb',
      canonicalName: 'Yoğurt, kaymaklı',
      nutritionPer100g: { calories: 77, protein: 3, carbs: 4, fat: 6 },
      aliases: [{ value: 'yoğurt', priority: 60 }],
      portions: [{ label: '1 porsiyon', grams: 100, isDefault: true }],
    },
    {
      id: 'aaa',
      canonicalName: 'Yoğurt, homojenize, yarım yağlı',
      nutritionPer100g: { calories: 49, protein: 3.5, carbs: 5, fat: 2 },
      aliases: [{ value: 'yoğurt', priority: 60 }],
      portions: [{ label: '1 porsiyon', grams: 100, isDefault: true }],
    },
  ]

  const forward = analyzeDeterministically('yoğurt', tied).items[0].foodId
  const reversed = analyzeDeterministically('yoğurt', [...tied].reverse()).items[0].foodId
  assertEquals(forward, reversed)
  // And it still asks, because priority 60 is below the ambiguity threshold.
  assertEquals(analyzeDeterministically('yoğurt', tied).items[0].clarificationReason, 'identity')
})
