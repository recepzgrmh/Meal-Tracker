# Supabase Edge Functions — Legacy / Pre-Migration Reference

> [!WARNING]
> The active meal-analysis runtime is `backend/` (Node.js/TypeScript).
> The `_analyze-meal/`, `_commit-meal/`, and `_evals/` directories are
> pre-migration Deno originals preserved for diff verification.
> They are marked with `_` prefix to exclude from Supabase CLI deploy.

## Actively deployed

- `send-email/` — Supabase Auth calls this webhook from the internet;
  it cannot point at the Node backend because Auth needs a public URL.
- `delete-account/` — Not yet ported to the Node backend.

## Deploy command

```bash
supabase functions deploy
```

Supabase CLI ignores directories prefixed with `_`, so only `send-email` and `delete-account` will deploy.

## Why legacy functions exist

The port from Deno to Node was deliberately a **move, not a rewrite**.
Keeping the Deno originals (prefixed `_`) lets anyone verify that the business logic
did not drift during the port by diffing corresponding files.
