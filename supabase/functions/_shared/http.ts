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

export function redactedLog(
  level: 'info' | 'error',
  event: string,
  fields: Record<string, string | number | boolean | null>,
): void {
  const log = JSON.stringify({ level, event, ...fields })
  if (level === 'error') console.error(log)
  else console.info(log)
}
