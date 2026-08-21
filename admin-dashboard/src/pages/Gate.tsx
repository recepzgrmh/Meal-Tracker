import { useState, type ReactNode } from 'react'
import { AlertTriangle, DatabaseZap, Gauge, LogOut, ShieldAlert } from 'lucide-react'
import { signInWithPassword, signOut } from '../lib/queries'
import { useSession } from '../lib/session'
import { Alert, Button, Field, Input, Skeleton } from '../ui'

/**
 * Everything behind this gate reads live data under the operator's own JWT.
 * There is no demo mode: if the console cannot reach real data it says so
 * rather than showing numbers that are not true.
 */
export function Gate({ t, children }: { t: (value: string) => string; children: ReactNode }) {
  const { status, refresh } = useSession()

  if (status === 'ready') return <>{children}</>

  if (status === 'loading') {
    return (
      <Centered>
        <div className="ds-stack ds-stack--sm" style={{ width: '100%' }}>
          <Skeleton height="1.25rem" width="60%" />
          <Skeleton height=".875rem" width="85%" />
          <Skeleton height="2.25rem" />
        </div>
      </Centered>
    )
  }

  if (status === 'unconfigured') {
    return (
      <Centered icon={<DatabaseZap size={20} />} title={t('Supabase is not connected')}>
        <Alert tone="warn" title={t('Missing environment')}>
          {t('Copy admin-dashboard/.env.example to .env.local, fill in VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY, then restart the dev server.')}
        </Alert>
      </Centered>
    )
  }

  if (status === 'forbidden') {
    return (
      <Centered icon={<ShieldAlert size={20} />} title={t('This account cannot read console data')}>
        <Alert tone="danger" title={t('Not on the admin allow-list')}>
          {t('Apply supabase/migrations/20260821120000_admin_console_reads.sql, then add this user to public.console_admins.')}
        </Alert>
        <div className="ds-row" style={{ justifyContent: 'flex-end' }}>
          <Button icon={<LogOut size={14} />} onClick={() => signOut().then(refresh)}>{t('Sign out')}</Button>
        </div>
      </Centered>
    )
  }

  return <SignIn t={t} />
}

function SignIn({ t }: { t: (value: string) => string }) {
  const { refresh } = useSession()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const submit = (event: React.FormEvent) => {
    event.preventDefault()
    setBusy(true)
    setError('')
    signInWithPassword(email, password).then(
      () => { setBusy(false); refresh() },
      (cause) => { setBusy(false); setError((cause as Error).message) },
    )
  }

  return (
    <Centered icon={<Gauge size={20} />} title={t('Sign in to the console')}>
      <form className="ds-stack ds-stack--sm" onSubmit={submit}>
        <Field label={t('Email')} htmlFor="console-email">
          <Input id="console-email" type="email" autoComplete="username" required value={email} onChange={(event) => setEmail(event.target.value)} />
        </Field>
        <Field label={t('Password')} htmlFor="console-password">
          <Input id="console-password" type="password" autoComplete="current-password" required value={password} onChange={(event) => setPassword(event.target.value)} />
        </Field>
        {error && (
          <p className="ds-error"><AlertTriangle size={12} aria-hidden="true" />{error}</p>
        )}
        <Button type="submit" variant="primary" block loading={busy} disabled={!email || !password}>{t('Sign in')}</Button>
        <p className="ds-help">{t('Console access is limited to operators listed in public.console_admins.')}</p>
      </form>
    </Centered>
  )
}

function Centered({ icon, title, children }: { icon?: ReactNode; title?: string; children: ReactNode }) {
  return (
    <div style={{ minHeight: '100dvh', display: 'grid', placeItems: 'center', padding: 'var(--sp-4)', background: 'var(--bg)' }}>
      <div className="ds-card" style={{ width: 'min(24rem, 100%)', padding: 'var(--sp-6)' }}>
        <div className="ds-stack ds-stack--sm">
          {icon && (
            <span className="ds-empty__icon" aria-hidden="true" style={{ marginBottom: 0 }}>{icon}</span>
          )}
          {title && <h1 style={{ fontSize: 'var(--fs-lg)', fontWeight: 650, letterSpacing: '-.015em' }}>{title}</h1>}
          {children}
        </div>
      </div>
    </div>
  )
}
