import { useCallback, useId, useLayoutEffect, useRef, useState, type ReactNode } from 'react'

/* ============================================================================
   Charts — one primary series, neutral comparison series, semantic only for
   state. Every chart is direct-labelled and readable without colour.
   ========================================================================= */

export type SeriesTone = 'primary' | 'neutral' | 'third' | 'ok' | 'warn' | 'danger'

export type Series = {
  id: string
  label: string
  values: number[]
  tone?: SeriesTone
  /** Fill the area under the line. Only the primary series should do this. */
  area?: boolean
  /** Render as a dashed line — for targets and forecasts. */
  dashed?: boolean
}

const TONE_VAR: Record<SeriesTone, string> = {
  primary: 'var(--series-1)',
  neutral: 'var(--series-2)',
  third: 'var(--series-3)',
  ok: 'var(--ok)',
  warn: 'var(--warn)',
  danger: 'var(--danger)',
}

export const seriesColor = (tone: SeriesTone = 'primary') => TONE_VAR[tone]

/** Measures the element so axis text renders at real pixel size, not stretched. */
function useWidth(fallback = 640) {
  const ref = useRef<HTMLDivElement>(null)
  const [width, setWidth] = useState(fallback)
  useLayoutEffect(() => {
    const node = ref.current
    if (!node) return
    const measure = () => setWidth(node.clientWidth || fallback)
    measure()
    if (typeof ResizeObserver === 'undefined') return
    const observer = new ResizeObserver(measure)
    observer.observe(node)
    return () => observer.disconnect()
  }, [fallback])
  return [ref, width] as const
}

const niceTicks = (min: number, max: number, count = 4) => {
  if (min === max) return [min]
  const step = (max - min) / (count - 1)
  return Array.from({ length: count }, (_, index) => min + step * index)
}

/* ── Chart container — title, controls, legend, and the plot ─────────────── */

export function ChartContainer({ title, subtitle, actions, legend, children }: {
  title?: string; subtitle?: string; actions?: ReactNode; legend?: ReactNode; children: ReactNode
}) {
  return (
    <div className="ds-stack ds-stack--sm">
      {(title || actions) && (
        <div className="ds-row" style={{ alignItems: 'flex-start', justifyContent: 'space-between', gap: '1rem' }}>
          <div>
            {title && <h3 className="ds-panel-title">{title}</h3>}
            {subtitle && <p className="ds-panel-sub">{subtitle}</p>}
          </div>
          {actions && <div className="ds-row">{actions}</div>}
        </div>
      )}
      {children}
      {legend}
    </div>
  )
}

export function Legend({ items }: { items: Array<{ label: string; tone?: SeriesTone; dashed?: boolean }> }) {
  return (
    <div className="ds-legend">
      {items.map((item) => (
        <span className="ds-legend__item" key={item.label}>
          <span
            className="ds-chart__swatch"
            style={{
              background: item.dashed ? 'transparent' : seriesColor(item.tone),
              boxShadow: item.dashed ? `inset 0 0 0 1.5px ${seriesColor(item.tone)}` : undefined,
            }}
            aria-hidden="true"
          />
          {item.label}
        </span>
      ))}
    </div>
  )
}

/* ── Line / area chart ───────────────────────────────────────────────────── */

export function LineChart({
  series, xLabels, height = 200, formatValue = String, formatTick, markerIndex, markerLabel, ariaLabel,
}: {
  series: Series[]
  xLabels: string[]
  height?: number
  formatValue?: (value: number) => string
  formatTick?: (value: number) => string
  /** Vertical rule for a deployment or release boundary. */
  markerIndex?: number
  markerLabel?: string
  ariaLabel: string
}) {
  const [ref, width] = useWidth()
  const [hover, setHover] = useState<number | null>(null)
  const gradientId = useId().replace(/:/g, '')

  const padding = { top: 8, right: 10, bottom: 22, left: 38 }
  const plotW = Math.max(40, width - padding.left - padding.right)
  const plotH = Math.max(40, height - padding.top - padding.bottom)

  const all = series.flatMap((entry) => entry.values)
  const rawMin = Math.min(...all)
  const rawMax = Math.max(...all)
  const span = rawMax - rawMin || 1
  const min = rawMin - span * 0.12
  const max = rawMax + span * 0.12
  const count = Math.max(...series.map((entry) => entry.values.length))

  const x = (index: number) => padding.left + (count === 1 ? plotW / 2 : (index / (count - 1)) * plotW)
  const y = (value: number) => padding.top + (1 - (value - min) / (max - min)) * plotH

  const onMove = useCallback((event: React.PointerEvent<SVGRectElement>) => {
    const box = event.currentTarget.getBoundingClientRect()
    const ratio = (event.clientX - box.left) / (box.width || 1)
    setHover(Math.max(0, Math.min(count - 1, Math.round(ratio * (count - 1)))))
  }, [count])

  const ticks = niceTicks(min, max)
  const tick = formatTick ?? formatValue

  return (
    <div className="ds-chart" ref={ref}>
      <svg height={height} width="100%" role="img" aria-label={ariaLabel} onPointerLeave={() => setHover(null)}>
        <defs>
          <linearGradient id={`area-${gradientId}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--chart-fill-from)" />
            <stop offset="100%" stopColor="var(--chart-fill-to)" />
          </linearGradient>
        </defs>

        {ticks.map((value, index) => (
          <g key={index}>
            <line className="ds-chart__grid" x1={padding.left} x2={padding.left + plotW} y1={y(value)} y2={y(value)} />
            <text className="ds-chart__axis" x={padding.left - 8} y={y(value)} dominantBaseline="middle" textAnchor="end">{tick(value)}</text>
          </g>
        ))}

        {markerIndex !== undefined && (
          <>
            <line className="ds-chart__marker" x1={x(markerIndex)} x2={x(markerIndex)} y1={padding.top} y2={padding.top + plotH} />
            {markerLabel && <text className="ds-chart__axis" x={x(markerIndex) + 4} y={padding.top + 8}>{markerLabel}</text>}
          </>
        )}

        {series.map((entry) => {
          const points = entry.values.map((value, index) => `${x(index)},${y(value)}`)
          return (
            <g key={entry.id}>
              {entry.area && (
                <path
                  d={`M${x(0)},${padding.top + plotH} L${points.join(' L')} L${x(entry.values.length - 1)},${padding.top + plotH} Z`}
                  fill={`url(#area-${gradientId})`}
                />
              )}
              <polyline
                className="ds-chart__line"
                points={points.join(' ')}
                stroke={seriesColor(entry.tone)}
                strokeDasharray={entry.dashed ? '4 3' : undefined}
              />
            </g>
          )
        })}

        {xLabels.map((entry, index) => {
          const step = Math.ceil(xLabels.length / Math.max(2, Math.floor(plotW / 64)))
          if (index % step !== 0 && index !== xLabels.length - 1) return null
          return (
            <text
              key={`${entry}-${index}`}
              className="ds-chart__axis"
              x={x(index)}
              y={height - 6}
              textAnchor={index === 0 ? 'start' : index === xLabels.length - 1 ? 'end' : 'middle'}
            >
              {entry}
            </text>
          )
        })}

        {hover !== null && (
          <>
            <line className="ds-chart__cursor" x1={x(hover)} x2={x(hover)} y1={padding.top} y2={padding.top + plotH} />
            {series.map((entry) => entry.values[hover] !== undefined && (
              <circle key={entry.id} cx={x(hover)} cy={y(entry.values[hover])} r="3.5" fill="var(--surface)" stroke={seriesColor(entry.tone)} strokeWidth="2" />
            ))}
          </>
        )}

        <rect className="ds-chart__hit" x={padding.left} y={padding.top} width={plotW} height={plotH} onPointerMove={onMove} />
      </svg>

      {hover !== null && (
        <div className="ds-chart__tip" style={{ left: x(hover), top: padding.top - 4 }}>
          <div className="ds-chart__tip-date">{xLabels[hover]}</div>
          {series.map((entry) => (
            <div className="ds-chart__tip-row" key={entry.id}>
              <span className="ds-chart__swatch" style={{ background: seriesColor(entry.tone) }} aria-hidden="true" />
              {entry.label}
              <b>{formatValue(entry.values[hover])}</b>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

/* ── Sparkline — trend shape only, no axes ───────────────────────────────── */

export function Sparkline({ values, tone = 'primary', height = 32, area = true, ariaLabel }: {
  values: number[]; tone?: SeriesTone; height?: number; area?: boolean; ariaLabel: string
}) {
  const [ref, width] = useWidth(140)
  const gradientId = useId().replace(/:/g, '')
  const min = Math.min(...values)
  const max = Math.max(...values)
  const span = max - min || 1
  const x = (index: number) => (index / Math.max(1, values.length - 1)) * (width - 2) + 1
  const y = (value: number) => height - 2 - ((value - min) / span) * (height - 4)
  const points = values.map((value, index) => `${x(index)},${y(value)}`)

  return (
    <div className="ds-chart" ref={ref}>
      <svg height={height} width="100%" role="img" aria-label={ariaLabel}>
        <defs>
          <linearGradient id={`spark-${gradientId}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--chart-fill-from)" />
            <stop offset="100%" stopColor="var(--chart-fill-to)" />
          </linearGradient>
        </defs>
        {area && <path d={`M${x(0)},${height} L${points.join(' L')} L${x(values.length - 1)},${height} Z`} fill={`url(#spark-${gradientId})`} />}
        <polyline className="ds-chart__line" points={points.join(' ')} stroke={seriesColor(tone)} strokeWidth="1.5" />
      </svg>
    </div>
  )
}

/* ── Column chart ────────────────────────────────────────────────────────── */

export function BarChart({ data, height = 200, formatValue = String, ariaLabel, onSelect }: {
  data: Array<{ label: string; value: number; tone?: SeriesTone }>
  height?: number; formatValue?: (value: number) => string; ariaLabel: string
  onSelect?: (label: string) => void
}) {
  const [ref, width] = useWidth()
  const [hover, setHover] = useState<number | null>(null)
  const padding = { top: 8, right: 8, bottom: 22, left: 38 }
  const plotW = Math.max(40, width - padding.left - padding.right)
  const plotH = Math.max(40, height - padding.top - padding.bottom)
  const max = Math.max(...data.map((entry) => entry.value)) || 1
  const slot = plotW / Math.max(1, data.length)
  const barW = Math.max(4, Math.min(28, slot * 0.62))
  const ticks = niceTicks(0, max)

  return (
    <div className="ds-chart" ref={ref}>
      <svg height={height} width="100%" role="img" aria-label={ariaLabel} onPointerLeave={() => setHover(null)}>
        {ticks.map((value, index) => {
          const y = padding.top + (1 - value / max) * plotH
          return (
            <g key={index}>
              <line className="ds-chart__grid" x1={padding.left} x2={padding.left + plotW} y1={y} y2={y} />
              <text className="ds-chart__axis" x={padding.left - 8} y={y} dominantBaseline="middle" textAnchor="end">{formatValue(value)}</text>
            </g>
          )
        })}
        {data.map((entry, index) => {
          const barH = (entry.value / max) * plotH
          const x = padding.left + slot * index + (slot - barW) / 2
          return (
            <g key={entry.label} onPointerEnter={() => setHover(index)} onClick={() => onSelect?.(entry.label)} style={{ cursor: onSelect ? 'pointer' : undefined }}>
              <rect x={padding.left + slot * index} y={padding.top} width={slot} height={plotH} fill="transparent" />
              <rect
                x={x}
                y={padding.top + plotH - barH}
                width={barW}
                height={Math.max(1, barH)}
                rx="2"
                fill={seriesColor(entry.tone)}
                opacity={hover === null || hover === index ? 1 : 0.45}
                style={{ transition: 'opacity 120ms' }}
              />
              <text className="ds-chart__axis" x={padding.left + slot * index + slot / 2} y={height - 6} textAnchor="middle">{entry.label}</text>
            </g>
          )
        })}
      </svg>
      {hover !== null && (
        <div className="ds-chart__tip" style={{ left: padding.left + slot * hover + slot / 2, top: padding.top }}>
          <div className="ds-chart__tip-date">{data[hover].label}</div>
          <div className="ds-chart__tip-row">
            <span className="ds-chart__swatch" style={{ background: seriesColor(data[hover].tone) }} aria-hidden="true" />
            <b>{formatValue(data[hover].value)}</b>
          </div>
        </div>
      )}
    </div>
  )
}

/* ── Donut — only when the parts genuinely make a whole ──────────────────── */

export function Donut({ data, size = 132, thickness = 14, centerValue, centerLabel, ariaLabel }: {
  data: Array<{ label: string; value: number; tone?: SeriesTone }>
  size?: number; thickness?: number; centerValue?: string; centerLabel?: string; ariaLabel: string
}) {
  const total = data.reduce((sum, entry) => sum + entry.value, 0) || 1
  const radius = (size - thickness) / 2
  const circumference = 2 * Math.PI * radius
  let offset = 0

  return (
    <div className="ds-row" style={{ gap: '1.25rem', flexWrap: 'wrap' }}>
      <svg width={size} height={size} role="img" aria-label={ariaLabel} style={{ flex: 'none' }}>
        <g transform={`rotate(-90 ${size / 2} ${size / 2})`}>
          <circle cx={size / 2} cy={size / 2} r={radius} fill="none" stroke="var(--surface-sunk)" strokeWidth={thickness} />
          {data.map((entry) => {
            const length = (entry.value / total) * circumference
            const element = (
              <circle
                key={entry.label}
                cx={size / 2} cy={size / 2} r={radius} fill="none"
                stroke={seriesColor(entry.tone)} strokeWidth={thickness}
                strokeDasharray={`${Math.max(0, length - 2)} ${circumference}`}
                strokeDashoffset={-offset}
                strokeLinecap="butt"
              />
            )
            offset += length
            return element
          })}
        </g>
        {centerValue && (
          <>
            <text x={size / 2} y={size / 2 - 2} textAnchor="middle" fill="var(--text)" style={{ fontSize: 18, fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{centerValue}</text>
            <text x={size / 2} y={size / 2 + 14} textAnchor="middle" className="ds-chart__axis">{centerLabel}</text>
          </>
        )}
      </svg>
      <div className="ds-stack ds-stack--sm" style={{ flex: 1, minWidth: '9rem' }}>
        {data.map((entry) => (
          <div className="ds-row" key={entry.label} style={{ justifyContent: 'space-between', gap: '.75rem' }}>
            <span className="ds-row" style={{ gap: '.5rem', minWidth: 0 }}>
              <span className="ds-chart__swatch" style={{ background: seriesColor(entry.tone) }} aria-hidden="true" />
              <span style={{ fontSize: 'var(--fs-sm)' }}>{entry.label}</span>
            </span>
            <span className="ds-meta tnum">{Math.round((entry.value / total) * 100)}%</span>
          </div>
        ))}
      </div>
    </div>
  )
}

/** Chart-shaped skeleton so the page does not reflow when data arrives. */
export function ChartSkeleton({ height = 200 }: { height?: number }) {
  return <div className="ds-skel" style={{ height, borderRadius: 'var(--r-2)' }} aria-hidden="true" />
}

export { useWidth }
