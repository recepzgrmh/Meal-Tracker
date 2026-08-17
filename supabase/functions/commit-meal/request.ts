export interface CommitMealItemRequest {
  itemKey: string
  foodId: string
  sourceText: string
  portionLabel: string
  grams: number
}

export interface CommitMealRequest {
  analysisRunId: string
  commitRequestId: string
  mealId: string
  name: string
  occurredAt: string
  items: CommitMealItemRequest[]
}

const requestKeys = new Set([
  'analysisRunId',
  'commitRequestId',
  'mealId',
  'name',
  'occurredAt',
  'items',
])
const itemKeys = new Set(['itemKey', 'foodId', 'sourceText', 'portionLabel', 'grams'])
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/iu
const databaseUuidPattern = /^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/iu

export class CommitRequestValidationError extends Error {
  constructor(message: string, readonly field?: string) {
    super(message)
    this.name = 'CommitRequestValidationError'
  }
}

export function parseCommitMealRequest(value: unknown): CommitMealRequest {
  const body = record(value, 'body')
  rejectUnknown(body, requestKeys, 'body')
  const analysisRunId = uuid(body.analysisRunId, 'analysisRunId')
  const commitRequestId = uuid(body.commitRequestId, 'commitRequestId')
  const mealId = uuid(body.mealId, 'mealId')
  const name = boundedString(body.name, 'name', 120)
  const occurredAt = isoDate(body.occurredAt, 'occurredAt')
  if (!Array.isArray(body.items) || body.items.length < 1 || body.items.length > 50) {
    throw new CommitRequestValidationError('items must contain 1 to 50 entries', 'items')
  }
  const items = body.items.map((value, index) => {
    const item = record(value, `items[${index}]`)
    rejectUnknown(item, itemKeys, `items[${index}]`)
    const grams = item.grams
    if (typeof grams !== 'number' || !Number.isFinite(grams) || grams <= 0 || grams > 10000) {
      throw new CommitRequestValidationError(
        'grams must be between 0 and 10000',
        `items[${index}].grams`,
      )
    }
    return {
      itemKey: boundedString(item.itemKey, `items[${index}].itemKey`, 120),
      foodId: databaseUuid(item.foodId, `items[${index}].foodId`),
      sourceText: boundedString(item.sourceText, `items[${index}].sourceText`, 400),
      portionLabel: boundedString(item.portionLabel, `items[${index}].portionLabel`, 120),
      grams,
    }
  })
  if (new Set(items.map((item) => item.itemKey)).size !== items.length) {
    throw new CommitRequestValidationError('item keys must be unique', 'items')
  }
  return { analysisRunId, commitRequestId, mealId, name, occurredAt, items }
}

function record(value: unknown, field: string): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new CommitRequestValidationError(`${field} must be an object`, field)
  }
  return value as Record<string, unknown>
}

function rejectUnknown(
  value: Record<string, unknown>,
  allowed: Set<string>,
  field: string,
): void {
  const unknown = Object.keys(value).find((key) => !allowed.has(key))
  if (unknown) {
    throw new CommitRequestValidationError(`Unknown field: ${unknown}`, `${field}.${unknown}`)
  }
}

function uuid(value: unknown, field: string): string {
  if (typeof value !== 'string' || !uuidPattern.test(value)) {
    throw new CommitRequestValidationError(`${field} must be a UUID`, field)
  }
  return value
}

function databaseUuid(value: unknown, field: string): string {
  if (typeof value !== 'string' || !databaseUuidPattern.test(value)) {
    throw new CommitRequestValidationError(`${field} must be a UUID`, field)
  }
  return value
}

function boundedString(value: unknown, field: string, max: number): string {
  if (typeof value !== 'string' || value.trim().length < 1 || value.length > max) {
    throw new CommitRequestValidationError(`${field} must contain 1 to ${max} characters`, field)
  }
  return value.trim()
}

function isoDate(value: unknown, field: string): string {
  if (typeof value !== 'string' || !Number.isFinite(Date.parse(value))) {
    throw new CommitRequestValidationError(`${field} must be an ISO-8601 timestamp`, field)
  }
  return new Date(value).toISOString()
}
