# Design audit

## Product promise

The product should let someone show a meal, verify only what is uncertain, save it, and return to their day. The redesign therefore treats food photography as the primary content and nutrition data as calm evidence—not as a dashboard to operate.

## What already works

- The core meal pipeline is functional: camera/gallery/text input, analysis, item correction, persistence, history, detail, and daily totals are connected.
- The existing warm off-white canvas, dark ink, restrained lime action color, and native typeface are appropriate foundations.
- The add-meal sheet already gives the camera the strongest hierarchy.
- Analysis is data-aware and does not fabricate trends when the history window is too small.
- The review model distinguishes canonical food identity from localized display names and highlights low-confidence items without alarming language.

## Friction and visual debt

### Today

- The daily summary is useful but reads as one large white data block; the remaining-calorie story and the meal-log story compete for the first screenful.
- Meal photography is too small relative to metadata, so the feed feels like a settings list rather than a food journal.
- The quick-add card repeats the bottom navigation action without adding enough photographic or task context.

### Add meal and AI review

- The photo route is correct, but the choice sheet still presents secondary methods with nearly equal visual weight.
- Review rows rely on long-press for removal. That interaction is undiscoverable and has no equivalent visible affordance.
- The review heading, image, detected-food list, totals, and sticky action are individually sound, but their rhythm feels like stacked modules rather than one continuous result.
- High-confidence rows still carry too much chrome; uncertainty should be the exception that receives emphasis.

### Meal detail

- The separate app bar and inset 16:9 photo reduce the emotional value of the meal image.
- Summary and ingredient cards repeat borders and shadows, producing a card-inside-a-feed feeling.
- Destructive action appears twice and the top overflow button does not describe its only action.

### History

- Day navigation consumes a full card before the user sees food.
- The narrow `ListTile` composition constrains meal names and calories on compact devices and makes images secondary.
- There is no quick visual sense of which adjacent days contain entries.

### Analysis

- The screen is appropriately honest about insufficient data, but repeated white surfaces make it feel more like a generic dashboard than a coaching view.
- Period controls, summary, and trend content need a clearer single narrative: consistency first, then calories/macros.

### Profile

- Every section uses the same row-card pattern and therefore has no primary personal/goal moment.
- Rows appear actionable but are static. Non-functional chevrons or switches must not be introduced.
- Goal values need a concise summary before detailed preferences and account state.

### System and accessibility

- Some semantic colors are embedded directly in screens instead of expressed as reusable roles.
- Several compact controls meet iOS minimums only indirectly; the system should guarantee 48 logical pixels for cross-platform touch targets.
- Text scaling, long Turkish labels, high contrast, reduced motion, empty history, and missing-photo states need explicit visual QA.

## Redesign thesis

Use an editorial food-journal composition: generous image crops, fewer but more purposeful surfaces, strong typographic grouping, and quiet nutrition metadata. Lime appears only on the primary action, current progress, and selected state. Amber appears only where the model needs human review. No gradients, decorative AI symbols, glass-heavy panels, neon effects, or fabricated health insights.

## Skill-based constraints

- Hallmark: Workbench app family, refined warm-consumer genre, asymmetric hierarchy, no excessive floating containers, no gradient-dependent styling.
- Mobile UI: one primary action per screen, safe-area-aware bottom actions, visible alternatives to gestures, and compact-device resilience.
- iOS: native system typography, 44pt-or-larger targets, semantic labels, Dynamic Type tolerance, restrained motion.
- Android: Material 3 behavior, 48dp targets, predictive/back-safe navigation, explicit TalkBack semantics, no status-bar overlap.
- UI/UX Pro Max: use `LayoutBuilder`/responsive constraints where needed, label icon-only controls, and verify touch-target spacing. Its two local visual-style searches did not produce a food-tracker match, so no unverified palette/font recommendation was adopted.

## Final implementation audit

**Hallmark pre-emit critique:** Philosophy 5, Hierarchy 4, Execution 4, Specificity 5, Restraint 4, Variety 4. No axis requires a revision pass.

**Hallmark slop test:** 58/58 design intents satisfied. The web-only display-font and CSS-spacing checks are fulfilled through their native equivalents: platform system typography with Dynamic Type/TextScaler support, and Flutter logical-pixel spacing validated at 360–430 px. The build has no gradients, decorative AI motifs, fake metrics, fake device chrome, mixed icon libraries, gesture-only actions, oversized accent fields, or fabricated insight copy.

**UI/UX Pro Max quick reference:**

1. Layout uses a 390 px reference viewport, safe-area-aware bottom actions, `LayoutBuilder` for the meal hero, and compact-device tests at 360, 375, 390, and 430 px.
2. Style is warm editorial utility: off-white canvas, white food surfaces, dark ink, restrained lime action/state, amber review-only state, muted macro colors, native system type.
3. Interaction uses 48 logical-pixel minimum targets, localized tooltips on icon-only actions, visible remove/edit routes, high-contrast-aware surfaces, reduced-motion-aware navigation, and no horizontal overflow in the tested phone widths.

**Platform audit:** iOS safe areas, Dynamic Type tolerance, native typography, clear modal dismissal, and 44 pt minimums are covered by the 48 logical-pixel target. Android Material 3 behavior, 48 dp targets, TalkBack semantics, system-back-safe routes, and bottom inset handling remain intact.

**Visual regression coverage:** Today, Add Meal, AI Review, Meal Detail, History, Analysis, and Profile are captured at 390 × 844. The golden harness intentionally uses Flutter's deterministic test font rendering, so glyphs appear as blocks in raw baseline PNGs; geometry, color, clipping, and overflow remain testable.

## Second-pass findings and fixes

The second pass used a running iPhone 17 Pro simulator rather than relying only on Flutter goldens.

- **History source mismatch — fixed:** non-persistent Today meals were visible on Today but absent from History. History now consumes the same de-duplicated, date-sorted meal collection as Analysis.
- **Lost tab state — fixed:** Analysis period and History day selection are owned by the shell, so switching tabs no longer resets the user's context.
- **Large-text overflow — fixed:** at 200% text scale, the Today calorie/macronutrient summary and Analysis metric groups now reflow vertically. Profile rows also switch from horizontal to stacked layout.
- **Add Meal accessibility — fixed:** paired gallery/text and retake/analyze actions stack at large text sizes instead of forcing two-line labels into fixed-width buttons.
- **Navigation legibility — fixed:** bottom navigation labels now meet the 11pt/sp platform minimum, remain single-line through controlled tab-label scaling, and expose stable semantic/key identities.
- **Redundant UI — fixed:** Profile no longer repeats the same four goals directly below its goal hero. Meal Detail no longer exposes the same delete action behind an ambiguous overflow icon and again at the bottom.
- **History recognition — fixed:** when several logged dates exist, a labeled, horizontally scrollable day rail exposes available days directly instead of requiring repeated arrow navigation.
- **AI-looking iconography — fixed:** the Analysis destination uses a conventional bar-chart symbol rather than an insights/sparkle-like mark.
- **Core action copy — fixed:** the Today shortcut now says “Show your meal” and explains the photo-first correction flow instead of duplicating the generic Add Meal label already present in navigation.

Second-pass checks cover 360–430 px widths, 200% text scaling across all primary tabs and Add Meal, state retention across tab changes, a real iOS safe-area render, and the seven-screen golden suite.

## Navigation and color vitality pass

- Replaced abrupt primary-tab swaps with a four-page horizontal `PageView`; Today, History, Analysis, and Profile now support direct left/right swipes.
- Kept the five-destination bottom bar fixed and synchronized with swipe state. Add Meal remains a modal action rather than becoming a blank page.
- Preserved visible tap navigation as the accessible alternative to the swipe gesture.
- Rebuilt the semantic palette around deep emerald, fresh lime, clean white surfaces, and a cool mint canvas. Muted text, dividers, shadows, and macro colors were strengthened instead of adding decorative gradients.
- Changed primary filled actions to high-contrast emerald with white text, while lime is reserved for energetic highlights and the central capture action.
- Applied a branded soft-green surface to the daily nutrition summary so the main dashboard has a clear visual anchor.
- Motion uses the shared duration and curve tokens, and becomes an immediate page jump when reduced animations are enabled.

## Food recognition and meal-review pass

- The Add Meal sheet now treats the camera as the dominant, full-width action. Its title and explanatory copy are centered as a single visual introduction.
- The analysis state uses a viewport-filling centered layout, so “Yiyecekler bulunuyor” remains geometrically centered instead of drifting with scroll content.
- Meal Review is now an exception-based checkpoint: confident foods stay quiet, while only uncertain identity or portion rows receive the amber review treatment.
- The footer separates the secondary correction route from the always-clear “Öğünü kaydet” primary action and stacks safely under large text.
- Portion correction no longer asks the user to infer grams alone. It presents small, regular, and large visual choices with gram labels, plus exact gram entry for users who know the value.
- Catalog-backed portion images take precedence. Where a curated reference does not exist yet, the UI uses an honest relative-size diagram rather than pretending to know photographic volume.
- Hallmark review found no new gradients, decorative AI motifs, confidence theater, nested-card excess, or gesture-only controls. The uncertain state is purposeful and the high-confidence path remains visually restrained.
- Golden coverage now includes the portion clarification sheet in addition to Add Meal, loading behavior, and Meal Review widget assertions.
