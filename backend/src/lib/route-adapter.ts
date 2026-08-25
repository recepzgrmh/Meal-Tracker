import type { RequestHandler } from 'express'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { errorResponse, jsonHeaders, redactedLog } from '../shared/http.ts'
import { sendWebResponse, toWebRequest } from './web-adapter.ts'

/**
 * The Edge Runtime wrapped every authed function in `withSupabase({ auth:
 * 'user' })`, which verified the caller's JWT and handed the handler a context
 * carrying two clients. This is the same contract rebuilt on Express so the
 * handler bodies did not have to change.
 *
 * Verification is delegated to `auth.getUser(token)` rather than reimplemented
 * against the project JWKS locally. It costs a network call per request, but it
 * cannot drift from Supabase's own notion of a valid session — including
 * revoked and banned users, which a local signature check would still accept
 * until the token expired.
 */

export interface SupabaseContext {
  supabase: SupabaseClient
  supabaseAdmin: SupabaseClient
  userClaims?: Record<string, unknown>
}

export type WebHandler = (request: Request, context: SupabaseContext) => Promise<Response>
export type PublicHandler = (request: Request) => Promise<Response>

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim()
  if (!value) throw new Error(`Missing required environment variable: ${name}`)
  return value
}

let adminClient: SupabaseClient | null = null

/** Service-role client. One per process — it holds no per-request state. */
export function supabaseAdmin(): SupabaseClient {
  if (adminClient === null) {
    adminClient = createClient(requiredEnv('SUPABASE_URL'), requiredEnv('SUPABASE_SERVICE_ROLE_KEY'), {
      auth: { persistSession: false, autoRefreshToken: false },
    })
  }
  return adminClient
}

/**
 * Per-request client carrying the caller's JWT, so anything read through it is
 * still subject to row level security. This is what `context.supabase` meant on
 * the Edge Runtime and it must not be collapsed into the admin client.
 */
function userClient(accessToken: string): SupabaseClient {
  return createClient(requiredEnv('SUPABASE_URL'), requiredEnv('SUPABASE_ANON_KEY'), {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  })
}

function bearerToken(request: Request): string | null {
  const header = request.headers.get('authorization')
  if (header === null) return null
  const match = /^Bearer\s+(.+)$/iu.exec(header.trim())
  return match ? match[1].trim() : null
}

export function mountAuthedHandler(handler: WebHandler): RequestHandler {
  return async (req, res) => {
    const request = toWebRequest(req)

    // Preflight never carries credentials, so it is answered before the token
    // check. Only analyze-meal did this for itself on the Edge Runtime; doing it
    // here covers every authed route uniformly.
    if (request.method === 'OPTIONS') {
      await sendWebResponse(new Response('ok', { headers: jsonHeaders }), res)
      return
    }

    const traceId = crypto.randomUUID()
    const token = bearerToken(request)
    if (token === null) {
      await sendWebResponse(
        errorResponse('FORBIDDEN', 'Oturum doğrulanamadı', traceId, 401),
        res,
      )
      return
    }

    try {
      const { data, error } = await supabaseAdmin().auth.getUser(token)
      if (error || !data.user) {
        await sendWebResponse(
          errorResponse('FORBIDDEN', 'Oturum doğrulanamadı', traceId, 401),
          res,
        )
        return
      }

      const context: SupabaseContext = {
        supabase: userClient(token),
        supabaseAdmin: supabaseAdmin(),
        // The handlers read `sub` off this; passing the whole user through
        // would widen what a handler can reach into for no benefit.
        userClaims: { sub: data.user.id },
      }

      await sendWebResponse(await handler(request, context), res)
    } catch (error) {
      redactedLog('error', 'request_failed', {
        traceId,
        path: req.path,
        message: error instanceof Error ? error.message.slice(0, 500) : 'Unknown error',
      })
      await sendWebResponse(
        errorResponse('INTERNAL_ERROR', 'Beklenmeyen bir hata oluştu', traceId, 500, true),
        res,
      )
    }
  }
}

/**
 * For routes that authenticate themselves. Today that is only send-email, whose
 * security boundary is the standardwebhooks HMAC over the raw body — a JWT check
 * here would be meaningless because Supabase Auth does not send one.
 */
export function mountPublicHandler(handler: PublicHandler): RequestHandler {
  return async (req, res) => {
    const request = toWebRequest(req)
    if (request.method === 'OPTIONS') {
      await sendWebResponse(new Response('ok', { headers: jsonHeaders }), res)
      return
    }

    const traceId = crypto.randomUUID()
    try {
      await sendWebResponse(await handler(request), res)
    } catch (error) {
      redactedLog('error', 'request_failed', {
        traceId,
        path: req.path,
        message: error instanceof Error ? error.message.slice(0, 500) : 'Unknown error',
      })
      await sendWebResponse(
        errorResponse('INTERNAL_ERROR', 'Beklenmeyen bir hata oluştu', traceId, 500, true),
        res,
      )
    }
  }
}
