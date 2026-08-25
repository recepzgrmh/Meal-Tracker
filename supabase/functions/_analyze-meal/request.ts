import type { AnalyzeMealRequest, InputKind, MealPhotoReference } from '../_shared/contracts.ts'

const allowedKeys = new Set(['clientRequestId', 'input', 'inputKind', 'locale', 'photo'])
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/iu
const photoPathPattern = /^[0-9a-f-]{36}\/[0-9a-f-]{36}\/source\.(?:jpg|png|webp)$/iu

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
  if (value.input !== undefined && typeof value.input !== 'string') {
    throw new RequestValidationError('input must be a string', 'input')
  }
  const input = typeof value.input === 'string' ? value.input.trim() : ''
  if (input.length > 1000) {
    throw new RequestValidationError('input must be at most 1000 characters', 'input')
  }
  const inputKind = (value.inputKind ?? 'text') as InputKind
  if (!['text', 'voice', 'photo', 'mixed'].includes(inputKind)) {
    throw new RequestValidationError('inputKind must be text, voice, photo, or mixed', 'inputKind')
  }
  const locale = value.locale ?? 'tr-TR'
  if (!['tr-TR', 'en-US'].includes(String(locale))) {
    throw new RequestValidationError('locale must be tr-TR or en-US', 'locale')
  }

  const photo = value.photo === undefined ? undefined : parsePhoto(value.photo)
  if (['text', 'voice'].includes(inputKind) && input.length === 0) {
    throw new RequestValidationError('input must not be empty for text or voice', 'input')
  }
  if (inputKind === 'photo' && !photo) {
    throw new RequestValidationError('photo is required for photo input', 'photo')
  }
  if (inputKind === 'mixed' && (input.length === 0 || !photo)) {
    throw new RequestValidationError('mixed input requires both input and photo', 'inputKind')
  }

  return {
    clientRequestId: value.clientRequestId,
    input,
    inputKind,
    locale: locale as 'tr-TR' | 'en-US',
    ...(photo ? { photo } : {}),
  }
}

function parsePhoto(value: unknown): MealPhotoReference {
  if (!isRecord(value)) throw new RequestValidationError('photo must be an object', 'photo')
  const keys = Object.keys(value)
  if (keys.some((key) => !['bucket', 'path', 'mimeType'].includes(key))) {
    throw new RequestValidationError('photo contains an unknown field', 'photo')
  }
  if (value.bucket !== 'meal-photos') {
    throw new RequestValidationError('photo bucket is invalid', 'photo.bucket')
  }
  if (typeof value.path !== 'string' || !photoPathPattern.test(value.path)) {
    throw new RequestValidationError('photo path is invalid', 'photo.path')
  }
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(String(value.mimeType))) {
    throw new RequestValidationError('photo mimeType is invalid', 'photo.mimeType')
  }
  return value as unknown as MealPhotoReference
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}
