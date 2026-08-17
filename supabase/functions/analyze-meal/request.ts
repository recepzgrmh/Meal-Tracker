import type { AnalyzeMealRequest } from '../_shared/contracts.ts'

const allowedKeys = new Set(['clientRequestId', 'input', 'inputKind', 'locale'])
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/iu

export class RequestValidationError extends Error {
  constructor(message: string, readonly field?: string) {
    super(message)
    this.name = 'RequestValidationError'
  }
}

export function parseAnalyzeMealRequest(value: unknown): AnalyzeMealRequest {
  if (!isRecord(value)) throw new RequestValidationError('Body must be a JSON object')

  const unknownKeys = Object.keys(value).filter((key) => !allowedKeys.has(key))
  if (unknownKeys.length > 0) {
    throw new RequestValidationError(`Unknown field: ${unknownKeys[0]}`, unknownKeys[0])
  }

  if (typeof value.clientRequestId !== 'string' || !uuidPattern.test(value.clientRequestId)) {
    throw new RequestValidationError('clientRequestId must be a UUID', 'clientRequestId')
  }
  if (typeof value.input !== 'string' || value.input.trim().length === 0) {
    throw new RequestValidationError('input must not be empty', 'input')
  }
  if (value.input.length > 1000) {
    throw new RequestValidationError('input must be at most 1000 characters', 'input')
  }
  if (value.inputKind !== undefined && !['text', 'voice'].includes(String(value.inputKind))) {
    throw new RequestValidationError('inputKind must be text or voice', 'inputKind')
  }
  if (value.locale !== undefined && value.locale !== 'tr-TR') {
    throw new RequestValidationError('Only tr-TR is supported in v1', 'locale')
  }

  return {
    clientRequestId: value.clientRequestId,
    input: value.input.trim(),
    ...(value.inputKind ? { inputKind: value.inputKind as 'text' | 'voice' } : {}),
    ...(value.locale ? { locale: value.locale as 'tr-TR' } : {}),
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}
