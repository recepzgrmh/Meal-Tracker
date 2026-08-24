import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'

export type ThemePreference = 'light' | 'dark' | 'system'

type ThemeValue = {
  /** What the user chose. `system` defers to the OS. */
  preference: ThemePreference
  /** What is actually painted right now. */
  resolved: 'light' | 'dark'
  setPreference: (next: ThemePreference) => void
  /** Cycles light → dark → system. */
  cycle: () => void
}

const STORAGE_KEY = 'console-theme'
const ThemeContext = createContext<ThemeValue>({
  preference: 'light', resolved: 'light', setPreference: () => undefined, cycle: () => undefined,
})

/** Light is the default. Dark and system are opt-in, never inferred from the OS. */
const readStored = (): ThemePreference => {
  const stored = globalThis.localStorage?.getItem(STORAGE_KEY)
  return stored === 'dark' || stored === 'system' ? stored : 'light'
}

const prefersDark = () => globalThis.matchMedia?.('(prefers-color-scheme: dark)').matches ?? false

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [preference, setPreferenceState] = useState<ThemePreference>(readStored)
  const [systemDark, setSystemDark] = useState(prefersDark)

  useEffect(() => {
    const query = globalThis.matchMedia?.('(prefers-color-scheme: dark)')
    if (!query) return
    const listener = (event: MediaQueryListEvent) => setSystemDark(event.matches)
    query.addEventListener('change', listener)
    return () => query.removeEventListener('change', listener)
  }, [])

  const resolved: 'light' | 'dark' = preference === 'system' ? (systemDark ? 'dark' : 'light') : preference

  useEffect(() => {
    const root = document.documentElement
    // `system` leaves the attribute off so the media query in tokens.css wins.
    if (preference === 'system') root.removeAttribute('data-theme')
    else root.setAttribute('data-theme', preference)
    globalThis.localStorage?.setItem(STORAGE_KEY, preference)
  }, [preference])

  const setPreference = useCallback((next: ThemePreference) => setPreferenceState(next), [])
  const cycle = useCallback(() => {
    setPreferenceState((current) => (current === 'light' ? 'dark' : current === 'dark' ? 'system' : 'light'))
  }, [])

  const value = useMemo(
    () => ({ preference, resolved, setPreference, cycle }),
    [preference, resolved, setPreference, cycle],
  )
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
}

export const useTheme = () => useContext(ThemeContext)
