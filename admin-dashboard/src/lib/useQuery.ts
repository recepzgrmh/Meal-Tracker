import { useCallback, useEffect, useRef, useState } from 'react'

export type QueryState<T> = {
  data: T | null
  loading: boolean
  error: unknown
  refetch: () => void
}

/**
 * The smallest thing that covers the four states every screen has to render:
 * loading, error, empty, and loaded. Deliberately not a cache — the console
 * refetches on navigation and on the explicit refresh action.
 */
export function useQuery<T>(run: () => Promise<T>, deps: unknown[]): QueryState<T> {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<unknown>(null)
  const [nonce, setNonce] = useState(0)
  const latest = useRef(0)

  useEffect(() => {
    const ticket = ++latest.current
    setLoading(true)
    setError(null)
    run().then(
      (result) => { if (ticket === latest.current) { setData(result); setLoading(false) } },
      (cause) => { if (ticket === latest.current) { setError(cause); setData(null); setLoading(false) } },
    )
    // `run` is recreated every render by design; deps are declared by the caller.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, nonce])

  const refetch = useCallback(() => setNonce((value) => value + 1), [])
  return { data, loading, error, refetch }
}
