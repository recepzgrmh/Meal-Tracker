import { createClient, type SupabaseClient } from '@supabase/supabase-js'

/*
 * The console talks to Supabase with the publishable (anon) key and the signed-in
 * operator's JWT. Cross-user reads come from the `console_admins` allow-list and
 * the additive RLS policies in
 * `supabase/migrations/20260821120000_admin_console_reads.sql` — never from a
 * service-role key, which must not reach the browser.
 */

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const isSupabaseConfigured = Boolean(url && anonKey)

export const supabase: SupabaseClient | null = isSupabaseConfigured
  ? createClient(url!, anonKey!, {
      auth: { persistSession: true, autoRefreshToken: true, storageKey: 'console-auth' },
      global: { headers: { 'x-client-info': 'meal-clarity-console' } },
    })
  : null

/** Thrown by every query when the environment has not been wired up yet. */
export class NotConfiguredError extends Error {
  constructor() {
    super('Supabase is not configured')
    this.name = 'NotConfiguredError'
  }
}

/** Thrown when the signed-in operator is not on the `console_admins` allow-list. */
export class NotAuthorizedError extends Error {
  constructor() {
    super('This account is not on the console admin allow-list')
    this.name = 'NotAuthorizedError'
  }
}

export function requireClient(): SupabaseClient {
  if (!supabase) throw new NotConfiguredError()
  return supabase
}

/**
 * Postgres reports a missing view as 42P01 and a blocked read as an empty set.
 * Surfacing the first as a distinct message is what tells the operator the
 * migration has not been applied yet, rather than leaving them to guess.
 */
export function describeError(error: unknown): { title: string; description: string; kind: 'config' | 'schema' | 'auth' | 'network' } {
  if (error instanceof NotConfiguredError) {
    return {
      kind: 'config',
      title: 'Supabase is not connected',
      description: 'Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in admin-dashboard/.env.local, then restart the dev server.',
    }
  }
  if (error instanceof NotAuthorizedError) {
    return {
      kind: 'auth',
      title: 'This account cannot read console data',
      description: 'Add the signed-in user to public.console_admins, then reload.',
    }
  }
  const code = (error as { code?: string } | null)?.code
  if (code === '42P01') {
    return {
      kind: 'schema',
      title: 'Console views are missing',
      description: 'Apply supabase/migrations/20260821120000_admin_console_reads.sql to this project, then reload.',
    }
  }
  if (code === '42501' || code === 'PGRST301') {
    return {
      kind: 'auth',
      title: 'Read was refused by row-level security',
      description: 'Sign in as an operator listed in public.console_admins.',
    }
  }
  return {
    kind: 'network',
    title: 'Could not load data',
    description: (error as Error | null)?.message ?? 'The request failed. Check the network tab and try again.',
  }
}
