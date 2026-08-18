# Meal Clarity design system

**Genre:** refined warm-consumer utility. **App family:** Workbench. **Core promise:** Show your meal. Check the result. Move on.

This system supports a warm, food-centric consumer nutrition product. Food imagery supplies the visual character; UI surfaces provide hierarchy without competing with it.

## Foundations

- Canvas: `#F6F6F2`, a warm off-white.
- Primary surface: white.
- Muted surface: `#F1F2F0`.
- Text: `#12130F`; secondary text: `#666862`.
- Border: `#E5E7E2`, used at low contrast.
- Accent: lime `#C7F36A`; selected/action dark lime `#5E7800`.
- Review surface: warm cream `#FFF8EA`; review ink: `#7A541D`.
- Destructive: `#B3261E`, reserved for confirmed removal flows.
- Macro colors: muted blue `#5F7892`, amber `#AD8248`, rose `#A86472`.

## Typography

- Screen title: 34/37, weight 700.
- Eyebrow/context label: 12/16, weight 700, modest letter spacing; never all-caps paragraphs.
- Hero metric: 44–52, weight 700; units remain 14–16 and muted.
- Section title: 21–24, weight 600–700.
- Card/row title: 16–19, weight 600.
- Body: 16/23; supporting copy: 14/20.
- Nutrition values use consistent Turkish thousands separators and aligned units.

The platform font is retained for native rendering and complete Turkish support.

## Spacing

The scale is 4, 8, 12, 16, 20, 24, 28, 32, 40, 48, 56, 64. Standard page gutters are 18–22 depending on screen density. Major sections use 28–40; closely related metadata uses 4–8.

## Radius and surfaces

- Input/control: 16.
- Compact/meal/action card: 20 with 16–20 padding.
- Standard/grouped card: 24 with 20–24 padding.
- Hero card: 28 with 24–28 padding.
- Food imagery: 20, or the containing card radius when edge-to-edge.

Cards use a faint border and two very soft shadows: a wide 6/24 shadow at 5% black and a near 1/4 shadow at 3% black. Elevation should be felt, not noticed. Avoid nesting multiple elevated cards; use dividers or tonal sections inside a primary surface.

## Navigation

The bottom navigation is a floating opaque-to-translucent surface with one subtle shadow. Add Meal is the only persistent lime-filled destination. Active tabs use icon/label weight and a short state mark rather than a second filled pill.

## Images

- Today/History thumbnail: 84–96 square, cover crop.
- Meal detail: 16:9, full-width.
- Photo review/result: 16:9 or 4:5 depending on captured image, with an uncluttered crop.

## Motion

- Fast feedback: 160 ms.
- Standard transitions and selected states: 220 ms.
- Larger content transitions: 280 ms.
- Respect reduced-motion settings; no decorative looping animation.

## Card roles

- `HeroCardSurface`: daily nutrition and primary analysis state.
- `StandardCardSurface`: meal summary, settings groups, current-period data.
- `CompactCardSurface`: meals and quick actions.

Do not nest these surfaces unless the inner element is an interactive control with a distinct semantic role.

## Interaction and accessibility

- Cross-platform touch targets are at least 48 logical pixels; adjacent targets retain at least 8 logical pixels of separation where possible.
- Icon-only buttons require localized tooltips and semantic labels.
- Long-press and swipe may accelerate an action but never provide its only discoverable route.
- Respect safe-area insets, system text scaling, high contrast, and reduced motion.
- Confident AI results stay visually quiet. Uncertain results use the review surface and a plain-language action; never use sparkles, lasers, scanning lines, or decorative “AI” badges.
