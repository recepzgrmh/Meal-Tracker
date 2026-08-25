-- Turkish aliases were machine-generated for the whole imported catalog,
-- including 30,000 foreign supermarket products. That put strings like
-- 'badem', 'yoğurt' and 'kremal' on branded rows at priority 85-90 and left
-- the curated Turkish foods they collide with at 60.
--
-- Two things then went wrong at once, and neither surfaced as an error:
--
--   1. The deterministic matcher does not rank by priority. It sorts by match
--      position and match length only, so among identical-length matches for
--      "yoğurt" the winner is whichever row the catalog query returned first —
--      a branded USDA yoghurt at 94 kcal instead of "Yoğurt, homojenize,
--      yarım yağlı" at 49. Nearly double, silently.
--
--   2. Priority is read later, only to decide whether to ask. The identity
--      ambiguity threshold is 80, so an 85 alias reports confidence 0.98 and
--      no clarification question at all — while the correct generic row, at
--      60, would have asked "which yoghurt?".
--
-- Worse than the calorie error is that 'badem' also matched "Imitation butter
-- flavor popcorn seasoning salt" (0 kcal) through the same route.
--
-- Demoting these below 80 would only fix the second half: selection still does
-- not consult priority, so a branded row could keep winning on row order and
-- would merely become a question instead of a silent answer. Removing the
-- aliases removes the competition itself.
--
-- Only the Turkish aliases go, and only on foreign branded tiers. Every one of
-- these 30,000 rows keeps a non-Turkish alias (verified: zero become
-- unreachable), so they remain findable through manual catalog search, which
-- is where someone looking for an imported product actually looks.
-- tr_branded, generic_core and quality_global are untouched.

delete from public.food_aliases a
using public.foods f
where a.food_id = f.id
  and a.locale = 'tr-TR'
  and f.metadata ->> 'tier' in ('off_en_global', 'usda_branded_quality');
