import { RotateCcw } from 'lucide-react'
import { formatCompact, formatInt, formatMs, formatUsd, formatWhen } from '../data'
import { fetchLatencyHistogram, fetchVersions, type VersionRow } from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import {
  Alert, Badge, BarChart, Button, Card, ChartContainer, DataTable, Metric, Metrics, Section,
  type Column,
} from '../ui'
import { Boundary, MetricsSkeleton } from './Boundary'
import { PageHeader, type PageProps } from './shared'

/** Cheapest, fastest and most accurate are rarely the same row — mark each. */
const best = <T,>(rows: T[], value: (row: T) => number | null, direction: 'min' | 'max') => {
  const usable = rows.filter((row) => value(row) != null)
  if (!usable.length) return null
  return usable.reduce((winner, row) =>
    direction === 'min'
      ? (value(row)! < value(winner)! ? row : winner)
      : (value(row)! > value(winner)! ? row : winner))
}

export function Versions({ t }: PageProps) {
  const versions = useQuery(() => fetchVersions(), [])
  const histogram = useQuery(() => fetchLatencyHistogram(), [])

  return (
    <div className="page page--wide">
      <PageHeader
        title={t('Versions')}
        description={t('Did the new prompt actually beat the old one?')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={() => { versions.refetch(); histogram.refetch() }}>{t('Refresh')}</Button>}
      />

      <Boundary
        query={versions}
        t={t}
        skeleton={<MetricsSkeleton />}
        emptyTitle={t('No analysis runs yet')}
        emptyDescription={t('Each model and prompt version appears here once it has served a request.')}
      >
        {(rows) => {
          const fastest = best(rows, (row) => row.p95_latency_ms, 'min')
          const cheapest = best(rows, (row) => row.avg_cost_micros, 'min')
          const mostReliable = best(rows, (row) => row.success_rate, 'max')
          const totalRuns = rows.reduce((sum, row) => sum + row.runs, 0)

          const columns: Array<Column<VersionRow>> = [
            {
              id: 'version', header: t('Version'), locked: true, sortValue: (row) => `${row.model_name}${row.prompt_version}`,
              cell: (row) => (
                <span className="ds-table__primary">
                  <span className="ds-table__primary-text">
                    <strong>{row.prompt_version}</strong>
                    <small>{row.model_name}</small>
                  </span>
                </span>
              ),
            },
            { id: 'runs', header: t('Runs'), align: 'end', sortValue: (row) => row.runs, cell: (row) => <span className="tnum">{formatInt(row.runs)}</span> },
            {
              id: 'success', header: t('Success'), align: 'end', sortValue: (row) => row.success_rate ?? 0,
              cell: (row) => (
                <span className="ds-row" style={{ justifyContent: 'flex-end' }}>
                  <span className="tnum">{(row.success_rate ?? 0).toFixed(1)}%</span>
                  {row === mostReliable && rows.length > 1 && <Badge tone="ok" dot>{t('best')}</Badge>}
                </span>
              ),
            },
            { id: 'p50', header: 'p50', align: 'end', sortValue: (row) => row.p50_latency_ms ?? 0, cell: (row) => <span className="tnum">{formatMs(row.p50_latency_ms)}</span> },
            {
              id: 'p95', header: 'p95', align: 'end', sortValue: (row) => row.p95_latency_ms ?? 0,
              cell: (row) => (
                <span className="ds-row" style={{ justifyContent: 'flex-end' }}>
                  <span className="tnum">{formatMs(row.p95_latency_ms)}</span>
                  {row === fastest && rows.length > 1 && <Badge tone="ok" dot>{t('best')}</Badge>}
                </span>
              ),
            },
            { id: 'p99', header: 'p99', align: 'end', defaultHidden: true, sortValue: (row) => row.p99_latency_ms ?? 0, cell: (row) => <span className="tnum">{formatMs(row.p99_latency_ms)}</span> },
            {
              id: 'cost', header: t('Cost / run'), align: 'end', sortValue: (row) => row.avg_cost_micros ?? 0,
              cell: (row) => (
                <span className="ds-row" style={{ justifyContent: 'flex-end' }}>
                  <span className="tnum">{row.avg_cost_micros == null ? '—' : formatUsd(Number(row.avg_cost_micros))}</span>
                  {row === cheapest && rows.length > 1 && <Badge tone="ok" dot>{t('best')}</Badge>}
                </span>
              ),
            },
            { id: 'tokens', header: t('Tokens'), align: 'end', defaultHidden: true, cell: (row) => <span className="tnum">{formatCompact(Number(row.input_tokens) + Number(row.output_tokens))}</span> },
            { id: 'cache', header: t('Cache hit'), align: 'end', sortValue: (row) => row.cache_hit_rate ?? 0, cell: (row) => <span className="tnum">{row.cache_hit_rate == null ? '—' : `${row.cache_hit_rate}%`}</span> },
            { id: 'retry', header: t('Retry'), align: 'end', sortValue: (row) => row.retry_rate ?? 0, cell: (row) => <span className={`tnum${(row.retry_rate ?? 0) > 10 ? ' ds-text-warn' : ''}`}>{(row.retry_rate ?? 0).toFixed(1)}%</span> },
            { id: 'fallback', header: t('Vision fallback'), align: 'end', defaultHidden: true, cell: (row) => <span className="tnum">{(row.vision_fallback_rate ?? 0).toFixed(1)}%</span> },
            { id: 'last', header: t('Last seen'), sortValue: (row) => row.last_seen, cell: (row) => <span className="ds-muted">{formatWhen(row.last_seen)}</span> },
          ]

          return (
            <>
              <Metrics>
                <Metric label={t('Versions in play')} value={String(rows.length)} footnote={`${formatInt(totalRuns)} ${t('runs total')}`} />
                <Metric label={t('Fastest p95')} value={formatMs(fastest?.p95_latency_ms ?? null)} footnote={fastest?.prompt_version} />
                <Metric label={t('Cheapest per run')} value={cheapest?.avg_cost_micros == null ? '—' : formatUsd(Number(cheapest.avg_cost_micros))} footnote={cheapest?.prompt_version} />
                <Metric label={t('Most reliable')} value={`${(mostReliable?.success_rate ?? 0).toFixed(1)}%`} footnote={mostReliable?.prompt_version} />
              </Metrics>

              {rows.length === 1 && (
                <Alert tone="info" title={t('Only one version has run so far')}>
                  {t('Ship a second prompt or model version and this table becomes a side-by-side comparison.')}
                </Alert>
              )}

              <Card flush title={t('Version comparison')} subtitle={t('Every model and prompt version that has served a request')}>
                <DataTable<VersionRow>
                  caption={t('Model and prompt version comparison')}
                  rows={rows}
                  columns={columns}
                  rowKey={(row) => `${row.model_name}::${row.prompt_version}`}
                  pageSize={12}
                />
              </Card>
            </>
          )
        }}
      </Boundary>

      <Section title={t('Latency distribution')} subtitle={t('Where analysis time actually lands, in one-second buckets')}>
        <Card>
          <Boundary
            query={histogram}
            t={t}
            emptyTitle={t('No completed runs yet')}
            emptyDescription={t('Latency is recorded when an analysis finishes.')}
          >
            {(rows) => (
              <ChartContainer>
                <BarChart
                  ariaLabel={t('Latency distribution')}
                  height={216}
                  formatValue={(value) => formatInt(value)}
                  data={rows.map((row) => ({
                    label: row.bucket_floor_ms >= 15000 ? '15s+' : `${row.bucket_floor_ms / 1000}s`,
                    value: row.runs,
                    tone: row.bucket_floor_ms >= 6000 ? 'danger' : row.bucket_floor_ms >= 3000 ? 'warn' : 'primary',
                  }))}
                />
              </ChartContainer>
            )}
          </Boundary>
        </Card>
      </Section>
    </div>
  )
}
