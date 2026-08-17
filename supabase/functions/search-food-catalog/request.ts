export interface SearchFoodCatalogRequest {
  query: string
  locale: 'tr-TR' | 'en-US'
  limit: number
}

export class SearchRequestValidationError extends Error {
  constructor(message: string, readonly field?: string) {
    super(message)
    this.name = 'SearchRequestValidationError'
  }
}

export function parseSearchRequest(value: unknown): SearchFoodCatalogRequest {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new SearchRequestValidationError('Body must be an object')
  }
  const body = value as Record<string, unknown>
  const unknown = Object.keys(body).find((key) => !['query', 'locale', 'limit'].includes(key))
  if (unknown) throw new SearchRequestValidationError(`Unknown field: ${unknown}`, unknown)
  if (typeof body.query !== 'string' || body.query.trim().length < 2 || body.query.length > 120) {
    throw new SearchRequestValidationError('query must contain 2 to 120 characters', 'query')
  }
  if (body.locale !== undefined && !['tr-TR', 'en-US'].includes(String(body.locale))) {
    throw new SearchRequestValidationError('locale must be tr-TR or en-US', 'locale')
  }
  const limit = body.limit ?? 7
  if (!Number.isInteger(limit) || Number(limit) < 1 || Number(limit) > 20) {
    throw new SearchRequestValidationError('limit must be between 1 and 20', 'limit')
  }
  return {
    query: body.query.trim(),
    locale: (body.locale ?? 'tr-TR') as 'tr-TR' | 'en-US',
    limit: Number(limit),
  }
}
