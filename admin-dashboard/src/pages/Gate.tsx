import { useState, type ReactNode } from 'react'
import { AlertTriangle, Check, Copy, DatabaseZap, Gauge, LogOut, RefreshCw, ShieldAlert } from 'lucide-react'
import { sendEmailCode, signInWithPassword, signOut, verifyEmailCode } from '../lib/queries'
import { useSession } from '../lib/session'
import { useI18n } from '../i18n'
import { Alert, Button, Field, Input, Segmented, Skeleton } from '../ui'

/**
 * Everything behind this gate reads live data under the operator's own JWT.
 * There is no demo mode: if the console cannot reach real data it says so
 * rather than showing numbers that are not true.
 *
 * Rendered *instead of* the shell, not inside it — navigation you cannot use
 * has no business being on screen before you are signed in.
 */
export function Gate({ t, children }: { t: (value: string) => string; children?: ReactNode }) {
  const { status, refresh, email } = useSession()

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
    // The allow-list row is the only thing missing at this point, so hand over
    // the exact statement rather than a description of it.
    const grant = `insert into public.console_admins (user_id, note)\nselect id, 'console operator' from auth.users\nwhere email = '${email ?? 'you@example.com'}'\non conflict (user_id) do nothing;`
    return (
      <Centered icon={<ShieldAlert size={20} />} title={t('This account cannot read console data')}>
        <Alert tone="danger" title={t('Not on the admin allow-list')}>
          {email
            ? `${email} ${t('is signed in but has no row in public.console_admins.')}`
            : t('This account has no row in public.console_admins.')}
        </Alert>
        <p className="ds-help">{t('Run this in the Supabase SQL editor, then reload:')}</p>
        <CopyBlock text={grant} t={t} />
        <div className="ds-row" style={{ justifyContent: 'space-between' }}>
          <Button icon={<LogOut size={14} />} onClick={() => signOut().then(refresh)}>{t('Sign out')}</Button>
          <Button variant="primary" icon={<RefreshCw size={14} />} onClick={refresh}>{t('Check again')}</Button>
        </div>
      </Centered>
    )
  }

  return <SignIn t={t} />
}

function SignIn({ t }: { t: (value: string) => string }) {
  const { refresh } = useSession()
  const [method, setMethod] = useState<'code' | 'password'>('code')
  const [stage, setStage] = useState<'identify' | 'confirm'>('identify')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [code, setCode] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')

  const run = (work: Promise<void>, onDone?: () => void) => {
    setBusy(true)
    setError('')
    work.then(
      () => { setBusy(false); onDone?.() },
      (cause) => { setBusy(false); setError((cause as Error).message) },
    )
  }

  const submit = (event: React.FormEvent) => {
    event.preventDefault()
    if (method === 'password') return run(signInWithPassword(email, password), refresh)
    if (stage === 'identify') {
      return run(sendEmailCode(email), () => {
        setStage('confirm')
        setNotice(t('We sent a one-time code to that address.'))
      })
    }
    return run(verifyEmailCode(email, code.trim()), refresh)
  }

  const switchMethod = (next: string) => {
    setMethod(next as 'code' | 'password')
    setStage('identify')
    setCode('')
    setError('')
    setNotice('')
  }

  return (
    <Centered icon={<Gauge size={20} />} title={t('Sign in to the console')}>
      <Segmented
        label={t('Sign-in method')}
        value={method}
        onChange={switchMethod}
        items={[{ id: 'code', label: t('Email code') }, { id: 'password', label: t('Password') }]}
      />

      <form className="ds-stack ds-stack--sm" onSubmit={submit}>
        <Field label={t('Email')} htmlFor="console-email">
          <Input
            id="console-email"
            type="email"
            autoComplete="username"
            required
            readOnly={stage === 'confirm'}
            value={email}
            onChange={(event) => setEmail(event.target.value)}
          />
        </Field>

        {method === 'password' && (
          <Field label={t('Password')} htmlFor="console-password">
            <Input id="console-password" type="password" autoComplete="current-password" required value={password} onChange={(event) => setPassword(event.target.value)} />
          </Field>
        )}

        {method === 'code' && stage === 'confirm' && (
          <Field label={t('One-time code')} htmlFor="console-code" help={t('Six digits, valid for a few minutes.')}>
            <Input
              id="console-code"
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={8}
              required
              value={code}
              onChange={(event) => setCode(event.target.value)}
            />
          </Field>
        )}

        {notice && !error && <p className="ds-help">{notice}</p>}
        {error && <p className="ds-error"><AlertTriangle size={12} aria-hidden="true" />{error}</p>}

        <Button
          type="submit"
          variant="primary"
          block
          loading={busy}
          disabled={method === 'password' ? !email || !password : stage === 'identify' ? !email : !code}
        >
          {method === 'password' ? t('Sign in') : stage === 'identify' ? t('Send code') : t('Sign in')}
        </Button>

        {method === 'code' && stage === 'confirm' && (
          <Button block onClick={() => { setStage('identify'); setCode(''); setNotice('') }}>{t('Use a different address')}</Button>
        )}

        <p className="ds-help">{t('Console access is limited to operators listed in public.console_admins.')}</p>
      </form>
    </Centered>
  )
}

function CopyBlock({ text, t }: { text: string; t: (value: string) => string }) {
  const [copied, setCopied] = useState(false)
  return (
    <div className="ds-stack ds-stack--sm">
      <pre
        className="ds-mono"
        style={{
          margin: 0, padding: 'var(--sp-3)', overflow: 'auto',
          background: 'var(--surface-sunk)', border: '1px solid var(--border)',
          borderRadius: 'var(--r-2)', fontSize: 'var(--fs-micro)', lineHeight: 1.6,
        }}
      >{text}</pre>
      <Button
        size="sm"
        icon={copied ? <Check size={13} /> : <Copy size={13} />}
        onClick={() => {
          navigator.clipboard?.writeText(text).then(
            () => { setCopied(true); window.setTimeout(() => setCopied(false), 2000) },
            () => undefined,
          )
        }}
      >
        {copied ? t('Copied') : t('Copy SQL')}
      </Button>
    </div>
  )
}

function Centered({ icon, title, children }: { icon?: ReactNode; title?: string; children: ReactNode }) {
  const { language, setLanguage } = useI18n()
  return (
    <div style={{ minHeight: '100dvh', display: 'grid', placeItems: 'center', padding: 'var(--sp-4)', background: 'var(--bg)' }}>
      <div className="ds-stack" style={{ width: 'min(24rem, 100%)' }}>
        <div className="ds-row" style={{ justifyContent: 'space-between' }}>
          <span className="ds-row" style={{ gap: 'var(--sp-2)' }}>
            <span className="rail__mark" aria-hidden="true"><Gauge size={15} /></span>
            <span className="rail__name">Meal Clarity</span>
          </span>
          {/* The product is bilingual, so the door is too. */}
          <Segmented
            label="Interface language"
            value={language}
            onChange={(next) => setLanguage(next as 'tr' | 'en')}
            items={[{ id: 'tr', label: 'TR' }, { id: 'en', label: 'EN' }]}
          />
        </div>

        <div className="ds-card" style={{ padding: 'var(--sp-6)' }}>
          <div className="ds-stack ds-stack--sm">
            {icon && (
              <span className="ds-empty__icon" aria-hidden="true" style={{ marginBottom: 0 }}>{icon}</span>
            )}
            {title && <h1 style={{ fontSize: 'var(--fs-lg)', fontWeight: 650, letterSpacing: '-.015em' }}>{title}</h1>}
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}
