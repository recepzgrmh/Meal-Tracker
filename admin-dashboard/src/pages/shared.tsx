import type { ReactNode } from 'react'
import type { Severity } from '../data'
import type { Tone } from '../ui'

export type Page =
  | 'overview' | 'analytics' | 'quality' | 'reviews' | 'traces'
  | 'reliability' | 'users' | 'mobile' | 'audit' | 'settings'
  | 'live' | 'lab' | 'versions'

/** Records are addressed by id, not by object, so a URL always survives a reload. */
export type Route = {
  page: Page
  itemId?: string
  traceId?: string
  userId?: string
  filter?: string
  section?: string
  /** `mine` narrows row-level screens to the signed-in operator's own runs. */
  scope?: 'all' | 'mine'
}

export type Navigate = (route: Route) => void

export type PageProps = {
  route: Route
  navigate: Navigate
  range: string
  t: (value: string) => string
}

/** Maps the domain severity vocabulary onto design-system tones. */
export const toneOf = (severity: Severity | string): Tone =>
  severity === 'healthy' ? 'ok' : severity === 'critical' ? 'danger' : severity === 'warning' ? 'warn' : 'info'

export function PageHeader({ title, description, actions }: { title: string; description?: string; actions?: ReactNode }) {
  return (
    <header className="page__head">
      <div className="page__head-row">
        <div style={{ minWidth: 0 }}>
          <h1 className="page__title">{title}</h1>
          {description && <p className="page__desc">{description}</p>}
        </div>
        {actions && <div className="page__actions">{actions}</div>}
      </div>
    </header>
  )
}
