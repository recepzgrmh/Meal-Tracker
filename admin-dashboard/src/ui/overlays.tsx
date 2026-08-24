import {
  createContext, useCallback, useContext, useEffect, useId, useMemo, useRef, useState,
  type ReactNode,
} from 'react'
import { AlertTriangle, Check, CornerDownLeft, Info, Search, X } from 'lucide-react'
import { Button, IconButton, Kbd, type Tone } from './primitives'

const cx = (...parts: Array<string | false | undefined | null>) => parts.filter(Boolean).join(' ')

/* ── Shared overlay behaviour ────────────────────────────────────────────── */

/** Escape to dismiss, background scroll lock, and focus returned on close. */
function useOverlay(open: boolean, onClose: () => void) {
  const restoreTo = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (!open) return
    restoreTo.current = document.activeElement as HTMLElement | null
    const onKey = (event: KeyboardEvent) => { if (event.key === 'Escape') { event.stopPropagation(); onClose() } }
    document.addEventListener('keydown', onKey)
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.style.overflow = previousOverflow
      restoreTo.current?.focus?.()
    }
  }, [open, onClose])
}

/** Keeps Tab inside the panel while it is open. */
function useFocusTrap(open: boolean) {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    if (!open || !ref.current) return
    const panel = ref.current
    const selector = 'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    const first = panel.querySelector<HTMLElement>(selector)
    first?.focus()
    const onKey = (event: KeyboardEvent) => {
      if (event.key !== 'Tab') return
      const nodes = Array.from(panel.querySelectorAll<HTMLElement>(selector)).filter((node) => node.offsetParent !== null)
      if (!nodes.length) return
      const edge = event.shiftKey ? nodes[0] : nodes[nodes.length - 1]
      if (document.activeElement === edge) {
        event.preventDefault()
        ;(event.shiftKey ? nodes[nodes.length - 1] : nodes[0]).focus()
      }
    }
    panel.addEventListener('keydown', onKey)
    return () => panel.removeEventListener('keydown', onKey)
  }, [open])
  return ref
}

/* ── Menu / dropdown ─────────────────────────────────────────────────────── */

export type MenuItem =
  | { type: 'separator' }
  | { type: 'label'; label: string }
  | { type?: 'item'; label: string; icon?: ReactNode; onSelect: () => void; danger?: boolean; disabled?: boolean; trailing?: ReactNode }

export function Menu({ trigger, items, align = 'end', label }: {
  trigger: (props: { onClick: () => void; 'aria-expanded': boolean; 'aria-haspopup': 'menu' }) => ReactNode
  items: MenuItem[]
  align?: 'start' | 'end'
  label: string
}) {
  const [open, setOpen] = useState(false)
  const anchor = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    const onPointer = (event: PointerEvent) => {
      if (!anchor.current?.contains(event.target as Node)) setOpen(false)
    }
    const onKey = (event: KeyboardEvent) => { if (event.key === 'Escape') setOpen(false) }
    document.addEventListener('pointerdown', onPointer)
    document.addEventListener('keydown', onKey)
    return () => { document.removeEventListener('pointerdown', onPointer); document.removeEventListener('keydown', onKey) }
  }, [open])

  return (
    <div className="ds-menu-anchor" ref={anchor}>
      {trigger({ onClick: () => setOpen((value) => !value), 'aria-expanded': open, 'aria-haspopup': 'menu' })}
      {open && (
        <div className={cx('ds-menu', `ds-menu--${align}`)} role="menu" aria-label={label}>
          {items.map((item, index) => {
            if (item.type === 'separator') return <div className="ds-menu__sep" key={index} role="separator" />
            if (item.type === 'label') return <div className="ds-menu__label" key={index}>{item.label}</div>
            return (
              <button
                key={index}
                type="button"
                role="menuitem"
                disabled={item.disabled}
                className={cx('ds-menu__item', item.danger && 'ds-menu__item--danger')}
                onClick={() => { setOpen(false); item.onSelect() }}
              >
                {item.icon}
                <span>{item.label}</span>
                {item.trailing}
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}

/* ── Modal — short, focused decisions ────────────────────────────────────── */

export function Modal({ open, onClose, title, description, children, footer, danger }: {
  open: boolean; onClose: () => void; title: string; description?: string
  children?: ReactNode; footer?: ReactNode; danger?: boolean
}) {
  useOverlay(open, onClose)
  const panel = useFocusTrap(open)
  const titleId = useId()
  const descId = useId()
  if (!open) return null
  return (
    <>
      <div className="ds-scrim" onClick={onClose} />
      <div className="ds-modal-host">
        <div className="ds-modal" role="alertdialog" aria-modal="true" aria-labelledby={titleId} aria-describedby={description ? descId : undefined} ref={panel}>
          <header className="ds-modal__head">
            <div style={{ flex: 1, minWidth: 0 }}>
              <h2 className="ds-modal__title" id={titleId}>{title}</h2>
              {description && <p className="ds-modal__desc" id={descId}>{description}</p>}
            </div>
            <IconButton label="Close" onClick={onClose}><X size={16} /></IconButton>
          </header>
          {children && <div className="ds-modal__body">{children}</div>}
          <footer className={cx('ds-modal__foot', danger && 'ds-modal__foot--split')}>
            {footer ?? <Button onClick={onClose}>Close</Button>}
          </footer>
        </div>
      </div>
    </>
  )
}

/* ── Drawer — inspect a record without losing the list ───────────────────── */

export function Drawer({ open, onClose, title, description, children, footer, wide }: {
  open: boolean; onClose: () => void; title: string; description?: string
  children: ReactNode; footer?: ReactNode; wide?: boolean
}) {
  useOverlay(open, onClose)
  const panel = useFocusTrap(open)
  const titleId = useId()
  if (!open) return null
  return (
    <>
      <div className="ds-scrim" onClick={onClose} />
      <div className="ds-drawer-host">
        <div className={cx('ds-drawer', wide && 'ds-drawer--wide')} role="dialog" aria-modal="true" aria-labelledby={titleId} ref={panel}>
          <header className="ds-drawer__head">
            <div style={{ flex: 1, minWidth: 0 }}>
              <h2 className="ds-drawer__title" id={titleId}>{title}</h2>
              {description && <p className="ds-drawer__desc">{description}</p>}
            </div>
            <IconButton label="Close panel" onClick={onClose}><X size={16} /></IconButton>
          </header>
          <div className="ds-drawer__body">{children}</div>
          {footer && <footer className="ds-drawer__foot">{footer}</footer>}
        </div>
      </div>
    </>
  )
}

/* ── Toast ───────────────────────────────────────────────────────────────── */

type Toast = { id: number; tone: Tone; title: string; description?: string }
type ToastValue = { push: (toast: Omit<Toast, 'id'>) => void }
const ToastContext = createContext<ToastValue>({ push: () => undefined })

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])
  const nextId = useRef(0)

  const push = useCallback((toast: Omit<Toast, 'id'>) => {
    const id = nextId.current++
    setToasts((current) => [...current, { ...toast, id }])
    window.setTimeout(() => setToasts((current) => current.filter((item) => item.id !== id)), 4200)
  }, [])

  const value = useMemo(() => ({ push }), [push])
  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="ds-toasts" role="region" aria-label="Notifications">
        {toasts.map((toast) => {
          const Icon = toast.tone === 'danger' || toast.tone === 'warn' ? AlertTriangle : toast.tone === 'ok' ? Check : Info
          return (
            <div key={toast.id} className={cx('ds-toast', toast.tone !== 'neutral' && `ds-toast--${toast.tone}`)} role="status">
              <Icon size={15} className="ds-toast__icon" aria-hidden="true" />
              <div className="ds-toast__text">
                <span className="ds-toast__title">{toast.title}</span>
                {toast.description && <span className="ds-toast__desc">{toast.description}</span>}
              </div>
              <IconButton size="sm" label="Dismiss" onClick={() => setToasts((current) => current.filter((item) => item.id !== toast.id))}>
                <X size={13} />
              </IconButton>
            </div>
          )
        })}
      </div>
    </ToastContext.Provider>
  )
}

export const useToast = () => useContext(ToastContext)

/* ── Command menu ────────────────────────────────────────────────────────── */

export type Command = { id: string; group: string; label: string; hint?: string; icon?: ReactNode; run: () => void; keywords?: string }

export function CommandMenu({ open, onClose, commands, placeholder = 'Search pages, records and actions…' }: {
  open: boolean; onClose: () => void; commands: Command[]; placeholder?: string
}) {
  const [query, setQuery] = useState('')
  const [cursor, setCursor] = useState(0)
  useOverlay(open, onClose)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => { if (open) { setQuery(''); setCursor(0); window.setTimeout(() => inputRef.current?.focus(), 0) } }, [open])

  const matches = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase()
    if (!needle) return commands
    return commands.filter((command) => `${command.label} ${command.group} ${command.keywords ?? ''}`.toLocaleLowerCase().includes(needle))
  }, [commands, query])

  useEffect(() => { setCursor(0) }, [query])

  if (!open) return null

  const grouped = matches.reduce<Array<[string, Command[]]>>((accumulator, command) => {
    const bucket = accumulator.find(([group]) => group === command.group)
    if (bucket) bucket[1].push(command)
    else accumulator.push([command.group, [command]])
    return accumulator
  }, [])

  const onKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'ArrowDown') { event.preventDefault(); setCursor((value) => Math.min(value + 1, matches.length - 1)) }
    if (event.key === 'ArrowUp') { event.preventDefault(); setCursor((value) => Math.max(value - 1, 0)) }
    if (event.key === 'Enter') { event.preventDefault(); const command = matches[cursor]; if (command) { onClose(); command.run() } }
  }

  let index = -1
  return (
    <>
      <div className="ds-scrim" onClick={onClose} />
      <div className="ds-cmdk-host">
        <div className="ds-cmdk" role="dialog" aria-modal="true" aria-label="Command menu">
          <div className="ds-cmdk__field">
            <Search size={16} aria-hidden="true" />
            <input
              ref={inputRef}
              value={query}
              placeholder={placeholder}
              aria-label={placeholder}
              role="combobox"
              aria-expanded="true"
              aria-controls="cmdk-list"
              onChange={(event) => setQuery(event.target.value)}
              onKeyDown={onKeyDown}
            />
            <Kbd>Esc</Kbd>
          </div>
          <div className="ds-cmdk__list" id="cmdk-list" role="listbox">
            {matches.length === 0 && <div className="ds-empty" style={{ padding: '2rem 1rem' }}><p className="ds-empty__desc">No matches for “{query}”.</p></div>}
            {grouped.map(([group, groupCommands]) => (
              <div key={group}>
                <div className="ds-cmdk__group">{group}</div>
                {groupCommands.map((command) => {
                  index += 1
                  const active = index === cursor
                  const position = index
                  return (
                    <button
                      key={command.id}
                      type="button"
                      role="option"
                      aria-selected={active}
                      data-active={active}
                      className="ds-cmdk__item"
                      onPointerMove={() => setCursor(position)}
                      onClick={() => { onClose(); command.run() }}
                    >
                      {command.icon}
                      <span>{command.label}</span>
                      {command.hint && <span className="ds-cmdk__hint">{command.hint}</span>}
                    </button>
                  )
                })}
              </div>
            ))}
          </div>
          <div className="ds-cmdk__foot">
            <span><Kbd>↑</Kbd><Kbd>↓</Kbd> navigate</span>
            <span><Kbd><CornerDownLeft size={10} /></Kbd> open</span>
          </div>
        </div>
      </div>
    </>
  )
}
