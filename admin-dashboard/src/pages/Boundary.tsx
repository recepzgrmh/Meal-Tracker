import type { ReactNode } from 'react'
import { AlertTriangle, Inbox, RotateCcw } from 'lucide-react'
import { describeError } from '../lib/supabase'
import type { QueryState } from '../lib/useQuery'
import { Button, EmptyState, Skeleton } from '../ui'

/**
 * Renders the four states every data surface has, in one place, so no screen
 * can accidentally fall back to placeholder numbers when a read fails.
 */
export function Boundary<T>({ query, t, skeleton, emptyTitle, emptyDescription, emptyAction, isEmpty, children }: {
  query: QueryState<T>
  t: (value: string) => string
  skeleton?: ReactNode
  emptyTitle?: string
  emptyDescription?: string
  emptyAction?: ReactNode
  isEmpty?: (data: T) => boolean
  children: (data: T) => ReactNode
}) {
  if (query.loading) return <>{skeleton ?? <DefaultSkeleton />}</>

  if (query.error) {
    const described = describeError(query.error)
    return (
      <EmptyState
        tone="danger"
        icon={<AlertTriangle size={18} />}
        title={t(described.title)}
        description={t(described.description)}
        actions={
          described.kind === 'network'
            ? <Button icon={<RotateCcw size={14} />} onClick={query.refetch}>{t('Try again')}</Button>
            : undefined
        }
      />
    )
  }

  const data = query.data as T
  const empty = data == null || (isEmpty ? isEmpty(data) : Array.isArray(data) && data.length === 0)
  if (empty) {
    return (
      <EmptyState
        icon={<Inbox size={18} />}
        title={emptyTitle ?? t('No data for this period')}
        description={emptyDescription ?? t('Nothing has been recorded in the selected range yet.')}
        actions={emptyAction}
      />
    )
  }

  return <>{children(data)}</>
}

function DefaultSkeleton() {
  return (
    <div className="ds-stack ds-stack--sm" aria-hidden="true">
      <Skeleton height="1rem" width="45%" />
      <Skeleton height="1rem" width="70%" />
      <Skeleton height="1rem" width="60%" />
    </div>
  )
}

/** Metric-shaped placeholder, so the KPI row does not reflow when data lands. */
export function MetricsSkeleton({ count = 4 }: { count?: number }) {
  return (
    <div className="ds-metrics" aria-hidden="true">
      {Array.from({ length: count }, (_, index) => (
        <div className="ds-metric" key={index}>
          <Skeleton height=".75rem" width="45%" />
          <Skeleton height="1.5rem" width="60%" />
          <Skeleton height=".75rem" width="35%" />
        </div>
      ))}
    </div>
  )
}
