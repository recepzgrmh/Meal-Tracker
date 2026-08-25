import type { ApiErrorBody } from './contracts.ts'

export const jsonHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json; charset=utf-8',
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders })
}

export function errorResponse(
  code: ApiErrorBody['error']['code'],
  message: string,
  traceId: string,
  status: number,
  retryable = false,
  details?: Record<string, unknown>,
): Response {
  const body: ApiErrorBody = {
    error: { code, message, traceId, retryable, ...(details ? { details } : {}) },
  }
  return jsonResponse(body, status)
}

/** Substrings that mark a value as something that must never be logged. */
const SECRET_PATTERNS = [
  /\bsk-[A-Za-z0-9_-]{12,}/g,
  /\bre_[A-Za-z0-9_-]{12,}/g,
  /\bsb_secret_[A-Za-z0-9_-]{12,}/g,
  /\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g,
  /\bBearer\s+[A-Za-z0-9._-]{12,}/gi,
  /[\w.+-]+@[\w-]+\.[\w.-]+/g,
]

/**
 * Structured log line with a last-resort scrub.
 *
 * Call sites are expected to pass derived values — `inputLength`, not the
 * sentence; a user id, not an email. That discipline is the real protection and
 * it is what the field-name conventions here encode.
 *
 * This function used to do nothing but `JSON.stringify`, which meant its name
 * asserted a guarantee it did not implement: one careless call site putting a
 * provider error body or an address into a field would have written it
 * straight to stdout. The scrub below does not make careless call sites safe —
 * it makes the guarantee in the name true for the cases that actually leak,
 * which are keys and addresses arriving inside a provider's error message.
 */
export function redactedLog(
  level: 'info' | 'error',
  event: string,
  fields: Record<string, string | number | boolean | null>,
): void {
  const scrubbed: Record<string, string | number | boolean | null> = {}
  for (const [key, value] of Object.entries(fields)) {
    scrubbed[key] = typeof value === 'string' ? redactSecrets(value) : value
  }
  const log = JSON.stringify({ level, event, ...scrubbed })
  if (level === 'error') console.error(log)
  else console.info(log)
}

export function redactSecrets(value: string): string {
  let out = value
  for (const pattern of SECRET_PATTERNS) out = out.replace(pattern, '[redacted]')
  return out
}
