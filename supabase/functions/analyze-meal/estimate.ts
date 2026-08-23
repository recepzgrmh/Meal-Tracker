export const ESTIMATE_PROMPT_VERSION = 'macro-estimate-fallback-v1'

// Server-side acceptance bounds for a per-100g estimate. Macros outside these
// ranges, or macros that disagree with the stated calories by more than the
// Atwater tolerance, reject the estimate outright: an estimate the model
// cannot state consistently is not worth recording as nutrition.
const MAX_CALORIES_PER_100G = 900
const MAX_MACRO_PER_100G = 100
const ATWATER_TOLERANCE_RATIO = 0.3
const MIN_ESTIMATED_GRAMS = 1
const MAX_ESTIMATED_GRAMS = 3000

export interface MacroEstimate {
  sourceText: string
  displayName: string
  estimatedGrams: number
  confidence: number
  nutritionPer100g: {
    calories: number
    protein: number
    carbs: number
    fat: number
  }
}

export interface MacroEstimateResult {
  estimates: MacroEstimate[]
  model: string
  promptVersion: typeof ESTIMATE_PROMPT_VERSION
  inputTokens: number
  outputTokens: number
  attempts: number
}

interface EstimatorOptions {
  apiKey: string
  locale: 'tr-TR' | 'en-US'
  foods: string[]
  model?: string
  fetcher?: typeof fetch
  timeoutMs?: number
  maxAttempts?: number
}

export class EstimateRefusalError extends Error {
  constructor() {
    super('Macro estimator refused the request')
    this.name = 'EstimateRefusalError'
  }
}

export async function estimateUnmatchedFoods(
  options: EstimatorOptions,
): Promise<MacroEstimateResult> {
  if (options.foods.length === 0) {
    throw new Error('Macro estimator requires at least one unmatched food text')
  }
  const model = options.model ??
    (Deno.env.get('OPENAI_SELECTION_MODEL')?.trim() || 'gpt-5.4-nano')
  const fetcher = options.fetcher ?? fetch
  const maxAttempts = options.maxAttempts ?? 3
  const timeoutMs = options.timeoutMs ?? 12_000
  const allowedTexts = new Set(options.foods)
  let lastStatus = 0

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), timeoutMs)
    try {
      const response = await fetcher('https://api.openai.com/v1/responses', {
        method: 'POST',
        headers: {
          authorization: `Bearer ${options.apiKey}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify(buildRequest(options, model)),
        signal: controller.signal,
      })
      lastStatus = response.status
      if (response.ok) {
        const payload = await response.json() as Record<string, unknown>
        const parsed = JSON.parse(outputText(payload)) as Record<string, unknown>
        const usage = payload.usage as Record<string, unknown> | undefined
        return {
          estimates: parseEstimates(parsed.estimates, allowedTexts),
          model,
          promptVersion: ESTIMATE_PROMPT_VERSION,
          inputTokens: Number(usage?.input_tokens ?? 0),
          outputTokens: Number(usage?.output_tokens ?? 0),
          attempts: attempt,
        }
      }
      if (![408, 409, 429].includes(response.status) && response.status < 500) break
    } catch (error) {
      if (error instanceof EstimateRefusalError) throw error
      if (attempt === maxAttempts) throw error
    } finally {
      clearTimeout(timeout)
    }
    await delay(150 * 2 ** (attempt - 1))
  }
  throw new Error(`Macro estimator failed with ${lastStatus || 'network_error'}`)
}

function buildRequest(options: EstimatorOptions, model: string): Record<string, unknown> {
  return {
    model,
    store: false,
    max_output_tokens: 4000,
    reasoning: { effort: 'minimal' },
    input: [
      {
        role: 'system',
        content: [{
          type: 'input_text',
          text:
            'Estimate conservative per-100g macros for foods that could not be matched to a catalog. Use typical prepared versions of the named food. Report calories consistent with the macros (4 kcal per gram of protein and carbs, 9 per gram of fat). Skip anything that is not a food. Keep confidence low: these are rough estimates.',
        }],
      },
      {
        role: 'user',
        content: [{
          type: 'input_text',
          text: JSON.stringify({ locale: options.locale, unmatchedFoods: options.foods }),
        }],
      },
    ],
    text: {
      format: {
        type: 'json_schema',
        name: 'macro_estimate_fallback',
        strict: true,
        schema: {
          type: 'object',
          additionalProperties: false,
          properties: {
            estimates: {
              type: 'array',
              maxItems: Math.min(options.foods.length, 12),
              items: {
                type: 'object',
                additionalProperties: false,
                properties: {
                  // Constrained to the request texts so an estimate can never
                  // introduce a food the user did not mention.
                  sourceText: { type: 'string', enum: options.foods },
                  displayName: { type: 'string', minLength: 1, maxLength: 100 },
                  estimatedGrams: {
                    type: 'number',
                    minimum: MIN_ESTIMATED_GRAMS,
                    maximum: MAX_ESTIMATED_GRAMS,
                  },
                  confidence: { type: 'number', minimum: 0, maximum: 1 },
                  caloriesPer100g: { type: 'number', minimum: 0, maximum: MAX_CALORIES_PER_100G },
                  proteinPer100g: { type: 'number', minimum: 0, maximum: MAX_MACRO_PER_100G },
                  carbsPer100g: { type: 'number', minimum: 0, maximum: MAX_MACRO_PER_100G },
                  fatPer100g: { type: 'number', minimum: 0, maximum: MAX_MACRO_PER_100G },
                },
                required: [
                  'sourceText',
                  'displayName',
                  'estimatedGrams',
                  'confidence',
                  'caloriesPer100g',
                  'proteinPer100g',
                  'carbsPer100g',
                  'fatPer100g',
                ],
              },
            },
          },
          required: ['estimates'],
        },
      },
    },
  }
}

function parseEstimates(value: unknown, allowedTexts: Set<string>): MacroEstimate[] {
  if (!Array.isArray(value)) return []
  const seen = new Set<string>()
  return value.flatMap((entry) => {
    if (typeof entry !== 'object' || entry === null) return []
    const row = entry as Record<string, unknown>
    const sourceText = typeof row.sourceText === 'string' ? row.sourceText : ''
    const displayName = typeof row.displayName === 'string' ? row.displayName.trim() : ''
    const estimatedGrams = Number(row.estimatedGrams)
    const confidence = Number(row.confidence)
    const calories = Number(row.caloriesPer100g)
    const protein = Number(row.proteinPer100g)
    const carbs = Number(row.carbsPer100g)
    const fat = Number(row.fatPer100g)
    if (
      !allowedTexts.has(sourceText) || seen.has(sourceText) || !displayName ||
      displayName.length > 100 || !Number.isFinite(estimatedGrams) ||
      !Number.isFinite(confidence) || confidence < 0 || confidence > 1 ||
      !Number.isFinite(calories) || calories < 0 || calories > MAX_CALORIES_PER_100G ||
      !Number.isFinite(protein) || protein < 0 || protein > MAX_MACRO_PER_100G ||
      !Number.isFinite(carbs) || carbs < 0 || carbs > MAX_MACRO_PER_100G ||
      !Number.isFinite(fat) || fat < 0 || fat > MAX_MACRO_PER_100G
    ) return []
    // Atwater consistency: calories that stray from 4P + 4C + 9F by more than
    // the tolerance mean the model made the numbers up independently.
    const derivedCalories = 4 * protein + 4 * carbs + 9 * fat
    if (Math.abs(calories - derivedCalories) > calories * ATWATER_TOLERANCE_RATIO) return []
    seen.add(sourceText)
    return [{
      sourceText,
      displayName,
      estimatedGrams: Math.min(
        Math.max(estimatedGrams, MIN_ESTIMATED_GRAMS),
        MAX_ESTIMATED_GRAMS,
      ),
      confidence,
      nutritionPer100g: { calories, protein, carbs, fat },
    }]
  })
}

function outputText(payload: Record<string, unknown>): string {
  const output = payload.output
  if (!Array.isArray(output)) throw new Error('Macro estimator returned no output')
  for (const item of output) {
    if (typeof item !== 'object' || item === null) continue
    const content = (item as Record<string, unknown>).content
    if (!Array.isArray(content)) continue
    for (const part of content) {
      if (typeof part !== 'object' || part === null) continue
      const typed = part as Record<string, unknown>
      if (typed.type === 'refusal') throw new EstimateRefusalError()
      if (typed.type === 'output_text' && typeof typed.text === 'string') return typed.text
    }
  }
  if (payload.status === 'incomplete') {
    const reason = (payload.incomplete_details as Record<string, unknown> | undefined)?.reason
    throw new Error(`Macro estimator response was incomplete: ${String(reason ?? 'unknown')}`)
  }
  throw new Error('Macro estimator returned no output text')
}

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds))
}
