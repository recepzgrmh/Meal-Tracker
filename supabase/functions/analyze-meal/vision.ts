import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'
import type { MealPhotoReference } from '../_shared/contracts.ts'

const promptVersion = 'meal-vision-extraction-v1'

interface VisionFood {
  description: string
  estimatedGrams: number
  confidence: number
}

export interface VisionExtraction {
  normalizedDescription: string
  model: string
  promptVersion: typeof promptVersion
  foods: VisionFood[]
  inputTokens: number
  outputTokens: number
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
  const response = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      authorization: `Bearer ${apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model,
      store: false,
      input: [
        {
          role: 'system',
          content: [
            {
              type: 'input_text',
              text:
                'You extract foods and visible portion estimates from one meal photo. Never invent nutrition, ingredients hidden inside a dish, or foods not visually supported. User text may disambiguate a visible food but is not visual evidence. Return short canonical food descriptions in the requested language. If uncertain, use a generic description and lower confidence.',
            },
          ],
        },
        {
          role: 'user',
          content: [
            {
              type: 'input_text',
              text: `Locale: ${locale}. Optional user description: ${userText || '(none)'}`,
            },
            { type: 'input_image', image_url: image, detail: 'low' },
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
                    confidence: { type: 'number', minimum: 0, maximum: 1 },
                  },
                  required: ['description', 'estimatedGrams', 'confidence'],
                },
              },
            },
            required: ['foods'],
          },
        },
      },
    }),
  })
  if (!response.ok) throw new Error(`Vision provider failed with ${response.status}`)

  const payload = await response.json()
  const parsed = JSON.parse(outputText(payload)) as { foods?: unknown[] }
  const foods = parseFoods(parsed.foods)
  if (foods.length === 0) throw new Error('Vision provider returned no supported foods')
  return {
    foods,
    model,
    promptVersion,
    inputTokens: Number(payload.usage?.input_tokens ?? 0),
    outputTokens: Number(payload.usage?.output_tokens ?? 0),
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
    const confidence = Number(row.confidence)
    if (!description || !Number.isFinite(estimatedGrams) || !Number.isFinite(confidence)) return []
    return [{ description, estimatedGrams, confidence }]
  })
}

function outputText(value: unknown): string {
  if (typeof value !== 'object' || value === null) throw new Error('Vision response is invalid')
  const output = (value as { output?: unknown }).output
  if (!Array.isArray(output)) throw new Error('Vision response has no output')
  for (const item of output) {
    if (typeof item !== 'object' || item === null) continue
    const content = (item as { content?: unknown }).content
    if (!Array.isArray(content)) continue
    for (const part of content) {
      if (
        typeof part === 'object' && part !== null &&
        (part as { type?: unknown }).type === 'output_text' &&
        typeof (part as { text?: unknown }).text === 'string'
      ) {
        return (part as { text: string }).text
      }
    }
  }
  throw new Error('Vision response has no output text')
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
