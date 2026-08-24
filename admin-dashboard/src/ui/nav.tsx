import { ChevronLeft, ChevronRight } from 'lucide-react'
import type { ReactNode } from 'react'

const cx = (...parts: Array<string | false | undefined | null>) => parts.filter(Boolean).join(' ')

/* ── Tabs — underline, for switching what the page shows ─────────────────── */

export type TabItem = { id: string; label: string; count?: number | string; icon?: ReactNode }

export function Tabs({ items, value, onChange, label }: {
  items: TabItem[]; value: string; onChange: (id: string) => void; label: string
}) {
  const onKeyDown = (event: React.KeyboardEvent) => {
    const index = items.findIndex((item) => item.id === value)
    if (event.key === 'ArrowRight') { event.preventDefault(); onChange(items[(index + 1) % items.length].id) }
    if (event.key === 'ArrowLeft') { event.preventDefault(); onChange(items[(index - 1 + items.length) % items.length].id) }
  }
  return (
    <div className="ds-tabs" role="tablist" aria-label={label} onKeyDown={onKeyDown}>
      {items.map((item) => (
        <button
          key={item.id}
          type="button"
          role="tab"
          aria-selected={item.id === value}
          tabIndex={item.id === value ? 0 : -1}
          className="ds-tabs__item"
          onClick={() => onChange(item.id)}
        >
          {item.icon}
          {item.label}
          {/* Decorative reinforcement — the tab's accessible name stays the label alone. */}
          {item.count !== undefined && <span className="ds-tabs__count" aria-hidden="true">{item.count}</span>}
        </button>
      ))}
    </div>
  )
}

/* ── Segmented control — for switching how the same thing is shown ───────── */

export function Segmented({ items, value, onChange, label }: {
  items: Array<{ id: string; label: string; icon?: ReactNode }>; value: string; onChange: (id: string) => void; label: string
}) {
  return (
    <div className="ds-segmented" role="group" aria-label={label}>
      {items.map((item) => (
        <button
          key={item.id}
          type="button"
          aria-pressed={item.id === value}
          className="ds-segmented__item"
          onClick={() => onChange(item.id)}
        >
          {item.icon}
          {item.label}
        </button>
      ))}
    </div>
  )
}

/* ── Breadcrumb — answers "where am I", lives in the top bar ─────────────── */

export type Crumb = { label: string; onClick?: () => void }

export function Breadcrumb({ items }: { items: Crumb[] }) {
  return (
    <nav className="ds-crumbs" aria-label="Breadcrumb">
      {items.map((item, index) => {
        const last = index === items.length - 1
        return (
          <span key={`${item.label}-${index}`} className="ds-row" style={{ minWidth: 0, gap: '.25rem' }}>
            {index > 0 && <ChevronRight size={13} className="ds-crumbs__sep" aria-hidden="true" />}
            {item.onClick && !last
              ? <button type="button" className="ds-crumbs__item" onClick={item.onClick}>{item.label}</button>
              : <span className="ds-crumbs__item" aria-current={last ? 'page' : undefined}>{item.label}</span>}
          </span>
        )
      })}
    </nav>
  )
}

/* ── Pagination ──────────────────────────────────────────────────────────── */

export function Pagination({ page, pageCount, total, pageSize, onPage, labels }: {
  page: number; pageCount: number; total: number; pageSize: number; onPage: (next: number) => void
  labels?: { previous: string; next: string; range: (from: number, to: number, total: number) => string }
}) {
  const from = total === 0 ? 0 : (page - 1) * pageSize + 1
  const to = Math.min(page * pageSize, total)
  const text = labels?.range ?? ((a: number, b: number, c: number) => `${a}–${b} of ${c}`)

  // Windowed page numbers so long lists stay one row.
  const pages: Array<number | '…'> = []
  for (let index = 1; index <= pageCount; index += 1) {
    if (index === 1 || index === pageCount || Math.abs(index - page) <= 1) pages.push(index)
    else if (pages[pages.length - 1] !== '…') pages.push('…')
  }

  return (
    <div className="ds-pagination">
      <span className="ds-pagination__info">{text(from, to, total)}</span>
      <div className="ds-pagination__nav">
        <button type="button" className="ds-pagination__page" disabled={page <= 1} aria-label={labels?.previous ?? 'Previous page'} onClick={() => onPage(page - 1)}>
          <ChevronLeft size={14} />
        </button>
        {pages.map((entry, index) =>
          entry === '…'
            ? <span key={`gap-${index}`} className="ds-pagination__info" aria-hidden="true">…</span>
            : <button key={entry} type="button" className="ds-pagination__page" aria-current={entry === page ? 'page' : undefined} onClick={() => onPage(entry)}>{entry}</button>,
        )}
        <button type="button" className="ds-pagination__page" disabled={page >= pageCount} aria-label={labels?.next ?? 'Next page'} onClick={() => onPage(page + 1)}>
          <ChevronRight size={14} />
        </button>
      </div>
    </div>
  )
}

/* ── Filter chips ────────────────────────────────────────────────────────── */

export function FilterChip({ name, value, onRemove }: { name: string; value: string; onRemove: () => void }) {
  return (
    <span className="ds-chip">
      {name}: <b>{value}</b>
      <button type="button" className="ds-chip__x" aria-label={`Remove filter ${name}: ${value}`} onClick={onRemove}>
        <svg width="9" height="9" viewBox="0 0 9 9" aria-hidden="true"><path d="M1 1l7 7M8 1l-7 7" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" /></svg>
      </button>
    </span>
  )
}

export const Chips = ({ children }: { children: ReactNode }) => <div className="ds-chips">{children}</div>

export const cxq = cx
