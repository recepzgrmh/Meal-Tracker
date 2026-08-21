import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { AlertTriangle, ChevronDown, ChevronUp, ChevronsUpDown, Columns3, Inbox, MoreHorizontal, RotateCcw } from 'lucide-react'
import { Button, Checkbox, EmptyState, IconButton, TableSkeleton } from './primitives'
import { Menu, type MenuItem } from './overlays'
import { Pagination } from './nav'

const cx = (...parts: Array<string | false | undefined | null>) => parts.filter(Boolean).join(' ')

export type Column<Row> = {
  id: string
  header: string
  cell: (row: Row) => ReactNode
  /** Provide to make the column sortable. */
  sortValue?: (row: Row) => string | number
  align?: 'start' | 'end'
  width?: string
  /** Hidden until the reader turns it on in the column picker. */
  defaultHidden?: boolean
  /** Excluded from the column picker — identity columns should stay put. */
  locked?: boolean
}

export type DataTableLabels = {
  selected: (count: number) => string
  clearSelection: string
  columns: string
  rowActions: string
  selectAll: string
  selectRow: string
  previous: string
  next: string
  range: (from: number, to: number, total: number) => string
  sortBy: (column: string) => string
}

const DEFAULT_LABELS: DataTableLabels = {
  selected: (count) => `${count} selected`,
  clearSelection: 'Clear',
  columns: 'Columns',
  rowActions: 'Row actions',
  selectAll: 'Select all rows',
  selectRow: 'Select row',
  previous: 'Previous page',
  next: 'Next page',
  range: (from, to, total) => `${from}–${to} of ${total}`,
  sortBy: (column) => `Sort by ${column}`,
}

export function DataTable<Row>({
  rows, columns, rowKey, onRowClick, selectable, bulkActions, rowMenu,
  toolbar, pageSize = 10, loading, error, empty, labels: overrides, caption,
}: {
  rows: Row[]
  columns: Array<Column<Row>>
  rowKey: (row: Row) => string
  onRowClick?: (row: Row) => void
  selectable?: boolean
  bulkActions?: (selected: Row[]) => ReactNode
  rowMenu?: (row: Row) => MenuItem[]
  /** Search, filters and view controls live above the header row. */
  toolbar?: ReactNode
  pageSize?: number
  loading?: boolean
  error?: { title: string; description?: string; retryLabel?: string; onRetry?: () => void }
  empty?: { title: string; description?: string; action?: ReactNode }
  labels?: Partial<DataTableLabels>
  caption: string
}) {
  const labels = { ...DEFAULT_LABELS, ...overrides }
  const [sort, setSort] = useState<{ id: string; direction: 'asc' | 'desc' } | null>(null)
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [hidden, setHidden] = useState<Set<string>>(() => new Set(columns.filter((column) => column.defaultHidden).map((column) => column.id)))
  const [page, setPage] = useState(1)

  // Any change to the underlying rows invalidates page and selection.
  useEffect(() => { setPage(1); setSelected(new Set()) }, [rows])

  const visibleColumns = columns.filter((column) => !hidden.has(column.id))

  const sorted = useMemo(() => {
    if (!sort) return rows
    const column = columns.find((entry) => entry.id === sort.id)
    if (!column?.sortValue) return rows
    const direction = sort.direction === 'asc' ? 1 : -1
    return [...rows].sort((a, b) => {
      const left = column.sortValue!(a)
      const right = column.sortValue!(b)
      if (left === right) return 0
      return (left > right ? 1 : -1) * direction
    })
  }, [rows, sort, columns])

  const pageCount = Math.max(1, Math.ceil(sorted.length / pageSize))
  const current = Math.min(page, pageCount)
  const visibleRows = sorted.slice((current - 1) * pageSize, current * pageSize)

  const pageKeys = visibleRows.map(rowKey)
  const allOnPageSelected = pageKeys.length > 0 && pageKeys.every((key) => selected.has(key))
  const someOnPageSelected = pageKeys.some((key) => selected.has(key))

  const toggleAll = (next: boolean) => {
    const updated = new Set(selected)
    pageKeys.forEach((key) => (next ? updated.add(key) : updated.delete(key)))
    setSelected(updated)
  }

  const toggleRow = (key: string, next: boolean) => {
    const updated = new Set(selected)
    if (next) updated.add(key)
    else updated.delete(key)
    setSelected(updated)
  }

  const onSort = (column: Column<Row>) => {
    if (!column.sortValue) return
    setSort((currentSort) =>
      currentSort?.id !== column.id
        ? { id: column.id, direction: 'asc' }
        : currentSort.direction === 'asc'
          ? { id: column.id, direction: 'desc' }
          : null,
    )
  }

  const selectedRows = rows.filter((row) => selected.has(rowKey(row)))

  const columnPicker: MenuItem[] = [
    { type: 'label', label: labels.columns },
    ...columns.filter((column) => !column.locked).map<MenuItem>((column) => ({
      label: column.header,
      trailing: hidden.has(column.id) ? undefined : <span aria-hidden="true">✓</span>,
      onSelect: () => setHidden((currentHidden) => {
        const updated = new Set(currentHidden)
        if (updated.has(column.id)) updated.delete(column.id)
        else updated.add(column.id)
        return updated
      }),
    })),
  ]

  const colSpan = visibleColumns.length + (selectable ? 1 : 0) + (rowMenu ? 1 : 0)

  return (
    <div>
      {(toolbar || true) && (
        <div className="ds-toolbar">
          {toolbar}
          <span className="ds-toolbar__spacer" />
          <Menu
            label={labels.columns}
            items={columnPicker}
            trigger={(props) => (
              <Button size="sm" icon={<Columns3 size={13} />} {...props}>{labels.columns}</Button>
            )}
          />
        </div>
      )}

      {selectable && selected.size > 0 && (
        <div className="ds-bulkbar" role="status">
          <strong>{labels.selected(selected.size)}</strong>
          <div className="ds-bulkbar__actions">
            {bulkActions?.(selectedRows)}
            <Button size="sm" variant="ghost" onClick={() => setSelected(new Set())}>{labels.clearSelection}</Button>
          </div>
        </div>
      )}

      {loading ? (
        <TableSkeleton rows={Math.min(pageSize, 6)} columns={visibleColumns.length} />
      ) : error ? (
        <EmptyState
          tone="danger"
          icon={<AlertTriangle size={18} />}
          title={error.title}
          description={error.description}
          actions={error.onRetry && <Button icon={<RotateCcw size={14} />} onClick={error.onRetry}>{error.retryLabel ?? 'Try again'}</Button>}
        />
      ) : (
        <div className="ds-table-wrap">
          <table className="ds-table">
            <caption className="sr-only">{caption}</caption>
            <thead>
              <tr>
                {selectable && (
                  <th className="ds-table__check" scope="col">
                    <Checkbox
                      checked={allOnPageSelected}
                      indeterminate={someOnPageSelected}
                      onChange={toggleAll}
                      ariaLabel={labels.selectAll}
                    />
                  </th>
                )}
                {visibleColumns.map((column) => {
                  const active = sort?.id === column.id
                  const Icon = !active ? ChevronsUpDown : sort.direction === 'asc' ? ChevronUp : ChevronDown
                  return (
                    <th
                      key={column.id}
                      scope="col"
                      style={{ width: column.width, textAlign: column.align === 'end' ? 'end' : undefined }}
                      aria-sort={active ? (sort.direction === 'asc' ? 'ascending' : 'descending') : column.sortValue ? 'none' : undefined}
                    >
                      {column.sortValue ? (
                        <button type="button" className="ds-table__sort" data-sorted={active} onClick={() => onSort(column)} aria-label={labels.sortBy(column.header)}>
                          {column.header}
                          <Icon size={12} aria-hidden="true" />
                        </button>
                      ) : column.header}
                    </th>
                  )
                })}
                {rowMenu && <th className="ds-table__actions" scope="col"><span className="sr-only">{labels.rowActions}</span></th>}
              </tr>
            </thead>
            <tbody>
              {visibleRows.length === 0 && (
                <tr>
                  <td colSpan={colSpan} style={{ height: 'auto' }}>
                    <EmptyState
                      icon={<Inbox size={18} />}
                      title={empty?.title ?? 'Nothing here yet'}
                      description={empty?.description}
                      actions={empty?.action}
                    />
                  </td>
                </tr>
              )}
              {visibleRows.map((row) => {
                const key = rowKey(row)
                const isSelected = selected.has(key)
                return (
                  <tr
                    key={key}
                    data-selected={isSelected || undefined}
                    data-clickable={onRowClick ? 'true' : undefined}
                    tabIndex={onRowClick ? 0 : undefined}
                    onClick={onRowClick ? () => onRowClick(row) : undefined}
                    onKeyDown={onRowClick ? (event) => {
                      if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); onRowClick(row) }
                    } : undefined}
                  >
                    {selectable && (
                      <td className="ds-table__check" onClick={(event) => event.stopPropagation()}>
                        <Checkbox checked={isSelected} onChange={(next) => toggleRow(key, next)} ariaLabel={labels.selectRow} />
                      </td>
                    )}
                    {visibleColumns.map((column) => (
                      <td key={column.id} className={cx(column.align === 'end' && 'ds-table__num')} style={{ width: column.width }}>
                        {column.cell(row)}
                      </td>
                    ))}
                    {rowMenu && (
                      <td className="ds-table__actions" onClick={(event) => event.stopPropagation()}>
                        <Menu
                          label={labels.rowActions}
                          items={rowMenu(row)}
                          trigger={(props) => (
                            <IconButton size="sm" label={labels.rowActions} {...props}><MoreHorizontal size={15} /></IconButton>
                          )}
                        />
                      </td>
                    )}
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}

      {!loading && !error && sorted.length > pageSize && (
        <Pagination
          page={current}
          pageCount={pageCount}
          total={sorted.length}
          pageSize={pageSize}
          onPage={setPage}
          labels={{ previous: labels.previous, next: labels.next, range: labels.range }}
        />
      )}
    </div>
  )
}
