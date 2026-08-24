import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { Session } from '@supabase/supabase-js'
import { isSupabaseConfigured, supabase } from './supabase'
import { assertConsoleAdmin } from './queries'

type Status = 'loading' | 'unconfigured' | 'signed-out' | 'forbidden' | 'ready'

type SessionValue = {
  status: Status
  session: Session | null
  email: string | null
  refresh: () => void
}

const SessionContext = createContext<SessionValue>({ status: 'loading', session: null, email: null, refresh: () => undefined })

export function SessionProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [status, setStatus] = useState<Status>(isSupabaseConfigured ? 'loading' : 'unconfigured')
  const [nonce, setNonce] = useState(0)

  useEffect(() => {
    if (!supabase) { setStatus('unconfigured'); return }
    let alive = true

    supabase.auth.getSession().then(({ data }) => { if (alive) setSession(data.session) })
    const { data: subscription } = supabase.auth.onAuthStateChange((_event, next) => {
      setSession(next)
      setNonce((value) => value + 1)
    })
    return () => { alive = false; subscription.subscription.unsubscribe() }
  }, [])

  // Membership of console_admins is checked once per session, not per query —
  // the RLS policies enforce it regardless; this only decides what UI to show.
  useEffect(() => {
    if (!supabase) return
    if (!session) { setStatus('signed-out'); return }
    let alive = true
    setStatus('loading')
    assertConsoleAdmin().then(
      () => { if (alive) setStatus('ready') },
      () => { if (alive) setStatus('forbidden') },
    )
    return () => { alive = false }
  }, [session, nonce])

  const refresh = useCallback(() => setNonce((value) => value + 1), [])
  const value = useMemo(
    () => ({ status, session, email: session?.user.email ?? null, refresh }),
    [status, session, refresh],
  )
  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>
}

export const useSession = () => useContext(SessionContext)
