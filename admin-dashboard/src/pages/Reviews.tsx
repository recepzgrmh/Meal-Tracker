import { useState } from 'react'
import { ArrowLeft, ListFilter, Network, RotateCcw } from 'lucide-react'
import { formatInt, formatMs, formatWhen, shortId } from '../data'
import { fetchReviewQueue, type QueueFilter, type QueueRow } from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import {
  Alert, Badge, Button, Card, Checkbox, DataTable, DefinitionList, Drawer, SearchInput, Tabs,
  type Column, type DataTableLabels,
} from '../ui'
import { Boundary } from './Boundary'
import { PageHeader, type PageProps } from './shared'

type Translate = (value: string) => string

export const reviewLabels = (t: Translate): Partial<DataTableLabels> => ({
  selected: (count) => `${count} ${t('selected')}`,
  clearSelection: t('Clear'),
  columns: t('Columns'),
  rowActions: t('Row actions'),
  selectAll: t('Select all rows'),
  selectRow: t('Select row'),
  previous: t('Previous page'),
  next: t('Next page'),
  range: (from, to, total) => `${from}–${to} / ${total}`,
  sortBy: (column) => `${t('Sort by')} ${column}`,
})

const STATUS_TONE: Record<string, 'ok' | 'warn' | 'danger' | 'neutral'> = {
  accepted: 'ok', unreviewed: 'warn', corrected: 'danger', rejected: 'neutral',
}

export const reviewColumns = (t: Translate): Array<Column<QueueRow>> => [
  {
    id: 'item', header: t('Logged item'), locked: true, sortValue: (row) => row.canonical_name,
    cell: (row) => (
      <span className="ds-table__primary">
        <span className="ds-table__primary-text">
          <strong>{row.canonical_name}</strong>
          <small>{row.meal_name}</small>
        </span>
      </span>
    ),
  },
  { id: 'occurred', header: t('Logged'), sortValue: (row) => row.occurred_at, cell: (row) => <span className="ds-muted">{formatWhen(row.occurred_at)}</span> },
  { id: 'portion', header: t('Portion'), cell: (row) => <span className="ds-muted">{row.portion_label} · {Number(row.grams)} g</span> },
  { id: 'calories', header: 'kcal', align: 'end', sortValue: (row) => Number(row.calories), cell: (row) => <span className="tnum">{formatInt(Number(row.calories))}</span> },
  {
    id: 'confidence', header: t('Confidence'), align: 'end', sortValue: (row) => row.confidence_pct,
    cell: (row) => (
      <span className="ds-row" style={{ justifyContent: 'flex-end' }}>
        <span className="tnum">{row.confidence_pct}%</span>
        <span className="ds-bar__track" style={{ width: '2.5rem' }} aria-hidden="true">
          <span
            className={`ds-bar__fill ds-bar__fill--${row.confidence_pct >= 88 && row.review_status === 'corrected' ? 'danger' : row.confidence_pct < 80 ? 'warn' : 'ok'}`}
            style={{ width: `${row.confidence_pct}%` }}
          />
        </span>
      </span>
    ),
  },
  { id: 'method', header: t('Match'), defaultHidden: true, cell: (row) => <code className="ds-mono ds-muted">{row.match_method}</code> },
  { id: 'model', header: t('Model'), defaultHidden: true, cell: (row) => <span className="ds-muted">{row.model_name ?? '—'}</span> },
  { id: 'user', header: t('User'), defaultHidden: true, cell: (row) => <code className="ds-mono ds-muted">{shortId(row.user_id)}</code> },
  {
    id: 'corrections', header: t('Corrections'), align: 'end', sortValue: (row) => row.correction_count,
    cell: (row) => <span className="tnum">{row.correction_count || '—'}</span>,
  },
  {
    id: 'status', header: t('Status'), sortValue: (row) => row.review_status,
    cell: (row) => <Badge tone={STATUS_TONE[row.review_status] ?? 'neutral'} dot>{t(row.review_status)}</Badge>,
  },
]

const QUEUES: Array<{ id: QueueFilter; label: string }> = [
  { id: 'unreviewed', label: 'Unreviewed' },
  { id: 'overconfident', label: 'High-confidence mistake' },
  { id: 'low', label: 'Low confidence' },
  { id: 'corrected', label: 'Corrected' },
  { id: 'all', label: 'All items' },
]

export function Reviews({ navigate, t }: PageProps) {
  const [queue, setQueue] = useState<QueueFilter>('unreviewed')
  const [query, setQuery] = useState('')
  const [filters, setFilters] = useState(false)
  const [photoOnly, setPhotoOnly] = useState(false)
  const items = useQuery(() => fetchReviewQueue(queue), [queue])

  return (
    <div className="page page--wide">
      <PageHeader
        title={t('Meal Reviews')}
        description={t('Human-in-the-loop evaluation queue')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={items.refetch}>{t('Refresh')}</Button>}
      />

      <Tabs
        label={t('Queue')}
        value={queue}
        onChange={(next) => setQueue(next as QueueFilter)}
        items={QUEUES.map((entry) => ({ id: entry.id, label: t(entry.label) }))}
      />

      <Card flush>
        <Boundary
          query={items}
          t={t}
          emptyTitle={t('Queue is clear')}
          emptyDescription={t('No logged item matches this queue right now.')}
        >
          {(rows) => {
            const visible = rows
              .filter((row) => (photoOnly ? Boolean(row.image_path) : true))
              .filter((row) => `${row.canonical_name} ${row.meal_name} ${row.match_method}`.toLocaleLowerCase().includes(query.trim().toLocaleLowerCase()))
            return (
              <DataTable<QueueRow>
                caption={t('Meal review queue')}
                rows={visible}
                columns={reviewColumns(t)}
                rowKey={(row) => row.item_id}
                selectable
                onRowClick={(row) => navigate({ page: 'reviews', itemId: row.item_id })}
                labels={reviewLabels(t)}
                toolbar={
                  <>
                    <SearchInput
                      className="ds-toolbar__search"
                      value={query}
                      onValueChange={setQuery}
                      label={t('Search the queue')}
                      placeholder={t('Search food, meal or match method…')}
                    />
                    <Button size="sm" icon={<ListFilter size={13} />} onClick={() => setFilters(true)}>{t('Filters')}</Button>
                    {photoOnly && <Badge tone="accent">{t('Photo only')}</Badge>}
                  </>
                }
                rowMenu={(row) => [
                  { label: t('Open inspector'), onSelect: () => navigate({ page: 'reviews', itemId: row.item_id }) },
                  ...(row.trace_id
                    ? [{ label: t('Open trace'), icon: <Network size={14} />, onSelect: () => navigate({ page: 'traces', traceId: row.trace_id! }) }]
                    : []),
                ]}
                empty={{
                  title: t('Nothing matches'),
                  description: t('Clear the search or widen the filters.'),
                  action: <Button onClick={() => { setQuery(''); setPhotoOnly(false) }}>{t('Reset filters')}</Button>,
                }}
              />
            )
          }}
        </Boundary>
      </Card>

      <Drawer
        open={filters}
        onClose={() => setFilters(false)}
        title={t('Filters')}
        description={t('Narrow the queue without leaving the list')}
        footer={<>
          <Button onClick={() => { setPhotoOnly(false); setQuery('') }}>{t('Clear filters')}</Button>
          <Button variant="primary" onClick={() => setFilters(false)}>{t('Apply')}</Button>
        </>}
      >
        <div className="ds-stack ds-stack--sm">
          <p className="ds-label">{t('Input')}</p>
          <Checkbox checked={photoOnly} onChange={setPhotoOnly} label={t('Photo only')} description={t('Items whose meal has a stored photo')} />
        </div>
        <Alert tone="info" title={t('Server-side filters')}>
          {t('Queue selection runs in Postgres; search and input filters run on the loaded page.')}
        </Alert>
      </Drawer>
    </div>
  )
}

/* ── Inspector ───────────────────────────────────────────────────────────── */

export function MealInspector({ route, navigate, t }: PageProps) {
  const itemId = route.itemId!
  const item = useQuery(async () => {
    const rows = await fetchReviewQueue('all', 500)
    return rows.find((row) => row.item_id === itemId) ?? null
  }, [itemId])

  return (
    <div className="page">
      <div>
        <Button variant="ghost" icon={<ArrowLeft size={14} />} onClick={() => navigate({ page: 'reviews' })}>{t('Back to queue')}</Button>
      </div>

      <Boundary
        query={item}
        t={t}
        isEmpty={(data) => data == null}
        emptyTitle={t('Item not found')}
        emptyDescription={t('This logged item is no longer in the queue.')}
        emptyAction={<Button onClick={() => navigate({ page: 'reviews' })}>{t('Back to queue')}</Button>}
      >
        {(row) => (
          <>
            <PageHeader
              title={row!.canonical_name}
              description={`${row!.meal_name} · ${formatWhen(row!.occurred_at)} · ${shortId(row!.user_id)}`}
              actions={row!.trace_id
                ? <Button icon={<Network size={14} />} onClick={() => navigate({ page: 'traces', traceId: row!.trace_id! })}>{t('Open trace')}</Button>
                : undefined}
            />

            <div className="ds-grid-2">
              <Card title={t('Logged item')} subtitle={t('What the user ended up with')}>
                <DefinitionList rows={[
                  [t('Canonical food'), row!.canonical_name],
                  [t('Portion'), `${row!.portion_label} · ${Number(row!.grams)} g`],
                  [t('Energy'), `${formatInt(Number(row!.calories))} kcal`],
                  [t('Confidence'), `${row!.confidence_pct}%`],
                  [t('Match method'), <code className="ds-mono" key="m">{row!.match_method}</code>],
                  [t('Review status'), <Badge tone={STATUS_TONE[row!.review_status] ?? 'neutral'} dot key="s">{t(row!.review_status)}</Badge>],
                  [t('Corrections'), String(row!.correction_count)],
                ]} />
              </Card>

              <Card title={t('Analysis context')} subtitle={t('Versioned metadata for reproduction')}>
                <DefinitionList rows={[
                  [t('Model'), row!.model_name ?? '—'],
                  [t('Prompt'), row!.prompt_version ?? '—'],
                  [t('Latency'), formatMs(row!.latency_ms)],
                  [t('Trace'), row!.trace_id ? <code className="ds-mono" key="t">{row!.trace_id}</code> : '—'],
                  [t('Meal'), <code className="ds-mono" key="me">{row!.meal_id}</code>],
                ]} />
              </Card>
            </div>

            <Alert tone="info" title={t('Read-only')}>
              {t('Labelling writes are not wired up: the console reads with the operator JWT and never writes user data from the browser.')}
            </Alert>
          </>
        )}
      </Boundary>
    </div>
  )
}
