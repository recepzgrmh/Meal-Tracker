import { describe, expect, it } from 'vitest'
import { validateTranslationBundle } from './mobileAdminApi'

describe('OTA bundle contract', () => {
  it('accepts the mobile app locale, size, and placeholder contract', () => {
    expect(validateTranslationBundle({ locale: 'tr', version: 12, status: 'draft', values: { mealFoundCount: '{count} yiyecek bulduk' } }, { mealFoundCount: 'We found {count} foods' })).toEqual([])
  })

  it('rejects a missing placeholder', () => {
    expect(validateTranslationBundle({ locale: 'en', version: 9, status: 'draft', values: { mealFoundCount: 'Foods found' } }, { mealFoundCount: 'We found {count} foods' })).toContainEqual({ key: 'mealFoundCount', code: 'placeholder_mismatch' })
  })
})
