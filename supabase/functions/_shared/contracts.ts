export const ANALYSIS_CONTRACT_VERSION = 'analysis.v1' as const
export const DETERMINISTIC_PIPELINE_VERSION = 'deterministic-tr-v1' as const
export const VISION_PIPELINE_VERSION = 'vision-grounded-hybrid-v1' as const

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
  foodId: string
  canonicalName: string
  portionLabel: string
  grams: number
  quantity: number
  confidence: number
  matchMethod: 'exact' | 'alias'
  needsClarification: boolean
  clarificationReason?: 'identity' | 'portion'
  nutritionPer100g: NutritionPer100g
}

export interface AnalyzeMealResponse {
  contractVersion: typeof ANALYSIS_CONTRACT_VERSION
  analysisRunId: string
  traceId: string
  status: 'needs_review'
  normalizedInput: string
  items: AnalysisItem[]
  unmatchedText: string[]
  pipeline: {
    extraction: typeof DETERMINISTIC_PIPELINE_VERSION | typeof VISION_PIPELINE_VERSION
    retrieval: 'exact-alias-v1'
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
      | 'INTERNAL_ERROR'
    message: string
    traceId: string
    retryable: boolean
    details?: Record<string, unknown>
  }
}
