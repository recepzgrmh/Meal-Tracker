import { useState } from 'react'
import { ArrowLeft, RotateCcw } from 'lucide-react'
import { formatMs, formatUsd, formatWhen, shortId } from '../data'
import { fetchTrace, fetchTraceCandidates, fetchTraces, type TraceFilter, type TraceRow } from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import {
  Alert, Badge, Button, Card, DataTable, DefinitionList, Metric, Metrics, Section, Segmented,
  Tabs, type Column,
} from '../ui'
import { Boundary, MetricsSkeleton } from './Boundary'
import { PageHeader, type PageProps } from './shared'

const RANGE_DAYS: Record<string, number> = { '24h': 1, '7d': 7, '30d': 30, '90d': 90 }

const STATUS_TONE: Record<string, 'ok' | 'warn' | 'danger' | 'neutral'> = {
  completed: 'ok', needs_review: 'warn', failed: 'danger', running: 'neutral', pending: 'neutral',
}

export function Traces({ route, navigate, range, t }: PageProps) {
  const days = RANGE_DAYS[range] ?? 30
  const [filter, setFilter] = useState<TraceFilter>((route.filter as TraceFilter) ?? 'all')
  const traces = useQuery(() => fetchTraces(filter, days), [filter, days])

  const columns: Array<Column<TraceRow>> = [
    { id: 'trace', header: t('Trace'), locked: true, cell: (row) => <code className="ds-mono">{row.trace_id.slice(0, 8)}</code> },
    { id: 'created', header: t('Started'), sortValue: (row) => row.created_at, cell: (row) => <span className="ds-muted">{formatWhen(row.created_at)}</span> },
    {
      id: 'status', header: t('Status'), sortValue: (row) => row.status,
      cell: (row) => <Badge tone={STATUS_TONE[row.status] ?? 'neutral'} dot>{t(row.status)}</Badge>,
    },
    {
      id: 'latency', header: t('Duration'), align: 'end', sortValue: (row) => row.latency_ms ?? 0,
      cell: (row) => <span className={row.latency_ms && row.latency_ms > 6000 ? 'ds-text-danger tnum' : 'tnum'}>{formatMs(row.latency_ms)}</span>,
    },
    { id: 'kind', header: t('Input'), cell: (row) => <span className="ds-muted">{row.input_kind}</span> },
    { id: 'model', header: t('Model'), cell: (row) => <span className="ds-muted">{row.model_name ?? '—'}</span> },
    { id: 'prompt', header: t('Prompt'), defaultHidden: true, cell: (row) => <span className="ds-muted">{row.prompt_version ?? '—'}</span> },
    { id: 'attempts', header: t('Attempts'), align: 'end', defaultHidden: true, cell: (row) => <span className="tnum">{row.provider_attempts ?? 1}</span> },
    {
      id: 'cost', header: t('Cost'), align: 'end', sortValue: (row) => row.estimated_cost_micros ?? 0,
      cell: (row) => <span className="tnum">{row.estimated_cost_micros == null ? '—' : formatUsd(Number(row.estimated_cost_micros))}</span>,
    },
    { id: 'error', header: t('Error'), cell: (row) => row.error_code ? <code className="ds-mono ds-text-danger">{row.error_code}</code> : <span className="ds-faint">—</span> },
    { id: 'user', header: t('User'), defaultHidden: true, cell: (row) => <code className="ds-mono ds-muted">{shortId(row.user_id)}</code> },
  ]

  return (
    <div className="page page--wide">
      <PageHeader
        title={t('Traces')}
        description={t('Follow every meal analysis through the pipeline')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={traces.refetch}>{t('Refresh')}</Button>}
      />

      <Tabs
        label={t('Trace filter')}
        value={filter}
        onChange={(next) => setFilter(next as TraceFilter)}
        items={[
          { id: 'all', label: t('All statuses') },
          { id: 'errors', label: t('Errors') },
          { id: 'slow', label: t('Slow > 6s') },
          { id: 'retried', label: t('Retried') },
        ]}
      />

      <Card flush>
        <Boundary
          query={traces}
          t={t}
          emptyTitle={t('No traces match')}
          emptyDescription={t('Try a wider status filter or a longer time range.')}
        >
          {(rows) => (
            <DataTable<TraceRow>
              caption={t('Pipeline traces')}
              rows={rows}
              columns={columns}
              rowKey={(row) => row.id}
              onRowClick={(row) => navigate({ page: 'traces', traceId: row.trace_id })}
              pageSize={15}
            />
          )}
        </Boundary>
      </Card>
    </div>
  )
}

/* ── Inspector ───────────────────────────────────────────────────────────── */

export function TraceInspector({ route, navigate, t }: PageProps) {
  const traceId = route.traceId!
  const [format, setFormat] = useState('formatted')
  const trace = useQuery(() => fetchTrace(traceId), [traceId])

  return (
    <div className="page page--wide">
      <div>
        <Button variant="ghost" icon={<ArrowLeft size={14} />} onClick={() => navigate({ page: 'traces' })}>{t('Back to traces')}</Button>
      </div>

      <Boundary
        query={trace}
        t={t}
        isEmpty={(data) => data == null}
        emptyTitle={t('Trace not found')}
        emptyDescription={t('No analysis run carries this trace id.')}
        emptyAction={<Button onClick={() => navigate({ page: 'traces' })}>{t('Back to traces')}</Button>}
        skeleton={<MetricsSkeleton />}
      >
        {(row) => <TraceDetail row={row!} format={format} setFormat={setFormat} t={t} />}
      </Boundary>
    </div>
  )
}

function TraceDetail({ row, format, setFormat, t }: {
  row: TraceRow; format: string; setFormat: (next: string) => void; t: (value: string) => string
}) {
  const candidates = useQuery(() => fetchTraceCandidates(row.id), [row.id])
  const tokens = (row.provider_input_tokens ?? 0) + (row.provider_output_tokens ?? 0)

  return (
    <>
      <PageHeader
        title={`${t('Trace')} ${row.trace_id.slice(0, 8)}`}
        description={`${formatWhen(row.created_at)} · ${shortId(row.user_id)} · ${row.input_kind}`}
        actions={<Badge tone={STATUS_TONE[row.status] ?? 'neutral'} dot>{t(row.status)}</Badge>}
      />

      <Metrics>
        <Metric label={t('Duration')} value={formatMs(row.latency_ms)} footnote={row.completed_at ? t('completed') : t('not completed')} />
        <Metric label={t('Attempts')} value={String(row.provider_attempts ?? 1)} footnote={row.retrieval_cache_hit ? t('cache hit') : t('cache miss')} />
        <Metric label={t('Tokens')} value={tokens ? String(tokens) : '—'} footnote={`${row.provider_input_tokens ?? 0} ${t('in')} · ${row.provider_output_tokens ?? 0} ${t('out')}`} />
        <Metric label={t('Cost')} value={row.estimated_cost_micros == null ? '—' : formatUsd(Number(row.estimated_cost_micros))} footnote={t('estimated')} />
      </Metrics>

      {row.error_code && (
        <Alert tone="danger" title={row.error_code}>
          {row.error_detail ?? t('No further detail was recorded.')}
        </Alert>
      )}

      <div className="ds-grid-2">
        <Card title={t('Run context')} subtitle={t('Versioned metadata for reproduction')}>
          <DefinitionList rows={[
            [t('Trace id'), <code className="ds-mono" key="t">{row.trace_id}</code>],
            [t('Model'), row.model_name ?? '—'],
            [t('Prompt'), row.prompt_version ?? '—'],
            [t('Retrieval'), row.retrieval_version ?? '—'],
            [t('Input kind'), row.input_kind],
            [t('Vision fallback'), row.vision_fallback_reason ?? t('none')],
            [t('Started'), new Date(row.created_at).toLocaleString()],
            [t('Completed'), row.completed_at ? new Date(row.completed_at).toLocaleString() : '—'],
          ]} />
        </Card>

        <Card
          title={t('Model output')}
          subtitle={t('Exactly what the run recorded')}
          actions={
            <Segmented
              label={t('Output format')}
              value={format}
              onChange={setFormat}
              items={[{ id: 'formatted', label: t('Input') }, { id: 'raw', label: t('Raw JSON') }]}
            />
          }
        >
          {format === 'raw' ? (
            <pre className="ds-mono" style={{ background: 'var(--surface-sunk)', border: '1px solid var(--border)', borderRadius: 'var(--r-2)', padding: '.875rem', overflow: 'auto', maxHeight: '22rem' }}>
              {JSON.stringify(row.output ?? {}, null, 2)}
            </pre>
          ) : (
            <blockquote style={{ fontSize: 'var(--fs-sm)', lineHeight: 1.6, color: 'var(--text-2)' }}>“{row.raw_input}”</blockquote>
          )}
        </Card>
      </div>

      <Section title={t('Retrieval candidates')} subtitle={t('What the retriever surfaced, and which one the run chose')}>
        <Card flush>
          <Boundary
            query={candidates}
            t={t}
            emptyTitle={t('No candidates recorded')}
            emptyDescription={t('This run did not store retrieval candidates.')}
          >
            {(rows) => (
              <div style={{ padding: 'var(--sp-4)' }} className="ds-stack ds-stack--sm">
                {rows.map((candidate) => (
                  <div className={`candidate${candidate.selected ? ' is-selected' : ''}`} key={candidate.id}>
                    <span className="candidate__rank">{candidate.rank}</span>
                    <span className="candidate__name">
                      {candidate.foods?.canonical_name ?? candidate.food_id ?? '—'}
                      <span className="ds-faint"> · {candidate.item_key}</span>
                    </span>
                    <span className="candidate__score">
                      {candidate.rerank_score != null
                        ? Number(candidate.rerank_score).toFixed(3)
                        : candidate.retrieval_score != null ? Number(candidate.retrieval_score).toFixed(3) : '—'}
                    </span>
                    {candidate.selected ? <Badge tone="accent" dot>{t('Selected')}</Badge> : <span />}
                  </div>
                ))}
                {rows.every((candidate) => candidate.rank === 1) && (
                  <Alert tone="warn" title={t('Only the chosen candidate is stored')}>
                    {t('analyze-meal persists one row per item at rank 1, so the runners-up the retriever produced are discarded. Ranking and margin metrics need that changed.')}
                  </Alert>
                )}
              </div>
            )}
          </Boundary>
        </Card>
      </Section>
    </>
  )
}
