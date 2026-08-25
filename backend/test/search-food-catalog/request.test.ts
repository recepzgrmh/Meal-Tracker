import { test } from 'vitest'
import {
  parseSearchRequest,
  SearchRequestValidationError,
} from '../../src/routes/search-food-catalog/request.ts'

test('normalizes a bounded Turkish catalog query', () => {
  const request = parseSearchRequest({ query: '  beyaz peynr ', limit: 5 })
  assertEquals(request.query, 'beyaz peynr')
  assertEquals(request.locale, 'tr-TR')
  assertEquals(request.limit, 5)
})

test('accepts English and rejects unsupported locale and unbounded limit', () => {
  assertEquals(parseSearchRequest({ query: 'egg', locale: 'en-US' }).locale, 'en-US')
  expectValidation(() => parseSearchRequest({ query: 'egg', locale: 'de-DE' }))
  expectValidation(() => parseSearchRequest({ query: 'yumurta', limit: 100 }))
})

test('rejects forged and unknown request fields', () => {
  expectValidation(() => parseSearchRequest({ query: 'simit', userId: 'victim' }))
})

function expectValidation(action: () => unknown): void {
  try {
    action()
  } catch (error) {
    if (error instanceof SearchRequestValidationError) return
    throw error
  }
  throw new Error('Expected SearchRequestValidationError')
}

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) throw new Error(`Expected ${expected}, received ${actual}`)
}
