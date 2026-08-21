import { useState } from 'react'
import { RotateCcw } from 'lucide-react'
import { THRESHOLDS, formatInt, formatWhen } from '../data'
import { fetchCategoryQuality, fetchCorrectionReasons, fetchReviewQueue, type QueueRow } from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import {
  Alert, Badge, Bar, Bars, Button, Card, Chips, DataTable, FilterChip, Metric, Metrics, Section,
  Tabs,
} from '../ui'
import { Boundary, MetricsSkeleton } from './Boundary'
import { PageHeader, type PageProps } from './shared'
import { reviewColumns, reviewLabels } from './Reviews'

export function Quality({ route, navigate, t }: PageProps) {
  const [tab, setTab] = useState('categories')
  const categories = useQuery(() => fetchCategoryQuality(24), [])
  const reasons = useQuery(() => fetchCorrectionReasons(), [])
  const overconfident = useQuery(() => fetchReviewQueue('overconfident'), [])
  const filter = route.filter

  return (
    <div className="page page--wide">
      <PageHeader
        title={t('AI Quality')}
        description={t('How accurate is the meal analysis system?')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={() => { categories.refetch(); reasons.refetch(); overconfident.refetch() }}>{t('Refresh')}</Button>}
      />

      <Boundary query={categories} t={t} skeleton={<MetricsSkeleton />} emptyTitle={t('Not enough logged items')}>
        {(rows) => {
          const items = rows.reduce((sum, row) => sum + row.items, 0)
          const corrected = rows.reduce((sum, row) => sum + row.corrected, 0)
          const rate = items ? (corrected / items) * 100 : 0
          const avgConfidence = rows.length
            ? rows.reduce((sum, row) => sum + (row.avg_confidence ?? 0) * row.items, 0) / Math.max(1, items)
            : 0
          const overThreshold = rows.filter((row) => (row.correction_rate ?? 0) >= THRESHOLDS.correctionRate).length
          return (
            <Metrics>
              <Metric label={t('Logged items')} value={formatInt(items)} footnote={t('with at least 5 per food')} />
              <Metric
                label={t('Correction rate')} value={`${rate.toFixed(1)}%`}
                footnote={`${t('target under')} ${THRESHOLDS.correctionRate}%`}
                badge={rate >= THRESHOLDS.correctionRate ? <Badge tone="warn" dot>{t('Above target')}</Badge> : undefined}
              />
              <Metric label={t('Average confidence')} value={`${avgConfidence.toFixed(1)}%`} footnote={t('weighted by item count')} />
              <Metric
                label={t('Foods over threshold')} value={formatInt(overThreshold)}
                footnote={`${t('of')} ${rows.length} ${t('tracked')}`}
                badge={overThreshold > 0 ? <Badge tone="danger" dot>{t('Needs work')}</Badge> : undefined}
              />
            </Metrics>
          )
        }}
      </Boundary>

      <Tabs
        label={t('AI Quality')}
        value={tab}
        onChange={setTab}
        items={[
          { id: 'categories', label: t('By food') },
          { id: 'reasons', label: t('By reason') },
          { id: 'overconfident', label: t('Overconfident mistakes') },
        ]}
      />

      {filter && (
        <Chips>
          <span className="ds-meta">{t('Active filter')}</span>
          <FilterChip name={t('Food')} value={filter} onRemove={() => navigate({ page: 'quality' })} />
        </Chips>
      )}

      {tab === 'categories' && (
        <Card title={t('Correction rate by food')} subtitle={t('Share of logged items the user then corrected')}>
          <Boundary
            query={categories}
            t={t}
            emptyTitle={t('Not enough logged items')}
            emptyDescription={t('A food needs at least 5 logged items before its correction rate means anything.')}
          >
            {(rows) => {
              const visible = filter ? rows.filter((row) => row.canonical_name === filter) : rows
              return (
                <Bars>
                  {visible.map((row) => (
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
              )
            }}
          </Boundary>
        </Card>
      )}

      {tab === 'reasons' && (
        <Section title={t('Why users corrected')} subtitle={t('Straight from meal_item_corrections.reason')}>
          <Card>
            <Boundary query={reasons} t={t} emptyTitle={t('No corrections recorded')}>
              {(rows) => {
                const max = Math.max(...rows.map((row) => row.occurrences), 1)
                return (
                  <>
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
                    <p className="ds-meta" style={{ marginTop: 'var(--sp-3)' }}>
                      {t('Most recent')}: {formatWhen(rows[0]?.last_seen ?? null)}
                    </p>
                  </>
                )
              }}
            </Boundary>
          </Card>
        </Section>
      )}

      {tab === 'overconfident' && (
        <Card flush title={t('High confidence, then corrected')} subtitle={t('Items the model was sure about and the user still changed')}>
          <Boundary
            query={overconfident}
            t={t}
            emptyTitle={t('No overconfident mistakes')}
            emptyDescription={t('No item above 88% confidence has been corrected.')}
          >
            {(rows) => (
              <>
                <Alert tone="warn" title={`${rows.length} ${t('cases')}`}>
                  {t('These are the most useful cases to inspect: the model gave no signal that it might be wrong.')}
                </Alert>
                <DataTable<QueueRow>
                  caption={t('High-confidence items that were corrected')}
                  rows={rows}
                  columns={reviewColumns(t)}
                  rowKey={(row) => row.item_id}
                  onRowClick={(row) => navigate({ page: 'reviews', itemId: row.item_id })}
                  labels={reviewLabels(t)}
                />
              </>
            )}
          </Boundary>
        </Card>
      )}
    </div>
  )
}
