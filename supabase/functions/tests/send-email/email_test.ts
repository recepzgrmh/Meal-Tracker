import { assertEquals, assertStringIncludes } from 'jsr:@std/assert@1'
import { buildEmailDeliveries, renderAuthEmail } from '../../send-email/email.ts'

Deno.test('renders a branded OTP email with plain-text fallback', () => {
  const email = renderAuthEmail('magiclink', '123456')

  assertEquals(email.subject, 'Meal Clarity giriş kodun')
  assertStringIncludes(email.text, '123456')
  assertStringIncludes(email.html, '1&nbsp;2&nbsp;3&nbsp;4&nbsp;5&nbsp;6')
  assertStringIncludes(email.html, 'Meal Clarity')
})

Deno.test('builds one delivery for passwordless sign in', () => {
  const deliveries = buildEmailDeliveries({
    user: { id: 'user-id', email: 'person@example.com' },
    email_data: {
      token: '654321',
      token_hash: 'hash',
      email_action_type: 'magiclink',
    },
  })

  assertEquals(deliveries.length, 1)
  assertEquals(deliveries[0].to, 'person@example.com')
  assertStringIncludes(deliveries[0].text, '654321')
})

Deno.test('builds both secure email-change deliveries with the correct tokens', () => {
  const deliveries = buildEmailDeliveries({
    user: {
      id: 'user-id',
      email: 'current@example.com',
      new_email: 'new@example.com',
    },
    email_data: {
      token: '111111',
      token_hash: 'new-email-hash',
      token_new: '222222',
      token_hash_new: 'current-email-hash',
      email_action_type: 'email_change',
    },
  })

  assertEquals(deliveries.length, 2)
  assertEquals(deliveries[0].to, 'current@example.com')
  assertStringIncludes(deliveries[0].text, '111111')
  assertEquals(deliveries[1].to, 'new@example.com')
  assertStringIncludes(deliveries[1].text, '222222')
})

Deno.test('escapes token content before rendering HTML', () => {
  const email = renderAuthEmail('magiclink', '<123>')

  assertStringIncludes(email.html, '&lt;&nbsp;1&nbsp;2&nbsp;3&nbsp;&gt;')
  assertEquals(email.html.includes('<123>'), false)
})
