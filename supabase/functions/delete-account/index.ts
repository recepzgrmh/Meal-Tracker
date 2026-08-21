import { withSupabase } from 'npm:@supabase/server@1.4.1'
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'
import { errorResponse, jsonResponse, redactedLog } from '../_shared/http.ts'

const MEAL_PHOTO_BUCKET = 'meal-photos'
const STORAGE_PAGE_SIZE = 100
/// Photos are written two levels deep (`<uid>/<analysisRunId>/source.<ext>`);
/// anything materially deeper means the layout changed and the recursion should
/// fail loudly rather than walk an unbounded tree.
const MAX_STORAGE_DEPTH = 4

interface DeleteAccountContext {
  supabase: SupabaseClient
  supabaseAdmin: SupabaseClient
  userClaims?: Record<string, unknown>
}

/**
 * App Store Guideline 5.1.1(v) requires an in-app path to permanent account
 * deletion. Relational rows hang off `auth.users` with `on delete cascade`, so
 * the admin delete is enough for the database — but storage objects are keyed
 * only by their `<uid>/` path prefix and would survive, so they are removed
 * first. Deleting the auth user is the last, irreversible step.
 */
export default {
  fetch: withSupabase({ auth: 'user' }, async (request: Request, rawContext: unknown) => {
    const traceId = crypto.randomUUID()
    if (request.method !== 'POST') {
      return errorResponse('METHOD_NOT_ALLOWED', 'Only POST is supported', traceId, 405)
    }

    const context = rawContext as DeleteAccountContext
    const userId = userIdFromClaims(context.userClaims)
    if (userId === null) {
      return errorResponse('FORBIDDEN', 'Oturum doğrulanamadı', traceId, 401)
    }

    const startedAt = performance.now()
    let removedPhotos = 0
    try {
      removedPhotos = await removeMealPhotos(context.supabaseAdmin, userId)
      const { error } = await context.supabaseAdmin.auth.admin.deleteUser(userId)
      if (error) throw error
    } catch (error) {
      redactedLog('error', 'account_delete_failed', {
        traceId,
        userId,
        removedPhotos,
        errorType: error instanceof Error ? error.name : 'UnknownError',
      })
      return errorResponse('INTERNAL_ERROR', 'Hesap silinemedi', traceId, 500, true)
    }

    redactedLog('info', 'account_delete_completed', {
      traceId,
      userId,
      removedPhotos,
      latencyMs: Math.round(performance.now() - startedAt),
    })
    return jsonResponse({
      contractVersion: 'account-delete.v1',
      traceId,
      deleted: true,
      removedPhotos,
    })
  }),
}

/**
 * Storage objects are not reachable by a foreign key, so the cascade never sees
 * them. Every meal photo lives under `<uid>/`, which the bucket policies already
 * enforce on write.
 */
async function removeMealPhotos(admin: SupabaseClient, userId: string): Promise<number> {
  return await removePrefix(admin.storage.from(MEAL_PHOTO_BUCKET), userId, 0)
}

/**
 * Removes every object under `prefix`, descending into sub-prefixes.
 *
 * `storage.list` only ever returns one level, and photos are written to
 * `<uid>/<analysisRunId>/source.<ext>` (see `SupabaseMealPhotoStorage.upload`),
 * so listing `<uid>` yields nothing but pseudo-folders — entries with a null
 * `id`. Treating those as "not a file" and stopping there deleted no photos at
 * all while still reporting success, which left the objects orphaned: once the
 * auth user is gone, the bucket's RLS delete policy (`foldername[1] =
 * auth.uid()`) can never match again.
 */
async function removePrefix(
  storage: ReturnType<SupabaseClient['storage']['from']>,
  prefix: string,
  depth: number,
): Promise<number> {
  if (depth > MAX_STORAGE_DEPTH) {
    throw new Error(`meal photo prefix nested deeper than ${MAX_STORAGE_DEPTH} levels`)
  }

  let removed = 0
  for (;;) {
    // Always offset 0: each pass deletes what it listed, so the next listing
    // starts at what used to be the following page.
    const { data, error } = await storage.list(prefix, { limit: STORAGE_PAGE_SIZE, offset: 0 })
    if (error) throw error

    const entries = data ?? []
    if (entries.length === 0) return removed

    const files = entries.filter((entry) => entry.id !== null)
    const folders = entries.filter((entry) => entry.id === null)

    if (files.length > 0) {
      const { error: removeError } = await storage.remove(
        files.map((entry) => `${prefix}/${entry.name}`),
      )
      if (removeError) throw removeError
      removed += files.length
    }

    for (const folder of folders) {
      removed += await removePrefix(storage, `${prefix}/${folder.name}`, depth + 1)
    }

    // A short page means everything under this prefix has now been handled.
    if (entries.length < STORAGE_PAGE_SIZE) return removed
  }
}

function userIdFromClaims(claims?: Record<string, unknown>): string | null {
  const value = claims?.sub ?? claims?.id
  return typeof value === 'string' && value.length > 0 ? value : null
}
