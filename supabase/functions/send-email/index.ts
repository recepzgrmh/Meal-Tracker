import { Webhook } from 'https://esm.sh/standardwebhooks@1.0.0'
import { buildEmailDeliveries, type SendEmailHookPayload } from './email.ts'

const resendEndpoint = 'https://api.resend.com/emails'

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim()
  if (!value) throw new Error(`Missing required secret: ${name}`)
  return value
}

function hookSecret(): string {
  return requiredEnv('SEND_EMAIL_HOOK_SECRET').replace(/^v1,whsec_/, '')
}

async function sendWithResend(
  apiKey: string,
  from: string,
  delivery: ReturnType<typeof buildEmailDeliveries>[number],
  idempotencyKey: string,
): Promise<void> {
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), 10000)

  try {
    const response = await fetch(resendEndpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'Idempotency-Key': idempotencyKey,
      },
      signal: controller.signal,
      body: JSON.stringify({
        from,
        to: [delivery.to],
        subject: delivery.subject,
        text: delivery.text,
        html: delivery.html,
      }),
    })

    if (!response.ok) {
      const providerRequestId = response.headers.get('x-request-id') ?? 'unknown'
      throw new Error(`Resend rejected delivery (${response.status}, request ${providerRequestId})`)
    }
  } finally {
    clearTimeout(timeoutId)
  }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return Response.json({ error: { message: 'Method not allowed' } }, { status: 405 })
  }

  const webhookId = request.headers.get('webhook-id') ?? crypto.randomUUID()
  const startedAt = performance.now()

  try {
    const rawBody = await request.text()
    const headers = Object.fromEntries(request.headers)
    const payload = new Webhook(hookSecret()).verify(rawBody, headers) as SendEmailHookPayload
    const deliveries = buildEmailDeliveries(payload)
    const apiKey = requiredEnv('RESEND_API_KEY')
    const from = requiredEnv('AUTH_EMAIL_FROM')

    await Promise.all(
      deliveries.map((delivery, index) =>
        sendWithResend(apiKey, from, delivery, `${webhookId}-${index}`)
      ),
    )

    console.info(JSON.stringify({
      level: 'info',
      event: 'auth_email_sent',
      webhookId,
      action: payload.email_data.email_action_type,
      deliveryCount: deliveries.length,
      durationMs: Math.round(performance.now() - startedAt),
    }))
    return Response.json({})
  } catch (error) {
    // Every error constructed above is deliberately scrubbed: it contains
    // only a missing secret name or the provider status/request id, never an
    // address, OTP, API key, webhook body, or provider response body.
    const safeError = error instanceof Error ? error.message : 'Unknown authentication email error'
    console.error(JSON.stringify({
      level: 'error',
      event: 'auth_email_failed',
      webhookId,
      errorType: error instanceof Error ? error.name : 'UnknownError',
      error: safeError,
      durationMs: Math.round(performance.now() - startedAt),
    }))

    return Response.json(
      { error: { http_code: 500, message: 'Authentication email could not be delivered' } },
      { status: 500 },
    )
  }
})
