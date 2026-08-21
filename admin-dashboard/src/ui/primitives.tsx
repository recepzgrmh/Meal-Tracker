import { forwardRef, useId, type ButtonHTMLAttributes, type InputHTMLAttributes, type ReactNode, type SelectHTMLAttributes, type TextareaHTMLAttributes } from 'react'
import { AlertTriangle, Check, ChevronDown, Info, Minus, Search, TrendingDown, TrendingUp, X } from 'lucide-react'

export type Tone = 'neutral' | 'ok' | 'warn' | 'danger' | 'info' | 'accent'

const cx = (...parts: Array<string | false | undefined | null>) => parts.filter(Boolean).join(' ')

/* ── Button ──────────────────────────────────────────────────────────────── */

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'default' | 'primary' | 'ghost' | 'danger'
  size?: 'sm' | 'md'
  block?: boolean
  loading?: boolean
  icon?: ReactNode
  iconEnd?: ReactNode
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = 'default', size = 'md', block, loading, icon, iconEnd, children, className, disabled, ...rest }, ref,
) {
  return (
    <button
      ref={ref}
      type="button"
      aria-busy={loading || undefined}
      disabled={disabled || loading}
      className={cx('ds-btn', variant !== 'default' && `ds-btn--${variant}`, size === 'sm' && 'ds-btn--sm', block && 'ds-btn--block', className)}
      {...rest}
    >
      {loading && <span className="ds-spinner" aria-hidden="true" />}
      {icon}
      {children}
      {iconEnd}
    </button>
  )
})

type IconButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & { label: string; size?: 'sm' | 'md'; bordered?: boolean }

export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(function IconButton(
  { label, size = 'md', bordered, children, className, ...rest }, ref,
) {
  return (
    <button
      ref={ref}
      type="button"
      aria-label={label}
      title={label}
      className={cx('ds-icon-btn', size === 'sm' && 'ds-icon-btn--sm', bordered && 'ds-icon-btn--bordered', className)}
      {...rest}
    >
      {children}
    </button>
  )
})

export const Kbd = ({ children }: { children: ReactNode }) => <kbd className="ds-kbd">{children}</kbd>

/* ── Status ──────────────────────────────────────────────────────────────── */

/** Status dots vary by shape as well as hue, so colour is never the only cue. */
export function StatusDot({ tone = 'neutral' }: { tone?: Tone }) {
  return <span className={cx('ds-dot', tone !== 'neutral' && tone !== 'accent' && `ds-dot--${tone}`)} aria-hidden="true" />
}

export function Badge({ tone = 'neutral', dot, plain, children }: { tone?: Tone; dot?: boolean; plain?: boolean; children: ReactNode }) {
  return (
    <span className={cx('ds-badge', tone !== 'neutral' && `ds-badge--${tone}`, plain && 'ds-badge--plain')}>
      {dot && <StatusDot tone={tone} />}
      {children}
    </span>
  )
}

/**
 * A period-over-period change. `inverse` flips the colour mapping for metrics
 * where a rise is bad (error rate, latency). The arrow carries the direction
 * so the meaning survives without colour.
 */
export function Delta({ value, inverse, children }: { value: number; inverse?: boolean; children?: ReactNode }) {
  const direction = value > 0 ? 'up' : value < 0 ? 'down' : 'flat'
  const tone = direction === 'flat' ? 'flat' : inverse ? `inverse-${direction}` : direction
  const Icon = direction === 'up' ? TrendingUp : direction === 'down' ? TrendingDown : Minus
  const sign = value > 0 ? '+' : ''
  return (
    <span className={`ds-delta ds-delta--${tone}`}>
      <Icon size={13} aria-hidden="true" />
      {children ?? `${sign}${value}%`}
    </span>
  )
}

export function Avatar({ name, src, size = 'md' }: { name: string; src?: string; size?: 'sm' | 'md' | 'lg' }) {
  const initials = name.split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]).join('').toUpperCase()
  return (
    <span className={cx('ds-avatar', size !== 'md' && `ds-avatar--${size}`)} aria-hidden="true">
      {src ? <img src={src} alt="" /> : initials}
    </span>
  )
}

/* ── Form controls ───────────────────────────────────────────────────────── */

type FieldProps = { label?: string; help?: string; error?: string; optional?: boolean; htmlFor?: string; children: ReactNode }

export function Field({ label, help, error, optional, htmlFor, children }: FieldProps) {
  return (
    <div className="ds-field">
      {label && (
        <label className="ds-label" htmlFor={htmlFor}>
          {label}{optional && <span className="ds-label__optional"> · optional</span>}
        </label>
      )}
      {children}
      {error
        ? <span className="ds-error"><AlertTriangle size={12} aria-hidden="true" />{error}</span>
        : help && <span className="ds-help">{help}</span>}
    </div>
  )
}

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(function Input({ className, ...rest }, ref) {
  return <input ref={ref} className={cx('ds-input', className)} {...rest} />
})

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaHTMLAttributes<HTMLTextAreaElement>>(function Textarea({ className, ...rest }, ref) {
  return <textarea ref={ref} className={cx('ds-textarea', className)} {...rest} />
})

export function SearchInput({ value, onValueChange, placeholder, label, onClear, className }: {
  value: string; onValueChange: (next: string) => void; placeholder?: string; label: string; onClear?: () => void; className?: string
}) {
  return (
    <div className={cx('ds-input-wrap', className)}>
      <Search size={14} aria-hidden="true" />
      <input
        className="ds-input"
        type="search"
        value={value}
        aria-label={label}
        placeholder={placeholder}
        onChange={(event) => onValueChange(event.target.value)}
      />
      {value && (
        <span className="ds-input-wrap__end">
          <IconButton size="sm" label="Clear search" onClick={() => { onValueChange(''); onClear?.() }}><X size={13} /></IconButton>
        </span>
      )}
    </div>
  )
}

type SelectProps = SelectHTMLAttributes<HTMLSelectElement> & { options: Array<{ value: string; label: string }> }

export const Select = forwardRef<HTMLSelectElement, SelectProps>(function Select({ options, className, ...rest }, ref) {
  return (
    <span className="ds-select-wrap">
      <select ref={ref} className={cx('ds-select', className)} {...rest}>
        {options.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
      </select>
      <ChevronDown size={14} aria-hidden="true" />
    </span>
  )
})

export function Checkbox({ checked, indeterminate, onChange, label, description, disabled, ariaLabel }: {
  checked: boolean; indeterminate?: boolean; onChange: (next: boolean) => void
  label?: string; description?: string; disabled?: boolean; ariaLabel?: string
}) {
  return (
    <label className="ds-check">
      <input
        type="checkbox"
        checked={checked}
        disabled={disabled}
        aria-label={ariaLabel ?? (label ? undefined : 'Select')}
        ref={(node) => { if (node) node.indeterminate = Boolean(indeterminate && !checked) }}
        onChange={(event) => onChange(event.target.checked)}
      />
      <span className="ds-check__box" aria-hidden="true">
        {indeterminate && !checked ? <Minus size={11} strokeWidth={3} /> : <Check size={11} strokeWidth={3} />}
      </span>
      {(label || description) && (
        <span className="ds-check__text">
          {label}
          {description && <span className="ds-help">{description}</span>}
        </span>
      )}
    </label>
  )
}

export function Radio({ checked, onChange, label, description, name, disabled }: {
  checked: boolean; onChange: () => void; label: string; description?: string; name: string; disabled?: boolean
}) {
  return (
    <label className="ds-check">
      <input type="radio" name={name} checked={checked} disabled={disabled} onChange={onChange} />
      <span className="ds-check__box ds-check__box--radio" aria-hidden="true"><Check size={10} strokeWidth={3} /></span>
      <span className="ds-check__text">
        {label}
        {description && <span className="ds-help">{description}</span>}
      </span>
    </label>
  )
}

export function Switch({ checked, onChange, label, disabled }: { checked: boolean; onChange: (next: boolean) => void; label: string; disabled?: boolean }) {
  return (
    <label className="ds-switch">
      <input type="checkbox" role="switch" checked={checked} disabled={disabled} aria-label={label} onChange={(event) => onChange(event.target.checked)} />
      <span className="ds-switch__track" aria-hidden="true"><span className="ds-switch__thumb" /></span>
    </label>
  )
}

export function Tooltip({ content, children }: { content: string; children: ReactNode }) {
  return (
    <span className="ds-tip">
      {children}
      <span className="ds-tip__body" role="tooltip">{content}</span>
    </span>
  )
}

/* ── Feedback ────────────────────────────────────────────────────────────── */

export function Alert({ tone = 'neutral', title, children, action }: { tone?: Tone; title?: string; children?: ReactNode; action?: ReactNode }) {
  const Icon = tone === 'danger' || tone === 'warn' ? AlertTriangle : tone === 'ok' ? Check : Info
  return (
    <div className={cx('ds-alert', tone !== 'neutral' && `ds-alert--${tone}`)} role={tone === 'danger' ? 'alert' : undefined}>
      <Icon size={15} className="ds-alert__icon" aria-hidden="true" />
      <div className="ds-alert__text">
        {title && <span className="ds-alert__title">{title}</span>}
        {children && <span className="ds-alert__desc">{children}</span>}
      </div>
      {action}
    </div>
  )
}

export function Skeleton({ width, height = '1rem', radius, className }: { width?: string; height?: string; radius?: string; className?: string }) {
  return <span className={cx('ds-skel', className)} style={{ width, height, borderRadius: radius, display: 'block' }} aria-hidden="true" />
}

/** Mirrors the real table so the layout does not jump when data lands. */
export function TableSkeleton({ rows = 6, columns = 5 }: { rows?: number; columns?: number }) {
  return (
    <div className="ds-table-wrap" aria-hidden="true">
      <table className="ds-table">
        <tbody>
          {Array.from({ length: rows }, (_, row) => (
            <tr key={row}>
              {Array.from({ length: columns }, (_, column) => (
                <td key={column}><Skeleton width={column === 0 ? '60%' : '40%'} height=".75rem" /></td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export function EmptyState({ icon, title, description, actions, tone = 'neutral' }: {
  icon?: ReactNode; title: string; description?: string; actions?: ReactNode; tone?: 'neutral' | 'danger'
}) {
  return (
    <div className={cx('ds-empty', tone === 'danger' && 'ds-empty--danger')}>
      {icon && <span className="ds-empty__icon" aria-hidden="true">{icon}</span>}
      <p className="ds-empty__title">{title}</p>
      {description && <p className="ds-empty__desc">{description}</p>}
      {actions && <div className="ds-empty__actions">{actions}</div>}
    </div>
  )
}

/* ── Containers ──────────────────────────────────────────────────────────── */

export function Card({ title, subtitle, actions, flush, children, className }: {
  title?: string; subtitle?: string; actions?: ReactNode; flush?: boolean; children: ReactNode; className?: string
}) {
  return (
    <section className={cx('ds-card', flush && 'ds-card--flush', className)}>
      {(title || actions) && (
        <header className="ds-card__head">
          <div>
            {title && <h2 className="ds-panel-title">{title}</h2>}
            {subtitle && <p className="ds-panel-sub">{subtitle}</p>}
          </div>
          {actions && <div className="ds-section__actions">{actions}</div>}
        </header>
      )}
      {flush ? children : <div className="ds-card__body">{children}</div>}
    </section>
  )
}

/**
 * A rule and a heading. Groups related content without spending a card on it —
 * the pattern that keeps dense pages from turning into a field of boxes.
 */
export function Section({ title, subtitle, actions, children, id }: {
  title: string; subtitle?: string; actions?: ReactNode; children: ReactNode; id?: string
}) {
  const headingId = useId()
  return (
    <section className="ds-section" aria-labelledby={headingId} id={id}>
      <header className="ds-section__head">
        <div>
          <h2 className="ds-section__title" id={headingId}>{title}</h2>
          {subtitle && <p className="ds-section__sub">{subtitle}</p>}
        </div>
        {actions && <div className="ds-section__actions">{actions}</div>}
      </header>
      {children}
    </section>
  )
}

/* ── Data display ────────────────────────────────────────────────────────── */

export function Metric({ label, value, delta, deltaLabel, inverseDelta, footnote, spark, onClick, badge }: {
  label: string; value: string; delta?: number; deltaLabel?: string; inverseDelta?: boolean
  footnote?: string; spark?: ReactNode; onClick?: () => void; badge?: ReactNode
}) {
  const body = (
    <>
      <div className="ds-metric__head">
        <span className="ds-metric__label">{label}</span>
        {badge}
      </div>
      <strong className="ds-metric__value">{value}</strong>
      {(delta !== undefined || footnote) && (
        <div className="ds-metric__foot">
          {delta !== undefined && <Delta value={delta} inverse={inverseDelta}>{deltaLabel}</Delta>}
          {footnote && <span>{footnote}</span>}
        </div>
      )}
      {spark && <div className="ds-metric__spark">{spark}</div>}
    </>
  )
  return onClick
    ? <button type="button" className="ds-metric ds-metric--interactive" onClick={onClick}>{body}</button>
    : <div className="ds-metric">{body}</div>
}

export const Metrics = ({ children }: { children: ReactNode }) => <div className="ds-metrics">{children}</div>

export function DefinitionList({ rows }: { rows: Array<[string, ReactNode]> }) {
  return (
    <dl className="ds-deflist">
      {rows.map(([term, value]) => (
        <div className="ds-deflist__row" key={term}>
          <dt>{term}</dt>
          <dd>{value}</dd>
        </div>
      ))}
    </dl>
  )
}

export function Bar({ label, value, max, display, tone = 'neutral', onClick }: {
  label: string; value: number; max: number; display: string; tone?: Tone; onClick?: () => void
}) {
  const content = (
    <>
      <span className="ds-bar__label" title={label}>{label}</span>
      <span className="ds-bar__track" aria-hidden="true">
        <span className={cx('ds-bar__fill', tone !== 'neutral' && tone !== 'accent' && `ds-bar__fill--${tone}`)} style={{ width: `${Math.min(100, (value / max) * 100)}%` }} />
      </span>
      <span className="ds-bar__value">{display}</span>
    </>
  )
  return onClick
    ? <button type="button" className="ds-bar" onClick={onClick}>{content}</button>
    : <div className="ds-bar">{content}</div>
}

export const Bars = ({ children }: { children: ReactNode }) => <div className="ds-bars">{children}</div>
