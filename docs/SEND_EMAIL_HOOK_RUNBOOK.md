# Send Email Hook runbook

Meal Clarity uses a Supabase Auth Send Email Hook and the Resend HTTP API. The
hook sends the six-digit token produced by Supabase Auth, so the Flutter
`verifyOTP` flow remains the source of truth. Supabase's dashboard email
template is not used.

## Security rules

- Revoke any API key pasted into chat, an issue, logs, or a command committed
  to source control.
- Store `RESEND_API_KEY` and `SEND_EMAIL_HOOK_SECRET` only as hosted Supabase
  Edge Function secrets.
- Never log recipients, OTP values, API keys, or raw webhook bodies.
- Deploy with Supabase JWT verification disabled because authenticity is
  checked with the Standard Webhooks signature instead.

## One-time hosted setup

1. In Resend, verify a sending domain. During owner-only development,
   `Meal Clarity <onboarding@resend.dev>` can be used instead.
2. Deploy the function:

   ```sh
   supabase functions deploy send-email --no-verify-jwt
   ```

3. Open Supabase Dashboard > Authentication > Hooks > Send Email and create an
   HTTP hook pointing to:

   ```text
   https://<project-ref>.supabase.co/functions/v1/send-email
   ```

4. Generate the hook secret, but do not enable the hook until all three Edge
   Function secrets have been configured:

   - `RESEND_API_KEY`: a newly generated Resend API key
   - `SEND_EMAIL_HOOK_SECRET`: the complete value beginning with
     `v1,whsec_`
   - `AUTH_EMAIL_FROM`: for example
     `Meal Clarity <auth@mail.example.com>`

   Add them from Supabase Dashboard > Edge Functions > Secrets. This avoids
   putting secret values in shell history or repository files.
5. Enable the Send Email hook while keeping the Email provider enabled.

When both are enabled, the hook sends the message and SMTP is not used. If the
Email provider is disabled, email signup is disabled even when the hook is
enabled.

## Verification

1. Trigger passwordless login from the Flutter app with an address Resend is
   permitted to receive.
2. Confirm the branded message contains a six-digit code rather than a magic
   link.
3. Enter the code in the app and verify that a Supabase session is created.
4. Check Edge Function logs for `auth_email_sent`. Logs intentionally include
   only the webhook ID, action, delivery count, and duration.
5. Retry once and confirm Resend does not produce duplicate delivery for the
   same webhook ID.

If delivery fails, disable the hook first to restore Supabase SMTP behavior for
authorized organization addresses, then inspect the Edge Function and Resend
logs. Do not print the raw hook payload while debugging.

## Local quality checks

```sh
cd supabase
deno task check
deno task test
```

The unit suite covers branded OTP rendering, HTML escaping, normal
passwordless delivery, and Supabase's two-recipient secure email-change flow.
