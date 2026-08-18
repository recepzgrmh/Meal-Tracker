# Redesign plan

## Direction

The app becomes a calm, photo-first meal journal. The home screen answers “where am I today?” and immediately shows recognizable meals. Add Meal answers “how do I show this meal?” Review answers “what needs my attention?” Detail answers “what was recorded?” Secondary screens retain the same visual grammar without turning into dashboards.

## Core sequence

1. **Add Meal** — camera is a large photographic action; gallery and text remain clearly available but secondary.
2. **AI Review** — the captured meal leads; confident detections are quiet; only uncertain detections receive a warm review treatment; edit and remove are visible.
3. **Today** — a compact daily status story, then a food-forward chronological journal with a direct add action.

## Screen changes

- **Today:** compress the hero, increase meal-image scale, simplify metadata, and reduce repeated container styling.
- **Add Meal:** retain the bottom sheet, strengthen camera dominance, and make the product promise explicit in plain language.
- **Review:** join image, detected items, and totals into a continuous result; expose row actions; retain a safe-area-aware sticky primary action.
- **Meal detail:** move to an edge-led image composition with overlaid navigation, a single nutrition summary, and quieter ingredient rows.
- **History:** replace the large date card with a compact real-data day rail and food-forward daily entries.
- **Analysis:** preserve insufficient-data honesty; emphasize consistency and a small number of interpretable metrics.
- **Profile:** add one goal summary and use quieter grouped information below it; do not imply unsupported editing.
- **Navigation:** keep five destinations and the persistent Add Meal action, but reduce glass styling and improve state clarity.

## Validation

- Run `dart format`, `flutter analyze`, and relevant widget/media/golden tests.
- Render compact-phone screenshots for Today, Review, Detail, History, Analysis, and Profile.
- Verify no overflow at larger text scale, no inaccessible gesture-only action, no touch target below 44pt/48dp, and no hidden primary action behind system insets.
- Finish with Hallmark slop and contract checks plus platform-specific accessibility review.
