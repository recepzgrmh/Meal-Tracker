import { ScrollText } from 'lucide-react'
import { Alert, Card, EmptyState } from '../ui'
import { PageHeader, type PageProps } from './shared'

/**
 * There is no audit table in this schema yet — `analysis_runs.error_code` is the
 * only trail, and it records pipeline failures rather than operator actions.
 * Rather than invent entries, this page says what is missing and what it would
 * take to fill it.
 */
export function Audit({ t }: PageProps) {
  return (
    <div className="page page--narrow">
      <PageHeader
        title={t('Audit Log')}
        description={t('Sensitive administrative actions and data access.')}
      />

      <Alert tone="warn" title={t('No audit source is connected')}>
        {t('This schema has no audit table, so there is nothing truthful to show here yet.')}
      </Alert>

      <Card>
        <EmptyState
          icon={<ScrollText size={18} />}
          title={t('Audit logging is not set up')}
          description={t('Create an append-only table that records operator, action, target, result and timestamp, then write to it from the server endpoints that perform admin mutations. This page will read it directly.')}
        />
      </Card>
    </div>
  )
}
