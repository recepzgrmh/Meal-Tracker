# Send Email Hook runbook

Meal Clarity uses a Supabase Auth Send Email Hook and the Resend HTTP API. The
hook sends the six-digit token produced by Supabase Auth, so the Flutter
`verifyOTP` flow remains the source of truth. Supabase's dashboard email
template is not used.

## Where this route runs today

The handler exists in two places: `backend/src/routes/send-email/` (Node, where
the rest of the backend moved) and `supabase/functions/send-email/` (Deno, the
pre-migration copy). **The Deno one is the deployed one, and the hook points at
it.**

That is not an oversight. Supabase Auth calls this webhook from the internet, so
the URL has to be publicly reachable. While the Node backend runs on
`localhost`, Supabase cannot reach it and the Edge Function is the only version
that can serve the hook. Nothing about the hook needs changing to develop or
demo the rest of the system locally.

Repointing it is a step that belongs with deploying the Node backend publicly —
see [Moving the hook to the Node backend](#moving-the-hook-to-the-node-backend)
below. Until then, leave `send-email` deployed; deleting it silently breaks
every authentication email.

## Security rules

- Revoke any API key pasted into chat, an issue, logs, or a command committed
  to source control.
- Store `RESEND_API_KEY` and `SEND_EMAIL_HOOK_SECRET` only as secrets of
  whichever host serves the hook: Supabase Edge Function secrets today, the Node
  backend's environment if it is ever moved there. Never in a repository file —
  `backend/.env` is gitignored for this reason.
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

## Moving the hook to the Node backend

Only once the Node backend is deployed to a public HTTPS host. In order:

1. Set `SEND_EMAIL_HOOK_SECRET` (the full `v1,whsec_…` value), `RESEND_API_KEY`
   and `AUTH_EMAIL_FROM` in the backend host's environment. The route reads the
   same three names it read as an Edge Function.
2. Dashboard > Authentication > Hooks > Send Email: change the URL to
   `https://<backend-host>/send-email`. Keep the same secret so tokens already
   in flight stay verifiable.
3. Use the dashboard's **send test webhook** and confirm an `auth_email_sent`
   line in the backend logs. A failure here is silent for users — they simply
   never receive a code — so this check is not optional.
4. Only after that passes, delete the Edge Function:
   `supabase functions delete send-email`.

The signature check needs the request body byte-for-byte as signed, which is why
the Express app mounts `express.raw` rather than `express.json` or
`express.text`. Do not change that; `backend/test/lib/web-adapter.test.ts` pins
the behaviour.

## Local quality checks

```sh
cd backend
npm run typecheck
npm test
```

The unit suite covers branded OTP rendering, HTML escaping, normal
passwordless delivery, and Supabase's two-recipient secure email-change flow.

The Deno copy still has its own equivalent (`cd supabase && deno task check &&
deno task test`) for as long as it is the deployed version.
