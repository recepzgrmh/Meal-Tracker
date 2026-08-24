import { RotateCcw } from 'lucide-react'
import { THRESHOLDS, formatDay, formatInt, formatMs } from '../data'
import { fetchAnalysisDaily, fetchErrorBreakdown } from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import {
  Badge, Bar, Bars, Button, Card, ChartContainer, LineChart, Metric, Metrics, Section,
} from '../ui'
import { Boundary, MetricsSkeleton } from './Boundary'
import { PageHeader, type PageProps } from './shared'
import { summarize } from './Overview'

const RANGE_DAYS: Record<string, number> = { '24h': 1, '7d': 7, '30d': 30, '90d': 90 }

export function Reliability({ range, t }: PageProps) {
  const days = RANGE_DAYS[range] ?? 30
  const daily = useQuery(() => fetchAnalysisDaily(days), [days])
  const errors = useQuery(() => fetchErrorBreakdown(), [])

  return (
    <div className="page">
      <PageHeader
        title={t('Reliability')}
        description={t('Is the meal analysis pipeline healthy?')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={() => { daily.refetch(); errors.refetch() }}>{t('Refresh')}</Button>}
      />

      <Boundary query={daily} t={t} skeleton={<MetricsSkeleton />} emptyTitle={t('No analyses in this period')}>
        {(rows) => {
          const summary = summarize(rows)
          const labels = rows.map((row) => formatDay(row.day))
          const retryRate = summary.runs ? (summary.retried / summary.runs) * 100 : 0

          return (
            <>
              <Metrics>
                <Metric label={t('Requests')} value={formatInt(summary.runs)} footnote={`${formatInt(summary.failed)} ${t('failed')}`} />
                <Metric
                  label={t('Success rate')} value={`${summary.successRate.toFixed(1)}%`}
                  footnote={`${t('target')} ${THRESHOLDS.successRate}%`}
                  badge={summary.successRate < THRESHOLDS.successRate ? <Badge tone="warn" dot>{t('Below target')}</Badge> : undefined}
                />
                <Metric
                  label={t('P95 latency')} value={formatMs(summary.p95)}
                  footnote={`${t('budget')} ${formatMs(THRESHOLDS.p95LatencyMs)}`}
                  badge={summary.p95 != null && summary.p95 > THRESHOLDS.p95LatencyMs ? <Badge tone="danger" dot>{t('Over budget')}</Badge> : undefined}
                />
                <Metric label={t('Retry rate')} value={`${retryRate.toFixed(1)}%`} footnote={`${formatInt(summary.retried)} ${t('runs retried')}`} />
              </Metrics>

              <div className="ds-grid-2">
                <Card>
                  <ChartContainer title={t('Latency')} subtitle={t('Average and P95 per day')}>
                    <LineChart
                      ariaLabel={t('Latency per day')}
                      xLabels={labels}
                      height={196}
                      formatValue={(value) => formatMs(value)}
                      formatTick={(value) => `${(value / 1000).toFixed(1)}s`}
                      series={[
                        { id: 'p95', label: 'P95', values: rows.map((row) => row.p95_latency_ms ?? 0), tone: 'danger', area: true },
                        { id: 'avg', label: t('Average'), values: rows.map((row) => row.avg_latency_ms ?? 0), tone: 'neutral' },
                      ]}
                    />
                  </ChartContainer>
                </Card>

                <Card>
                  <ChartContainer title={t('Failures')} subtitle={t('Failed runs per day')}>
                    <LineChart
                      ariaLabel={t('Failed runs per day')}
                      xLabels={labels}
                      height={196}
                      formatValue={(value) => formatInt(value)}
                      formatTick={(value) => formatInt(value)}
                      series={[{ id: 'failed', label: t('Failed'), values: rows.map((row) => row.failed), tone: 'danger', area: true }]}
                    />
                  </ChartContainer>
                </Card>
              </div>
            </>
          )
        }}
      </Boundary>

      <Section title={t('Error breakdown')} subtitle={t('Grouped by the error code the pipeline recorded')}>
        <Card>
          <Boundary
            query={errors}
            t={t}
            emptyTitle={t('No failures recorded')}
            emptyDescription={t('No analysis run has failed, so there is nothing to break down.')}
          >
            {(rows) => {
              const max = Math.max(...rows.map((row) => row.occurrences), 1)
              return (
                <Bars>
                  {rows.map((row) => (
                    <Bar
                      key={row.error_code}
                      label={row.error_code}
                      value={row.occurrences}
                      max={max}
                      display={formatInt(row.occurrences)}
                      tone={row.occurrences === max ? 'danger' : 'warn'}
                    />
                  ))}
                </Bars>
              )
            }}
          </Boundary>
        </Card>
      </Section>
    </div>
  )
}
