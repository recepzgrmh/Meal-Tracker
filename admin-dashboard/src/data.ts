export type Severity = 'healthy' | 'info' | 'warning' | 'critical'

export type ReviewMeal = {
  id: string
  created: string
  title: string
  image: string
  foods: number
  confidence: number
  correction: string
  error: string
  model: string
  status: string
  user: string
  trace: string
  input: string
  diffs: Array<{ name: string; ai: string; final: string; note: string; severity: Severity }>
}

export const qualityErrors = [
  ['Portion overestimate', 29, 286, 'warning'],
  ['Food missing', 21, 207, 'info'],
  ['Wrong canonical match', 18, 177, 'critical'],
  ['Hidden sauce', 12, 118, 'critical'],
  ['Food hallucinated', 8, 79, 'info'],
  ['Mixed dish decomposition', 7, 69, 'warning'],
  ['Other', 5, 49, 'info'],
] as const

export const categoryData = [
  ['Eggs', 6, 482], ['Chicken', 9, 718], ['Rice', 14, 641], ['Bread', 15, 525],
  ['Soups', 19, 288], ['Mixed dishes', 22, 391], ['Sauces', 31, 244],
] as const

export const reviews: ReviewMeal[] = [
  {
    id: 'meal_01J8K7F2', created: 'Today, 14:32', title: 'Chicken rice bowl', image: '/images/chicken-salad.png',
    foods: 3, confidence: 96, correction: '−126 kcal', error: 'wrong_canonical_match', model: 'v3.2', status: 'Unreviewed',
    user: 'User 8F31…', trace: 'tr_9da48b1e', input: 'Chicken and rice. Sauce is yogurt.',
    diffs: [
      { name: 'Chicken breast', ai: '145 g', final: '150 g', note: '+5 g', severity: 'info' },
      { name: 'Rice', ai: '180 g', final: '120 g', note: '−60 g · quantity changed', severity: 'warning' },
      { name: 'Mayonnaise', ai: '30 g', final: 'Removed', note: 'Wrong food', severity: 'critical' },
      { name: 'Yogurt sauce', ai: 'Not detected', final: '25 g', note: 'Added by user', severity: 'critical' },
    ],
  },
  {
    id: 'meal_01J8K68A', created: 'Today, 13:09', title: 'Breakfast plate', image: '/images/breakfast.png',
    foods: 4, confidence: 72, correction: '+84 kcal', error: 'food_missing', model: 'v3.2', status: 'Unreviewed',
    user: 'User 1A09…', trace: 'tr_a815ca72', input: 'Eggs, cheese and half a simit.',
    diffs: [{ name: 'White cheese', ai: 'Not detected', final: '30 g', note: 'Added by user', severity: 'critical' }],
  },
  {
    id: 'meal_01J8K3QK', created: 'Today, 11:46', title: 'Banana yogurt', image: '/images/banana-yogurt.png',
    foods: 2, confidence: 91, correction: '−42 kcal', error: 'portion_overestimate', model: 'v3.2', status: 'Needs improvement',
    user: 'User 72D4…', trace: 'tr_029ad84c', input: 'Yogurt with one banana.',
    diffs: [{ name: 'Yogurt', ai: '250 g', final: '180 g', note: '−70 g · quantity changed', severity: 'warning' }],
  },
  {
    id: 'meal_01J8JY2M', created: 'Today, 09:18', title: 'Restaurant soup', image: '/images/meal-scan-guide.webp',
    foods: 1, confidence: 88, correction: '+112 kcal', error: 'hidden_oil_missing', model: 'v3.1', status: 'Unreviewed',
    user: 'User C921…', trace: 'tr_c161802f', input: 'Lentil soup.',
    diffs: [{ name: 'Olive oil', ai: 'Not detected', final: '12 g', note: 'Added by user', severity: 'critical' }],
  },
]

export const spans = [
  ['image_upload', 0, 182, 'healthy', 'JPEG · 1280×960 · 382 KB'],
  ['image_preprocess', 182, 94, 'healthy', 'Resize, EXIF strip, contrast normalize'],
  ['vision_analysis', 276, 1410, 'warning', 'OpenAI · vision-v3.2'],
  ['food_candidate_generation', 1686, 224, 'healthy', '4 concepts generated'],
  ['canonical_retrieval', 1910, 312, 'critical', 'Mayonnaise selected over yogurt sauce'],
  ['portion_estimation', 2222, 286, 'healthy', '4 portion estimates'],
  ['nutrition_lookup', 2508, 126, 'healthy', 'NutritionDB · cache hit 3/4'],
  ['validation', 2634, 48, 'healthy', 'Schema valid · calorie sanity passed'],
  ['meal_response', 2682, 62, 'healthy', 'HTTP 200'],
] as const

export const correctionTrend = [22.8, 21.9, 22.4, 21.2, 20.7, 20.9, 19.8, 20.2, 19.4, 18.9, 19.7, 18.4]
export const sauceTrend = [21, 22, 21, 23, 22, 24, 23, 24, 25, 27, 29, 31]
export const latencyTrend = [4.8, 5.1, 4.9, 5.2, 5, 5.3, 5.7, 5.5, 6.1, 6.4, 6.8, 6.6]
