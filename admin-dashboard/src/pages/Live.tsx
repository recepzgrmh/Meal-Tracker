import { useEffect, useState } from 'react'
import { RotateCcw } from 'lucide-react'
import { formatInt, formatMs, formatWhen, shortId } from '../data'
import {
  fetchRecentRuns, fetchStuckRuns, fetchUncommittedRuns,
  type StuckRunRow, type TraceRow, type UncommittedRunRow,
} from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import { useSession } from '../lib/session'
import {
  Alert, Badge, Button, Card, DataTable, Metric, Metrics, Section, Switch, type Column,
} from '../ui'
import { Boundary, MetricsSkeleton } from './Boundary'
import { PageHeader, type PageProps } from './shared'

const STATUS_TONE: Record<string, 'ok' | 'warn' | 'danger' | 'neutral'> = {
  completed: 'ok', needs_review: 'warn', failed: 'danger', running: 'neutral', pending: 'neutral',
}

const REFRESH_MS = 5000

export function Live({ route, navigate, t }: PageProps) {
  const { session } = useSession()
  const mine = route.scope === 'mine'
  const [following, setFollowing] = useState(true)

  const recent = useQuery(() => fetchRecentRuns(25, mine ? session?.user.id : undefined), [mine, session?.user.id])
  const stuck = useQuery(() => fetchStuckRuns(), [])
  const uncommitted = useQuery(() => fetchUncommittedRuns(), [])

  // Polling, not Realtime: these are plain selects over views, and a five second
  // beat is enough to watch a device hit the pipeline without a socket.
  useEffect(() => {
    if (!following) return
    const timer = window.setInterval(() => { recent.refetch(); stuck.refetch() }, REFRESH_MS)
    return () => window.clearInterval(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [following])

  const runColumns: Array<Column<TraceRow>> = [
    { id: 'when', header: t('When'), locked: true, cell: (row) => <span className="ds-muted">{formatWhen(row.created_at)}</span> },
    {
      id: 'status', header: t('Status'),
      cell: (row) => <Badge tone={STATUS_TONE[row.status] ?? 'neutral'} dot>{t(row.status)}</Badge>,
    },
    { id: 'input', header: t('Input'), cell: (row) => <span className="ds-muted">{row.input_kind}</span> },
    {
      id: 'raw', header: t('Text'),
      cell: (row) => <span className="ds-muted" style={{ maxWidth: '18rem', display: 'inline-block', overflow: 'hidden', textOverflow: 'ellipsis' }}>{row.raw_input}</span>,
    },
    {
      id: 'latency', header: t('Duration'), align: 'end',
      cell: (row) => <span className={row.latency_ms && row.latency_ms > 6000 ? 'ds-text-danger tnum' : 'tnum'}>{formatMs(row.latency_ms)}</span>,
    },
    { id: 'model', header: t('Model'), defaultHidden: true, cell: (row) => <span className="ds-muted">{row.model_name ?? '—'}</span> },
    { id: 'error', header: t('Error'), cell: (row) => row.error_code ? <code className="ds-mono ds-text-danger">{row.error_code}</code> : <span className="ds-faint">—</span> },
  ]

  return (
    <div className="page page--wide">
      <PageHeader
        title={t('Live')}
        description={t('Watch the pipeline while you test the app')}
        actions={<>
          <label className="ds-row" style={{ gap: 'var(--sp-2)' }}>
            <span className="ds-meta">{t('Follow')}</span>
            <Switch checked={following} onChange={setFollowing} label={t('Follow new runs')} />
          </label>
          <Button icon={<RotateCcw size={14} />} onClick={() => { recent.refetch(); stuck.refetch(); uncommitted.refetch() }}>{t('Refresh')}</Button>
        </>}
      />

      <div className="ds-row ds-row--wrap">
        <Badge tone={following ? 'ok' : 'neutral'} dot>
          {following ? `${t('Following')} · ${REFRESH_MS / 1000}s` : t('Paused')}
        </Badge>
        {mine && <Badge tone="accent">{t('Only my runs')}</Badge>}
      </div>

      <Boundary
        query={recent}
        t={t}
        skeleton={<MetricsSkeleton count={3} />}
        emptyTitle={mine ? t('You have no runs yet') : t('No runs yet')}
        emptyDescription={t('Log a meal from the app and it lands here within seconds.')}
      >
        {(rows) => {
          const failed = rows.filter((row) => row.status === 'failed').length
          const slowest = rows.reduce((worst, row) => Math.max(worst, row.latency_ms ?? 0), 0)
          return (
            <Metrics>
              <Metric label={t('Recent runs')} value={String(rows.length)} footnote={t('newest first')} />
              <Metric label={t('Failed')} value={String(failed)} badge={failed > 0 ? <Badge tone="danger" dot>{t('check errors')}</Badge> : undefined} footnote={t('in this window')} />
              <Metric label={t('Slowest')} value={formatMs(slowest || null)} footnote={t('in this window')} />
              <Metric label={t('Last run')} value={formatWhen(rows[0]?.created_at ?? null)} footnote={rows[0]?.model_name ?? '—'} />
            </Metrics>
          )
        }}
      </Boundary>

      <Card flush title={t('Recent runs')} subtitle={t('The last 25 analyses, newest first')}>
        <Boundary query={recent} t={t} emptyTitle={t('No runs yet')}>
          {(rows) => (
            <DataTable<TraceRow>
              caption={t('Recent analysis runs')}
              rows={rows}
              columns={runColumns}
              rowKey={(row) => row.id}
              onRowClick={(row) => navigate({ page: 'traces', traceId: row.trace_id })}
              pageSize={25}
            />
          )}
        </Boundary>
      </Card>

      <Section title={t('Stuck runs')} subtitle={t('Still pending or running after five minutes — usually a crashed or timed-out function')}>
        <Card flush>
          <Boundary
            query={stuck}
            t={t}
            emptyTitle={t('Nothing is stuck')}
            emptyDescription={t('Every run has reached a terminal state.')}
          >
            {(rows) => (
              <>
                <Alert tone="warn" title={`${rows.length} ${t('stuck')}`}>
                  {t('These never reached completed or failed, so they are invisible to the success rate.')}
                </Alert>
                <DataTable<StuckRunRow>
                  caption={t('Stuck analysis runs')}
                  rows={rows}
                  columns={[
                    { id: 'trace', header: t('Trace'), locked: true, cell: (row) => <code className="ds-mono">{row.trace_id.slice(0, 8)}</code> },
                    { id: 'status', header: t('Status'), cell: (row) => <Badge tone="warn" dot>{t(row.status)}</Badge> },
                    { id: 'age', header: t('Stuck for'), align: 'end', sortValue: (row) => row.age_seconds, cell: (row) => <span className="tnum">{Math.round(row.age_seconds / 60)} {t('min')}</span> },
                    { id: 'kind', header: t('Input'), cell: (row) => <span className="ds-muted">{row.input_kind}</span> },
                    { id: 'model', header: t('Model'), cell: (row) => <span className="ds-muted">{row.model_name ?? '—'}</span> },
                    { id: 'user', header: t('User'), defaultHidden: true, cell: (row) => <code className="ds-mono ds-muted">{shortId(row.user_id)}</code> },
                    { id: 'created', header: t('Started'), cell: (row) => <span className="ds-muted">{formatWhen(row.created_at)}</span> },
                  ]}
                  rowKey={(row) => row.id}
                  onRowClick={(row) => navigate({ page: 'traces', traceId: row.trace_id })}
                />
              </>
            )}
          </Boundary>
        </Card>
      </Section>

      <Section title={t('Abandoned analyses')} subtitle={t('Analysis succeeded but no meal was ever committed from it')}>
        <Card flush>
          <Boundary
            query={uncommitted}
            t={t}
            emptyTitle={t('Every analysis became a meal')}
            emptyDescription={t('Nothing was abandoned after a successful analysis.')}
          >
            {(rows) => (
              <DataTable<UncommittedRunRow>
                caption={t('Analyses that never became a meal')}
                rows={rows}
                columns={[
                  { id: 'trace', header: t('Trace'), locked: true, cell: (row) => <code className="ds-mono">{row.trace_id.slice(0, 8)}</code> },
                  { id: 'raw', header: t('Text'), cell: (row) => <span className="ds-muted" style={{ maxWidth: '20rem', display: 'inline-block', overflow: 'hidden', textOverflow: 'ellipsis' }}>{row.raw_input}</span> },
                  { id: 'items', header: t('Proposed'), align: 'end', sortValue: (row) => row.proposed_items, cell: (row) => <span className="tnum">{formatInt(row.proposed_items)}</span> },
                  { id: 'latency', header: t('Duration'), align: 'end', cell: (row) => <span className="tnum">{formatMs(row.latency_ms)}</span> },
                  { id: 'when', header: t('When'), sortValue: (row) => row.created_at, cell: (row) => <span className="ds-muted">{formatWhen(row.created_at)}</span> },
                ]}
                rowKey={(row) => row.id}
                onRowClick={(row) => navigate({ page: 'traces', traceId: row.trace_id })}
                pageSize={10}
              />
            )}
          </Boundary>
        </Card>
      </Section>
    </div>
  )
}
