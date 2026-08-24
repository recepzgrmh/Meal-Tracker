export const TEXT_EXTRACTION_PROMPT_VERSION = 'meal-text-extraction-v1'

const MAX_COMPONENT_GRAMS = 3000
const MAX_QUANTITY = 100

export interface ExtractedComponent {
  name: string
  grams: number
}

export interface ExtractedFood {
  name: string
  quantity: number | null
  unit: string | null
  components: ExtractedComponent[]
}

export interface TextExtraction {
  foods: ExtractedFood[]
  model: string
  promptVersion: typeof TEXT_EXTRACTION_PROMPT_VERSION
  inputTokens: number
  outputTokens: number
  attempts: number
}

export type TextExtractionFailureReason =
  | 'timeout'
  | 'rate_limit'
  | 'refusal'
  | 'provider_error'

interface TextExtractionOptions {
  apiKey: string
  locale: 'tr-TR' | 'en-US'
  input: string
  model?: string
  fetcher?: typeof fetch
  timeoutMs?: number
  maxAttempts?: number
}

export class TextExtractionError extends Error {
  constructor(
    message: string,
    readonly reason: TextExtractionFailureReason,
    readonly status: number | null = null,
  ) {
    super(message)
    this.name = 'TextExtractionError'
  }
}

export class TextExtractionRefusalError extends TextExtractionError {
  constructor() {
    super('Text extractor refused the request', 'refusal')
    this.name = 'TextExtractionRefusalError'
  }
}

/**
 * Turns one free-text meal sentence into structured food mentions.
 *
 * This exists because a rule-based parser cannot separate food words from the
 * rest of a Turkish sentence. Turkish is agglutinative and the logging input is
 * conversational, so the non-food vocabulary ("yedim", "kanka", "sabah",
 * "bi tane daha") is open-ended and a stopword denylist can never close it.
 * Every leftover token used to become a food candidate, which is how "yedim"
 * and "kanka" reached catalog retrieval.
 *
 * The model only ever returns identity and amount. The output schema has no
 * nutrition fields at all, so the "nutrition comes from the catalog, never from
 * the model" invariant is preserved structurally rather than by convention.
 */
export async function extractFoodsFromText(
  options: TextExtractionOptions,
): Promise<TextExtraction> {
  const model = options.model ??
    (Deno.env.get('OPENAI_TEXT_EXTRACTION_MODEL')?.trim() ||
      Deno.env.get('OPENAI_SELECTION_MODEL')?.trim() || 'gpt-5.4-nano')
  const fetcher = options.fetcher ?? fetch
  const timeoutMs = options.timeoutMs ?? 12_000
  const maxAttempts = options.maxAttempts ?? 3
  let lastError = new TextExtractionError('Text extractor failed', 'provider_error')

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
      if (response.ok) return parseResponse(await response.json(), model, attempt)

      const reason = response.status === 429 ? 'rate_limit' : 'provider_error'
      lastError = new TextExtractionError(
        `Text extractor failed with ${response.status}`,
        reason,
        response.status,
      )
      if (!isRetryableStatus(response.status)) throw lastError
    } catch (error) {
      if (error instanceof TextExtractionRefusalError) throw error
      if (error instanceof TextExtractionError) {
        lastError = error
        if (!isRetryableStatus(error.status)) throw error
      } else if (error instanceof DOMException && error.name === 'AbortError') {
        lastError = new TextExtractionError('Text extractor timed out', 'timeout')
      } else {
        lastError = new TextExtractionError('Text extractor network failure', 'provider_error')
      }
    } finally {
      clearTimeout(timeout)
    }
    if (attempt < maxAttempts) await delay(150 * 2 ** (attempt - 1))
  }
  throw lastError
}

/**
 * Renders one extracted food back into the clean, canonical phrasing the
 * deterministic matcher was designed for ("2 adet yumurta"). Reusing the
 * existing alias matcher and portion resolver keeps quantity handling in one
 * place instead of duplicating it on the model path.
 */
export function renderExtractedFood(food: ExtractedFood): string {
  const amount = food.quantity !== null && Number.isFinite(food.quantity)
    ? trimNumber(food.quantity)
    : ''
  const unit = food.unit?.trim() ?? ''
  return [amount, unit, food.name].filter(Boolean).join(' ').trim()
}

export function renderExtractedComponent(component: ExtractedComponent): string {
  return `${trimNumber(component.grams)} g ${component.name}`.trim()
}

export interface ExtractionPhrase {
  /** Canonical phrasing fed to the alias matcher, amount included. */
  matchPhrase: string
  /** Bare food name, used for retrieval queries and for display when unmatched. */
  name: string
}

/**
 * Every phrase an extraction should be matched against: the food itself, plus
 * its components when the model decomposed a composite dish. Composite dishes
 * ("kaşarlı tavuklu makarna") are never a single catalog row, so the components
 * are what actually reach the catalog.
 *
 * The amount belongs in `matchPhrase` so the portion resolver can read it, but
 * never in `name`: searching the catalog for "2 adet yumurta" ranks worse than
 * searching for "yumurta", and the amount is noise in an unmatched-item chip.
 */
export function extractionPhrases(food: ExtractedFood): ExtractionPhrase[] {
  if (food.components.length > 0) {
    return food.components.map((component) => ({
      matchPhrase: renderExtractedComponent(component),
      name: component.name,
    }))
  }
  const matchPhrase = renderExtractedFood(food)
  return matchPhrase ? [{ matchPhrase, name: food.name }] : []
}

function trimNumber(value: number): string {
  return Number.isInteger(value) ? String(value) : String(Math.round(value * 100) / 100)
}

function buildRequest(options: TextExtractionOptions, model: string): Record<string, unknown> {
  return {
    model,
    store: false,
    max_output_tokens: 2000,
    reasoning: { effort: 'none' },
    input: [
      {
        role: 'system',
        content: [{
          type: 'input_text',
          text: [
            'You extract the foods and drinks a person says they consumed from one short, conversational sentence.',
            'Return only edible or drinkable items.',
            'Ignore everything else: verbs ("yedim", "içtim", "atıştırdım", "ate", "had"), greetings and slang ("kanka", "abi", "ya", "işte", "bro"), pronouns, time references ("sabah", "akşam", "kahvaltıda", "this morning"), and any other filler. These are never foods.',
            'Use the singular, canonical name of the food without the sentence around it. Strip inflection: "yumurtayı" is "yumurta", "eggs" is "egg".',
            'Set quantity and unit only when the person actually stated an amount. Otherwise use null for both. Never guess an amount.',
            'Treat a described dish as one item under its own full name. "kaşarlı tavuklu makarna" is one dish, not three foods.',
            'Only when a dish is a combination that a food catalog would not list as a single row, also fill components with its main ingredients and a typical cooked gram amount for each. Leave components empty for plain single foods.',
            'Never output calories, macros, or any other nutrition value. You are not asked for them and there is no field for them.',
            'If the sentence names no food at all, return an empty foods array.',
          ].join(' '),
        }],
      },
      {
        role: 'user',
        content: [{
          type: 'input_text',
          text: JSON.stringify({ locale: options.locale, mealInput: options.input }),
        }],
      },
    ],
    text: {
      format: {
        type: 'json_schema',
        name: 'meal_text_extraction',
        strict: true,
        schema: {
          type: 'object',
          additionalProperties: false,
          properties: {
            foods: {
              type: 'array',
              maxItems: 12,
              items: {
                type: 'object',
                additionalProperties: false,
                properties: {
                  name: { type: 'string', minLength: 1, maxLength: 100 },
                  quantity: {
                    type: ['number', 'null'],
                    minimum: 0,
                    maximum: MAX_QUANTITY,
                  },
                  unit: { type: ['string', 'null'], maxLength: 32 },
                  components: {
                    type: 'array',
                    maxItems: 8,
                    items: {
                      type: 'object',
                      additionalProperties: false,
                      properties: {
                        name: { type: 'string', minLength: 1, maxLength: 100 },
                        grams: {
                          type: 'number',
                          minimum: 1,
                          maximum: MAX_COMPONENT_GRAMS,
                        },
                      },
                      required: ['name', 'grams'],
                    },
                  },
                },
                required: ['name', 'quantity', 'unit', 'components'],
              },
            },
          },
          required: ['foods'],
        },
      },
    },
  }
}

function parseResponse(payload: unknown, model: string, attempts: number): TextExtraction {
  if (typeof payload !== 'object' || payload === null) {
    throw new TextExtractionError('Text extractor response is invalid', 'provider_error')
  }
  const parsed = JSON.parse(outputText(payload)) as { foods?: unknown }
  const usage = (payload as Record<string, unknown>).usage as Record<string, unknown> | undefined
  return {
    // An empty list is a successful answer ("no food in this sentence"), not a
    // provider failure. The caller routes it to normal no-match handling.
    foods: parseFoods(parsed.foods),
    model,
    promptVersion: TEXT_EXTRACTION_PROMPT_VERSION,
    inputTokens: Number(usage?.input_tokens ?? 0),
    outputTokens: Number(usage?.output_tokens ?? 0),
    attempts,
  }
}

function parseFoods(value: unknown): ExtractedFood[] {
  if (!Array.isArray(value)) return []
  const seen = new Set<string>()
  return value.flatMap((entry) => {
    if (typeof entry !== 'object' || entry === null) return []
    const row = entry as Record<string, unknown>
    const name = typeof row.name === 'string' ? row.name.trim() : ''
    if (!name || name.length > 100) return []
    const key = name.toLocaleLowerCase('tr-TR')
    if (seen.has(key)) return []

    const rawQuantity = Number(row.quantity)
    const quantity = row.quantity === null || !Number.isFinite(rawQuantity) || rawQuantity <= 0 ||
        rawQuantity > MAX_QUANTITY
      ? null
      : rawQuantity
    const rawUnit = typeof row.unit === 'string' ? row.unit.trim() : ''
    const unit = rawUnit && rawUnit.length <= 32 ? rawUnit : null

    seen.add(key)
    return [{ name, quantity, unit, components: parseComponents(row.components) }]
  })
}

function parseComponents(value: unknown): ExtractedComponent[] {
  if (!Array.isArray(value)) return []
  return value.flatMap((entry) => {
    if (typeof entry !== 'object' || entry === null) return []
    const row = entry as Record<string, unknown>
    const name = typeof row.name === 'string' ? row.name.trim() : ''
    const grams = Number(row.grams)
    if (
      !name || name.length > 100 || !Number.isFinite(grams) || grams < 1 ||
      grams > MAX_COMPONENT_GRAMS
    ) return []
    return [{ name, grams }]
  })
}

function outputText(value: unknown): string {
  const output = (value as { output?: unknown }).output
  if (!Array.isArray(output)) {
    throw new TextExtractionError('Text extractor returned no output', 'provider_error')
  }
  for (const item of output) {
    if (typeof item !== 'object' || item === null) continue
    const content = (item as { content?: unknown }).content
    if (!Array.isArray(content)) continue
    for (const part of content) {
      if (typeof part !== 'object' || part === null) continue
      const typed = part as Record<string, unknown>
      if (typed.type === 'refusal') throw new TextExtractionRefusalError()
      if (typed.type === 'output_text' && typeof typed.text === 'string') return typed.text
    }
  }
  if ((value as Record<string, unknown>).status === 'incomplete') {
    const reason =
      ((value as Record<string, unknown>).incomplete_details as Record<string, unknown> | undefined)
        ?.reason
    throw new TextExtractionError(
      `Text extractor response was incomplete: ${String(reason ?? 'unknown')}`,
      'provider_error',
    )
  }
  throw new TextExtractionError('Text extractor returned no output text', 'provider_error')
}

function isRetryableStatus(status: number | null): boolean {
  return status === null || status === 408 || status === 409 || status === 429 || status >= 500
}

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds))
}
