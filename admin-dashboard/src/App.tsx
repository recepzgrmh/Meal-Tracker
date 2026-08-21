import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  Activity, BarChart3, Bell, BookOpen, ChevronsUpDown, ClipboardCheck, Gauge, LayoutDashboard,
  LifeBuoy, Languages, LogOut, Monitor, Moon, Network, PanelLeft, ScrollText,
  Settings, Smartphone, Sun, Users as UsersIcon, Utensils,
} from 'lucide-react'
import { useI18n } from './i18n'
import { signOut } from './lib/queries'
import { SessionProvider, useSession } from './lib/session'
import {
  Avatar, Breadcrumb, Button, CommandMenu, IconButton, Menu, Segmented, ToastProvider,
  useTheme, type Command, type Crumb,
} from './ui'
import { Gate } from './pages/Gate'
import type { Navigate, Page, Route } from './pages/shared'
import { Overview } from './pages/Overview'
import { Quality } from './pages/Quality'
import { Reviews, MealInspector } from './pages/Reviews'
import { Traces, TraceInspector } from './pages/Traces'
import { Reliability } from './pages/Reliability'
import { Analytics } from './pages/Analytics'
import { UsersPage } from './pages/UsersPage'
import { MobileApp } from './pages/MobileApp'
import { Audit } from './pages/Audit'
import { SettingsPage } from './pages/SettingsPage'

type NavLink = { page: Page; label: string; icon: typeof LayoutDashboard }
type NavGroup = { label: string; links: NavLink[] }

const NAV: NavGroup[] = [
  { label: 'MENU', links: [
    { page: 'overview', label: 'Overview', icon: LayoutDashboard },
    { page: 'analytics', label: 'Analytics', icon: BarChart3 },
  ] },
  { label: 'QUALITY', links: [
    { page: 'quality', label: 'AI Quality', icon: ClipboardCheck },
    { page: 'reviews', label: 'Meal Reviews', icon: Utensils },
    { page: 'traces', label: 'Traces', icon: Network },
    { page: 'reliability', label: 'Reliability', icon: Activity },
  ] },
  { label: 'PRODUCT', links: [
    { page: 'users', label: 'Users', icon: UsersIcon },
    { page: 'mobile', label: 'Mobile App', icon: Smartphone },
  ] },
  { label: 'SYSTEM', links: [
    { page: 'audit', label: 'Audit Log', icon: ScrollText },
    { page: 'settings', label: 'Settings', icon: Settings },
  ] },
]

const PAGE_LABEL: Record<Page, string> = {
  overview: 'Overview', analytics: 'Analytics', quality: 'AI Quality', reviews: 'Meal Reviews',
  traces: 'Traces', reliability: 'Reliability', users: 'Users', mobile: 'Mobile App',
  audit: 'Audit Log', settings: 'Settings',
}

function readRoute(): Route {
  const path = location.pathname.split('/').filter(Boolean)
  const page = (PAGE_LABEL[path[1] as Page] ? path[1] : 'overview') as Page
  const params = new URLSearchParams(location.search)
  return {
    page,
    itemId: params.get('item') || undefined,
    traceId: params.get('trace') || undefined,
    userId: params.get('user') || undefined,
    filter: params.get('filter') || undefined,
    section: params.get('section') || undefined,
  }
}

export default function App() {
  return (
    <ToastProvider>
      <SessionProvider>
        <Shell />
      </SessionProvider>
    </ToastProvider>
  )
}

function Shell() {
  const { t, language, setLanguage } = useI18n()
  const { preference, cycle } = useTheme()
  const { email, refresh, status } = useSession()
  const [route, setRoute] = useState<Route>(readRoute)
  const [collapsed, setCollapsed] = useState(() => globalThis.localStorage?.getItem('console-rail') === 'collapsed')
  const [drawer, setDrawer] = useState(false)
  const [palette, setPalette] = useState(false)
  const [range, setRange] = useState('30d')

  useEffect(() => {
    const listener = () => setRoute(readRoute())
    addEventListener('popstate', listener)
    return () => removeEventListener('popstate', listener)
  }, [])

  useEffect(() => { globalThis.localStorage?.setItem('console-rail', collapsed ? 'collapsed' : 'expanded') }, [collapsed])

  const navigate = useCallback<Navigate>((next) => {
    const query = new URLSearchParams()
    if (next.itemId) query.set('item', next.itemId)
    if (next.traceId) query.set('trace', next.traceId)
    if (next.userId) query.set('user', next.userId)
    if (next.filter) query.set('filter', next.filter)
    if (next.section) query.set('section', next.section)
    history.pushState(null, '', `/admin/${next.page}${query.size ? `?${query}` : ''}`)
    setRoute(next)
    setDrawer(false)
    globalThis.scrollTo?.({ top: 0 })
  }, [])

  // ⌘K / Ctrl+K opens the command menu from anywhere.
  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() === 'k' && (event.metaKey || event.ctrlKey)) {
        event.preventDefault()
        setPalette((open) => !open)
      }
    }
    addEventListener('keydown', onKey)
    return () => removeEventListener('keydown', onKey)
  }, [])

  const commands = useMemo<Command[]>(() => [
    ...NAV.flatMap((group) => group.links.map((link) => ({
      id: `go-${link.page}`,
      group: t('Navigate'),
      label: t(link.label),
      icon: <link.icon size={15} />,
      hint: '↵',
      keywords: link.page,
      run: () => navigate({ page: link.page }),
    }))),
    { id: 'theme', group: t('Actions'), label: t('Toggle theme'), icon: <Moon size={15} />, keywords: 'dark light appearance', run: cycle },
    {
      id: 'language', group: t('Actions'), label: t('Switch language'), icon: <Languages size={15} />,
      keywords: 'turkish english tr en', run: () => setLanguage(language === 'tr' ? 'en' : 'tr'),
    },
  ], [t, navigate, cycle, language, setLanguage])

  const crumbs: Crumb[] = [
    { label: t('Console'), onClick: () => navigate({ page: 'overview' }) },
    { label: t(PAGE_LABEL[route.page]), onClick: () => navigate({ page: route.page }) },
    ...(route.traceId ? [{ label: route.traceId.slice(0, 8) }] : route.itemId ? [{ label: route.itemId.slice(0, 8) }] : []),
  ]

  const ThemeIcon = preference === 'dark' ? Moon : preference === 'light' ? Sun : Monitor
  const themeLabel = t(preference === 'dark' ? 'Theme: dark' : preference === 'light' ? 'Theme: light' : 'Theme: system')

  // Navigation you cannot use has no business being on screen. Until the
  // session is ready the gate replaces the shell entirely.
  if (status !== 'ready') return <Gate t={t} />

  const pageProps = { route, navigate, range, t }
  const content = route.traceId
    ? <TraceInspector {...pageProps} />
    : route.itemId
      ? <MealInspector {...pageProps} />
      : <PageBody {...pageProps} />

  return (
    <div className={`shell${collapsed ? ' is-collapsed' : ''}${drawer ? ' is-drawer-open' : ''}`}>
      {drawer && <div className="rail__scrim" onClick={() => setDrawer(false)} />}

      <aside className="rail">
        <div className="rail__brand">
          <span className="rail__mark" aria-hidden="true"><Gauge size={15} /></span>
          <span className="rail__name">Meal Clarity</span>
        </div>

        <nav className="rail__nav" aria-label={t('Primary')}>
          {NAV.map((group) => (
            <div className="rail__group" key={group.label}>
              <p className="rail__group-label">{t(group.label)}</p>
              {group.links.map((link) => {
                const active = route.page === link.page
                return (
                  <button
                    key={link.page}
                    type="button"
                    className={`rail__link${active ? ' is-active' : ''}`}
                    aria-current={active ? 'page' : undefined}
                    title={collapsed ? t(link.label) : undefined}
                    onClick={() => navigate({ page: link.page })}
                  >
                    <link.icon size={15} aria-hidden="true" />
                    <span className="rail__link-text">{t(link.label)}</span>
                  </button>
                )
              })}
            </div>
          ))}
        </nav>

        <div className="rail__foot">
          <button type="button" className="rail__link"><LifeBuoy size={15} aria-hidden="true" /><span className="rail__link-text">{t('Help')}</span></button>
          <button type="button" className="rail__link"><BookOpen size={15} aria-hidden="true" /><span className="rail__link-text">{t('Documentation')}</span></button>
          <Menu
            align="start"
            label={t('Account')}
            items={[
              { type: 'label', label: email ?? t('Not signed in') },
              { label: t('Settings'), icon: <Settings size={14} />, onSelect: () => navigate({ page: 'settings' }) },
              { label: themeLabel, icon: <ThemeIcon size={14} />, onSelect: cycle },
              { type: 'separator' },
              { label: t('Sign out'), icon: <LogOut size={14} />, danger: true, onSelect: () => { signOut().then(refresh) } },
            ]}
            trigger={(props) => (
              <button type="button" className="rail__user" {...props}>
                <Avatar name={email ?? 'Console'} />
                <span className="rail__user-text">
                  <span className="rail__user-name">{email?.split('@')[0] ?? t('Console')}</span>
                  <span className="rail__user-role">{email ?? t('Not signed in')}</span>
                </span>
                <ChevronsUpDown size={13} />
              </button>
            )}
          />
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <IconButton
            label={t(collapsed ? 'Expand sidebar' : 'Collapse sidebar')}
            onClick={() => { setCollapsed((value) => !value); setDrawer((value) => !value) }}
          >
            <PanelLeft size={16} />
          </IconButton>

          <div className="topbar__crumbs"><Breadcrumb items={crumbs} /></div>

          <input
            className="ds-input topbar__search"
            style={{ width: 'auto' }}
            readOnly
            aria-haspopup="dialog"
            placeholder={t('Search pages and actions')}
            aria-label={t('Search pages and actions')}
            onClick={() => setPalette(true)}
            onKeyDown={(event) => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); setPalette(true) } }}
          />

          <span className="topbar__sep" aria-hidden="true" />

          <span className="topbar__range">
            <Segmented
              label={t('Time range')}
              value={range}
              onChange={setRange}
              items={[{ id: '24h', label: '24H' }, { id: '7d', label: '7D' }, { id: '30d', label: '30D' }, { id: '90d', label: '90D' }]}
            />
          </span>
          <Segmented
            label={t('Interface language')}
            value={language}
            onChange={(next) => setLanguage(next as 'tr' | 'en')}
            items={[{ id: 'tr', label: 'TR' }, { id: 'en', label: 'EN' }]}
          />

          <IconButton label={themeLabel} onClick={cycle}><ThemeIcon size={16} /></IconButton>
          <IconButton label={t('Notifications')}><Bell size={16} /></IconButton>
        </header>

        <main>{content}</main>
      </div>

      <CommandMenu
        open={palette}
        onClose={() => setPalette(false)}
        commands={commands}
        placeholder={t('Search pages and actions')}
      />
    </div>
  )
}

function PageBody(props: { route: Route; navigate: Navigate; range: string; t: (value: string) => string }) {
  switch (props.route.page) {
    case 'overview': return <Overview {...props} />
    case 'analytics': return <Analytics {...props} />
    case 'quality': return <Quality {...props} />
    case 'reviews': return <Reviews {...props} />
    case 'traces': return <Traces {...props} />
    case 'reliability': return <Reliability {...props} />
    case 'users': return <UsersPage {...props} />
    case 'mobile': return <MobileApp {...props} />
    case 'audit': return <Audit {...props} />
    case 'settings': return <SettingsPage {...props} />
  }
}
