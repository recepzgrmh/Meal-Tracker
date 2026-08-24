import { useState } from 'react'
import { RotateCcw } from 'lucide-react'
import { formatMs, formatUsd, formatWhen } from '../data'
import { fetchEvalCases, fetchEvalRuns, type EvalCaseRow, type EvalRunRow } from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import {
  Badge, Button, Card, DataTable, DefinitionList, Drawer, EmptyState, Metric, Metrics,
  TableSkeleton, type Column,
} from '../ui'
import { Boundary, MetricsSkeleton } from './Boundary'
import { PageHeader, type PageProps } from './shared'

const num = (value: unknown): number | null =>
  typeof value === 'number' && Number.isFinite(value) ? value : null

const pct = (value: number) => `${(value * 100).toFixed(1)}%`

const passRate = (run: EvalRunRow) =>
  run.case_count > 0 ? run.passed_count / run.case_count : 0

/** The report's most decision-relevant numbers, whichever runner wrote them. */
function headline(run: EvalRunRow): string {
  const metrics = run.metrics ?? {}
  const parts: string[] = []
  const f1 = num(metrics.foodIdentityF1) ?? num(metrics.identityExactAccuracy)
  if (f1 != null) parts.push(`F1 ${pct(f1)}`)
  const mape = num(metrics.portionMape)
  if (mape != null) parts.push(`MAPE ${pct(mape)}`)
  const noMatch = num(metrics.noMatchSpecificity) ?? num(metrics.noMatchAccuracy)
  if (noMatch != null) parts.push(`NM ${pct(noMatch)}`)
  const p95 = num(metrics.latencyP95Ms)
  if (p95 != null) parts.push(`p95 ${formatMs(p95)}`)
  return parts.join(' · ') || '—'
}

export function Evals({ t }: PageProps) {
  const runs = useQuery(() => fetchEvalRuns(), [])
  const [selected, setSelected] = useState<EvalRunRow | null>(null)

  return (
    <div className="page page--wide">
      <PageHeader
        title={t('AI Evals')}
        description={t('Gold-set results the eval runners persisted, run over run.')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={runs.refetch}>{t('Refresh')}</Button>}
      />

      <Boundary
        query={runs}
        t={t}
        skeleton={<MetricsSkeleton />}
        emptyTitle={t('No eval results stored yet')}
        emptyDescription={t('Run `deno task eval -- --persist`, or the live eval with service credentials, and results land here.')}
      >
        {(rows) => {
          const latest = rows[0]
          const liveSpend = rows.reduce((sum, row) => sum + Number(row.cost_micros ?? 0), 0)

          const columns: Array<Column<EvalRunRow>> = [
            {
              id: 'kind', header: t('Kind'), locked: true, sortValue: (row) => row.kind,
              cell: (row) => <Badge tone={row.kind === 'live' ? 'warn' : 'info'}>{t(row.kind)}</Badge>,
            },
            {
              id: 'suite', header: t('Suite'), sortValue: (row) => row.suite,
              cell: (row) => (
                <span className="ds-table__primary">
                  <span className="ds-table__primary-text">
                    <strong>{row.suite}</strong>
                    <small>{row.git_ref ?? '—'}</small>
                  </span>
                </span>
              ),
            },
            {
              id: 'pass', header: t('Pass rate'), align: 'end', sortValue: passRate,
              cell: (row) => (
                <span className="ds-row" style={{ justifyContent: 'flex-end' }}>
                  <span className="tnum">{row.passed_count}/{row.case_count}</span>
                  <Badge tone={passRate(row) >= 1 ? 'ok' : passRate(row) >= 0.9 ? 'warn' : 'danger'} dot>
                    {pct(passRate(row))}
                  </Badge>
                </span>
              ),
            },
            {
              id: 'version', header: t('Version'), sortValue: (row) => `${row.model}${row.prompt_version}`,
              cell: (row) => (
                <span className="ds-table__primary-text">
                  <strong>{row.prompt_version ?? '—'}</strong>
                  <small>{row.model ?? '—'}</small>
                </span>
              ),
            },
            { id: 'headline', header: t('Headline metrics'), cell: (row) => <span className="tnum">{headline(row)}</span> },
            {
              id: 'cost', header: t('Cost'), align: 'end', sortValue: (row) => row.cost_micros ?? 0,
              cell: (row) => <span className="tnum">{row.cost_micros == null ? '—' : formatUsd(Number(row.cost_micros))}</span>,
            },
            { id: 'created', header: t('Created'), sortValue: (row) => row.created_at, cell: (row) => <span className="ds-muted">{formatWhen(row.created_at)}</span> },
          ]

          return (
            <>
              <Metrics>
                <Metric label={t('Eval runs')} value={String(rows.length)} footnote={`${rows.filter((row) => row.kind === 'live').length} ${t('live')}`} />
                <Metric label={t('Latest pass rate')} value={latest ? pct(passRate(latest)) : '—'} footnote={latest ? `${latest.passed_count}/${latest.case_count} · ${latest.suite}` : undefined} />
                <Metric label={t('Latest headline')} value={latest ? headline(latest) : '—'} footnote={latest ? t(latest.kind) : undefined} />
                <Metric label={t('Recorded eval spend')} value={formatUsd(liveSpend)} footnote={t('live runs only')} />
              </Metrics>

              <Card flush title={t('Eval runs')} subtitle={t('Select a run to review its failed cases')}>
                <DataTable<EvalRunRow>
                  caption={t('Eval runs')}
                  rows={rows}
                  columns={columns}
                  rowKey={(row) => row.id}
                  onRowClick={setSelected}
                  pageSize={12}
                />
              </Card>
            </>
          )
        }}
      </Boundary>

      {selected && <EvalRunDrawer run={selected} onClose={() => setSelected(null)} t={t} />}
    </div>
  )
}

function EvalRunDrawer({ run, onClose, t }: { run: EvalRunRow; onClose: () => void; t: PageProps['t'] }) {
  const cases = useQuery(() => fetchEvalCases(run.id), [run.id])

  return (
    <Drawer open onClose={onClose} wide title={`${t(run.kind)} · ${run.suite}`} description={run.id}>
      <section className="catalog-detail-section">
        <h3>{t('Eval run')}</h3>
        <DefinitionList rows={[
          [t('Pass rate'), `${run.passed_count}/${run.case_count} (${pct(passRate(run))})`],
          [t('Model'), run.model ?? '—'],
          [t('Prompt'), run.prompt_version ?? '—'],
          [t('Git ref'), <code className="ds-mono" key="ref">{run.git_ref ?? '—'}</code>],
          [t('Started'), new Date(run.started_at).toLocaleString()],
          [t('Completed'), new Date(run.finished_at).toLocaleString()],
          [t('Cost'), run.cost_micros == null ? '—' : formatUsd(Number(run.cost_micros))],
          [t('Notes'), run.notes ?? '—'],
        ]} />
      </section>

      <section className="catalog-detail-section">
        <h3>{t('Report metrics')}</h3>
        <DefinitionList rows={Object.entries(run.metrics ?? {}).map(([key, value]) => (
          [key, <span className="tnum" key={key}>{value == null ? '—' : String(value)}</span>]
        ))} />
      </section>

      <section className="catalog-detail-section">
        <h3>{t('Failed cases')}</h3>
        {cases.loading ? <TableSkeleton rows={4} columns={2} /> : cases.error ? (
          <EmptyState
            tone="danger"
            title={t('Eval cases could not be loaded')}
            actions={<Button onClick={cases.refetch}>{t('Try again')}</Button>}
          />
        ) : <FailedCases rows={(cases.data ?? []).filter((row) => !row.passed)} t={t} />}
      </section>
    </Drawer>
  )
}

function FailedCases({ rows, t }: { rows: EvalCaseRow[]; t: PageProps['t'] }) {
  if (rows.length === 0) {
    return <EmptyState title={t('All cases passed')} description={t('Nothing to triage in this run.')} />
  }
  return (
    <div className="ds-stack">
      {rows.map((row) => (
        <Card
          key={row.id}
          title={row.case_id}
          subtitle={row.latency_ms == null ? undefined : formatMs(row.latency_ms)}
          actions={row.failure_kind ? <Badge tone="danger" dot>{row.failure_kind}</Badge> : undefined}
        >
          <DefinitionList rows={[
            [t('Expected'), <pre className="ds-mono" key="expected" style={{ margin: 0, whiteSpace: 'pre-wrap' }}>{JSON.stringify(row.expected, null, 2)}</pre>],
            [t('Actual'), <pre className="ds-mono" key="actual" style={{ margin: 0, whiteSpace: 'pre-wrap' }}>{JSON.stringify(row.actual, null, 2)}</pre>],
          ]} />
        </Card>
      ))}
    </div>
  )
}
