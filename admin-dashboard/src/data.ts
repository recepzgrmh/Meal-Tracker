export type Severity = 'healthy' | 'info' | 'warning' | 'critical'

/**
 * Operating thresholds the console judges live measurements against.
 *
 * This is product configuration — decisions the team made — not data. Every
 * number the console *reports* comes from Supabase; nothing is synthesised.
 */
export const THRESHOLDS = {
  /** Share of analysis runs that must complete, in percent. */
  successRate: 99,
  /** P95 end-to-end analysis latency budget, in milliseconds. */
  p95LatencyMs: 6000,
  /** Share of logged items a user may correct before quality is a concern. */
  correctionRate: 20,
  /** Cost per completed analysis, in US dollars. */
  costPerAnalysis: 0.03,
} as const

/** Correction reasons the mobile app can record, in reporting order. */
export const CORRECTION_REASONS = ['wrong_food', 'wrong_portion', 'wrong_nutrition', 'missing_item', 'other'] as const

export const formatInt = (value: number) => Math.round(value).toLocaleString('en-US')
export const formatCompact = (value: number) =>
  value >= 1000 ? `${(value / 1000).toFixed(value >= 10_000 ? 0 : 1)}k` : String(Math.round(value))
export const formatMs = (value: number | null) =>
  value == null ? '—' : value >= 1000 ? `${(value / 1000).toFixed(2)}s` : `${Math.round(value)} ms`
export const formatUsd = (micros: number) => `$${(micros / 1_000_000).toFixed(micros < 10_000_000 ? 4 : 2)}`
export const formatDay = (iso: string) =>
  new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
export const formatWhen = (iso: string | null) => {
  if (!iso) return '—'
  const delta = Date.now() - new Date(iso).getTime()
  const minutes = Math.round(delta / 60_000)
  if (minutes < 1) return 'just now'
  if (minutes < 60) return `${minutes} min ago`
  const hours = Math.round(minutes / 60)
  if (hours < 24) return `${hours} hr ago`
  const days = Math.round(hours / 24)
  return days < 30 ? `${days} d ago` : new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}
/** Short, stable, non-identifying label for a user UUID. */
export const shortId = (id: string) => `${id.slice(0, 4)}…${id.slice(-4)}`
