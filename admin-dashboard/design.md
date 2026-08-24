# Console DS — Meal Clarity admin console

A design system for an operational console people use for hours a day. Borrowed
principles, not appearances: Linear's spacing discipline, Stripe's table and
financial clarity, Vercel's monochrome chrome, Retool's rule-separated sections,
PostHog's restraint in charts. No product's identity is reproduced.

## Stance

Neutral base, one accent, semantic colour reserved for state. Borders do the
work that shadows usually do. Density is medium-high: scanability and speed
outrank decoration. Every element earns its place or is removed.

## Theme

Light-first; dark is opt-in and never inferred from the OS. Both are the same
system with a swapped neutral ramp, so no component hardcodes a colour.

Surfaces step three times — rail, canvas, card — and are separated by hairlines.

| Token | Light | Dark |
| --- | --- | --- |
| `--bg` | `oklch(97.7% .002 265)` | `oklch(13.2% .008 265)` |
| `--bg-rail` | `oklch(99.1% .001 265)` | `oklch(15% .008 265)` |
| `--surface` | `oklch(100% 0 0)` | `oklch(16.5% .008 265)` |
| `--text` | `oklch(19% .012 265)` | `oklch(95% .004 265)` |
| `--border` | `oklch(91.4% .005 265)` | `oklch(26% .011 265)` |
| `--accent` | `oklch(53% .185 272)` | `oklch(56% .185 272)` |

Accent (iris) is used only for: primary actions, the active navigation icon and
indicator, the selected tab underline, selection, focus, and the primary data
series. Green / amber / red carry state and nothing else.

Every foreground/background pair in the system is measured, not eyeballed:
26 pairs across both themes clear WCAG AA 4.5:1. The dark accent sits at 56%
rather than 64% because white button text needs 4.5:1 while the fill itself
only needs 3:1 — text wins that trade.

## Typography

One family, Inter. Hierarchy comes from size, weight, and spacing — not from a
second voice or dramatic scale jumps.

- Page title `1.5rem` / 650
- Section title `1rem` / 600 · panel title `0.875rem` / 600
- Body `0.875rem` · tables, buttons, dense body `0.8125rem`
- Metadata `0.75rem` · micro-labels and badges `0.6875rem`
- Metric value `1.5rem` / 600, tabular figures
- Mono (`--font-mono`) only for ids, keys, codes, and JSON

## Spacing, shape, elevation

4/8 scale (`--sp-1`…`--sp-12`). Radii stay modest: `6px` chips, `8px` inputs and
buttons, `10px` cards, `12px` dialogs. Nothing is pill-shaped except badges and
progress tracks.

Default elevation is a 1px border plus `--shadow-xs`. Real shadow is reserved
for floating layers: menus, dialogs, drawers, toasts, command menu.

## Layout

Rail (240px, collapsible to 56px) + top context bar (52px) + content. Content
caps at 1400px, or 1600px on table-heavy pages, 900px on settings.

The rail is `position: fixed` below 60rem, which takes it out of the shell grid —
so the shell is a single column there and two columns above. Group labels,
counts, and the user block collapse to icons when the rail is collapsed.

The top bar answers "where am I" first: breadcrumbs, then search (⌘K), then the
global range, language, theme, and notifications. It never repeats navigation.

## Sections over cards

A card is for a bounded object. Related content that merely belongs together
gets a `Section`: a heading, an optional action, and a rule. This is what keeps
dense pages from becoming a field of boxes.

## Data visualisation

One primary series in accent, one neutral comparison series, semantic colour
only for failure. Charts measure their own container so axis text renders at
real pixel size. Every chart has axis labels, subtle grid lines, a hover cursor
with a tooltip, and a direct-labelled legend. Sparklines carry trend shape only.
Donuts appear only when the parts genuinely make a whole.

## Tables

Sticky header, sortable columns with an explicit `aria-sort`, row selection with
a bulk action bar, a per-row menu, column visibility, search and filter chips,
and windowed pagination. Rows are compact (44px) with hairline dividers and no
zebra striping. Every table carries a caption for screen readers.

## States

Loading, empty, and error are designed, not afterthoughts. Skeletons mirror the
final layout so nothing reflows. Errors name the cause and the fix. Empty states
say what would put data there.

The console has no demo mode: if it cannot reach real data it says so rather
than showing numbers that are not true.

## Motion

110ms for colour and press, 160ms for hover and fade, 220ms for layout and
enter/exit. Transform and opacity only. Everything collapses under
`prefers-reduced-motion`.

## Accessibility

WCAG AA across both themes. Visible focus rings everywhere; inputs own a ring
that hugs the field. Status is never colour alone — badges carry text, deltas
carry an arrow, and status dots vary by shape (circle, square, diamond, ring).
Decorative counts are `aria-hidden` so an accessible name stays the label alone.
Dialogs trap focus, close on Escape, lock background scroll, and restore focus.
