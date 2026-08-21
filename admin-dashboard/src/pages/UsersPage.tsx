import { useState } from 'react'
import { RotateCcw } from 'lucide-react'
import { formatInt, formatWhen, shortId } from '../data'
import { fetchAccounts, type AccountRow } from '../lib/queries'
import { useQuery } from '../lib/useQuery'
import { Alert, Avatar, Badge, Button, Card, DataTable, SearchInput, type Column } from '../ui'
import { Boundary } from './Boundary'
import { PageHeader, type PageProps } from './shared'

const activityTone = (lastMealAt: string | null): { tone: 'ok' | 'warn' | 'neutral'; label: string } => {
  if (!lastMealAt) return { tone: 'neutral', label: 'Never logged' }
  const days = (Date.now() - new Date(lastMealAt).getTime()) / 86_400_000
  if (days <= 7) return { tone: 'ok', label: 'Active' }
  if (days <= 30) return { tone: 'warn', label: 'Slowing' }
  return { tone: 'neutral', label: 'Dormant' }
}

export function UsersPage({ t }: PageProps) {
  const [query, setQuery] = useState('')
  const accounts = useQuery(() => fetchAccounts(), [])

  const columns: Array<Column<AccountRow>> = [
    {
      id: 'account', header: t('Account'), locked: true, sortValue: (row) => row.user_id,
      cell: (row) => (
        <span className="ds-table__primary">
          <Avatar name={row.user_id.slice(0, 2)} size="sm" />
          <span className="ds-table__primary-text"><strong className="ds-mono">{shortId(row.user_id)}</strong></span>
        </span>
      ),
    },
    {
      id: 'activity', header: t('Activity'), sortValue: (row) => row.last_meal_at ?? '',
      cell: (row) => {
        const state = activityTone(row.last_meal_at)
        return <Badge tone={state.tone} dot>{t(state.label)}</Badge>
      },
    },
    { id: 'meals', header: t('Meals'), align: 'end', sortValue: (row) => row.meals, cell: (row) => <span className="tnum">{formatInt(row.meals)}</span> },
    { id: 'items', header: t('Items'), align: 'end', sortValue: (row) => row.items, cell: (row) => <span className="tnum">{formatInt(row.items)}</span> },
    {
      id: 'rate', header: t('Correction rate'), align: 'end',
      sortValue: (row) => (row.items ? row.corrected_items / row.items : 0),
      cell: (row) => <span className="tnum">{row.items ? `${Math.round((row.corrected_items / row.items) * 100)}%` : '—'}</span>,
    },
    { id: 'first', header: t('First meal'), defaultHidden: true, sortValue: (row) => row.first_meal_at ?? '', cell: (row) => <span className="ds-muted">{formatWhen(row.first_meal_at)}</span> },
    { id: 'last', header: t('Last meal'), sortValue: (row) => row.last_meal_at ?? '', cell: (row) => <span className="ds-muted">{formatWhen(row.last_meal_at)}</span> },
  ]

  return (
    <div className="page page--wide">
      <PageHeader
        title={t('Users')}
        description={t('Support-relevant account signals with identity minimized by default.')}
        actions={<Button icon={<RotateCcw size={14} />} onClick={accounts.refetch}>{t('Refresh')}</Button>}
      />

      <Alert tone="info" title={t('Identity minimization')}>
        {t('Only the account UUID is read, and it is shortened before display. No email, name or photo reaches this screen.')}
      </Alert>

      <Card flush>
        <Boundary
          query={accounts}
          t={t}
          emptyTitle={t('No accounts have logged a meal')}
          emptyDescription={t('Account rows appear here once a user logs their first meal.')}
        >
          {(rows) => {
            const visible = rows.filter((row) => row.user_id.toLocaleLowerCase().includes(query.trim().toLocaleLowerCase()))
            return (
              <DataTable<AccountRow>
                caption={t('User accounts')}
                rows={visible}
                columns={columns}
                rowKey={(row) => row.user_id}
                pageSize={15}
                toolbar={
                  <SearchInput
                    className="ds-toolbar__search"
                    value={query}
                    onValueChange={setQuery}
                    label={t('Search accounts')}
                    placeholder={t('Search by account id…')}
                  />
                }
                empty={{
                  title: t('No accounts match'),
                  description: t('Clear the search to see every account.'),
                  action: <Button onClick={() => setQuery('')}>{t('Reset filters')}</Button>,
                }}
              />
            )
          }}
        </Boundary>
      </Card>
    </div>
  )
}
