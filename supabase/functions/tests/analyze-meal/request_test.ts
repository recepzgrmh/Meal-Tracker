import { parseAnalyzeMealRequest, RequestValidationError } from '../../analyze-meal/request.ts'

Deno.test('accepts text in Turkish and English', () => {
  const request = parseAnalyzeMealRequest({
    clientRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
    input: '  2 yumurta  ',
    inputKind: 'voice',
    locale: 'tr-TR',
  })

  assertEquals(request.input, '2 yumurta')
  assertEquals(request.inputKind, 'voice')

  const english = parseAnalyzeMealRequest({
    clientRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
    input: '2 eggs',
    locale: 'en-US',
  })
  assertEquals(english.locale, 'en-US')
})

Deno.test('accepts private photo and mixed contracts', () => {
  const photo = {
    bucket: 'meal-photos',
    path: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66/018f6a5e-3528-7b52-a47d-2d5efc3b2f67/source.jpg',
    mimeType: 'image/jpeg',
  }
  const request = parseAnalyzeMealRequest({
    clientRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
    input: 'some cheese',
    inputKind: 'mixed',
    locale: 'en-US',
    photo,
  })
  assertEquals(request.inputKind, 'mixed')
  assertEquals(request.photo?.bucket, 'meal-photos')
})

Deno.test('rejects a forged user id and unknown fields', () => {
  assertValidationError(() =>
    parseAnalyzeMealRequest({
      clientRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
      input: 'yumurta',
      userId: 'victim-user-id',
    })
  )
})

Deno.test('rejects invalid ids, incomplete input kinds, and unsupported locale', () => {
  assertValidationError(() => parseAnalyzeMealRequest({ clientRequestId: 'nope', input: 'x' }))
  assertValidationError(() =>
    parseAnalyzeMealRequest({
      clientRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
      inputKind: 'photo',
    })
  )
  assertValidationError(() =>
    parseAnalyzeMealRequest({
      clientRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
      input: 'egg',
      locale: 'de-DE',
    })
  )
})

function assertValidationError(action: () => unknown): void {
  try {
    action()
  } catch (error) {
    if (error instanceof RequestValidationError) return
    throw error
  }
  throw new Error('Expected RequestValidationError')
}

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) throw new Error(`Expected ${expected}, received ${actual}`)
}
