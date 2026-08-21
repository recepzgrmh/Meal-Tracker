import { AlertCircle, ChevronRight, Gauge, RotateCcw, Utensils } from 'lucide-react'
import {
  THRESHOLDS, formatCompact, formatDay, formatInt, formatMs, formatUsd,
} from '../data'
import { fetchAnalysisDaily, fetchCategoryQuality, fetchCorrectionReasons, type DailyRow } from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import {
  Badge, Bar, Bars, Button, Card, ChartContainer, DefinitionList, LineChart, Metric, Metrics,
  Section, Sparkline,
} from '../ui'
import { Boundary, MetricsSkeleton } from './Boundary'
import { PageHeader, type PageProps } from './shared'

const RANGE_DAYS: Record<string, number> = { '24h': 1, '7d': 7, '30d': 30, '90d': 90 }

export type Summary = {
  runs: number
  completed: number
  failed: number
  successRate: number
  p95: number | null
  costMicros: number
  photoShare: number
  retried: number
}

export function summarize(rows: DailyRow[]): Summary {
  const runs = rows.reduce((sum, row) => sum + row.runs, 0)
  const completed = rows.reduce((sum, row) => sum + row.completed, 0)
  const failed = rows.reduce((sum, row) => sum + row.failed, 0)
  const withPhoto = rows.reduce((sum, row) => sum + row.with_photo, 0)
  const p95s = rows.map((row) => row.p95_latency_ms).filter((value): value is number => value != null)
  return {
    runs,
    completed,
    failed,
    successRate: runs ? (completed / runs) * 100 : 0,
    // The worst day in the window, not an average of percentiles — averaging
    // percentiles is meaningless and would hide the breach we care about.
    p95: p95s.length ? Math.max(...p95s) : null,
    costMicros: rows.reduce((sum, row) => sum + Number(row.cost_micros ?? 0), 0),
    photoShare: runs ? (withPhoto / runs) * 100 : 0,
    retried: rows.reduce((sum, row) => sum + row.retried, 0),
  }
}

export function Overview({ navigate, range, t }: PageProps) {
  const days = RANGE_DAYS[range] ?? 30
  const daily = useQuery(() => fetchAnalysisDaily(days), [days])
  const reasons = useQuery(() => fetchCorrectionReasons(), [])
  const categories = useQuery(() => fetchCategoryQuality(6), [])

  return (
    <div className="page">
      <PageHeader
        title={t('Overview')}
        description={t('Does anything require attention right now?')}
        actions={<>
          <Button icon={<RotateCcw size={14} />} onClick={() => { daily.refetch(); reasons.refetch(); categories.refetch() }}>
            {t('Refresh')}
          </Button>
          <Button variant="primary" onClick={() => navigate({ page: 'reviews' })}>{t('Open review queue')}</Button>
        </>}
      />

      <Boundary
        query={daily}
        t={t}
        skeleton={<MetricsSkeleton />}
        emptyTitle={t('No analyses in this period')}
        emptyDescription={t('Once the mobile app records an analysis run it will appear here.')}
      >
        {(rows) => {
          const summary = summarize(rows)
          const labels = rows.map((row) => formatDay(row.day))
          const costPerAnalysis = summary.completed ? summary.costMicros / 1_000_000 / summary.completed : 0

          const signals = [
            summary.successRate < THRESHOLDS.successRate && {
              icon: AlertCircle, tone: 'danger' as const,
              title: t('Success rate below target'),
              value: `${summary.successRate.toFixed(1)}%`,
              detail: `${formatInt(summary.failed)} ${t('failed runs')} · ${t('target')} ${THRESHOLDS.successRate}%`,
              cta: t('Open reliability'), go: () => navigate({ page: 'reliability' }),
            },
            summary.p95 != null && summary.p95 > THRESHOLDS.p95LatencyMs && {
              icon: Gauge, tone: 'warn' as const,
              title: t('P95 latency above budget'),
              value: formatMs(summary.p95),
              detail: `${t('budget')} ${formatMs(THRESHOLDS.p95LatencyMs)}`,
              cta: t('Inspect slow traces'), go: () => navigate({ page: 'traces', filter: 'slow' }),
            },
            costPerAnalysis > THRESHOLDS.costPerAnalysis && {
              icon: Utensils, tone: 'warn' as const,
              title: t('Cost per analysis above target'),
              value: `$${costPerAnalysis.toFixed(4)}`,
              detail: `${t('target')} $${THRESHOLDS.costPerAnalysis.toFixed(2)}`,
              cta: t('Open analytics'), go: () => navigate({ page: 'analytics' }),
            },
          ].filter(Boolean) as Array<{ icon: typeof Gauge; tone: 'danger' | 'warn'; title: string; value: string; detail: string; cta: string; go: () => void }>

          return (
            <>
              <Metrics>
                <Metric
                  label={t('Analyses')} value={formatInt(summary.runs)}
                  footnote={`${formatInt(summary.completed)} ${t('completed')}`}
                  spark={<Sparkline values={rows.map((row) => row.runs)} ariaLabel={t('Analyses per day')} />}
                />
                <Metric
                  label={t('Success rate')} value={`${summary.successRate.toFixed(1)}%`}
                  footnote={`${t('target')} ${THRESHOLDS.successRate}%`}
                  badge={summary.successRate < THRESHOLDS.successRate ? <Badge tone="warn" dot>{t('Below target')}</Badge> : undefined}
                  spark={<Sparkline
                    values={rows.map((row) => (row.runs ? (row.completed / row.runs) * 100 : 0))}
                    tone={summary.successRate < THRESHOLDS.successRate ? 'warn' : 'primary'}
                    ariaLabel={t('Success rate per day')}
                  />}
                />
                <Metric
                  label={t('P95 latency')} value={formatMs(summary.p95)}
                  footnote={`${t('budget')} ${formatMs(THRESHOLDS.p95LatencyMs)}`}
                  badge={summary.p95 != null && summary.p95 > THRESHOLDS.p95LatencyMs ? <Badge tone="danger" dot>{t('Over budget')}</Badge> : undefined}
                  spark={<Sparkline
                    values={rows.map((row) => row.p95_latency_ms ?? 0)}
                    tone={summary.p95 != null && summary.p95 > THRESHOLDS.p95LatencyMs ? 'danger' : 'primary'}
                    ariaLabel={t('P95 latency per day')}
                  />}
                />
                <Metric
                  label={t('Provider cost')} value={formatUsd(summary.costMicros)}
                  footnote={summary.completed ? `$${costPerAnalysis.toFixed(4)} ${t('per analysis')}` : undefined}
                  spark={<Sparkline values={rows.map((row) => Number(row.cost_micros ?? 0))} ariaLabel={t('Provider cost per day')} />}
                />
              </Metrics>

              <div className="ds-split">
                <Card>
                  <ChartContainer
                    title={t('Analysis volume')}
                    subtitle={t('Completed and failed runs per day')}
                  >
                    <LineChart
                      ariaLabel={t('Analysis volume per day')}
                      xLabels={labels}
                      height={232}
                      formatValue={(value) => formatInt(value)}
                      formatTick={(value) => formatCompact(value)}
                      series={[
                        { id: 'completed', label: t('Completed'), values: rows.map((row) => row.completed), tone: 'primary', area: true },
                        { id: 'failed', label: t('Failed'), values: rows.map((row) => row.failed), tone: 'danger' },
                      ]}
                    />
                  </ChartContainer>
                </Card>

                <div className="ds-stack">
                  <Card title={t('Against thresholds')} subtitle={t('Measured this period')}>
                    <DefinitionList rows={[
                      [t('Success rate'), <ThresholdValue key="s" value={`${summary.successRate.toFixed(1)}%`} ok={summary.successRate >= THRESHOLDS.successRate} t={t} />],
                      [t('P95 latency'), <ThresholdValue key="l" value={formatMs(summary.p95)} ok={summary.p95 == null || summary.p95 <= THRESHOLDS.p95LatencyMs} t={t} />],
                      [t('Cost / analysis'), <ThresholdValue key="c" value={`$${costPerAnalysis.toFixed(4)}`} ok={costPerAnalysis <= THRESHOLDS.costPerAnalysis} t={t} />],
                      [t('Photo input share'), `${summary.photoShare.toFixed(0)}%`],
                      [t('Retried runs'), formatInt(summary.retried)],
                    ]} />
                  </Card>

                  <Card flush title={t('Needs attention')} subtitle={t('Derived from live measurements against the operating thresholds')}>
                    {signals.length === 0 ? (
                      <p className="ds-meta" style={{ padding: 'var(--sp-4)' }}>{t('Every threshold is being met in this period.')}</p>
                    ) : (
                      <div className="signals">
                        {signals.map(({ icon: Icon, ...signal }) => (
                          <button type="button" className="signal" key={signal.title} onClick={signal.go}>
                            <span className={`signal__icon signal__icon--${signal.tone}`} aria-hidden="true"><Icon size={14} /></span>
                            <span className="signal__title">{signal.title}</span>
                            <span className="signal__value tnum">{signal.value}</span>
                            <span className="signal__detail">{signal.detail}</span>
                            <span className="signal__cta">{signal.cta}</span>
                            <ChevronRight size={14} className="signal__chev" aria-hidden="true" />
                          </button>
                        ))}
                      </div>
                    )}
                  </Card>
                </div>
              </div>
            </>
          )
        }}
      </Boundary>

      <Section
        title={t('Quality signals')}
        subtitle={t('What users corrected, straight from the correction log')}
        actions={<Button size="sm" onClick={() => navigate({ page: 'quality' })}>{t('Open AI Quality')}</Button>}
      >
        <div className="ds-grid-2">
          <Card title={t('Correction reasons')} subtitle={t('Every correction the mobile app recorded')}>
            <Boundary query={reasons} t={t} emptyTitle={t('No corrections recorded')} emptyDescription={t('Users have not corrected any logged item yet.')}>
              {(rows) => {
                const max = Math.max(...rows.map((row) => row.occurrences), 1)
                return (
                  <Bars>
                    {rows.map((row) => (
                      <Bar
                        key={row.reason}
                        label={row.reason}
                        value={row.occurrences}
                        max={max}
                        display={`${formatInt(row.occurrences)} · ${row.affected_users} ${t('users')}`}
                        tone={row.reason === 'wrong_food' ? 'danger' : row.reason === 'missing_item' ? 'warn' : 'neutral'}
                      />
                    ))}
                  </Bars>
                )
              }}
            </Boundary>
          </Card>

          <Card title={t('Highest correction rate')} subtitle={t('Canonical foods with at least 5 logged items')}>
            <Boundary query={categories} t={t} emptyTitle={t('Not enough logged items')} emptyDescription={t('A food needs at least 5 logged items before its correction rate is meaningful.')}>
              {(rows) => (
                <Bars>
                  {rows.map((row) => (
                    <Bar
                      key={row.canonical_name}
                      label={row.canonical_name}
                      value={row.correction_rate ?? 0}
                      max={100}
                      display={`${(row.correction_rate ?? 0).toFixed(1)}% · n=${row.items}`}
                      tone={(row.correction_rate ?? 0) >= THRESHOLDS.correctionRate ? 'danger' : (row.correction_rate ?? 0) >= 10 ? 'warn' : 'ok'}
                      onClick={() => navigate({ page: 'quality', filter: row.canonical_name })}
                    />
                  ))}
                </Bars>
              )}
            </Boundary>
          </Card>
        </div>
      </Section>
    </div>
  )
}

function ThresholdValue({ value, ok, t }: { value: string; ok: boolean; t: (value: string) => string }) {
  return (
    <span className="ds-row">
      <span className="tnum">{value}</span>
      <Badge tone={ok ? 'ok' : 'warn'} dot>{t(ok ? 'On target' : 'Off target')}</Badge>
    </span>
  )
}
