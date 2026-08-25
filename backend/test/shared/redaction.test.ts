import { expect, test } from 'vitest'
import { redactedLog, redactSecrets } from '../../src/shared/http.ts'

/**
 * `redactedLog` used to be `JSON.stringify` with a level selector — a name that
 * asserted a guarantee the function did not implement. These pin the guarantee.
 *
 * The realistic leak is not a careless call site inventing a field; it is a
 * provider's error message, which the pipeline already logs, arriving with a
 * key or an address inside it.
 */

function capture(run: () => void): string {
  const lines: string[] = []
  // info and error both, because redactedLog picks the sink by level.
  const originalError = console.error
  const originalInfo = console.info
  console.error = (line: string) => lines.push(String(line))
  console.info = (line: string) => lines.push(String(line))
  try {
    run()
  } finally {
    console.error = originalError
    console.info = originalInfo
  }
  return lines.join('\n')
}

test('a provider key inside an error message never reaches the log', () => {
  const logged = capture(() =>
    redactedLog('error', 'provider_failed', {
      message: 'Incorrect API key provided: sk-proj-abc123def456ghi789jkl',
    })
  )

  expect(logged).not.toContain('sk-proj-abc123def456ghi789jkl')
  expect(logged).toContain('[redacted]')
  // The event itself still has to be readable, or the scrub has cost more than
  // it bought.
  expect(logged).toContain('provider_failed')
})

test('an email address is treated as secret', () => {
  const logged = capture(() =>
    redactedLog('error', 'auth_email_failed', { message: 'no such user: ali@example.com' })
  )

  expect(logged).not.toContain('ali@example.com')
})

test('a bearer token and a JWT are both scrubbed', () => {
  expect(redactSecrets('Authorization: Bearer abcdefghijklmnop123')).not.toContain('abcdefghij')
  expect(
    redactSecrets('token eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abcdefgh'),
  ).toContain('[redacted]')
})

test('ordinary diagnostic values pass through untouched', () => {
  // Over-eager redaction would make the logs useless, which is its own failure.
  const logged = capture(() =>
    redactedLog('info', 'analysis_completed', {
      traceId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
      inputLength: 42,
      cacheHit: true,
      fallbackReason: null,
    })
  )

  expect(logged).toContain('018f6a5e-3528-7b52-a47d-2d5efc3b2f66')
  expect(logged).toContain('42')
  expect(logged).not.toContain('[redacted]')
})
