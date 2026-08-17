import { parseAnalyzeMealRequest, RequestValidationError } from '../../analyze-meal/request.ts'

Deno.test('accepts the strict v1 request contract', () => {
  const request = parseAnalyzeMealRequest({
    clientRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
    input: '  2 yumurta  ',
    inputKind: 'voice',
    locale: 'tr-TR',
  })

  assertEquals(request.input, '2 yumurta')
  assertEquals(request.inputKind, 'voice')
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

Deno.test('rejects invalid ids, empty input, and unsupported locale', () => {
  assertValidationError(() => parseAnalyzeMealRequest({ clientRequestId: 'nope', input: 'x' }))
  assertValidationError(() =>
    parseAnalyzeMealRequest({
      clientRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
      input: '',
    })
  )
  assertValidationError(() =>
    parseAnalyzeMealRequest({
      clientRequestId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
      input: 'egg',
      locale: 'en-US',
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
