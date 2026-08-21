import { RotateCcw } from 'lucide-react'
import { formatCompact, formatDay, formatInt, formatUsd } from '../data'
import { fetchAnalysisDaily, fetchCategoryQuality } from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import { BarChart, Button, Card, ChartContainer, Donut, LineChart, Metric, Metrics, Section } from '../ui'
import { Boundary, MetricsSkeleton } from './Boundary'
import { PageHeader, type PageProps } from './shared'
import { summarize } from './Overview'

const RANGE_DAYS: Record<string, number> = { '24h': 1, '7d': 7, '30d': 30, '90d': 90 }

export function Analytics({ range, t }: PageProps) {
  const days = RANGE_DAYS[range] ?? 30
  const daily = useQuery(() => fetchAnalysisDaily(days), [days])
  const categories = useQuery(() => fetchCategoryQuality(10), [])

  return (
    <div className="page">
      <PageHeader
        title={t('Analytics')}
        description={t('Volume, token spend and what people actually log')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={() => { daily.refetch(); categories.refetch() }}>{t('Refresh')}</Button>}
      />

      <Boundary query={daily} t={t} skeleton={<MetricsSkeleton />} emptyTitle={t('No analyses in this period')}>
        {(rows) => {
          const summary = summarize(rows)
          const labels = rows.map((row) => formatDay(row.day))
          const inputTokens = rows.reduce((sum, row) => sum + Number(row.input_tokens ?? 0), 0)
          const outputTokens = rows.reduce((sum, row) => sum + Number(row.output_tokens ?? 0), 0)
          const withPhoto = rows.reduce((sum, row) => sum + row.with_photo, 0)

          return (
            <>
              <Metrics>
                <Metric label={t('Analyses')} value={formatInt(summary.runs)} footnote={`${summary.completed} ${t('completed')}`} />
                <Metric label={t('Input tokens')} value={formatCompact(inputTokens)} footnote={t('provider reported')} />
                <Metric label={t('Output tokens')} value={formatCompact(outputTokens)} footnote={t('provider reported')} />
                <Metric label={t('Provider cost')} value={formatUsd(summary.costMicros)} footnote={t('estimated')} />
              </Metrics>

              <div className="ds-split">
                <Card>
                  <ChartContainer title={t('Token spend')} subtitle={t('Input and output tokens per day')}>
                    <LineChart
                      ariaLabel={t('Token spend per day')}
                      xLabels={labels}
                      height={216}
                      formatValue={(value) => formatInt(value)}
                      formatTick={(value) => formatCompact(value)}
                      series={[
                        { id: 'in', label: t('Input tokens'), values: rows.map((row) => Number(row.input_tokens ?? 0)), tone: 'primary', area: true },
                        { id: 'out', label: t('Output tokens'), values: rows.map((row) => Number(row.output_tokens ?? 0)), tone: 'neutral' },
                      ]}
                    />
                  </ChartContainer>
                </Card>

                <Card title={t('Input mix')} subtitle={t('How meals reached the analyzer')}>
                  <Donut
                    ariaLabel={t('Input mix')}
                    centerValue={formatCompact(summary.runs)}
                    centerLabel={t('runs')}
                    data={[
                      { label: t('With photo'), value: withPhoto, tone: 'primary' },
                      { label: t('Text only'), value: Math.max(0, summary.runs - withPhoto), tone: 'neutral' },
                    ]}
                  />
                </Card>
              </div>
            </>
          )
        }}
      </Boundary>

      <Section title={t('Most logged foods')} subtitle={t('Ranked by correction rate, so the noisiest sit on top')}>
        <Card>
          <Boundary
            query={categories}
            t={t}
            emptyTitle={t('Not enough logged items')}
            emptyDescription={t('A food needs at least 5 logged items before it appears here.')}
          >
            {(rows) => (
              <ChartContainer subtitle={t('Correction rate per canonical food')}>
                <BarChart
                  ariaLabel={t('Correction rate per canonical food')}
                  height={232}
                  formatValue={(value) => `${Math.round(value)}%`}
                  data={rows.map((row) => ({
                    label: row.canonical_name.length > 12 ? `${row.canonical_name.slice(0, 11)}…` : row.canonical_name,
                    value: row.correction_rate ?? 0,
                    tone: (row.correction_rate ?? 0) >= 20 ? 'danger' : (row.correction_rate ?? 0) >= 10 ? 'warn' : 'primary',
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
