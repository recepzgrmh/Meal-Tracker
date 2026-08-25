import type { Request as ExpressRequest, Response as ExpressResponse } from 'express'

/**
 * Every route handler in this backend is shaped `(Request) => Promise<Response>`
 * against the Web Fetch API, because that is the shape it had on the Edge
 * Runtime and keeping it meant the handler bodies could move over unchanged.
 * Express speaks its own req/res objects, so these two functions are the only
 * place the two worlds meet.
 */

export function toWebRequest(req: ExpressRequest): Request {
  const url = `${req.protocol}://${req.get('host') ?? 'localhost'}${req.originalUrl}`

  const headers = new Headers()
  for (const [key, value] of Object.entries(req.headers)) {
    if (value === undefined) continue
    if (Array.isArray(value)) {
      for (const entry of value) headers.append(key, entry)
    } else {
      headers.set(key, value)
    }
  }

  // `express.raw({ type: () => true })` leaves req.body as the raw Buffer.
  // Passing those bytes straight through is what keeps `await request.text()`
  // byte-faithful for send-email's HMAC — decoding to a string here and letting
  // undici re-encode it would corrupt any body that is not already UTF-8.
  // GET and HEAD must not carry a body at all or undici rejects the Request.
  const hasBody = req.method !== 'GET' && req.method !== 'HEAD'
  const body = hasBody && Buffer.isBuffer(req.body) && req.body.length > 0
    ? new Uint8Array(req.body)
    : undefined

  return new Request(url, { method: req.method, headers, body })
}

export async function sendWebResponse(response: Response, res: ExpressResponse): Promise<void> {
  res.status(response.status)
  response.headers.forEach((value, key) => {
    res.setHeader(key, value)
  })

  const buffer = Buffer.from(await response.arrayBuffer())
  res.end(buffer)
}
