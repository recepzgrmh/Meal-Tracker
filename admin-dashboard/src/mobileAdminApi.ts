export type SupportedLocale = 'tr' | 'en'
export type BundleStatus = 'draft' | 'staging' | 'production' | 'archived'

export type TranslationBundleDraft = {
  locale: SupportedLocale
  version: number
  status: BundleStatus
  values: Record<string, string>
}

export type ValidationIssue = { key: string; code: 'unsupported_locale' | 'invalid_version' | 'value_too_long' | 'payload_too_large' | 'placeholder_mismatch' }

const placeholders = (value: string) => [...value.matchAll(/\{([a-zA-Z][a-zA-Z0-9_]*)\}/g)].map((match) => match[1]).sort().join(',')

export function validateTranslationBundle(draft: TranslationBundleDraft, fallbacks: Record<string, string>): ValidationIssue[] {
  const issues: ValidationIssue[] = []
  if (!['tr', 'en'].includes(draft.locale)) issues.push({ key: 'locale', code: 'unsupported_locale' })
  if (!Number.isInteger(draft.version) || draft.version < 1) issues.push({ key: 'version', code: 'invalid_version' })
  for (const [key, value] of Object.entries(draft.values)) {
    if (value.length > 500) issues.push({ key, code: 'value_too_long' })
    if (value.trim() && placeholders(value) !== placeholders(fallbacks[key] || '')) issues.push({ key, code: 'placeholder_mismatch' })
  }
  if (new TextEncoder().encode(JSON.stringify(draft.values)).byteLength > 65_536) issues.push({ key: 'values', code: 'payload_too_large' })
  return issues
}

export interface MobileAdminApi {
  saveDraft(bundle: TranslationBundleDraft): Promise<void>
  promote(locale: SupportedLocale, version: number, target: 'staging' | 'production'): Promise<void>
  rollback(locale: SupportedLocale, fromVersion: number): Promise<void>
}

// The production implementation should call an authenticated admin endpoint.
// It must never write Supabase service-role credentials from the browser.
