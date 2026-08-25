export const CANDIDATE_SELECTION_PROMPT_VERSION = 'candidate-allow-list-v1'

export interface RetrievalCandidate {
  foodId: string
  canonicalName: string
  matchedAlias: string
  score: number
  defaultGrams: number
  defaultPortionLabel: string
  nutritionPer100g: {
    calories: number
    protein: number
    carbs: number
    fat: number
  }
}

export interface CandidateSelection {
  candidateId: string
  sourceText: string
  estimatedGrams: number
  confidence: number
}

export interface CandidateSelectionResult {
  selections: CandidateSelection[]
  noMatch: boolean
  model: string
  promptVersion: typeof CANDIDATE_SELECTION_PROMPT_VERSION
  inputTokens: number
  outputTokens: number
  attempts: number
  cacheHit: boolean
}

interface SelectorOptions {
  apiKey: string
  locale: 'tr-TR' | 'en-US'
  input: string
  candidates: RetrievalCandidate[]
  model?: string
  fetcher?: typeof fetch
  timeoutMs?: number
  maxAttempts?: number
}

export class ProviderRefusalError extends Error {
  constructor() {
    super('Candidate selector refused the request')
    this.name = 'ProviderRefusalError'
  }
}

export async function selectCatalogCandidates(
  options: SelectorOptions,
): Promise<CandidateSelectionResult> {
  if (options.candidates.length === 0) {
    throw new Error('Candidate selector requires at least one catalog candidate')
  }
  const model = options.model ??
    (process.env.OPENAI_SELECTION_MODEL?.trim() || 'gpt-5.4-nano')
  const fetcher = options.fetcher ?? fetch
  const maxAttempts = options.maxAttempts ?? 3
  const timeoutMs = options.timeoutMs ?? 12_000
  const allowedIds = new Set(options.candidates.map((candidate) => candidate.foodId))
  let lastStatus = 0
  // Provider rejections are otherwise indistinguishable from each other: a
  // retired model, an unsupported parameter, and a schema the account cannot
  // use all arrive as a bare 400. Keep a bounded slice of the body so the
  // failure is diagnosable from telemetry instead of only from a local repro.
  let lastDetail = ''

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
        const selections = parseSelections(parsed.selections, allowedIds)
        const usage = payload.usage as Record<string, unknown> | undefined
        return {
          selections,
          noMatch: parsed.noMatch === true || selections.length === 0,
          model,
          promptVersion: CANDIDATE_SELECTION_PROMPT_VERSION,
          inputTokens: Number(usage?.input_tokens ?? 0),
          outputTokens: Number(usage?.output_tokens ?? 0),
          attempts: attempt,
          cacheHit: false,
        }
      }
      lastDetail = providerErrorDetail(await response.text().catch(() => ''))
      if (![408, 409, 429].includes(response.status) && response.status < 500) break
    } catch (error) {
      if (error instanceof ProviderRefusalError) throw error
      if (attempt === maxAttempts) throw error
    } finally {
      clearTimeout(timeout)
    }
    await delay(150 * 2 ** (attempt - 1))
  }
  throw new Error(
    `Candidate selector failed with ${lastStatus || 'network_error'}` +
      (lastDetail ? `: ${lastDetail}` : ''),
  )
}

/** Provider error bodies carry the actionable message; keep it short and drop
 * anything that is not the message so request echoes cannot reach telemetry. */
export function providerErrorDetail(body: string): string {
  if (!body) return ''
  try {
    const parsed = JSON.parse(body) as { error?: { message?: unknown; code?: unknown } }
    const message = parsed.error?.message
    if (typeof message === 'string' && message.length > 0) return message.slice(0, 300)
  } catch {
    // Non-JSON bodies (gateway HTML, plain text) still help when truncated.
  }
  return body.replace(/\s+/gu, ' ').trim().slice(0, 300)
}

function buildRequest(options: SelectorOptions, model: string): Record<string, unknown> {
  const candidateIds = options.candidates.map((candidate) => candidate.foodId)
  return {
    model,
    store: false,
    // Reasoning tokens are drawn from this budget. At 500 the model could burn
    // the whole allowance before emitting the JSON payload, and the response
    // then carried no output_text at all — which surfaced to the user as
    // "no catalog match" rather than a provider failure.
    max_output_tokens: 4000,
    reasoning: { effort: 'none' },
    input: [
      {
        role: 'system',
        content: [{
          type: 'input_text',
          text:
            'Normalize meal mentions by selecting only from the supplied catalog candidates. Never create a food ID, nutrition value, or hidden ingredient. Select no candidate when evidence is insufficient. Portion is an estimate and must remain conservative.',
        }],
      },
      {
        role: 'user',
        content: [{
          type: 'input_text',
          text: JSON.stringify({
            locale: options.locale,
            mealInput: options.input,
            allowedCandidates: options.candidates.map((candidate) => ({
              id: candidate.foodId,
              name: candidate.canonicalName,
              matchedAlias: candidate.matchedAlias,
              retrievalScore: candidate.score,
              defaultGrams: candidate.defaultGrams,
            })),
          }),
        }],
      },
    ],
    text: {
      format: {
        type: 'json_schema',
        name: 'catalog_candidate_selection',
        strict: true,
        schema: {
          type: 'object',
          additionalProperties: false,
          properties: {
            selections: {
              type: 'array',
              maxItems: Math.min(options.candidates.length, 12),
              items: {
                type: 'object',
                additionalProperties: false,
                properties: {
                  candidateId: { type: 'string', enum: candidateIds },
                  sourceText: { type: 'string', minLength: 1, maxLength: 120 },
                  estimatedGrams: { type: 'number', minimum: 1, maximum: 3000 },
                  confidence: { type: 'number', minimum: 0, maximum: 1 },
                },
                required: ['candidateId', 'sourceText', 'estimatedGrams', 'confidence'],
              },
            },
            noMatch: { type: 'boolean' },
          },
          required: ['selections', 'noMatch'],
        },
      },
    },
  }
}

function parseSelections(value: unknown, allowedIds: Set<string>): CandidateSelection[] {
  if (!Array.isArray(value)) return []
  const seen = new Set<string>()
  return value.flatMap((entry) => {
    if (typeof entry !== 'object' || entry === null) return []
    const row = entry as Record<string, unknown>
    const candidateId = typeof row.candidateId === 'string' ? row.candidateId : ''
    const sourceText = typeof row.sourceText === 'string' ? row.sourceText.trim() : ''
    const estimatedGrams = Number(row.estimatedGrams)
    const confidence = Number(row.confidence)
    if (
      !allowedIds.has(candidateId) || seen.has(candidateId) || !sourceText ||
      !Number.isFinite(estimatedGrams) || estimatedGrams < 1 || estimatedGrams > 3000 ||
      !Number.isFinite(confidence) || confidence < 0 || confidence > 1
    ) return []
    seen.add(candidateId)
    return [{ candidateId, sourceText, estimatedGrams, confidence }]
  })
}

function outputText(payload: Record<string, unknown>): string {
  const output = payload.output
  if (!Array.isArray(output)) throw new Error('Candidate selector returned no output')
  for (const item of output) {
    if (typeof item !== 'object' || item === null) continue
    const content = (item as Record<string, unknown>).content
    if (!Array.isArray(content)) continue
    for (const part of content) {
      if (typeof part !== 'object' || part === null) continue
      const typed = part as Record<string, unknown>
      if (typed.type === 'refusal') throw new ProviderRefusalError()
      if (typed.type === 'output_text' && typeof typed.text === 'string') return typed.text
    }
  }
  if (payload.status === 'incomplete') {
    const reason = (payload.incomplete_details as Record<string, unknown> | undefined)?.reason
    throw new Error(`Candidate selector response was incomplete: ${String(reason ?? 'unknown')}`)
  }
  throw new Error('Candidate selector returned no output text')
}

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds))
}
