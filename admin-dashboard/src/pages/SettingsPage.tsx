import { useState } from 'react'
import { LogOut } from 'lucide-react'
import { signOut } from '../lib/queries'
import { useSession } from '../lib/session'
import { Alert, Badge, Button, Card, DefinitionList, Section, Segmented, useTheme } from '../ui'
import { useI18n } from '../i18n'
import { PageHeader, type PageProps } from './shared'

const SECTIONS = ['Appearance', 'Session', 'Console access', 'Data sources'] as const
type SectionId = typeof SECTIONS[number]

/**
 * Only settings that are genuinely wired up appear here. Workspace, member and
 * API-key management belong to a server endpoint that does not exist yet, so
 * they are not mocked into the UI.
 */
export function SettingsPage({ t }: PageProps) {
  const [section, setSection] = useState<SectionId>('Appearance')

  return (
    <div className="page page--narrow">
      <PageHeader title={t('Settings')} description={t('Console preferences and connection status.')} />

      <div className="settings">
        <nav className="settings__nav" aria-label={t('Settings sections')}>
          {SECTIONS.map((entry) => (
            <button
              key={entry}
              type="button"
              className={`settings__link${section === entry ? ' is-active' : ''}`}
              aria-current={section === entry ? 'page' : undefined}
              onClick={() => setSection(entry)}
            >
              {t(entry)}
            </button>
          ))}
        </nav>

        <div className="ds-stack ds-stack--lg">
          {section === 'Appearance' && <Appearance t={t} />}
          {section === 'Session' && <SessionSettings t={t} />}
          {section === 'Console access' && <AccessSettings t={t} />}
          {section === 'Data sources' && <SourceSettings t={t} />}
        </div>
      </div>
    </div>
  )
}

type T = { t: (value: string) => string }

function Row({ label, help, children }: { label: string; help?: string; children: React.ReactNode }) {
  return (
    <div className="settings__field">
      <span className="settings__field-text">
        <span className="settings__field-label">{label}</span>
        {help && <span className="settings__field-help">{help}</span>}
      </span>
      <div>{children}</div>
    </div>
  )
}

function Appearance({ t }: T) {
  const { preference, setPreference } = useTheme()
  const { language, setLanguage } = useI18n()
  return (
    <Section title={t('Appearance')} subtitle={t('Stored in this browser only')}>
      <div className="settings__group">
        <Row label={t('Theme')} help={t('Light is the default. System follows your operating system setting.')}>
          <Segmented
            label={t('Theme')}
            value={preference}
            onChange={(next) => setPreference(next as 'light' | 'dark' | 'system')}
            items={[{ id: 'light', label: t('Light') }, { id: 'dark', label: t('Dark') }, { id: 'system', label: t('System') }]}
          />
        </Row>
        <Row label={t('Interface language')} help={t('Applies to console chrome. Data is shown as stored.')}>
          <Segmented
            label={t('Interface language')}
            value={language}
            onChange={(next) => setLanguage(next as 'tr' | 'en')}
            items={[{ id: 'tr', label: 'Türkçe' }, { id: 'en', label: 'English' }]}
          />
        </Row>
      </div>
    </Section>
  )
}

function SessionSettings({ t }: T) {
  const { email, session, refresh } = useSession()
  return (
    <Section title={t('Session')} subtitle={t('The identity every query runs as')}>
      <Card>
        <DefinitionList rows={[
          [t('Signed in as'), email ?? '—'],
          [t('User id'), <code className="ds-mono" key="u">{session?.user.id ?? '—'}</code>],
          [t('Provider'), session?.user.app_metadata?.provider ?? '—'],
          [t('Session expires'), session?.expires_at ? new Date(session.expires_at * 1000).toLocaleString() : '—'],
        ]} />
      </Card>
      <div className="ds-row" style={{ justifyContent: 'flex-end' }}>
        <Button icon={<LogOut size={14} />} onClick={() => signOut().then(refresh)}>{t('Sign out')}</Button>
      </div>
    </Section>
  )
}

function AccessSettings({ t }: T) {
  return (
    <Section title={t('Console access')} subtitle={t('How cross-user reads are authorised')}>
      <Card>
        <DefinitionList rows={[
          [t('Mechanism'), t('Row-level security plus an allow-list')],
          [t('Allow-list table'), <code className="ds-mono" key="a">public.console_admins</code>],
          [t('Check'), <code className="ds-mono" key="c">public.is_console_admin()</code>],
          [t('Key in browser'), <Badge tone="ok" dot key="k">{t('Publishable (anon) only')}</Badge>],
          [t('Writes'), <Badge key="w">{t('None from the browser')}</Badge>],
        ]} />
      </Card>
      <Alert tone="info" title={t('Granting access')}>
        {t('Insert the operator’s auth user id into public.console_admins as the service role. Removing the row revokes access on their next request.')}
      </Alert>
    </Section>
  )
}

function SourceSettings({ t }: T) {
  return (
    <Section title={t('Data sources')} subtitle={t('Where each screen reads from')}>
      <Card>
        <DefinitionList rows={[
          [t('Overview, Reliability, Analytics'), <code className="ds-mono" key="1">admin_analysis_daily</code>],
          [t('AI Quality'), <code className="ds-mono" key="2">admin_category_quality, admin_correction_reasons</code>],
          [t('Meal Reviews'), <code className="ds-mono" key="3">admin_review_queue</code>],
          [t('Traces'), <code className="ds-mono" key="4">analysis_runs, analysis_candidates</code>],
          [t('Users'), <code className="ds-mono" key="5">admin_account_summary</code>],
          [t('Mobile App'), <code className="ds-mono" key="6">translation_bundles</code>],
          [t('Audit Log'), <Badge tone="warn" dot key="7">{t('No source yet')}</Badge>],
        ]} />
      </Card>
      <Alert tone="info" title={t('Migration')}>
        {t('The admin views live in supabase/migrations/20260821120000_admin_console_reads.sql.')}
      </Alert>
    </Section>
  )
}
