# Controlled Portion Reference System — Pilot Batch

Date: 2026-08-18 · Batch `pilot-portion-references-2026-08` · Portion policy `portion-policy-v1`

This document covers the first 10 foods of the portion-reference programme: where every
gram and every nutrient came from, what could not be sourced, how the images are produced,
and what has to happen before anything is published.

The rule the whole pipeline is built around: **a reference image shows relative amount,
nothing else.** The gram value comes from the controlled catalog portion record. No image
model is asked for a weight, a calorie or a macro, and no photograph is ever presented as
measurement evidence.

---

## 1. Source policy

| Data | Primary source | Fallback |
| --- | --- | --- |
| Composition per 100 g | TürKomp (T.C. Tarım ve Orman Bakanlığı) | TÜBER 2022 per-portion table, divided by the published portion weight |
| Standard portion + household measure | TÜBER 2022 (T.C. Sağlık Bakanlığı, Yayın No: 1031) | none |
| Generic non-Turkish foods | — | USDA FoodData Central |

**USDA is never used as an analogue for a Turkish dish.** Menemen is not "egg omelet with
tomato"; kuru fasulye is not "beans, cooked, canned". A food with no Turkish published
source stays `blocked`.

Source artefacts are hashed and committed under `tool/catalog/snapshots/` with
`snapshot_index.json` recording URL, release, retrieval time and sha256. The builder
verifies every hash before it reads a single number; a changed snapshot fails the build
rather than silently shifting a value.

## 2. Mapping table — 10 pilot foods

| Requested | Catalog record (named after its source) | Composition | Portion | small / **regular** / large (g) | Status |
| --- | --- | --- | --- | --- | --- |
| Beyaz peynir | Peynir, beyaz, tam yağlı | TürKomp `01.02.0004` | TÜBER Ek 2.1.1 + Ek 2.3.1 | 40 / **60** / 90 | `needs_review` |
| Pilav | Beyaz pirinç, pişmiş (yağ ilavesi hariç) | TÜBER Ek 2.3.1 | TÜBER Ek 2.1.5 + Ek 2.3.1 | 90 / **180** / 270 | `needs_review` |
| Bulgur pilavı | Bulgur, pişmiş (yağ ilavesi hariç) | TÜBER Ek 2.3.1 | TÜBER Ek 2.1.5 + Ek 2.3.1 | 90 / **180** / 270 | `needs_review` |
| Makarna | Makarna, haşlanmış | TÜBER Ek 2.3.1 | TÜBER Ek 2.1.5 + Ek 2.3.1 | 75 / **150** / 225 | `needs_review` |
| Yoğurt | Yoğurt, homojenize, tam yağlı | TürKomp `01.02.0015` | TÜBER Ek 2.3.1 | 150 / **240** / 360 | `needs_review` |
| Menemen | — | — | — | — | **`blocked`** |
| Tavuk göğsü | Tavuk göğüs eti, pişmiş | TÜBER Ek 2.3.1 | TÜBER Ek 2.1.3 + Ek 2.3.1 | 50 / **80** / 120 | `needs_review` |
| Kuru fasulye | Kuru fasulye, haşlanmış (yağsız) | TÜBER Ek 2.3.1 | TÜBER Ek 2.1.3 + Ek 2.3.1 | 85 / **130** / 195 | `needs_review` |
| Mercimek çorbası | — | — | — | — | **`blocked`** |
| Patates kızartması | — | — | — | — | **`blocked`** |

Every record is named after the source row, not after the colloquial dish. That is
deliberate: `Beyaz pirinç, pişmiş` and `pilav` are not the same food, and pretending
otherwise is how an unsourced number enters the catalog wearing a citation.

### Composition per 100 g as published / derived

| Record | kcal | Protein | Carbs | Fat | Basis |
| --- | --- | --- | --- | --- | --- |
| Peynir, beyaz, tam yağlı | 309 | 16.01 | 8.21 | 23.55 | published per 100 g |
| Beyaz pirinç, pişmiş | 93.33 | 2.0 | 20.0 | 0.0 | 84 kcal ÷ 90 g portion |
| Bulgur, pişmiş | 83.33 | 3.11 | 18.89 | 0.0 | 75 kcal ÷ 90 g portion |
| Makarna, haşlanmış | 126.67 | 5.33 | 25.33 | 0.0 | 95 kcal ÷ 75 g portion |
| Yoğurt, homojenize, tam yağlı | 69 | 4.53 | 4.24 | 3.80 | published per 100 g |
| Tavuk göğüs eti, pişmiş | 110 | 25.5 | 0.0 | 1.25 | 88 kcal ÷ 80 g portion |
| Kuru fasulye, haşlanmış | 120 | 9.69 | 18.46 | 0.77 | 156 kcal ÷ 130 g portion |

TÜBER prints carbohydrate and fat as whole grams, so every `derived_from_published_portion`
row inherits that precision limit. This is recorded in each row's `transformation_notes`.

## 3. Blocked foods and why

**Menemen.** No entry in TürKomp (645 records, incl. 122 traditional foods) and none in any
TÜBER appendix. Resolving it needs a weighed recipe study: standardised recipe, ingredient
weights from TürKomp, measured cooked yield, dietitian sign-off, then publication as a
recipe-derived record with its own provenance.

**Mercimek çorbası.** The portion exists but the composition does not. TÜBER Ek 2.1.5
publishes `Çorba çeşitleri … = ¾ kupa veya 1.5 orta kepçe veya 180 mL veya 1 küçük kase`
(footnote 10: that is ½ standard portion) — a **volume**, with no gram weight and no
nutrient row in Ek 2.3.1. TürKomp only holds `12.02.0156 Kuru Çorba Karışımı, Mercimek`,
a dry powder. Converting 180 mL to grams would require a density assumption, which is
exactly the kind of invention this pipeline exists to prevent. Note also that
`food_portions.grams` is `NOT NULL`, so the schema currently cannot express a
volume-only portion.

**Patates kızartması.** TÜBER Ek 2.3.1 lists only `Patates, pişmiş` (90 g, boiled) and the
optional-foods table Ek 2.3.2 has no fries or crisps. TürKomp has `08.02.0002 Patates,
kızartmalık, dondurulmuş` (raw frozen) and `12.02.0031 Cips, patates` (crisps). Frying oil
uptake is preparation-dependent and must be measured, not assumed.

## 4. Source conflicts found

1. **Beyaz peynir energy.** TürKomp `01.02.0004` = 309 kcal/100 g. TÜBER Ek 2.3.1 implies
   275 kcal/100 g (165 kcal per 60 g). ~11% apart. TürKomp wins per the source policy;
   the gap is recorded, not averaged away.
2. **Beyaz peynir vs. the shipped seed.** `supabase/seed.sql` currently states 289 kcal and
   2.5 g carbs per 100 g with portions 15/30/50 g, source `curated-demo`. None of it is
   traceable and all of it differs materially from both official sources. The app is
   shipping an unsourced cheese record today.
3. **Yogurt portion.** TÜBER Ek 2.1.1 says `Yoğurt = 1 küçük kase veya 200 mL`, while
   Ek 2.3.1 tabulates the portion as **240 g**. Two tables of the same guide disagree.
   240 g is used because it is printed in grams and needs no density assumption; the
   200 mL variant is recorded unresolved.
4. **Cooked state, three foods.** TÜBER Ek 2.1.5 footnote 5 states that fat added during
   cooking is excluded. So `Beyaz pirinç, pişmiş`, `Bulgur, pişmiş` and
   `Makarna, haşlanmış` are not pilav, bulgur pilavı or sauced pasta. The colloquial
   aliases are deliberately withheld (see `aliasPolicyNote` in the mapping file).
5. **Kuru fasulye.** TÜBER's row is boiled beans (1 g fat per 130 g). The Turkish dish
   `kuru fasulye` is a stew with oil and tomato paste. The alias `kuru fasulye` is
   withheld; only `haşlanmış kuru fasulye` is exposed.
6. **Grouped household measure.** TÜBER Ek 2.1.3 groups `Nohut, fasulye, barbunya, iç
   bakla, börülce (haşlanmış)` into one 130 g row. It is not bean-specific.

## 5. Portion derivation policy

`regular` is always an officially published standard portion. `small` and `large` are
**product-derived reference sizes** unless a source publishes them, and every derived row
says so in `transformation_notes`. Coefficients live in one file,
`tool/catalog/data/portion_policy.json`, and the loader rejects a factor edited outside the
documented band (small 0.60–0.70, large 1.40–1.60) unless it carries an explicit
`bandExemption` with a written reason.

| Category | small | large | Rounding |
| --- | --- | --- | --- |
| `dairy_cheese` | ×0.67 | ×1.50 | 5 g |
| `dairy_yogurt` | ×0.625 (exempt, documented) | ×1.50 | 10 g |
| `grain_cooked` | **published** | ×1.50 | 5 g |
| `legume_cooked` | ×0.65 | ×1.50 | 5 g |
| `meat_cooked` | ×0.625 (exempt, documented) | ×1.50 | 5 g |

`grain_cooked` is the one category where `small` is not derived. TÜBER Ek 2.1.5 footnote 4
publishes the distinction directly: one standard portion of rice/bulgur/pasta is the
**garnish** serving, and the second-course serving eaten at home equals **2 standard
portions**. So `small` = published 1-portion garnish weight and `regular` = published
2-portion serving weight; only `large` is derived.

None of these derived values may be labelled as a TÜBER-published figure in the UI, in
export, or in support answers.

## 6. Image production standard

Version `portion-reference-standard-v1`. Applies to every image in the programme.

- Photorealistic overhead food photograph, fixed **85°** camera, fixed camera distance.
- Same matte white plate (or bowl) across all three variants of a food; **plate diameter
  constant across the whole series**.
- Neutral light stone tabletop, soft diffused daylight, no hard shadows.
- Colours vivid but natural; food realistic and edible-looking; no restaurant styling.
- No utensils, hands, people, napkins, packaging, logos, watermarks, text or decorative
  objects. No garnish unless the canonical recipe includes it.
- Whole plate inside the frame; food never crops out of frame.
- Background and vessel as close to pixel-identical as the generator allows.
- 1:1 aspect, ≥1024×1024 production render, WebP at 512×512 for mobile, sRGB.
- **No gram value or any other text inside the image.** The app renders the weight.

Soups and yogurt use a bowl. The bowl size never changes between the three variants of one
food; only the fill level does.

Prompts and the per-food `consistency_note` are generated, not hand-written:
`tool/catalog/out/prompts/<slug>/<slug>--<size>--<grams>g.txt`, plus
`_consistency_note.txt` per food. 21 prompt files exist (7 resolvable foods × 3); the
3 blocked foods produce none.

### File naming

```
food-portions/{food_slug}/{food_slug}--small--{grams}g.webp
food-portions/{food_slug}/{food_slug}--regular--{grams}g.webp
food-portions/{food_slug}/{food_slug}--large--{grams}g.webp
```

Slugs are lowercase ASCII letters, digits and hyphens only. Paths are asserted in
`test/catalog/pilot_manifest_test.dart`.

## 7. QA checklist

No image reaches `visual_status = reviewed` or `published` without a named human working
through this list. Automated checks run in the manifest test; the rest are human review.

| # | Check | How |
| --- | --- | --- |
| 1 | Is it the right food? | human |
| 2 | Any wrong or extra ingredient? | human |
| 3 | Same plate/bowl across all three variants? | human, side by side |
| 4 | Same camera angle? | human, side by side |
| 5 | Same background? | human, side by side |
| 6 | Is small < regular < large visually obvious? | human, side by side |
| 7 | Is the portion difference exaggerated or meaningless? | human |
| 8 | Does the food look realistic? | human |
| 9 | Any text, logo or watermark? | human + prompt assertion (automated) |
| 10 | Readable at 120–160 px on a phone? | human, at thumbnail size |
| 11 | Has a human compared the image against the gram value? | human, sign-off recorded |
| 12 | Source, license and attribution metadata complete? | automated (manifest test) |

Failures are marked `rejected` with a reason in `reviewer_notes` and re-rendered. Only a
human sets `approved`/`reviewed`. The manifest test enforces that a `reviewed` or
`published` visual, or a `verified` verification status, cannot exist without
`reviewed_by` and `reviewed_at`.

## 8. Pipeline — how to reproduce

Prerequisite: `pdftotext` (poppler-utils) for the TÜBER PDF.

```bash
# 1. Rebuild the manifest, the CSV and the prompt files from hashed snapshots.
dart run tool/catalog/bin/build_pilot_manifest.dart --check

# 2. Regenerate the reviewable SQL seed from the manifest.
dart run tool/catalog/bin/build_catalog_seed.dart

# 3. Verify.
flutter test test/catalog
```

Outputs:

- `tool/catalog/out/pilot_portion_manifest.json` — 30 rows, full provenance
- `tool/catalog/out/pilot_portion_manifest.csv` — same rows, flat
- `tool/catalog/out/prompts/**` — 21 prompt files + 7 consistency notes
- `supabase/seed/pilot_portion_references.sql` — reviewable, **not** auto-applied

## 9. Supabase rollout (nothing is deployed automatically)

The schema and the public bucket already exist in
`supabase/migrations/20260818220000_food_catalog_portion_references.sql`. The edge function
already turns `food_portions.reference_image_path` into a public URL and ships it on
`portionOptions[].imageUrl`. Only data and images are missing.

Order of operations:

```bash
# 1. Confirm the migration is applied in the target project.
supabase migration list --linked

# 2. Apply it if it is not (staging first).
supabase db push --linked

# 3. Review supabase/seed/pilot_portion_references.sql by hand. In particular decide
#    what happens to the unsourced curated-demo beyaz peynir record, whose aliases
#    collide with the new one. Then apply against staging:
psql "$SUPABASE_DB_URL" -f supabase/seed/pilot_portion_references.sql

# 4. Render the pilot images from tool/catalog/out/prompts/, run the QA checklist,
#    convert to 512x512 WebP, then upload:
supabase storage cp --recursive ./renders/food-portions \
  ss:///food-portion-references/food-portions --linked

# 5. Only after QA sign-off, run the PUBLISH BLOCK at the bottom of the seed file with
#    real reviewer, source, license and attribution literals.
```

Do not run step 3 or 5 against production before staging verification.

## 10. Flutter integration

The portion bottom sheet (`lib/src/features/meal_flow.dart`) now:

- ranks catalog portions by `size_class` (`small`/`regular`/`large`) instead of taking the
  three lightest rows, so reviewed records drive the card order;
- renders the real catalog image from `portionOptions[].imageUrl`, with a neutral
  placeholder while the bytes load and the existing relative schematic on failure —
  the schematic never implies photographic precision;
- labels the three cards **Az / Normal / Fazla** with the gram value underneath;
- exposes each card to assistive technology as a button with a selected state and a
  `"<food>, <size>, <grams> g"` label, so selection is not conveyed by colour alone
  (the border weight already changes too);
- makes the whole card the tap target;
- scrolls the sheet instead of overflowing at large text;
- keeps the exact-gram entry as an always-available alternative.

Two bugs were fixed while doing this, both in the sheet itself:

- The sheet's `TextEditingController` was disposed the moment
  `showModalBottomSheet` returned, but a modal route keeps rebuilding through its exit
  animation — so applying a typed gram value threw *"A TextEditingController was used
  after being disposed"* and silently lost the entry. The field now owns its controller
  (`_PortionGramField`).
- The sheet had no scroll view, so at large text settings the exact-gram row was pushed
  off-screen behind a `RenderFlex` overflow.

## 11. Tests

`flutter test` — 121 pass, plus 42 Deno tests for the edge functions. Added or updated:

- `test/catalog/pilot_manifest_test.dart` (13) — 10 foods × 3 sizes; strictly ascending
  grams; blocked rows explicit with a reason and searched sources; nothing `verified` or
  `reviewed` without a named human; full provenance on resolved rows; derived weights
  labelled as derived; deterministic, unique, slug-safe image paths; prompts free of
  weight/calorie/label requests; one consistency note and one vessel per food; a prompt
  file on disk per resolved portion; gaps reported; CSV matches JSON.
- `test/catalog/source_parser_test.dart` (15) — TÜBER nutrient rows read verbatim, no
  column confusion, exact-match only; household measures keep full text, rejoin names that
  wrapped below their measure, strip footnote markers, keep the two yogurt rows distinct,
  and refuse to turn a mL measure into a gram value; TürKomp average column with kcal over
  kJ and a hard failure when the food code is unknown; portion policy band enforcement and
  kitchen rounding.
- `test/features/portion_sheet_test.dart` (13) — reviewed image shown per portion, failure
  fallback, schematic when no image exists, Az/Normal/Fazla labels with grams, semantics
  with selected state, whole-card tap, exact-gram entry, and layout at 360/390/430 px at
  1× and 1.5× text scale.
- `test/analysis/supabase_meal_analysis_repository_test.dart` — `imageUrl` now asserted
  through the response mapping, including the null case.
- `test/goldens/portion_clarification.png` — regenerated for the new labels and layout.

### Known failures not caused by this work

- `test/golden_test.dart: history visual baseline` fails on `main` as well (verified by
  stashing these changes). Untouched here.
- The **composer** screen (`_Composer`, `meal_flow.dart`) has a `RenderFlex` overflow above
  roughly 1.4× text scale at 360–390 px, which makes the analyze button unhittable. It is
  pre-existing and on a different screen, so it was left alone per the "do not redesign
  other screens" constraint — but it is a real accessibility defect and blocks large-text
  users before they ever reach the portion sheet. The layout tests here use a taller
  viewport at 1.5× so they measure the sheet, not the composer.

## 12. Scaling to 500 foods / 1500 images

What already scales without change: the snapshot + hash integrity layer, both parsers, the
portion policy, the prompt and consistency-note generators, the manifest schema, the SQL
generator, and all manifest assertions. Adding a food is an entry in
`tool/catalog/data/pilot_food_mapping.json` plus a snapshot.

What the pilot proves does **not** scale as-is:

1. **TÜBER Ek 2.3.1 covers roughly a few hundred generic foods, not 500 Turkish dishes.**
   Of 10 everyday foods, 7 resolved and 3 could not — and 4 of the 7 resolved only to a
   *plainer* food than the one requested (no added fat, no sauce). Expect a similar or
   worse ratio across a 500-food target. Composite dishes (menemen, karnıyarık, mercimek
   çorbası, lahmacun) are the majority of what users actually log and are the majority of
   what has no published source.
2. **Recipe-derived records are the missing capability.** The realistic path to Tier A
   coverage is a recipe pipeline: standardised recipe → ingredient weights from TürKomp →
   measured cooked yield → dietitian review → published as its own record type with
   ingredient-level provenance. This should be built before, not after, the image batch —
   images for foods with no gram value are wasted renders.
3. **Volume-only portions need schema support.** `food_portions.grams` is `NOT NULL`, so
   soups (`180 mL`) cannot be represented honestly. Either add a nullable
   `household_volume_ml` or measure densities.

Suggested order:

| Phase | Work | Gate |
| --- | --- | --- |
| 1 | Render + QA the 21 pilot images; resolve the 6 source conflicts; decide the curated-demo cheese record | 21/21 approved by a named reviewer |
| 2 | Build the recipe-derived record type and unblock menemen, mercimek çorbası, patates kızartması | 3/3 with ingredient-level provenance |
| 3 | Extend the mapping file to Tier A (top 200 by search misses and user corrections), 3 portions each | ≥80% resolvable; the rest explicitly blocked |
| 4 | Batch-render Tier A (600 images) in food-family groups sharing one plate render | QA sample ≥10% per batch, 100% on rejects |
| 5 | Tier B (next 300) with one default portion each; add small/large only where corrections cluster | correction rate per food tracked |
| 6 | Backfill to 1500 images by correction frequency, not alphabetically | — |

Two things to hold to at scale: never fill a row to hit a count, and never let a
product-derived portion be shown or exported as an officially published one.

## 13. Delivery status against the acceptance criteria

| Criterion | Status |
| --- | --- |
| 30 portion records for the 10 pilot foods | Done — 30 rows |
| Each record has a verified gram value or is explicitly `blocked` | Done — 21 `needs_review`, 9 `blocked`; 0 `verified` because no human has signed off yet |
| Prompt and manifest files created | Done — 21 prompts, 7 consistency notes, JSON + CSV manifest |
| 30 images pass QA | **Not done** — no image generation tool available in this environment; the batch is prompt-ready only. 9 of 30 have no gram value and must not be rendered at all |
| Flutter integration with real URL and fallback | Done — real `imageUrl`, placeholder, fallback, all covered by tests |
| Tests pass | Done — 121 Flutter + 42 Deno pass; the one failure (`history` golden) predates this work |
| No fabricated nutrition, gram, source or license value | Done — every value traces to a hashed snapshot; unresolvable values are `blocked`, and `image_source`/`image_license`/`attribution`/`generation_*` are `null` because no image exists yet |
