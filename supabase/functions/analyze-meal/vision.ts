import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'
import type { MealPhotoReference } from '../_shared/contracts.ts'

const promptVersion = 'meal-vision-extraction-v2'

export interface VisionFood {
  description: string
  estimatedGrams: number
  identityConfidence: number
  portionConfidence: number
  portionBasis: 'user_text' | 'container_reference' | 'visible_scale' | 'catalog_default'
}

export interface VisionExtraction {
  normalizedDescription: string
  model: string
  promptVersion: typeof promptVersion
  foods: VisionFood[]
  inputTokens: number
  outputTokens: number
  attempts: number
}

export type VisionFallbackReason = 'timeout' | 'rate_limit' | 'refusal' | 'provider_error'

export interface VisionAttempt {
  extraction: VisionExtraction | null
  fallbackReason: VisionFallbackReason | null
}

interface VisionRequestOptions {
  apiKey: string
  image: string
  locale: 'tr-TR' | 'en-US'
  userText: string
  model?: string
  fetcher?: typeof fetch
  timeoutMs?: number
  maxAttempts?: number
}

export class VisionProviderError extends Error {
  constructor(
    message: string,
    readonly reason: VisionFallbackReason,
    readonly status: number | null = null,
  ) {
    super(message)
    this.name = 'VisionProviderError'
  }
}

export class VisionRefusalError extends VisionProviderError {
  constructor() {
    super('Vision provider refused the request', 'refusal')
    this.name = 'VisionRefusalError'
  }
}

export async function extractFoodsFromPhoto(
  client: SupabaseClient,
  photo: MealPhotoReference,
  locale: 'tr-TR' | 'en-US',
  userText: string,
): Promise<VisionExtraction> {
  const apiKey = requiredEnv('OPENAI_API_KEY')
  const model = Deno.env.get('OPENAI_VISION_MODEL')?.trim() || 'gpt-5.4-nano'
  const { data, error } = await client.storage.from(photo.bucket).download(photo.path)
  if (error || !data) throw new Error('Meal photo could not be downloaded')

  const image = `data:${photo.mimeType};base64,${encodeBase64(await data.arrayBuffer())}`
  return await requestVisionExtraction({ apiKey, image, locale, userText, model })
}

export async function requestVisionExtraction(
  options: VisionRequestOptions,
): Promise<VisionExtraction> {
  const model = options.model ?? 'gpt-5.4-nano'
  const fetcher = options.fetcher ?? fetch
  const timeoutMs = options.timeoutMs ?? 15_000
  const maxAttempts = options.maxAttempts ?? 3
  let lastError = new VisionProviderError('Vision provider failed', 'provider_error')

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
        body: JSON.stringify(buildVisionRequest(options, model)),
        signal: controller.signal,
      })
      if (response.ok) return parseVisionResponse(await response.json(), model, attempt)

      const reason = response.status === 429 ? 'rate_limit' : 'provider_error'
      lastError = new VisionProviderError(
        `Vision provider failed with ${response.status}`,
        reason,
        response.status,
      )
      if (!isRetryableStatus(response.status)) throw lastError
    } catch (error) {
      if (error instanceof VisionRefusalError) throw error
      if (error instanceof VisionProviderError) {
        lastError = error
        if (!isRetryableStatus(error.status)) throw error
      } else if (error instanceof DOMException && error.name === 'AbortError') {
        lastError = new VisionProviderError('Vision provider timed out', 'timeout')
      } else {
        lastError = new VisionProviderError('Vision provider network failure', 'provider_error')
      }
    } finally {
      clearTimeout(timeout)
    }
    if (attempt < maxAttempts) await delay(150 * 2 ** (attempt - 1))
  }
  throw lastError
}

export async function extractVisionWithTextFallback(
  userText: string,
  extractor: () => Promise<VisionExtraction>,
): Promise<VisionAttempt> {
  try {
    return { extraction: await extractor(), fallbackReason: null }
  } catch (error) {
    if (!userText.trim()) throw error
    return {
      extraction: null,
      fallbackReason: error instanceof VisionProviderError ? error.reason : 'provider_error',
    }
  }
}

function buildVisionRequest(options: VisionRequestOptions, model: string): Record<string, unknown> {
  return {
    model,
    store: false,
    input: [
      {
        role: 'system',
        content: [
          {
            type: 'input_text',
            text:
              'You identify visibly supported foods in one meal photo. Never invent nutrition, hidden ingredients, cooking oil, sauces, or foods that are not visible or explicitly stated by the user. Separate identity confidence from portion confidence. Exact mass from a single RGB photo is usually uncertain: use catalog_default and low portion confidence unless user text gives an amount, a known container clearly supplies scale, or a visible reference supplies scale. Return short canonical food descriptions in the requested language.',
          },
        ],
      },
      {
        role: 'user',
        content: [
          {
            type: 'input_text',
            text: `Locale: ${options.locale}. Optional user description: ${
              options.userText || '(none)'
            }`,
          },
          { type: 'input_image', image_url: options.image, detail: 'high' },
        ],
      },
    ],
    text: {
      format: {
        type: 'json_schema',
        name: 'meal_photo_extraction',
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
                  description: { type: 'string', minLength: 1, maxLength: 100 },
                  estimatedGrams: { type: 'number', minimum: 1, maximum: 3000 },
                  identityConfidence: { type: 'number', minimum: 0, maximum: 1 },
                  portionConfidence: { type: 'number', minimum: 0, maximum: 1 },
                  portionBasis: {
                    type: 'string',
                    enum: ['user_text', 'container_reference', 'visible_scale', 'catalog_default'],
                  },
                },
                required: [
                  'description',
                  'estimatedGrams',
                  'identityConfidence',
                  'portionConfidence',
                  'portionBasis',
                ],
              },
            },
          },
          required: ['foods'],
        },
      },
    },
  }
}

function parseVisionResponse(payload: unknown, model: string, attempts: number): VisionExtraction {
  if (typeof payload !== 'object' || payload === null) {
    throw new VisionProviderError('Vision response is invalid', 'provider_error')
  }
  const parsed = JSON.parse(outputText(payload)) as { foods?: unknown[] }
  const foods = parseFoods(parsed.foods)
  if (foods.length === 0) {
    throw new VisionProviderError('Vision provider returned no supported foods', 'provider_error')
  }
  const usage = (payload as Record<string, unknown>).usage as Record<string, unknown> | undefined
  return {
    foods,
    model,
    promptVersion,
    inputTokens: Number(usage?.input_tokens ?? 0),
    outputTokens: Number(usage?.output_tokens ?? 0),
    attempts,
    normalizedDescription: foods
      .map((food) => `${Math.round(food.estimatedGrams)} g ${food.description}`)
      .join(' ve '),
  }
}

function parseFoods(value: unknown): VisionFood[] {
  if (!Array.isArray(value)) return []
  return value.flatMap((item) => {
    if (typeof item !== 'object' || item === null) return []
    const row = item as Record<string, unknown>
    const description = typeof row.description === 'string' ? row.description.trim() : ''
    const estimatedGrams = Number(row.estimatedGrams)
    const identityConfidence = Number(row.identityConfidence)
    const portionConfidence = Number(row.portionConfidence)
    const portionBasis = row.portionBasis
    if (
      !description || description.length > 100 || !Number.isFinite(estimatedGrams) ||
      estimatedGrams < 1 || estimatedGrams > 3000 ||
      !Number.isFinite(identityConfidence) || identityConfidence < 0 || identityConfidence > 1 ||
      !Number.isFinite(portionConfidence) || portionConfidence < 0 || portionConfidence > 1 ||
      !['user_text', 'container_reference', 'visible_scale', 'catalog_default'].includes(
        String(portionBasis),
      )
    ) return []
    return [{
      description,
      estimatedGrams,
      identityConfidence,
      portionConfidence,
      portionBasis: portionBasis as VisionFood['portionBasis'],
    }]
  })
}

function outputText(value: unknown): string {
  if (typeof value !== 'object' || value === null) {
    throw new VisionProviderError('Vision response is invalid', 'provider_error')
  }
  const output = (value as { output?: unknown }).output
  if (!Array.isArray(output)) {
    throw new VisionProviderError('Vision response has no output', 'provider_error')
  }
  for (const item of output) {
    if (typeof item !== 'object' || item === null) continue
    const content = (item as { content?: unknown }).content
    if (!Array.isArray(content)) continue
    for (const part of content) {
      if (
        typeof part === 'object' && part !== null &&
        (part as { type?: unknown }).type === 'refusal'
      ) throw new VisionRefusalError()
      if (
        typeof part === 'object' && part !== null &&
        (part as { type?: unknown }).type === 'output_text' &&
        typeof (part as { text?: unknown }).text === 'string'
      ) {
        return (part as { text: string }).text
      }
    }
  }
  throw new VisionProviderError('Vision response has no output text', 'provider_error')
}

function isRetryableStatus(status: number | null): boolean {
  return status === null || status === 408 || status === 409 || status === 429 || status >= 500
}

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds))
}

function encodeBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer)
  let binary = ''
  for (let offset = 0; offset < bytes.length; offset += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + 0x8000))
  }
  return btoa(binary)
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim()
  if (!value) throw new Error(`${name} is not configured`)
  return value
}
