# Food Recognition and Portion Accuracy Research

Date: 2026-08-18

## Executive decision

The product should use a grounded, hybrid pipeline. A vision or language model may identify visible food and extract user intent, but it must never be the source of calories or macros. Nutrition is calculated only after the prediction is mapped to a versioned catalog record. Identity confidence and portion confidence are separate. A low-confidence portion triggers the smallest useful clarification rather than silently becoming an exact gram value.

The requested 500+ food catalog is feasible. Türkiye's official [TürKomp database](https://turkomp.tarimorman.gov.tr/database) currently exposes 645 foods, including 122 traditional foods. USDA [FoodData Central](https://fdc.nal.usda.gov/api-guide/) provides search/detail APIs and downloadable Foundation/FNDDS data; FNDDS includes household portion descriptions and gram weights. Source licenses and reuse terms must be recorded per import batch. Open Food Facts is valuable for packaged/barcoded products and product images, but its own documentation warns that community data is not guaranteed accurate; it should not be the primary source for generic cooked-food nutrition ([official API documentation](https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/)).

## Current implementation audit

### What is already strong

- Exact and alias matching is deterministic.
- Turkish inflections, counts, halves, grams, and common vague portions are parsed before any model call.
- Unmatched text uses hybrid lexical/vector retrieval and an allow-list candidate selector; the model cannot invent food IDs or nutrition values.
- Analysis runs, candidate rationale, provider telemetry, correction records, and replay protection already exist.
- Meal nutrition is calculated from catalog values per 100 g.

### Critical problems found

1. Photo input was sent with `detail: low`. OpenAI's official Responses API supports `low`, `high`, and `auto`; high detail is the appropriate starting point for small and overlapping meal components ([API reference](https://platform.openai.com/docs/api-reference/responses-streaming/response/refusal/delta?lang=curl)).
2. Vision returned one generic confidence value even though food identity and portion size have different uncertainty.
3. Vision output was converted to text such as `180 g pilav`. The deterministic parser interpreted this as an explicit user-entered amount and could promote an uncertain visual estimate to high confidence.
4. A single RGB image has no dependable physical scale. Research consistently identifies portion estimation as the harder stage and recommends depth, multiple views, or a known reference/container when accuracy matters ([systematic review](https://pmc.ncbi.nlm.nih.gov/articles/PMC9776640/)).
5. The production seed contains only a demo slice, not a catalog capable of grounding everyday Turkish meals.
6. `food_portions` held gram weights but had no visual-reference provenance, review state, size class, or image path.

## Target pipeline

### Text input

1. Normalize Unicode, Turkish case, punctuation, number words, fractions, and measurement units.
2. Segment the sentence into food mentions without losing modifiers such as cooking method, fat level, brand, sauce, or container.
3. Resolve exact canonical names and high-priority aliases first.
4. Parse explicit amounts and household units (`2 adet`, `yarım kase`, `3 yemek kaşığı`, `150 g`).
5. For unresolved mentions, retrieve a bounded candidate set using lexical rank + embeddings.
6. Let the model select only from the candidate IDs. Nutrition fields remain invisible to the selector to reduce anchoring and fabrication.
7. Calibrate identity and portion scores independently using an eval set, not model self-confidence alone.
8. Ask one targeted question only when the expected nutrition error would materially change.

### Photo input

1. Capture quality gate: plate fully visible, adequate light, acceptable blur, no severe occlusion.
2. Send high-detail image input and optional user note.
3. Extract visible foods with separate `identityConfidence`, `portionConfidence`, and `portionBasis`.
4. Treat hidden oil, fillings, and sauces as unknown unless visible or explicitly stated.
5. Ground every food description against the catalog.
6. Preserve visual portion uncertainty through reconciliation; never convert a model estimate into an “explicit” amount.
7. Use a reviewed catalog portion as the default when the photo has no scale, and require a portion clarification.
8. Later accuracy tiers:
   - known plate/bowl/cup dimensions;
   - two-view capture;
   - device depth where available;
   - segmentation masks + geometric volume + food-density lookup.

The [Nutrition5k paper](https://openaccess.thecvf.com/content/CVPR2021/papers/Thames_Nutrition5k_Towards_Automatic_Nutritional_Understanding_of_Generic_Food_CVPR_2021_paper.pdf) is useful for model/eval methodology because it includes 5,000 dishes, component weights, video, depth, and nutritional annotations. It is not a Turkish production catalog and should not be treated as one.

## 500+ food catalog design

### Coverage target

- Tier A — top 200 Turkish daily foods and dishes: three reviewed portions each.
- Tier B — next 300 foods: at least one default household portion; add three visuals according to correction frequency.
- Tier C — packaged foods: barcode/product lookup through Open Food Facts or manufacturer data, clearly separated from generic dishes.

For 500 foods with small/regular/large references, the initial visual workload is approximately 1,500 reviewed images. These should be produced under a controlled capture protocol, not scraped from search results.

### Required records

- `foods`: canonical identity, locale, preparation state, source ID, macro hot path, active/version state.
- `food_aliases`: Turkish/English names, regional terms, spelling variants, and priority.
- `food_portions`: household label, exact gram weight, size class, optional container measure, reviewed image path and provenance.
- `food_nutrients`: detailed nutrient rows per 100 g with unit and source reference.
- `catalog_import_batches` and `catalog_source_records`: release, checksum, raw payload, validation errors, publication state.
- `meal_item_corrections`: feedback for evaluation and ranking; never automatically overwrite canonical nutrition.

The migration `20260818220000_food_catalog_portion_references.sql` implements these missing structures and a public read-only storage bucket for reviewed portion references.

## Portion-reference image protocol

Each reference image must represent one catalog portion, not merely the food category.

- Same plate/bowl family and known dimensions.
- Same camera angle and focal range per food family.
- Controlled neutral light and background.
- Weighed edible mass recorded before capture.
- `small`, `regular`, and `large` labels mapped to exact grams.
- Crop, resolution, source/license, reviewer, and review date stored.
- No generated or web-scraped image presented as measurement evidence.

The app may show a relative schematic when a reviewed image is missing, but it must not imply photographic precision.

## Evaluation gates

Maintain separate text and photo gold sets, stratified by simple foods, mixed dishes, sauces, occlusion, regional names, and portion ambiguity.

- Identity: macro/micro F1 and top-k recall.
- Grounding: unsupported-food rate must approach zero.
- Portion: median absolute gram error and MAPE, grouped by portion basis.
- Nutrition: calorie/protein MAE after catalog calculation.
- Calibration: expected calibration error for identity and portion independently.
- UX: clarification rate, correction rate, time-to-log, and abandoned analyses.

Do not ship a model/prompt change solely because aggregate accuracy improves. It must not regress common Turkish foods, photo-only input, or the unsupported-food rate.

## Rollout sequence

1. **Implemented now:** high-detail vision; separate identity/portion evidence; catalog-default portions remain reviewable; centered loading; redesigned result and visual portion selection; catalog schema expansion.
2. Import and validate the first 200 Tier-A foods from TürKomp/USDA with source permissions verified.
3. Produce 600 controlled portion images and publish only reviewed records.
4. Build a 300–500 example Turkish text eval set and 300+ weighed photo eval set.
5. Tune thresholds from measured calibration; do not hard-code confidence percentages into the UI.
6. Expand to 500 foods and 1,500 visuals, prioritized by search misses and user corrections.
7. Add multi-view/depth capture only after the single-image baseline and user friction are measured.

## Product truth

“A photo gives an exact gram amount” is not defensible. The production promise should be: identify likely foods quickly, ground nutrition in verified data, show honest visual portion choices, and ask only the smallest question needed to improve the result.
