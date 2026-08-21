import { useMemo, useState } from 'react'
import { RotateCcw } from 'lucide-react'
import { formatWhen } from '../data'
import { mobileCopyCatalog } from '../mobileCopyCatalog.generated'
import { validateTranslationBundle } from '../mobileAdminApi'
import { fetchBundles, type BundleRow } from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import {
  Alert, Badge, Button, Card, DefinitionList, Metric, Metrics, SearchInput, Section, Textarea,
  useToast,
} from '../ui'
import { Boundary, MetricsSkeleton } from './Boundary'
import { PageHeader, type PageProps } from './shared'

const STATUS_TONE = { production: 'ok', staging: 'warn', draft: 'neutral', archived: 'neutral' } as const

export function MobileApp({ t }: PageProps) {
  const bundles = useQuery(() => fetchBundles(), [])
  const [selected, setSelected] = useState<string | null>(null)
  const [keyQuery, setKeyQuery] = useState('')
  const toast = useToast()

  // The bundled ARB strings are generated from the Flutter app at build time,
  // so they are real fallbacks — not sample copy.
  const fallbacks = useMemo(
    () => Object.fromEntries(mobileCopyCatalog.map((row) => [String(row.key), row])),
    [],
  )

  return (
    <div className="page page--wide">
      <PageHeader
        title={t('Mobile App')}
        description={t('OTA copy bundles as they exist in translation_bundles')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={bundles.refetch}>{t('Refresh')}</Button>}
      />

      <Boundary
        query={bundles}
        t={t}
        skeleton={<MetricsSkeleton count={3} />}
        emptyTitle={t('No bundles published')}
        emptyDescription={t('The app is running entirely on its bundled ARB fallbacks.')}
      >
        {(rows) => {
          const active = rows.find((row) => String(row.version) === selected) ?? rows[0]
          const production = rows.filter((row) => row.status === 'production')
          const overrideKeys = Object.keys(active?.values ?? {})
          const coverage = Math.round((overrideKeys.length / Math.max(1, mobileCopyCatalog.length)) * 100)
          const payloadBytes = new TextEncoder().encode(JSON.stringify(active?.values ?? {})).byteLength

          const validate = () => {
            const locale = active.locale
            const map = Object.fromEntries(mobileCopyCatalog.map((row) => [String(row.key), row[locale]]))
            const issues = validateTranslationBundle(
              { locale, version: active.version, status: active.status, values: active.values },
              map,
            )
            if (issues.length) {
              toast.push({ tone: 'danger', title: `${issues[0].code}: ${issues[0].key}`, description: `${issues.length} ${t('issues found')}` })
            } else {
              toast.push({ tone: 'ok', title: t('Validation passed'), description: t('No placeholder, length, or payload-size errors found.') })
            }
          }

          const visibleKeys = overrideKeys.filter((key) =>
            `${key} ${active.values[key]}`.toLocaleLowerCase().includes(keyQuery.toLocaleLowerCase()),
          )

          return (
            <>
              <Metrics>
                <Metric label={t('Bundles')} value={String(rows.length)} footnote={`${production.length} ${t('in production')}`} />
                <Metric label={t('Locales')} value={String(new Set(rows.map((row) => row.locale)).size)} footnote={[...new Set(rows.map((row) => row.locale))].join(' · ').toUpperCase()} />
                <Metric label={t('Coverage')} value={`${coverage}%`} footnote={`${overrideKeys.length} / ${mobileCopyCatalog.length} ${t('keys overridden')}`} />
                <Metric
                  label={t('Payload')} value={`${payloadBytes} B`} footnote={t('limit 64 KB')}
                  badge={payloadBytes > 65_536 ? <Badge tone="danger" dot>{t('Over limit')}</Badge> : <Badge tone="ok" dot>{t('Within limit')}</Badge>}
                />
              </Metrics>

              <Section title={t('Translation bundles')} subtitle={t('Every row is a real bundle in translation_bundles')}>
                <Card flush>
                  <div className="ds-table-wrap">
                    <table className="ds-table">
                      <caption className="sr-only">{t('Translation bundles by locale and version')}</caption>
                      <thead>
                        <tr>
                          <th scope="col">{t('Locale')}</th>
                          <th scope="col">{t('Version')}</th>
                          <th scope="col">{t('Status')}</th>
                          <th scope="col" className="ds-table__num">{t('Overrides')}</th>
                          <th scope="col">{t('Published')}</th>
                          <th scope="col">{t('Updated')}</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((row) => (
                          <tr
                            key={`${row.locale}-${row.version}`}
                            data-selected={row === active || undefined}
                            data-clickable="true"
                            tabIndex={0}
                            onClick={() => setSelected(String(row.version))}
                            onKeyDown={(event) => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); setSelected(String(row.version)) } }}
                          >
                            <td><strong>{row.locale.toUpperCase()}</strong></td>
                            <td className="ds-mono">v{row.version}</td>
                            <td><Badge tone={STATUS_TONE[row.status]} dot>{t(row.status)}</Badge></td>
                            <td className="ds-table__num tnum">{Object.keys(row.values ?? {}).length}</td>
                            <td className="ds-muted">{formatWhen(row.published_at)}</td>
                            <td className="ds-muted">{formatWhen(row.updated_at)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </Card>
              </Section>

              <div className="ds-grid-2">
                <Card
                  title={`${active.locale.toUpperCase()} · v${active.version}`}
                  subtitle={t('Overrides in this bundle, against the bundled ARB fallback')}
                  actions={<Button size="sm" onClick={validate}>{t('Validate')}</Button>}
                >
                  <SearchInput value={keyQuery} onValueChange={setKeyQuery} label={t('Search keys')} placeholder={t('Search key or copy…')} />
                  {visibleKeys.length === 0 ? (
                    <p className="ds-meta" style={{ marginTop: 'var(--sp-4)' }}>
                      {overrideKeys.length === 0 ? t('This bundle overrides nothing; the app uses its bundled strings.') : t('No key matches that search.')}
                    </p>
                  ) : (
                    <div className="ds-stack ds-stack--sm" style={{ marginTop: 'var(--sp-3)' }}>
                      {visibleKeys.slice(0, 30).map((key) => (
                        <div key={key} className="ds-stack ds-stack--sm">
                          <code className="ds-mono ds-muted">{key}</code>
                          <Textarea readOnly rows={2} value={active.values[key]} aria-label={`${t('OTA override')} ${key}`} />
                          {fallbacks[key] && (
                            <p className="ds-help">{t('Bundled fallback')}: {fallbacks[key][active.locale]}</p>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </Card>

                <Card title={t('Bundle metadata')} subtitle={t('Straight from the row')}>
                  <DefinitionList rows={[
                    [t('Locale'), active.locale.toUpperCase()],
                    [t('Version'), `v${active.version}`],
                    [t('Status'), <Badge tone={STATUS_TONE[active.status]} dot key="s">{t(active.status)}</Badge>],
                    [t('Overrides'), String(overrideKeys.length)],
                    [t('Payload'), `${payloadBytes} B`],
                    [t('Created'), formatWhen(active.created_at)],
                    [t('Updated'), formatWhen(active.updated_at)],
                    [t('Published'), formatWhen(active.published_at)],
                  ]} />
                  <Alert tone="info" title={t('Read-only')}>
                    {t('Publishing and rollback must go through an authenticated server endpoint, never from the browser.')}
                  </Alert>
                </Card>
              </div>
            </>
          )
        }}
      </Boundary>
    </div>
  )
}
