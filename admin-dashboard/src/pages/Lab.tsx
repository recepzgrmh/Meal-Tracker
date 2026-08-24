import { RotateCcw } from 'lucide-react'
import { formatInt } from '../data'
import {
  fetchCalibration, fetchCandidateMargins, fetchMatchMethods, fetchPortionError,
} from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import {
  Alert, Badge, Bar, BarChart, Bars, Button, Card, ChartContainer, DefinitionList, Metric,
  Metrics, Section, Tabs,
} from '../ui'
import { Boundary, MetricsSkeleton } from './Boundary'
import { PageHeader, type PageProps } from './shared'
import { useState } from 'react'

export function Lab({ t }: PageProps) {
  const [tab, setTab] = useState('calibration')
  const calibration = useQuery(() => fetchCalibration(), [])
  const methods = useQuery(() => fetchMatchMethods(), [])
  const portions = useQuery(() => fetchPortionError(), [])
  const margins = useQuery(() => fetchCandidateMargins(), [])

  return (
    <div className="page page--wide">
      <PageHeader
        title={t('AI Lab')}
        description={t('Is the model honest about what it knows, and where is it wrong?')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={() => { calibration.refetch(); methods.refetch(); portions.refetch(); margins.refetch() }}>{t('Refresh')}</Button>}
      />

      <Tabs
        label={t('AI Lab')}
        value={tab}
        onChange={setTab}
        items={[
          { id: 'calibration', label: t('Calibration') },
          { id: 'methods', label: t('Match methods') },
          { id: 'portions', label: t('Portion error') },
          { id: 'margins', label: t('Candidate margin') },
        ]}
      />

      {tab === 'calibration' && (
        <>
          <Boundary query={calibration} t={t} skeleton={<MetricsSkeleton count={3} />} emptyTitle={t('No logged items yet')}>
            {(rows) => {
              const items = rows.reduce((sum, row) => sum + row.items, 0)
              const corrected = rows.reduce((sum, row) => sum + row.corrected, 0)
              const high = rows.filter((row) => row.bucket_floor_pct >= 80)
              const highItems = high.reduce((sum, row) => sum + row.items, 0)
              const highCorrected = high.reduce((sum, row) => sum + row.corrected, 0)
              const highRate = highItems ? (highCorrected / highItems) * 100 : 0
              return (
                <Metrics>
                  <Metric label={t('Logged items')} value={formatInt(items)} footnote={t('across all confidence levels')} />
                  <Metric label={t('Overall correction rate')} value={`${items ? ((corrected / items) * 100).toFixed(1) : '0.0'}%`} footnote={`${formatInt(corrected)} ${t('corrected')}`} />
                  <Metric
                    label={t('Corrected above 80% confidence')} value={`${highRate.toFixed(1)}%`}
                    footnote={`${formatInt(highCorrected)} / ${formatInt(highItems)}`}
                    badge={highRate > 10 ? <Badge tone="danger" dot>{t('Overconfident')}</Badge> : <Badge tone="ok" dot>{t('Honest')}</Badge>}
                  />
                </Metrics>
              )
            }}
          </Boundary>

          <Card title={t('Confidence calibration')} subtitle={t('Stated confidence against the rate the user actually changed the answer')}>
            <Boundary
              query={calibration}
              t={t}
              emptyTitle={t('No logged items yet')}
              emptyDescription={t('Log a meal from the app and this fills in.')}
            >
              {(rows) => (
                <>
                  <ChartContainer>
                    <BarChart
                      ariaLabel={t('Correction rate by stated confidence')}
                      height={228}
                      formatValue={(value) => `${Math.round(value)}%`}
                      data={rows.map((row) => ({
                        label: `${row.bucket_floor_pct}%`,
                        value: row.correction_rate ?? 0,
                        tone: (row.correction_rate ?? 0) >= 20 ? 'danger' : (row.correction_rate ?? 0) >= 10 ? 'warn' : 'primary',
                      }))}
                    />
                  </ChartContainer>
                  <Alert tone="info" title={t('How to read this')}>
                    {t('Bars should fall from left to right. A tall bar on the right means the model is confidently wrong, which is the failure mode worth fixing first.')}
                  </Alert>
                </>
              )}
            </Boundary>
          </Card>
        </>
      )}

      {tab === 'methods' && (
        <Card title={t('Match method quality')} subtitle={t('Which strategy resolves the food, and how often the user disagrees')}>
          <Boundary
            query={methods}
            t={t}
            emptyTitle={t('No logged items yet')}
            emptyDescription={t('Match method is recorded from the analysis run when a meal is committed.')}
          >
            {(rows) => {
              const max = Math.max(...rows.map((row) => row.items), 1)
              const onlyManual = rows.length === 1 && rows[0].match_method === 'manual'
              return (
                <>
                  <Bars>
                    {rows.map((row) => (
                      <Bar
                        key={row.match_method}
                        label={row.match_method}
                        value={row.items}
                        max={max}
                        display={`${formatInt(row.items)} · ${(row.correction_rate ?? 0).toFixed(1)}% ${t('corrected')}`}
                        tone={(row.correction_rate ?? 0) >= 20 ? 'danger' : (row.correction_rate ?? 0) >= 10 ? 'warn' : 'ok'}
                      />
                    ))}
                  </Bars>
                  {onlyManual && (
                    <Alert tone="warn" title={t('Every item still reads as manual')}>
                      {t('These rows were committed before the telemetry fix. New meals will carry the real method.')}
                    </Alert>
                  )}
                </>
              )
            }}
          </Boundary>
        </Card>
      )}

      {tab === 'portions' && (
        <Section title={t('Portion error')} subtitle={t('Gram difference between what the model proposed and what the user logged')}>
          <Card>
            <Boundary
              query={portions}
              t={t}
              emptyTitle={t('No portion corrections recorded')}
              emptyDescription={t('This fills in when a user changes a proposed portion by more than 2% or 1 g.')}
            >
              {(rows) => {
                const max = Math.max(...rows.map((row) => row.mean_abs_error_g ?? 0), 1)
                return (
                  <>
                    <Bars>
                      {rows.map((row) => (
                        <Bar
                          key={row.canonical_name}
                          label={row.canonical_name}
                          value={row.mean_abs_error_g ?? 0}
                          max={max}
                          display={`${(row.mean_abs_error_g ?? 0).toFixed(1)} g · n=${row.corrections}`}
                          tone={(row.mean_abs_error_g ?? 0) >= 50 ? 'danger' : (row.mean_abs_error_g ?? 0) >= 20 ? 'warn' : 'ok'}
                        />
                      ))}
                    </Bars>
                    <Alert tone="info" title={t('Signed error tells you the bias')}>
                      {t('A positive mean signed error means the model under-estimates the portion; negative means it over-estimates.')}
                    </Alert>
                  </>
                )
              }}
            </Boundary>
          </Card>
        </Section>
      )}

      {tab === 'margins' && (
        <Card title={t('Candidate margin')} subtitle={t('Score gap between the chosen food and the runner-up')}>
          <Boundary
            query={margins}
            t={t}
            emptyTitle={t('No candidate sets recorded')}
            emptyDescription={t('analyze-meal stores one candidate per item, so there is no runner-up to compare against.')}
          >
            {(rows) => {
              const withRunnerUp = rows.filter((row) => row.runner_up_score != null)
              if (withRunnerUp.length === 0) {
                return (
                  <Alert tone="warn" title={t('Only the chosen candidate is being stored')}>
                    {t('analyze-meal writes one row per item at rank 1, so the retriever’s runners-up are discarded before they reach the database. Until that changes this metric has no source.')}
                  </Alert>
                )
              }
              return (
                <>
                  <DefinitionList rows={[
                    [t('Item sets'), formatInt(rows.length)],
                    [t('With a runner-up'), formatInt(withRunnerUp.length)],
                    [t('Median margin'), (withRunnerUp[Math.floor(withRunnerUp.length / 2)]?.margin ?? 0).toFixed(3)],
                  ]} />
                  <Bars>
                    {withRunnerUp.slice(0, 20).map((row) => (
                      <Bar
                        key={`${row.analysis_run_id}-${row.item_key}`}
                        label={row.item_key}
                        value={Math.max(0, row.margin ?? 0)}
                        max={1}
                        display={`${(row.margin ?? 0).toFixed(3)} · ${t('rank')} ${row.selected_rank ?? '—'}`}
                        tone={(row.margin ?? 0) < 0.05 ? 'danger' : (row.margin ?? 0) < 0.15 ? 'warn' : 'ok'}
                      />
                    ))}
                  </Bars>
                </>
              )
            }}
          </Boundary>
        </Card>
      )}
    </div>
  )
}
