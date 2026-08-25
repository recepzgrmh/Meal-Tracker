import { expect, test } from 'vitest'
import type { Request as ExpressRequest } from 'express'
import { toWebRequest } from '../../src/lib/web-adapter.ts'

/**
 * The adapter is the seam where the Edge Runtime's native Request was replaced
 * by Express's req. Two things here are load-bearing and were both wrong at
 * first: a body must survive even when the caller sends no Content-Type, and
 * send-email's HMAC needs the bytes it was signed over, not a re-encoding.
 */

function fakeExpressRequest(overrides: {
  method?: string
  body?: unknown
  headers?: Record<string, string | string[]>
  originalUrl?: string
}): ExpressRequest {
  const headers = overrides.headers ?? {}
  return {
    method: overrides.method ?? 'POST',
    originalUrl: overrides.originalUrl ?? '/send-email',
    protocol: 'http',
    headers,
    body: overrides.body,
    get: (name: string) => (name.toLowerCase() === 'host' ? 'localhost:8080' : undefined),
  } as unknown as ExpressRequest
}

test('carries the body through when the caller sends no content-type', async () => {
  // express.raw matches on Content-Type; '*/*' does not match an absent header,
  // which silently dropped the body and handed the handler an empty string.
  const request = toWebRequest(
    fakeExpressRequest({ body: Buffer.from('{"hello":"world"}', 'utf-8'), headers: {} }),
  )

  expect(await request.text()).toBe('{"hello":"world"}')
})

test('preserves bytes exactly rather than re-encoding them', async () => {
  // A decode/re-encode round trip turns invalid UTF-8 into U+FFFD and changes
  // the length, which would break an HMAC computed over the original bytes.
  const raw = Buffer.from([0x7b, 0x22, 0x61, 0x22, 0x3a, 0xff, 0xfe, 0x22, 0x7d])
  const request = toWebRequest(
    fakeExpressRequest({ body: raw, headers: { 'content-type': 'application/json' } }),
  )

  const received = Buffer.from(await request.arrayBuffer())
  expect(received.equals(raw)).toBe(true)
})

test('reads an ordinary JSON body', async () => {
  const request = toWebRequest(
    fakeExpressRequest({
      body: Buffer.from(JSON.stringify({ input: '2 yumurta' }), 'utf-8'),
      headers: { 'content-type': 'application/json' },
    }),
  )

  expect(await request.json()).toEqual({ input: '2 yumurta' })
})

test('an empty body reads as an empty string, as it did on Deno', async () => {
  const request = toWebRequest(fakeExpressRequest({ body: Buffer.alloc(0) }))

  expect(await request.text()).toBe('')
})

test('does not attach a body to GET or HEAD', () => {
  // undici rejects constructing such a Request outright.
  for (const method of ['GET', 'HEAD']) {
    const request = toWebRequest(
      fakeExpressRequest({ method, body: Buffer.from('ignored', 'utf-8') }),
    )
    expect(request.body).toBeNull()
  }
})

test('forwards headers, including repeated ones', () => {
  const request = toWebRequest(
    fakeExpressRequest({
      headers: {
        authorization: 'Bearer token-abc',
        'webhook-id': 'msg_1',
        'x-repeated': ['a', 'b'],
      },
    }),
  )

  expect(request.headers.get('authorization')).toBe('Bearer token-abc')
  expect(request.headers.get('webhook-id')).toBe('msg_1')
  expect(request.headers.get('x-repeated')).toBe('a, b')
})

test('builds an absolute URL from the host header and original url', () => {
  const request = toWebRequest(fakeExpressRequest({ originalUrl: '/analyze-meal' }))

  expect(request.url).toBe('http://localhost:8080/analyze-meal')
})
