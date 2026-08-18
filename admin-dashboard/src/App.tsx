import { useEffect, useMemo, useState } from 'react'
import {
  Activity, AlertCircle, ArrowLeft, BarChart3, Bell, ChevronRight, CircleUserRound, ClipboardCheck,
  Gauge, GitCompareArrows, Languages, LayoutDashboard, Menu, Network, PanelLeftClose, PanelLeftOpen, Search,
  Settings, ShieldCheck, SlidersHorizontal, Timer, Users, Utensils, X,
} from 'lucide-react'
import { categoryData, correctionTrend, latencyTrend, qualityErrors, reviews, sauceTrend, spans, type ReviewMeal, type Severity } from './data'
import { useI18n } from './i18n'
import { validateTranslationBundle } from './mobileAdminApi'
import { mobileCopyCatalog as otaRows } from './mobileCopyCatalog.generated'

type Page = 'overview' | 'quality' | 'reviews' | 'traces' | 'reliability' | 'analytics' | 'users' | 'mobile' | 'audit' | 'settings'
type Route = { page: Page; meal?: ReviewMeal; trace?: ReviewMeal; filter?: string }

const navGroups: Array<[string, Array<[Page, string, typeof LayoutDashboard]>]> = [
  ['MONITOR', [['overview', 'Overview', LayoutDashboard], ['quality', 'AI Quality', ClipboardCheck], ['reviews', 'Meal Reviews', Utensils]]],
  ['DEBUG', [['traces', 'Traces', Network], ['reliability', 'Reliability', Activity]]],
  ['PRODUCT', [['analytics', 'Analytics', BarChart3], ['users', 'Users', Users], ['mobile', 'Mobile App', Languages]]],
  ['SYSTEM', [['audit', 'Audit Log', ShieldCheck], ['settings', 'Settings', Settings]]],
]

function readRoute(): Route {
  const path = location.pathname.split('/').filter(Boolean)
  const page = (path[1] || 'overview') as Page
  const params = new URLSearchParams(location.search)
  const meal = params.get('meal') ? reviews.find((x) => x.id === params.get('meal')) : undefined
  const trace = params.get('trace') ? reviews.find((x) => x.trace === params.get('trace')) : undefined
  return { page, meal, trace, filter: params.get('filter') || undefined }
}

export default function App() {
  const { t, language, setLanguage } = useI18n()
  const [route, setRoute] = useState<Route>(readRoute)
  const [collapsed, setCollapsed] = useState(false)
  const [range, setRange] = useState('30D')
  const [environment, setEnvironment] = useState('Production')

  useEffect(() => {
    const listener = () => setRoute(readRoute())
    addEventListener('popstate', listener)
    return () => removeEventListener('popstate', listener)
  }, [])

  const navigate = (next: Route) => {
    const query = new URLSearchParams()
    if (next.meal) query.set('meal', next.meal.id)
    if (next.trace) query.set('trace', next.trace.trace)
    if (next.filter) query.set('filter', next.filter)
    const url = `/admin/${next.page}${query.size ? `?${query}` : ''}`
    history.pushState(null, '', url)
    setRoute(next)
    const main = document.querySelector('main')
    if (main && 'scrollTo' in main) main.scrollTo({ top: 0 })
  }

  const content = route.trace
    ? <TraceInspector meal={route.trace} back={() => navigate({ page: 'traces' })} openMeal={() => navigate({ page: 'reviews', meal: route.trace })} />
    : route.meal
      ? <MealInspector meal={route.meal} back={() => navigate({ page: 'reviews' })} openTrace={() => navigate({ page: 'traces', trace: route.meal })} />
      : <PageContent route={route} range={range} navigate={navigate} />

  return <div className={`app-shell ${collapsed ? 'sidebar-collapsed' : ''}`}>
    <aside className="sidebar">
      <div className="brand"><div className="brand-mark"><Gauge size={18} /></div><div className="brand-copy"><strong>Meal Clarity</strong><span>{t('AI operations')}</span></div></div>
      <nav aria-label="Admin navigation">
        {navGroups.map(([group, links]) => <section key={group} className="nav-group"><p>{t(group)}</p>{links.map(([page, label, Icon]) =>
          <button key={page} className={route.page === page ? 'active' : ''} onClick={() => navigate({ page })} title={collapsed ? label : undefined}>
            <Icon size={17} /><span>{t(label)}</span>
          </button>
        )}</section>)}
      </nav>
      <button className="collapse-button" onClick={() => setCollapsed(!collapsed)} aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}>{collapsed ? <PanelLeftOpen size={17} /> : <PanelLeftClose size={17} />}</button>
      <div className="admin-profile"><div className="avatar">RE</div><div><strong>R. Engineer</strong><span>{t('Engineer role')}</span></div></div>
    </aside>
    <div className="workspace">
      <header className="topbar">
        <button className="mobile-menu" onClick={() => setCollapsed(!collapsed)}><Menu size={18} /></button>
        <SearchBox navigate={navigate} />
        <div className="topbar-spacer" />
        <Pill tone="warning">{t('DEMO DATA')}</Pill>
        <div className="language-control" aria-label="Interface language"><button className={language === 'tr' ? 'active' : ''} onClick={() => setLanguage('tr')}>TR</button><button className={language === 'en' ? 'active' : ''} onClick={() => setLanguage('en')}>EN</button></div>
        <label className="environment"><span className="sr-only">{t('Environment')}</span><select value={environment} onChange={(e) => setEnvironment(e.target.value)}><option value="Production">{t('Production')}</option><option value="Staging">{t('Staging')}</option><option value="Development">{t('Development')}</option></select></label>
        <div className="range-control" aria-label="Global time range">{['24H', '7D', '30D', '90D'].map((value) => <button className={range === value ? 'active' : ''} key={value} onClick={() => setRange(value)}>{value}</button>)}</div>
        <button className="icon-button" aria-label="Notifications"><Bell size={18} /></button>
      </header>
      <main>{content}</main>
    </div>
  </div>
}

function SearchBox({ navigate }: { navigate: (route: Route) => void }) {
  const { t } = useI18n()
  const [value, setValue] = useState('')
  const submit = (e: React.FormEvent) => {
    e.preventDefault()
    const meal = reviews.find((x) => x.id === value.trim() || x.trace === value.trim())
    if (!meal) return
    navigate(value.startsWith('tr_') ? { page: 'traces', trace: meal } : { page: 'reviews', meal })
  }
  return <form className="global-search" onSubmit={submit}><Search size={17} /><input value={value} onChange={(e) => setValue(e.target.value)} placeholder={t('Search meal, trace, request, user ID')} aria-label={t('Search meal, trace, request, user ID')} /><kbd>⌘K</kbd></form>
}

function PageContent({ route, range, navigate }: { route: Route; range: string; navigate: (route: Route) => void }) {
  switch (route.page) {
    case 'overview': return <Overview range={range} navigate={navigate} />
    case 'quality': return <Quality filter={route.filter} navigate={navigate} />
    case 'reviews': return <Reviews navigate={navigate} />
    case 'traces': return <Traces navigate={navigate} />
    case 'reliability': return <Reliability />
    case 'analytics': return <Analytics />
    case 'users': return <UsersPage />
    case 'mobile': return <MobileAppPage />
    case 'audit': return <Audit />
    case 'settings': return <SettingsPage />
  }
}

function PageHeader({ title, question, fresh = 'Updated 45 sec ago', action }: { title: string; question: string; fresh?: string; action?: React.ReactNode }) {
  const { t } = useI18n()
  return <div className="page-header"><div><h1>{t(title)}</h1><p>{t(question)}</p></div><div className="page-header-action">{action || <span className="fresh"><Timer size={13} />{t(fresh)}</span>}</div></div>
}

function Metrics({ items }: { items: Array<{ label: string; value: string; delta?: string; note?: string; tone?: Severity }> }) {
  const { t } = useI18n()
  return <section className="panel metric-strip" aria-label="Key metrics">{items.map((x) => <div className="metric" key={x.label}><span>{t(x.label)}</span><strong>{t(x.value)}</strong><small className={x.tone || ''}>{x.delta}{x.delta && x.note ? ' · ' : ''}<i>{x.note ? t(x.note) : ''}</i></small></div>)}</section>
}

function Overview({ range, navigate }: { range: string; navigate: (route: Route) => void }) {
  const { t } = useI18n()
  const alerts = [
    { icon: Utensils, tone: 'critical' as Severity, title: 'Sauce correction rate', value: '31%', detail: '↑ 14% since model v3.2 deployment', action: 'View 76 cases', click: () => navigate({ page: 'quality', filter: 'Sauces · High confidence + corrected' }) },
    { icon: Gauge, tone: 'warning' as Severity, title: 'P95 analysis latency', value: '6.8s', detail: 'Threshold is 6.0s · vision stage responsible', action: 'Inspect slow traces', click: () => navigate({ page: 'traces', filter: 'Slow > 6s' }) },
    { icon: AlertCircle, tone: 'critical' as Severity, title: 'Analysis requests failed', value: '17', detail: 'Last hour · 11 provider timeouts', action: 'Open reliability', click: () => navigate({ page: 'reliability' }) },
    { icon: Activity, tone: 'warning' as Severity, title: 'Nutrition lookup retry rate', value: '3.2%', detail: `↑ 0.8 pp over the previous ${range}`, action: 'View service health', click: () => navigate({ page: 'reliability' }) },
  ]
  return <div className="page">
    <PageHeader title="Overview" question="Does anything require attention right now?" />
    <Metrics items={[
      { label: 'Meals analyzed', value: '12,482', delta: '+8.2%', note: 'vs prior period', tone: 'healthy' },
      { label: 'Success rate', value: '98.7%', delta: '−0.3 pp', note: 'target 99%', tone: 'warning' },
      { label: 'Meals edited', value: '21.4%', delta: '+2.6 pp', note: 'needs review', tone: 'critical' },
      { label: 'Clarification rate', value: '8.2%', delta: '−0.9 pp', tone: 'healthy' },
      { label: 'Median / P95', value: '2.8s / 6.8s', delta: '+0.7s P95', tone: 'warning' },
    ]} />
    <section className="panel flush attention"><PanelTitle title="Needs attention" subtitle="Signals ordered by likely user impact. Select one to investigate." />
      {alerts.map(({ icon: Icon, ...a }) => <button className="attention-row" key={a.title} onClick={a.click}><span className={`signal-icon ${a.tone}`}><Icon size={16} /></span><strong>{t(a.title)}</strong><b>{a.value}</b><span>{t(a.detail)}</span><em>{t(a.action)}</em><ChevronRight size={15} /></button>)}
    </section>
    <div className="two-column">
      <section className="panel"><PanelTitle title="Production quality signal" subtitle="Meals requiring any user correction" badge={<Pill>User corrections</Pill>} /><div className="inline-value"><strong>18.4%</strong><span className="healthy">↓ 3.7 pp vs previous 30 days</span></div><Trend values={correctionTrend} color="#167b55" marker={7} labels={['Jul 20', 'Aug 12 · v3.2', 'Aug 18']} /></section>
      <section className="panel"><PanelTitle title="Top quality errors" subtitle="Reviewed and user-corrected meals" />{qualityErrors.slice(0, 5).map((x) => <Bar key={x[0]} label={x[0]} value={x[1]} max={32} suffix={`${x[1]}%`} tone={x[3]} onClick={() => navigate({ page: 'quality', filter: x[0] })} />)}</section>
    </div>
    <p className="footnote">Data freshness: behavioral events &lt; 1 min · evaluation aggregates 15 min</p>
  </div>
}

function Quality({ filter, navigate }: { filter?: string; navigate: (route: Route) => void }) {
  const { t } = useI18n()
  const [tab, setTab] = useState('Production signals')
  return <div className="page">
    <PageHeader title="AI Quality" question="How accurate is the meal analysis system?" fresh="Aggregated 4 min ago" />
    <div className="tabs">{['Production signals', 'Golden dataset', 'Human review', 'Eval runs'].map((x) => <button className={tab === x ? 'active' : ''} onClick={() => setTab(x)} key={x}>{t(x)}</button>)}</div>
    {filter && <div className="active-filter"><span>{t('Active filter')}</span><button onClick={() => navigate({ page: 'quality' })}><SlidersHorizontal size={13} />{t(filter)}<X size={13} /></button></div>}
    <Metrics items={[
      { label: 'Meals corrected', value: '18.4%', delta: '↓ 3.7 pp', note: 'user signal', tone: 'healthy' }, { label: 'Foods corrected', value: '12.8%', delta: '−1.4 pp', tone: 'healthy' },
      { label: 'Canonical accuracy', value: '92.7%', delta: '+3.5 pp', note: 'golden v4', tone: 'healthy' }, { label: 'Portion MAE', value: '22.6 g', delta: '+3.1 g', note: 'human labeled', tone: 'critical' },
      { label: 'Calorie MAE', value: '74 kcal', delta: '−18 kcal', note: 'golden v4', tone: 'healthy' }, { label: 'Protein error', value: 'Unavailable', note: 'insufficient labels' },
    ]} />
    <div className="two-column quality-grid">
      <section className="panel"><PanelTitle title="Where does the AI fail?" subtitle="981 errors across reviewed or corrected meals" />{qualityErrors.map((x) => <Bar key={x[0]} label={x[0]} value={x[1]} max={32} suffix={`${x[1]}%`} tone={x[3]} />)}</section>
      <section className="panel"><PanelTitle title="Sauce corrections" subtitle="Correction rate over time" badge={<select aria-label="Error category"><option>Sauces</option><option>Portions</option></select>} /><div className="inline-value"><strong>31.0%</strong><Pill tone="critical">↑ 7.4 pp</Pill></div><Trend values={sauceTrend} color="#c53a34" marker={7} labels={['Jul 20', 'Aug 12 · prompt v16', 'Aug 18']} /><p className="insight">Increase is concentrated in yogurt-based sauces incorrectly normalized as mayonnaise.</p></section>
    </div>
    <section className="panel"><PanelTitle title="Category performance" subtitle="Production correction rate · exact counts shown for context" badge={<Pill>Lower is better</Pill>} />{categoryData.map((x) => <Bar key={x[0]} label={x[0]} value={x[1]} max={35} suffix={`${x[1]}% · n=${x[2]}`} tone={x[1] >= 25 ? 'critical' : x[1] >= 18 ? 'warning' : 'healthy'} />)}</section>
    <ModelComparison />
    <section className="panel flush"><PanelTitle title="High-confidence + user corrected" subtitle="Overconfident mistakes prioritized for investigation" badge={<Pill tone="critical">76 cases</Pill>} /><ReviewTable meals={reviews.filter((x) => x.confidence >= 88)} open={(meal) => navigate({ page: 'reviews', meal })} /></section>
  </div>
}

function ModelComparison() {
  const { t } = useI18n()
  const rows: Array<[string, string, string, string, Severity, string]> = [
    ['Canonical match', '89.2%', '92.7%', '+3.5 pp', 'healthy', 'Improvement'], ['Sauce accuracy', '82.4%', '75.0%', '−7.4 pp', 'critical', 'Regression'],
    ['Calorie MAE', '92 kcal', '74 kcal', '−18 kcal', 'healthy', 'Improvement'], ['P95 latency', '3.8s', '5.1s', '+1.3s', 'critical', 'Regression'],
    ['Cost / analysis', '$0.021', '$0.026', '+$0.005', 'warning', 'Watch'], ['Failure rate', '1.1%', '1.3%', '+0.2 pp', 'warning', 'Watch'],
  ]
  return <section className="panel"><PanelTitle title="Model version comparison" subtitle="Golden Meal Set v4 · prompt v16 · pipeline 3.4.2" badge={<Pill tone="critical">Regression detected</Pill>} /><table className="comparison-table"><thead><tr><th>{t('Metric')}</th><th>v3.1</th><th>v3.2</th><th>{t('Change')}</th><th>{t('Result')}</th></tr></thead><tbody>{rows.map((r) => <tr key={r[0]}><th>{t(r[0])}</th><td>{r[1]}</td><td>{r[2]}</td><td className={r[4]}>{r[3]}</td><td className={r[4]}>{t(r[5])}</td></tr>)}</tbody></table></section>
}

function Reviews({ navigate }: { navigate: (route: Route) => void }) {
  const { t } = useI18n()
  const [filter, setFilter] = useState('Unreviewed')
  return <div className="page"><PageHeader title="Meal Reviews" question="Human-in-the-loop evaluation queue" action={<Pill tone="warning">128 unreviewed</Pill>} />
    <div className="tabs filter-tabs">{['Unreviewed', 'High-confidence mistake', 'Low confidence', 'Large calorie correction', 'Clarification required', 'Random sample'].map((x) => <button className={filter === x ? 'active' : ''} onClick={() => setFilter(x)} key={x}>{t(x)}</button>)}</div>
    <section className="panel flush"><div className="table-toolbar"><span><SlidersHorizontal size={14} />{t('Queue')}: <strong>{t(filter)}</strong></span><span>4 / 128 <button className="small-button">{t('Columns')}</button></span></div><ReviewTable meals={reviews} open={(meal) => navigate({ page: 'reviews', meal })} /></section><p className="keyboard-note">J / K · 1–4</p>
  </div>
}

function ReviewTable({ meals, open }: { meals: ReviewMeal[]; open: (meal: ReviewMeal) => void }) {
  const { t } = useI18n()
  return <div className="table-scroll"><table className="data-table"><thead><tr><th>{t('Meal')}</th><th>{t('Created')}</th><th>{t('Foods')}</th><th>{t('Confidence')}</th><th>{t('Correction')}</th><th>{t('Error type')}</th><th>{t('Model')}</th><th>{t('Status')}</th></tr></thead><tbody>{meals.map((meal) => <tr key={meal.id} onClick={() => open(meal)} tabIndex={0} onKeyDown={(e) => e.key === 'Enter' && open(meal)}><td><div className="meal-cell"><img src={meal.image} alt="" /><span><strong>{meal.title}</strong><small>{meal.id}</small></span></div></td><td>{meal.created}</td><td>{meal.foods}</td><td><div className="confidence"><b>{meal.confidence}%</b><i><em style={{ width: `${meal.confidence}%` }} /></i></div></td><td className="critical">{meal.correction}</td><td><code>{meal.error}</code></td><td>{meal.model}</td><td><Pill tone={meal.status === 'Unreviewed' ? 'warning' : 'info'}>{meal.status}</Pill></td></tr>)}</tbody></table></div>
}

function MealInspector({ meal, back, openTrace }: { meal: ReviewMeal; back: () => void; openTrace: () => void }) {
  const { t } = useI18n()
  const [review, setReview] = useState('')
  useEffect(() => {
    const key = (e: KeyboardEvent) => { const labels = ['Correct', 'Acceptable estimate', 'Needs improvement', 'Incorrect']; const i = Number(e.key) - 1; if (i >= 0 && i < 4 && !(e.target instanceof HTMLInputElement) && !(e.target instanceof HTMLTextAreaElement)) setReview(labels[i]) }
    addEventListener('keydown', key); return () => removeEventListener('keydown', key)
  }, [])
  return <div className="page"><div className="inspector-heading"><button className="back-button" onClick={back}><ArrowLeft size={18} />{t('Back')}</button><PageHeader title="Meal inspector" question={`${meal.id} · ${meal.created} · ${meal.user}`} action={<button className="secondary-button" onClick={openTrace}><Network size={15} />{t('Open trace')} {meal.trace}</button>} /></div>
    <div className="inspector-grid"><section className="panel flush photo-panel"><img src={meal.image} alt="Meal submitted for review" /><div><span className="eyebrow">{t('USER INPUT')}</span><blockquote>“{meal.input}”</blockquote><div className="pill-row"><Pill>Photo + text</Pill><Pill tone="healthy">PII redacted</Pill></div></div></section>
      <section className="panel flush diff-panel"><div className="diff-heading"><div><span>{t('AI PREDICTION')}</span><small>model v3.2 · prompt v16</small></div><div><span>{t('FINAL USER LOG')}</span><small>14:34</small></div></div>{meal.diffs.map((d) => <div className={`diff-row ${d.severity}`} key={d.name}><div><strong>{d.name}</strong><span>{d.ai}</span></div><ChevronRight size={16} /><div><strong>{d.final}</strong><span>{d.note}</span></div></div>)}<div className="nutrition-diff"><div><span>{t('AI TOTAL')}</span><strong>684 kcal</strong><small>P 48 · C 72 · F 24</small></div><div><span>{t('FINAL TOTAL')}</span><strong>558 kcal</strong><small>P 51 · C 49 · F 18</small></div></div></section>
    </div>
    <div className="review-grid"><section className="panel"><PanelTitle title="Review this case" subtitle="Use keys 1–4 for rapid labeling" /><div className="review-labels">{['Correct', 'Acceptable estimate', 'Needs improvement', 'Incorrect'].map((x, i) => <button className={review === x ? 'active' : ''} key={x} onClick={() => setReview(x)}><kbd>{i + 1}</kbd>{t(x)}</button>)}</div><div className="tag-row"><button className="active">wrong_canonical_match</button><button>portion_overestimate</button><button>hidden_sauce_missing</button></div><textarea aria-label="Reviewer note" placeholder={t('Optional reviewer note…')} /></section><section className="panel"><PanelTitle title="Analysis context" subtitle="Versioned metadata for reproduction" /><Meta rows={[['Model', 'vision-v3.2'], ['Prompt', 'meal-analysis-v16'], ['Pipeline', '3.4.2'], ['Confidence', '0.96'], ['Clarification', 'Not requested'], ['Environment', 'Production']]} /></section></div>
  </div>
}

function Traces({ navigate }: { navigate: (route: Route) => void }) {
  const [filter, setFilter] = useState('All statuses')
  const rows = Array.from({ length: 8 }, (_, i) => ({ meal: reviews[i % 4], duration: [2744, 1852, 8104, 3210, 2988, 6421, 7492, 2136][i], failed: i === 2 || i === 6 }))
  return <div className="page"><PageHeader title="Traces" question="Follow every meal analysis through the pipeline" fresh="Streaming · 12 sec ago" /><div className="tabs">{['All statuses', 'Errors', 'Slow > 6s', 'Retried', 'Corrected'].map((x) => <button className={filter === x ? 'active' : ''} onClick={() => setFilter(x)} key={x}>{x}</button>)}</div><section className="panel flush"><div className="table-scroll"><table className="data-table trace-table"><thead><tr><th>Trace ID</th><th>Time</th><th>Duration</th><th>Status</th><th>Model</th><th>Prompt</th><th>Foods / confidence</th><th>Corrections</th></tr></thead><tbody>{rows.map(({ meal, duration, failed }, i) => <tr key={i} onClick={() => navigate({ page: 'traces', trace: meal })}><td><code>{i === 0 ? meal.trace : `tr_${i}b91a07c`}</code></td><td>{14 - i}:3{i}</td><td className={duration > 6000 ? 'critical' : ''}>{duration}ms</td><td><Pill tone={failed ? 'critical' : 'healthy'}>{failed ? 'Error' : 'Success'}</Pill></td><td>v3.2</td><td>p16</td><td>{2 + (i % 4)} foods · {96 - i * 3}%</td><td>{i % 3 === 0 ? '2 edits' : 'None'}</td></tr>)}</tbody></table></div></section></div>
}

function TraceInspector({ meal, back, openMeal }: { meal: ReviewMeal; back: () => void; openMeal: () => void }) {
  const { t } = useI18n()
  const [selected, setSelected] = useState(4)
  const [raw, setRaw] = useState(false)
  const span = spans[selected]
  return <div className="page"><div className="inspector-heading"><button className="back-button" onClick={back}><ArrowLeft size={18} />{t('Back')}</button><PageHeader title={`${t('Traces')} · ${meal.trace}`} question={`${meal.id} · request req_7fd12c · analysis job aj_91c7`} action={<button className="secondary-button" onClick={openMeal}><Utensils size={15} />{t('Meal')}</button>} /></div>
    <Metrics items={[{ label: 'Status', value: 'Success', delta: 'HTTP 200', tone: 'healthy' }, { label: 'Total duration', value: '2.74s', delta: 'P78' }, { label: 'Model / prompt', value: 'v3.2 / p16', note: 'pipeline 3.4.2' }, { label: 'Retries', value: '1', delta: 'Succeeded', tone: 'warning' }, { label: 'Environment', value: 'Production', note: 'eu-central' }]} />
    <section className="panel"><PanelTitle title="Trace waterfall" subtitle="Select a span to inspect provider, output, validation, and retries" /><div className="waterfall">{spans.map((s, i) => <button key={s[0]} className={selected === i ? 'active' : ''} onClick={() => setSelected(i)}><code>{s[0]}</code><span><i className={s[3]} style={{ left: `${s[1] / 27.44}%`, width: `${Math.max(0.5, s[2] / 27.44)}%` }} /></span><b>{s[2]}ms</b></button>)}</div><div className="waterfall-axis"><span>0ms</span><span>1.0s</span><span>2.0s</span><span>2.74s</span></div></section>
    <div className="two-column trace-details"><section className="panel"><PanelTitle title={span[0]} subtitle={span[4]} badge={<Pill tone={span[3]}>{span[3] === 'critical' ? 'Selection issue' : 'Success'}</Pill>} /><Meta rows={[['Duration', `${span[2]} ms`], ['Provider', 'Nutrition retrieval service'], ['Attempt', '2 of 2'], ['Cache', 'Miss'], ['Region', 'eu-central-1']]} />{selected === 4 && <><h3 className="eyebrow">{t('RETRIEVAL CANDIDATES')}</h3><Candidate rank="1" name="Mayonnaise, regular" score="0.86" selected /><Candidate rank="2" name="Yogurt sauce, plain" score="0.84" /><Candidate rank="3" name="Garlic yogurt dip" score="0.78" /><p className="insight">Selected by combined vector rank + lexical match. The 0.02 score margin was below the recommended clarification threshold.</p></>}</section>
      <section className="panel"><PanelTitle title="Structured output" subtitle="Secrets and signed image URLs are redacted" badge={<div className="toggle"><button className={!raw ? 'active' : ''} onClick={() => setRaw(false)}>{t('Formatted')}</button><button className={raw ? 'active' : ''} onClick={() => setRaw(true)}>{t('Raw JSON')}</button></div>} />{raw ? <pre>{`{\n  "concept": "creamy white sauce",\n  "selected_food_id": "food_mayo_001",\n  "confidence": 0.96,\n  "api_key": "[REDACTED]"\n}`}</pre> : <Meta rows={[['Detected concept', 'creamy white sauce'], ['Selected food', 'Mayonnaise, regular'], ['Canonical food ID', 'food_mayo_001'], ['Similarity', '0.86'], ['Selection confidence', '0.96'], ['Validation', 'Schema passed']]} />}<hr /><h3 className="eyebrow">{t('NUTRITION SOURCE')}</h3><Meta rows={[['Source', 'NutritionDB'], ['Reference', '100 g'], ['Energy', '680 kcal / 100 g'], ['Estimated amount', '30 g'], ['Calculated', '204 kcal']]} /></section></div>
    <section className="panel idempotency"><GitCompareArrows size={20} /><div><strong>Idempotency check passed</strong><span>operation meal-log-f71a · 2 attempts · 1 meal created · duplicate prevented</span></div><Pill tone="healthy">Duplicate prevented</Pill></section>
  </div>
}

function Reliability() {
  const services: Array<[string, string, string, Severity, string]> = [['Image upload', '99.9%', '420ms', 'healthy', 'Healthy'], ['Vision model', '99.1%', '2.8s', 'warning', 'Degraded'], ['Food retrieval', '99.8%', '310ms', 'healthy', 'Healthy'], ['Nutrition lookup', '98.9%', '640ms', 'warning', 'Degraded'], ['Meal persistence', '99.99%', '92ms', 'healthy', 'Healthy']]
  return <div className="page"><PageHeader title="Reliability" question="Is the meal logging pipeline healthy?" fresh="Auto-refresh · 30 sec" /><Metrics items={[{ label: 'Request volume', value: '18.6k', delta: '+6.2%' }, { label: 'Success rate', value: '98.7%', delta: '−0.3 pp', tone: 'warning' }, { label: 'Median latency', value: '2.8s', delta: '+0.1s', tone: 'warning' }, { label: 'P95 / P99', value: '6.8s / 9.2s', delta: 'P95 above SLO', tone: 'critical' }, { label: 'Retry rate', value: '3.2%', delta: '81% recovered', tone: 'warning' }, { label: 'Timeout rate', value: '0.6%', delta: '112 requests', tone: 'critical' }]} /><div className="two-column"><section className="panel flush"><PanelTitle title="Pipeline health" subtitle="Quality errors excluded from this operational view" /><table className="service-table"><thead><tr><th>Service</th><th>Success</th><th>P95</th><th>Status</th></tr></thead><tbody>{services.map((s) => <tr key={s[0]}><th>{s[0]}</th><td>{s[1]}</td><td>{s[2]}</td><td><Pill tone={s[3]}>{s[4]}</Pill></td></tr>)}</tbody></table></section><section className="panel"><PanelTitle title="P95 latency trend" subtitle="Deployment markers align version changes" /><div className="inline-value"><strong>6.8s</strong><Pill tone="critical">SLO &lt; 6.0s</Pill></div><Trend values={latencyTrend} color="#c53a34" marker={7} labels={['Jul 20', 'Aug 12 · v3.2', 'Aug 18']} /></section></div><section className="panel"><PanelTitle title="System error breakdown" subtitle="Operational failures, separate from AI accuracy errors" />{[['AI_PROVIDER_TIMEOUT', 112, '112 · 0.60%', 'critical'], ['NUTRITION_LOOKUP_FAILED', 54, '54 · 0.29%', 'warning'], ['INVALID_MODEL_OUTPUT', 31, '31 · 0.17%', 'warning'], ['IMAGE_UPLOAD_FAILED', 18, '18 · 0.10%', 'info'], ['DATABASE_TIMEOUT', 6, '6 · 0.03%', 'info']].map((x) => <Bar key={x[0]} label={x[0] as string} value={x[1] as number} max={130} suffix={x[2] as string} tone={x[3] as Severity} />)}</section></div>
}

function MobileAppPage() {
  const { t, language } = useI18n()
  const [tab, setTab] = useState<'ota' | 'config'>('ota')
  const [locale, setLocale] = useState<'tr' | 'en'>('tr')
  const [selectedKey, setSelectedKey] = useState(otaRows[0].key as string)
  const [keyQuery, setKeyQuery] = useState('')
  const [overrides, setOverrides] = useState<Record<string, string>>({ mealComposeTitle: 'Bugün ne yedin?', mealAnalyze: 'AI ile analiz et' })
  const [notice, setNotice] = useState('')
  const [flags, setFlags] = useState({ photo: true, voice: false, maintenance: false, rollout: 35, minVersion: '1.0.0' })
  const row = otaRows.find((item) => item.key === selectedKey) || otaRows[0]
  const visibleRows = otaRows.filter((item) =>
    `${item.key} ${item.tr} ${item.en}`
      .toLocaleLowerCase()
      .includes(keyQuery.toLocaleLowerCase()),
  )
  const fallback = row[locale]
  const payloadBytes = new Blob([JSON.stringify(overrides)]).size
  const coverage = Math.round(Object.values(overrides).filter((value) => value.trim()).length / otaRows.length * 100)
  const validate = () => {
    const fallbacks = Object.fromEntries(otaRows.map((item) => [item.key, item[locale]]))
    const issues = validateTranslationBundle({ locale, version: 12, status: 'draft', values: overrides }, fallbacks)
    setNotice(issues.length ? `${issues[0].code}: ${issues[0].key}` : 'Validation passed')
  }
  const notify = (message: string) => { setNotice(message); window.setTimeout(() => setNotice(''), 2800) }

  return <div className="page mobile-app-page">
    <PageHeader title="Mobile App" question="Manage OTA copy, rollout, and mobile runtime configuration." action={<Pill tone="healthy">Supabase · translation_bundles</Pill>} />
    <div className="tabs"><button className={tab === 'ota' ? 'active' : ''} onClick={() => setTab('ota')}>{t('OTA Translations')}</button><button className={tab === 'config' ? 'active' : ''} onClick={() => setTab('config')}>{t('Remote Config')}</button></div>
    {tab === 'ota' ? <>
      <Metrics items={[{ label: 'Locale', value: locale.toUpperCase(), note: locale === 'tr' ? 'Türkçe' : 'English' }, { label: 'Version', value: locale === 'tr' ? 'v12' : 'v9', delta: language === 'tr' ? '+1 taslak' : '+1 draft', tone: 'warning' }, { label: 'Coverage', value: `${coverage}%`, note: language === 'tr' ? `${Object.keys(overrides).length} / ${otaRows.length} geçersiz kılma` : `${Object.keys(overrides).length} / ${otaRows.length} overrides` }, { label: 'Status', value: 'Draft', note: language === 'tr' ? 'Canlı v11' : 'Production v11', tone: 'warning' }, { label: 'Payload', value: `${payloadBytes} B`, note: language === 'tr' ? 'sınır 64 KB' : 'limit 64 KB', tone: 'healthy' }]} />
      <section className="panel flush bundle-list"><div className="translation-toolbar"><div><h2>{t('Translation bundles')}</h2><p>{t('Mobile clients cache the latest valid bundle and retain bundled ARB fallback.')}</p></div><button className="secondary-button">+ {t('New draft')}</button></div><table className="data-table"><thead><tr><th>{t('Locale')}</th><th>{t('Version')}</th><th>{t('Status')}</th><th>{t('Coverage')}</th><th>{t('Updated')}</th><th>{t('Actions')}</th></tr></thead><tbody><tr className={locale === 'tr' ? 'selected-row' : ''} onClick={() => setLocale('tr')}><td><strong>TR</strong> · Türkçe</td><td>v12</td><td><Pill tone="warning">Draft</Pill></td><td>96%</td><td>8 dk önce</td><td><button className="text-button">{t('Edit bundle')}</button></td></tr><tr className={locale === 'en' ? 'selected-row' : ''} onClick={() => setLocale('en')}><td><strong>EN</strong> · English</td><td>v9</td><td><Pill tone="healthy">Production</Pill></td><td>100%</td><td>Aug 16</td><td><button className="text-button">{t('Edit bundle')}</button></td></tr></tbody></table></section>
      <div className="translation-editor-grid"><section className="panel flush key-list"><div className="key-list-header"><strong>{t('Translation key')}</strong><span>{otaRows.length} keys</span></div><input className="key-search" value={keyQuery} onChange={(event) => setKeyQuery(event.target.value)} placeholder={language === 'tr' ? 'Anahtar veya metin ara…' : 'Search key or copy…'} />{visibleRows.map((item) => <button className={selectedKey === item.key ? 'active' : ''} key={item.key} onClick={() => setSelectedKey(item.key)}><code>{item.key}</code><span className={overrides[item.key]?.trim() ? 'healthy-dot' : 'empty-dot'} /></button>)}</section>
        <section className="panel translation-editor"><PanelTitle title="Edit bundle" subtitle={`${locale.toUpperCase()} · v12 · ${selectedKey}`} badge={<Pill tone="warning">Draft</Pill>} /><label><span>{t('Bundled fallback')}</span><textarea value={fallback} readOnly /></label><label><span>{t('OTA override')}</span><textarea value={overrides[selectedKey] || ''} maxLength={500} onChange={(event) => setOverrides({ ...overrides, [selectedKey]: event.target.value })} placeholder={fallback} /></label><div className="editor-meta"><span>{(overrides[selectedKey] || '').length} / 500</span><span>{payloadBytes} / 65,536 bytes</span></div><p className="insight">{t('Only non-empty values override the bundled ARB string.')}</p><div className="editor-actions"><button className="secondary-button" onClick={validate}>{t('Validate')}</button><button className="primary-button" onClick={() => notify('Draft saved')}>{t('Save draft')}</button></div></section>
        <aside className="panel release-panel"><PanelTitle title="Release" subtitle="Draft v12 → Staging → Production" /><div className="release-step done"><span>1</span><div><strong>{t('Save draft')}</strong><small>r.engineer · 8 dk önce</small></div></div><div className="release-step"><span>2</span><div><strong>{t('Validate')}</strong><small>Placeholder · length · payload</small></div></div><div className="release-step"><span>3</span><div><strong>{t('Promote to staging')}</strong><small>Internal QA devices</small></div></div><div className="release-step locked"><span>4</span><div><strong>{t('Promote to production')}</strong><small>{t('Production promotion requires Admin role.')}</small></div></div><button className="secondary-button full" onClick={() => notify('Promoted to staging')}>{t('Promote to staging')}</button><button className="primary-button full" disabled title={t('Production promotion requires Admin role.')}>{t('Promote to production')}</button></aside>
      </div>
      <section className="panel"><PanelTitle title="Change history" subtitle="Every publication and rollback is audit logged" /><div className="audit-row"><code>v11</code><strong>mealComposeTitle · 3 overrides</strong><code>admin.user</code><span>Production · Aug 16</span></div><div className="audit-row"><code>v10</code><strong>mealAnalyze · 1 override</strong><code>r.engineer</code><span>Archived · Aug 12</span></div><button className="secondary-button history-button">{t('Rollback')} v11 → v13</button></section>
    </> : <>
      <div className="two-column mobile-config-grid"><section className="panel"><PanelTitle title="Feature flags" subtitle="Changes are versioned and applied through remote configuration" /><ConfigToggle label="Analysis photo input" checked={flags.photo} onChange={(photo) => setFlags({ ...flags, photo })} /><ConfigToggle label="Voice meal entry" checked={flags.voice} onChange={(voice) => setFlags({ ...flags, voice })} /><ConfigToggle label="Maintenance mode" checked={flags.maintenance} onChange={(maintenance) => setFlags({ ...flags, maintenance })} tone="critical" /></section><section className="panel"><PanelTitle title="Mobile runtime" subtitle="Safe rollout controls" /><label className="config-field"><span>{t('Minimum app version')}</span><input value={flags.minVersion} onChange={(e) => setFlags({ ...flags, minVersion: e.target.value })} /></label><label className="config-field"><span>{t('Rollout')} · {flags.rollout}%</span><input type="range" min="0" max="100" value={flags.rollout} onChange={(e) => setFlags({ ...flags, rollout: Number(e.target.value) })} /></label><div className="config-summary"><span>{t('Eligible users')}</span><strong>4,369 / 12,482</strong></div><button className="primary-button" onClick={() => notify('Draft saved')}>{t('Save configuration')}</button></section></div>
      <section className="panel"><PanelTitle title="Safety checks" subtitle="Server-side authorization remains required for every write" /><div className="safety-grid"><Pill tone="healthy">Schema valid</Pill><Pill tone="healthy">Audit logging enabled</Pill><Pill tone="warning">Production requires Admin</Pill><Pill>Rollback available</Pill></div></section>
    </>}
    {notice && <div className={`toast ${notice.startsWith('Placeholder') ? 'error' : ''}`} role="status"><ClipboardCheck size={16} /><div><strong>{t(notice)}</strong>{notice === 'Validation passed' && <span>{t('No placeholder, length, or payload-size errors found.')}</span>}</div></div>}
  </div>
}

function ConfigToggle({ label, checked, onChange, tone = 'info' }: { label: string; checked: boolean; onChange: (value: boolean) => void; tone?: Severity }) {
  const { t } = useI18n()
  return <label className="config-toggle"><span><strong>{t(label)}</strong><small>{t(checked ? 'Enabled' : 'Disabled')}</small></span><input type="checkbox" checked={checked} onChange={(e) => onChange(e.target.checked)} /><i className={tone} /></label>
}

function Analytics() { return <Supporting title="Analytics" question="Where does meal logging friction appear?"><Metrics items={[{ label: 'Starts', value: '10,000' }, { label: 'Input selected', value: '9,620', delta: '96.2%', tone: 'healthy' }, { label: 'Analyzed', value: '9,410', delta: '97.8%', tone: 'healthy' }, { label: 'Reviewed', value: '8,970', delta: '95.3%', tone: 'warning' }, { label: 'Logged', value: '8,721', delta: '97.2%', tone: 'healthy' }]} /><section className="panel"><PanelTitle title="Meal logging funnel" subtitle="Unique meal-add sessions" />{[['Add meal started', 10000], ['Photo / text selected', 9620], ['Analysis completed', 9410], ['Review completed', 8970], ['Meal logged', 8721]].map((x) => <Bar key={x[0]} label={x[0] as string} value={x[1] as number} max={10000} suffix={String(x[1])} tone="healthy" />)}</section></Supporting> }
function UsersPage() { return <Supporting title="Users" question="Support-relevant account signals with identity minimized by default."><section className="panel flush"><table className="data-table"><thead><tr><th>Anonymized ID</th><th>Status</th><th>Created</th><th>Meals</th><th>Last activity</th></tr></thead><tbody>{[['User 8F31…', 'Active', 'Aug 2', '48', '2 min ago'], ['User 1A09…', 'Active', 'Jul 18', '132', '1 hr ago'], ['User C921…', 'Limited', 'Jun 12', '28', 'Today']].map((x) => <tr key={x[0]}>{x.map((v) => <td key={v}>{v}</td>)}</tr>)}</tbody></table></section></Supporting> }
function Audit() { return <Supporting title="Audit Log" question="Sensitive administrative actions and data access."><section className="panel"><PanelTitle title="Recent activity" />{[['r.engineer', 'model rollout inspected', 'model/v3.2', 'Success · 14:22'], ['a.reviewer', 'meal review updated', 'meal/01J8K3QK', 'Success · 13:48'], ['admin', 'prompt activated', 'prompt/v16', 'Success · Aug 12']].map((x) => <div className="audit-row" key={x[2]}><code>{x[0]}</code><strong>{x[1]}</strong><code>{x[2]}</code><span>{x[3]}</span></div>)}</section></Supporting> }
function SettingsPage() { return <Supporting title="Settings" question="Production configuration is informational for the Engineer role."><section className="panel settings-panel"><PanelTitle title="Active production stack" subtitle="Promotion requires Admin role and a passed evaluation run" /><Meta rows={[['Vision', 'vision-v3.2'], ['Normalization', 'normalizer-v2'], ['Prompt', 'meal-analysis-v16 · Production'], ['Pipeline', '3.4.2'], ['Evaluation gate', 'Golden Meal Set v4 · Passed']]} /><Pill>Read only · Engineer role</Pill></section></Supporting> }
function Supporting({ title, question, children }: { title: string; question: string; children: React.ReactNode }) { return <div className="page"><PageHeader title={title} question={question} />{children}</div> }

function PanelTitle({ title, subtitle, badge }: { title: string; subtitle?: string; badge?: React.ReactNode }) { const { t } = useI18n(); return <div className="panel-title"><div><h2>{t(title)}</h2>{subtitle && <p>{t(subtitle)}</p>}</div>{badge}</div> }
function Pill({ children, tone = 'info' }: { children: React.ReactNode; tone?: Severity }) { const { t } = useI18n(); return <span className={`pill ${tone}`}>{typeof children === 'string' ? t(children) : children}</span> }
function Meta({ rows }: { rows: Array<[string, string]> }) { const { t } = useI18n(); return <dl className="meta-list">{rows.map(([key, value]) => <div key={key}><dt>{t(key)}</dt><dd>{t(value)}</dd></div>)}</dl> }
function Candidate({ rank, name, score, selected }: { rank: string; name: string; score: string; selected?: boolean }) { return <div className={`candidate ${selected ? 'selected' : ''}`}><span>{rank}.</span><strong>{name}</strong><code>{score}</code>{selected && <Pill tone="warning">Selected</Pill>}</div> }

function Bar({ label, value, max, suffix, tone = 'info', onClick }: { label: string; value: number; max: number; suffix: string; tone?: Severity; onClick?: () => void }) {
  const { t } = useI18n()
  const content = <><span title={t(label)}>{t(label)}</span><i><em className={tone} style={{ width: `${(value / max) * 100}%` }} /></i><b>{suffix}</b></>
  return onClick ? <button className="bar-row" onClick={onClick}>{content}</button> : <div className="bar-row">{content}</div>
}

function Trend({ values, color, marker, labels }: { values: number[]; color: string; marker?: number; labels: string[] }) {
  const width = 600, height = 118, pad = 6
  const min = Math.min(...values), max = Math.max(...values)
  const points = values.map((v, i) => `${pad + (i / (values.length - 1)) * (width - pad * 2)},${pad + (1 - (v - min) / (max - min)) * (height - pad * 2)}`).join(' ')
  return <figure className="trend" aria-label={`Trend from ${values[0]} to ${values.at(-1)}`}><svg viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="none">{[0, 1, 2, 3].map((i) => <line key={i} x1="0" x2={width} y1={8 + i * 32} y2={8 + i * 32} className="gridline" />)}{marker !== undefined && <line x1={(marker / (values.length - 1)) * width} x2={(marker / (values.length - 1)) * width} y1="0" y2={height} className="marker" />}<polyline points={points} fill="none" stroke={color} strokeWidth="2.2" vectorEffect="non-scaling-stroke" /><circle cx={points.split(' ').at(-1)?.split(',')[0]} cy={points.split(' ').at(-1)?.split(',')[1]} r="3.5" fill={color} /></svg><figcaption>{labels.map((x) => <span key={x}>{x}</span>)}</figcaption></figure>
}
