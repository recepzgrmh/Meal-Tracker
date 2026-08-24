import { useEffect, useState } from 'react'
import { Database, RotateCcw } from 'lucide-react'
import {
  fetchProductionCatalogFood,
  fetchProductionCatalogFoods,
  fetchProductionCatalogStatus,
  type CatalogFoodDetail,
  type CatalogFoodRow,
} from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import {
  Badge, Button, Card, DefinitionList, Drawer, EmptyState, Metric, Metrics,
  Pagination, SearchInput, Select, TableSkeleton,
} from '../ui'
import { PageHeader, type PageProps } from './shared'

const PAGE_SIZE = 25
const TIERS = ['all', 'generic_core', 'tr_branded', 'off_en_global', 'usda_branded_quality', 'quality_global']

// Pinned to en-US like data.ts formatInt: the host locale would render 60000
// as "60.000" on a Turkish machine and the console copy assumes "60,000".
const number = (value: number, maximumFractionDigits = 1) =>
  new Intl.NumberFormat('en-US', { maximumFractionDigits }).format(Number(value))

export function FoodCatalog({ t }: PageProps) {
  const [draftQuery, setDraftQuery] = useState('')
  const [query, setQuery] = useState('')
  const [kind, setKind] = useState<'all' | 'generic' | 'branded'>('all')
  const [tier, setTier] = useState('all')
  const [page, setPage] = useState(1)
  const [selectedId, setSelectedId] = useState<string | null>(null)

  useEffect(() => {
    const timer = window.setTimeout(() => setQuery(draftQuery.trim()), 300)
    return () => window.clearTimeout(timer)
  }, [draftQuery])

  useEffect(() => setPage(1), [query, kind, tier])

  const status = useQuery(() => fetchProductionCatalogStatus(), [])
  const foods = useQuery(
    () => fetchProductionCatalogFoods({ query, kind, tier, page, pageSize: PAGE_SIZE }),
    [query, kind, tier, page],
  )
  const reset = () => { setDraftQuery(''); setQuery(''); setKind('all'); setTier('all'); setPage(1) }
  const total = foods.data?.total ?? 0
  const pageCount = Math.max(1, Math.ceil(total / PAGE_SIZE))
  const filtered = Boolean(query || kind !== 'all' || tier !== 'all')

  return (
    <div className="page page--wide">
      <PageHeader
        title={t('Food Catalog')}
        description={t('Browse the validated 60K Supabase production catalog without loading it into the browser.')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={() => { status.refetch(); foods.refetch() }}>{t('Refresh')}</Button>}
      />

      <Metrics>
        <Metric label={t('Production foods')} value={status.data ? number(status.data.food_records, 0) : '—'} footnote="canonical-v2-lean-60k" />
        <Metric label={t('Macro complete')} value={status.data ? number(status.data.macro_complete_records, 0) : '—'} footnote={t('kcal + protein + carbs + fat')} />
        <Metric label={t('Search aliases')} value={status.data ? number(status.data.alias_records, 0) : '—'} footnote={t('Turkish + English')} />
        <Metric label={t('Portions')} value={status.data ? number(status.data.portion_records, 0) : '—'} footnote={t('Turkish + English')} />
      </Metrics>

      <Card flush>
        <div className="catalog-toolbar" role="search" aria-label={t('Filter food catalog')}>
          <SearchInput
            className="catalog-toolbar__search"
            value={draftQuery}
            onValueChange={setDraftQuery}
            label={t('Search foods')}
            placeholder={t('Search name, alias, brand or barcode…')}
          />
          <Select
            aria-label={t('Food type')}
            value={kind}
            onChange={(event) => setKind(event.target.value as typeof kind)}
            options={[
              { value: 'all', label: t('All foods') },
              { value: 'generic', label: t('Generic') },
              { value: 'branded', label: t('Branded') },
            ]}
          />
          <Select
            aria-label={t('Selection tier')}
            value={tier}
            onChange={(event) => setTier(event.target.value)}
            options={TIERS.map((value) => ({ value, label: value === 'all' ? t('All tiers') : value }))}
          />
          {filtered && <Button size="sm" variant="ghost" onClick={reset}>{t('Reset filters')}</Button>}
        </div>

        {foods.loading ? (
          <TableSkeleton rows={8} columns={8} />
        ) : foods.error ? (
          <EmptyState
            tone="danger"
            title={t('Catalog could not be loaded')}
            description={t('Check the production connection and try again.')}
            actions={<Button onClick={foods.refetch}>{t('Try again')}</Button>}
          />
        ) : foods.data?.rows.length ? (
          <>
            <CatalogTable rows={foods.data.rows} onSelect={setSelectedId} t={t} />
            <Pagination
              page={page}
              pageCount={pageCount}
              total={total}
              pageSize={PAGE_SIZE}
              onPage={setPage}
              labels={{
                previous: t('Previous page'),
                next: t('Next page'),
                range: (from, to, count) => `${number(from, 0)}–${number(to, 0)} / ${number(count, 0)}`,
              }}
            />
          </>
        ) : (
          <EmptyState
            icon={<Database size={18} />}
            title={t('No foods match these filters')}
            description={t('Try a broader query or reset the filters.')}
            actions={<Button onClick={reset}>{t('Reset filters')}</Button>}
          />
        )}
      </Card>

      {selectedId && <FoodDetailDrawer foodId={selectedId} onClose={() => setSelectedId(null)} t={t} />}
    </div>
  )
}

function CatalogTable({ rows, onSelect, t }: { rows: CatalogFoodRow[]; onSelect: (id: string) => void; t: PageProps['t'] }) {
  return (
    <div className="ds-table-wrap">
      <table className="ds-table catalog-table">
        <caption className="sr-only">{t('Production food catalog')}</caption>
        <thead><tr>
          <th scope="col">{t('Food')}</th>
          <th scope="col">{t('Brand')}</th>
          <th scope="col">{t('Category')}</th>
          <th scope="col">{t('Tier')}</th>
          <th scope="col" className="ds-table__num">{t('kcal')}</th>
          <th scope="col" className="ds-table__num">{t('Protein')}</th>
          <th scope="col" className="ds-table__num">{t('Carbs')}</th>
          <th scope="col" className="ds-table__num">{t('Fat')}</th>
        </tr></thead>
        <tbody>
          {rows.map((row) => (
            <tr
              key={row.food_id}
              data-clickable="true"
              tabIndex={0}
              onClick={() => onSelect(row.food_id)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); onSelect(row.food_id) }
              }}
            >
              <td>
                <span className="catalog-food-name">
                  <strong>{row.canonical_name}</strong>
                  <span>{row.barcode || row.dataset_version || row.locale}</span>
                </span>
              </td>
              <td>{row.brand || <span className="ds-muted">—</span>}</td>
              <td><span className="catalog-cell-clamp">{row.category || '—'}</span></td>
              <td><Badge>{row.tier || '—'}</Badge></td>
              <td className="ds-table__num tnum">{number(row.calories_per_100g)}</td>
              <td className="ds-table__num tnum">{number(row.protein_per_100g)} g</td>
              <td className="ds-table__num tnum">{number(row.carbs_per_100g)} g</td>
              <td className="ds-table__num tnum">{number(row.fat_per_100g)} g</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function FoodDetailDrawer({ foodId, onClose, t }: { foodId: string; onClose: () => void; t: PageProps['t'] }) {
  const food = useQuery(() => fetchProductionCatalogFood(foodId), [foodId])
  return (
    <Drawer open onClose={onClose} wide title={food.data?.canonical_name ?? t('Food details')} description={food.data?.source_food_id ?? foodId}>
      {food.loading ? <TableSkeleton rows={5} columns={2} /> : food.error || !food.data ? (
        <EmptyState tone="danger" title={t('Food details could not be loaded')} actions={<Button onClick={food.refetch}>{t('Try again')}</Button>} />
      ) : <FoodDetail food={food.data} t={t} />}
    </Drawer>
  )
}

function FoodDetail({ food, t }: { food: CatalogFoodDetail; t: PageProps['t'] }) {
  const metadata = food.metadata ?? {}
  const reasons = Array.isArray(metadata.inclusion_reasons) ? metadata.inclusion_reasons.map(String) : []
  return (
    <>
      <section className="catalog-detail-section">
        <h3>{t('Nutrition per 100 g')}</h3>
        <Metrics>
          <Metric label={t('Calories')} value={`${number(food.calories_per_100g)} kcal`} />
          <Metric label={t('Protein')} value={`${number(food.protein_per_100g)} g`} />
          <Metric label={t('Carbs')} value={`${number(food.carbs_per_100g)} g`} />
          <Metric label={t('Fat')} value={`${number(food.fat_per_100g)} g`} />
        </Metrics>
      </section>

      <section className="catalog-detail-section">
        <h3>{t('Identity and provenance')}</h3>
        <DefinitionList rows={[
          [t('Brand'), String(metadata.brand ?? '—')],
          [t('Barcode'), <code className="ds-mono" key="barcode">{String(metadata.barcode ?? '—')}</code>],
          [t('Category'), String(metadata.category ?? '—')],
          [t('Selection tier'), <Badge key="tier">{String(metadata.tier ?? '—')}</Badge>],
          [t('Dataset version'), String(metadata.dataset_version ?? '—')],
          [t('Canonical ID'), <code className="ds-mono" key="canonical">{String(metadata.canonical_id ?? food.source_food_id)}</code>],
          [t('Locale'), food.locale],
        ]} />
        {reasons.length > 0 && <div className="catalog-reasons" aria-label={t('Inclusion reasons')}>{reasons.map((reason) => <Badge key={reason}>{reason}</Badge>)}</div>}
      </section>

      <section className="catalog-detail-section">
        <h3>{t('Aliases')}</h3>
        <div className="catalog-record-list">
          {food.food_aliases.map((alias) => <div key={alias.id}><strong>{alias.alias}</strong><Badge>{alias.locale}</Badge></div>)}
        </div>
      </section>

      <section className="catalog-detail-section">
        <h3>{t('Portions')}</h3>
        <div className="catalog-record-list">
          {food.food_portions.map((portion) => <div key={portion.id}><strong>{portion.label}</strong><span className="tnum">{number(portion.grams)} g</span><Badge>{portion.locale}</Badge></div>)}
        </div>
      </section>
    </>
  )
}
