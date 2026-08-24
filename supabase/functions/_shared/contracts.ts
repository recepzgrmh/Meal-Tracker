export const ANALYSIS_CONTRACT_VERSION = 'analysis.v1' as const
export const DETERMINISTIC_PIPELINE_VERSION = 'deterministic-tr-v1' as const
export const TEXT_EXTRACTION_PIPELINE_VERSION = 'text-extraction-grounded-v1' as const
export const VISION_PIPELINE_VERSION = 'vision-grounded-hybrid-v2' as const

export type InputKind = 'text' | 'voice' | 'photo' | 'mixed'

export interface MealPhotoReference {
  bucket: 'meal-photos'
  path: string
  mimeType: 'image/jpeg' | 'image/png' | 'image/webp'
}

export interface AnalyzeMealRequest {
  clientRequestId: string
  input: string
  inputKind?: InputKind
  locale?: 'tr-TR' | 'en-US'
  photo?: MealPhotoReference
}

export interface NutritionPer100g {
  calories: number
  protein: number
  carbs: number
  fat: number
}

export interface AnalysisItem {
  itemKey: string
  sourceText: string
  /** Null only for `matchMethod: 'ai_estimate'` items, which carry an `estimateId` instead. */
  foodId: string | null
  canonicalName: string
  /**
   * What to call this food in the user's language.
   *
   * Roughly 14k catalog rows are USDA generic foods whose canonical name only
   * exists in English, so grounding a Turkish sentence could put "Restaurant
   * pasta with cream sauce and poultry" in front of someone who typed "kremalı
   * tavuklu makarna". The catalog name stays as provenance; the title is the
   * user's own words.
   */
  displayName?: string
  portionLabel: string
  grams: number
  quantity: number
  confidence: number
  matchMethod: 'exact' | 'alias' | 'retrieval' | 'llm' | 'ai_estimate'
  needsClarification: boolean
  clarificationReason?: 'identity' | 'portion'
  /** Runner-up catalog food ids when clarificationReason is 'identity' on the LLM path. */
  alternativeFoodIds?: string[]
  /** Server-recorded estimate row this item commits against. Never client-supplied. */
  estimateId?: string
  /** Marks nutrition as a bounds-checked AI estimate rather than catalog data. */
  estimated?: boolean
  portionOptions?: Array<{
    label: string
    grams: number
    sizeClass?: 'small' | 'regular' | 'large' | 'custom'
    imageUrl?: string
  }>
  nutritionPer100g: NutritionPer100g
}

export interface UnmatchedItem {
  itemKey: string
  text: string
}

export interface AnalyzeMealResponse {
  contractVersion: typeof ANALYSIS_CONTRACT_VERSION
  analysisRunId: string
  traceId: string
  status: 'needs_review'
  normalizedInput: string
  items: AnalysisItem[]
  unmatchedText: string[]
  /** Per-item view of unmatchedText so the client can say "we couldn't match: ayran". */
  unmatchedItems: UnmatchedItem[]
  pipeline: {
    extraction:
      | typeof DETERMINISTIC_PIPELINE_VERSION
      | typeof TEXT_EXTRACTION_PIPELINE_VERSION
      | typeof VISION_PIPELINE_VERSION
    retrieval: 'exact-alias-v1' | 'hybrid-rrf-v1'
    model: string | null
    promptVersion?: string
  }
  replayed: boolean
}

export interface ApiErrorBody {
  error: {
    code:
      | 'INVALID_REQUEST'
      | 'METHOD_NOT_ALLOWED'
      | 'NO_MATCH'
      | 'ANALYSIS_IN_PROGRESS'
      | 'FORBIDDEN'
      | 'CONFLICT'
      | 'RATE_LIMITED'
      | 'PROVIDER_UNAVAILABLE'
      | 'INTERNAL_ERROR'
    message: string
    traceId: string
    retryable: boolean
    details?: Record<string, unknown>
  }
}
