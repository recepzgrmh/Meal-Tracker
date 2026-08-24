# Meal Clarity admin console

Read-only operations console for the Meal Clarity pipeline. It reads live data
from Supabase — there is no demo mode and no seeded data. If the console cannot
reach real data it says so rather than showing numbers that are not true.

## Setup

```bash
cp .env.example .env.local     # fill in from ../config/app_config.dev.json
npm install
npm run dev
```

Both values ship to the browser, so `.env.local` must hold the **publishable
(anon)** key. Never the service-role key.

## Granting console access

Every table in the schema is owner-scoped by RLS, so the anon key alone sees
nothing across users. Cross-user reads come from an explicit allow-list:

1. Apply `supabase/migrations/20260821120000_admin_console_reads.sql`. It creates
   `public.console_admins`, the `is_console_admin()` check, additive read-only
   RLS policies, and the aggregation views the console queries.
2. Add the operator, as the service role:

   ```sql
   insert into public.console_admins (user_id, note)
   values ('<auth.users.id>', 'console operator')
   on conflict (user_id) do nothing;
   ```

3. Sign in at the console with that account.

Removing the row revokes access on the operator's next request. The migration
grants no write access; admin mutations must go through a server endpoint.

## Where each screen reads from

| Screen | Source |
| --- | --- |
| Overview, Reliability, Analytics | `admin_analysis_daily` |
| AI Quality | `admin_category_quality`, `admin_correction_reasons` |
| Meal Reviews | `admin_review_queue` |
| Traces | `analysis_runs`, `analysis_candidates` |
| Users | `admin_account_summary` |
| Mobile App | `translation_bundles` + the generated ARB catalog |
| Audit Log | no source yet — the schema has no audit table |

## Commands

```bash
npm run dev      # vite dev server
npm run test     # vitest
npm run build    # tsc -b && vite build
```

The design system lives in `src/ui/` and is documented in `design.md`.
