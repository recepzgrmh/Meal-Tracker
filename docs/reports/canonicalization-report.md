# Canonicalization Report

Generated: 2026-08-22T23:43:29.858Z

This stage is deliberately conservative. Every source record receives a reversible mapping. Branded products are automatically merged only by an identical checksum-valid GTIN. Generic foods require an exact normalized or curated bilingual identity, preserved preparation/state, different source, and compatible macro profile.

## Metrics

| Metric | Count |
|---|---:|
| Total source records | 1,242,528 |
| Canonical foods | 1,226,178 |
| Automatic high-confidence merges | 16,350 |
| Review candidates | 153,370 |
| Unmerged singleton records | 1,209,845 |
| TR ↔ EN canonical matches | 8,608 |
| Barcode-merged branded mappings | 16,158 |

## Match methods

| Method | Mappings |
|---|---:|
| exact_valid_gtin | 1,201,725 |
| singleton_no_safe_identity | 26,570 |
| singleton_generic_record | 13,866 |
| exact_normalized_generic_name_with_nutrition_guard | 367 |

## Important decisions

- Canonical IDs are SHA-256-derived deterministic identifiers; reruns with unchanged inputs are stable.
- Same brand or similar name never triggers an automatic branded merge.
- A checksum-invalid barcode is not treated as identity.
- Preparation/state remains in the generic semantic key (raw, boiled, fried, cooked, white/yolk, whole/skim).
- Nutrition is only a compatibility guard; it is never averaged or rewritten.
- Review candidates are capped at 3 per repeated branded identity key to prevent a single noisy product family from exploding the file.
- Medium candidates are never added to automatic source mappings; each source remains a high-confidence singleton until reviewed.

## 30 correct automatic merge examples

| # | Left | Right | Method / reason |
|---:|---|---|---|
| 1 | usda_foundation/2346386 — Cream, heavy | usda_fndds/2705597 — Cream, heavy | exact_normalized_generic_name_with_nutrition_guard |
| 2 | usda_foundation/328637 — Cheese, cheddar | usda_fndds/2705709 — Cheese, Cheddar | exact_normalized_generic_name_with_nutrition_guard |
| 3 | usda_foundation/746767 — Cheese, swiss | usda_fndds/2705735 — Cheese, Swiss | exact_normalized_generic_name_with_nutrition_guard |
| 4 | usda_foundation/2346398 — Pineapple, raw | usda_fndds/2709260 — Pineapple, raw | exact_normalized_generic_name_with_nutrition_guard |
| 5 | usda_foundation/2346411 — Blueberries, raw | usda_fndds/2709275 — Blueberries, raw | exact_normalized_generic_name_with_nutrition_guard |
| 6 | usda_foundation/2346410 — Raspberries, raw | usda_fndds/2709281 — Raspberries, raw | exact_normalized_generic_name_with_nutrition_guard |
| 7 | usda_foundation/2346409 — Strawberries, raw | usda_fndds/2709283 — Strawberries, raw | exact_normalized_generic_name_with_nutrition_guard |
| 8 | usda_foundation/2747653 — Beet greens, raw | usda_fndds/2709570 — Beet greens, raw | exact_normalized_generic_name_with_nutrition_guard |
| 9 | usda_foundation/2685574 — Collards, raw | usda_fndds/2709576 — Collards, raw | exact_normalized_generic_name_with_nutrition_guard |
| 10 | usda_foundation/323505 — Kale, raw | usda_fndds/2709599 — Kale, raw | exact_normalized_generic_name_with_nutrition_guard |
| 11 | usda_foundation/2747664 — Radicchio, raw | usda_fndds/2709613 — Radicchio, raw | exact_normalized_generic_name_with_nutrition_guard |
| 12 | usda_foundation/747447 — Broccoli, raw | usda_fndds/2709643 — Broccoli, raw | exact_normalized_generic_name_with_nutrition_guard |
| 13 | usda_foundation/2685576 — Beets, raw | usda_fndds/2709770 — Beets, raw | exact_normalized_generic_name_with_nutrition_guard |
| 14 | usda_foundation/2685575 — Brussels sprouts, raw | usda_fndds/2709772 — Brussels sprouts, raw | exact_normalized_generic_name_with_nutrition_guard |
| 15 | usda_foundation/2346407 — Cabbage, green, raw | usda_fndds/2709773 — Cabbage, green, raw | exact_normalized_generic_name_with_nutrition_guard |
| 16 | usda_foundation/2346408 — Cabbage, red, raw | usda_fndds/2709775 — Cabbage, red, raw | exact_normalized_generic_name_with_nutrition_guard |
| 17 | usda_foundation/2685573 — Cauliflower, raw | usda_fndds/2709777 — Cauliflower, raw | exact_normalized_generic_name_with_nutrition_guard |
| 18 | usda_foundation/2346405 — Celery, raw | usda_fndds/2709778 — Celery, raw | exact_normalized_generic_name_with_nutrition_guard |
| 19 | usda_foundation/2747655 — Fennel, bulb, raw | usda_fndds/2709779 — Fennel bulb, raw | exact_normalized_generic_name_with_nutrition_guard |
| 20 | usda_foundation/2685577 — Eggplant, raw | usda_fndds/2709785 — Eggplant, raw | exact_normalized_generic_name_with_nutrition_guard |
| 21 | usda_foundation/1104647 — Garlic, raw | usda_fndds/2709786 — Garlic, raw | exact_normalized_generic_name_with_nutrition_guard |
| 22 | usda_fndds/2708031 — Cream puff, eclair, custard or cream filled, iced | usda_sr_legacy/167534 — Cream puff, eclair, custard or cream filled, iced | exact_normalized_generic_name_with_nutrition_guard |
| 23 | usda_foundation/334720 — Restaurant, Latino, pupusas con frijoles (pupusas, bean) | usda_sr_legacy/167661 — Restaurant, Latino, pupusas con frijoles (pupusas, bean) | exact_normalized_generic_name_with_nutrition_guard |
| 24 | usda_foundation/334536 — Restaurant, Chinese, fried rice, without meat | usda_sr_legacy/167668 — Restaurant, Chinese, fried rice, without meat | exact_normalized_generic_name_with_nutrition_guard |
| 25 | usda_fndds/2710006 — Yeast extract spread | usda_sr_legacy/167717 — Yeast extract spread | exact_normalized_generic_name_with_nutrition_guard |
| 26 | usda_fndds/2707469 — Chicken, meatless, breaded, fried | usda_sr_legacy/167719 — Chicken, meatless, breaded, fried | exact_normalized_generic_name_with_nutrition_guard |
| 27 | usda_foundation/2346410 — Raspberries, raw | usda_sr_legacy/167755 — Raspberries, raw | exact_normalized_generic_name_with_nutrition_guard |
| 28 | usda_foundation/2346409 — Strawberries, raw | usda_sr_legacy/167762 — Strawberries, raw | exact_normalized_generic_name_with_nutrition_guard |
| 29 | usda_fndds/2709270 — Watermelon, raw | usda_sr_legacy/167765 — Watermelon, raw | exact_normalized_generic_name_with_nutrition_guard |
| 30 | usda_fndds/2708187 — Crackers, wheat, reduced fat | usda_sr_legacy/167934 — Crackers, wheat, reduced fat | exact_normalized_generic_name_with_nutrition_guard |

## 30 examples that must not be merged

| # | Left | Right | Method / reason |
|---:|---|---|---|
| 1 | usda_branded/1107032 — YELLOW CLING PEACH SLICES IN LIGHT SYRUP | usda_branded/1107130 — CHICKEN FLAVOR INSTANT BOUILLON CUBES, CHICKEN | same_brand_alone_is_not_product_identity |
| 2 | usda_branded/1106628 — SPRING ROLL SKIN | usda_branded/1107686 — MINI ANGEL FOOD CAKES | same_brand_alone_is_not_product_identity |
| 3 | usda_branded/1107837 — SPACE ADVENTUTES PASTA | usda_branded/1107851 — TRAINS PLANES & AUTOMOBILES PASTA | same_brand_alone_is_not_product_identity |
| 4 | usda_branded/1109735 — A UNIQUE SEASONING, CORIANDER & ANNATTO | usda_branded/1109736 — HAM FLAVORED CONCENTRATE, HAM | same_brand_alone_is_not_product_identity |
| 5 | usda_branded/1106456 — EGGS, EGG SHAPED BUBBLE GUM FILLED WITH EXTRA SOUR FLAVOR CRYSTALS | usda_branded/1110935 — SOUR MINI DRINKS, LECTRIC LIME, OVERLOAD ORANGE, LIGHTNING LEMON, CHARGIN CHERRY, BLASTIN BLUE RASPBERRY | same_brand_alone_is_not_product_identity |
| 6 | usda_branded/1106457 — DUBBLE BUBBLE, BUBBLE GUM | usda_branded/1110936 — THE DUGOUT GUM, ORIGINAL | same_brand_alone_is_not_product_identity |
| 7 | usda_branded/1106457 — DUBBLE BUBBLE, BUBBLE GUM | usda_branded/1111071 — BUBBLE GUM, EXTRA SOUR | same_brand_alone_is_not_product_identity |
| 8 | usda_branded/1106457 — DUBBLE BUBBLE, BUBBLE GUM | usda_branded/1111072 — GUMBALL | same_brand_alone_is_not_product_identity |
| 9 | usda_branded/1109576 — SIMPLE TRUTH ORGANIC, CHAMOMILE WITH LEMON HERBAL TEA | usda_branded/1111326 — SIMPLE TRUTH ORGANIC, GINGER GREEN TEA | same_brand_alone_is_not_product_identity |
| 10 | usda_branded/1106456 — EGGS, EGG SHAPED BUBBLE GUM FILLED WITH EXTRA SOUR FLAVOR CRYSTALS | usda_branded/1111365 — LEMON, CHERRY, BERRY, ORANGE, APPLE EXTRA SOUR SUPERCHARGED CHEWY CANDY, LEMON, CHERRY, BERRY, ORANGE, APPLE | same_brand_alone_is_not_product_identity |
| 11 | usda_branded/1107032 — YELLOW CLING PEACH SLICES IN LIGHT SYRUP | usda_branded/1111859 — TEXAS GARLIC TOAST, GARLIC | same_brand_alone_is_not_product_identity |
| 12 | usda_branded/1108773 — TRIPLE CHOCOLATE TIGER CAKE | usda_branded/1112094 — HEAVENLY LEMON CAKE | same_brand_alone_is_not_product_identity |
| 13 | usda_branded/1108773 — TRIPLE CHOCOLATE TIGER CAKE | usda_branded/1112095 — CHOCOHOLIC CAKE | same_brand_alone_is_not_product_identity |
| 14 | usda_branded/1108773 — TRIPLE CHOCOLATE TIGER CAKE | usda_branded/1112097 — CELEBRATION CAKE | same_brand_alone_is_not_product_identity |
| 15 | usda_branded/1112099 — VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | usda_branded/1112100 — CUPCAKES, VANILLA | same_brand_alone_is_not_product_identity |
| 16 | usda_branded/1112105 — CARROT CAKE, REAL CREAM CHEESE | usda_branded/1112107 — HALLOWEEN BLACKOUT GOURMET CUPCAKES, RICH CHOCOLATEY FUDGE | same_brand_alone_is_not_product_identity |
| 17 | usda_branded/1106457 — DUBBLE BUBBLE, BUBBLE GUM | usda_branded/1112224 — BUBBLE GUM | same_brand_alone_is_not_product_identity |
| 18 | usda_branded/1111089 — LIGHT COCONUT MILK, LIGHT | usda_branded/1112292 — APRICOT PRESERVES, APRICOT | same_brand_alone_is_not_product_identity |
| 19 | usda_branded/1111089 — LIGHT COCONUT MILK, LIGHT | usda_branded/1112311 — BEST THING SINCE BUTTER 58% VEGETABLE OIL SPREAD, BEST THING SINCE BUTTER | same_brand_alone_is_not_product_identity |
| 20 | usda_branded/1106628 — SPRING ROLL SKIN | usda_branded/1112446 — RAW VANNAMEI SHRIMP | same_brand_alone_is_not_product_identity |
| 21 | usda_branded/1111089 — LIGHT COCONUT MILK, LIGHT | usda_branded/1112550 — PUMPKIN PIE, PUMPKIN | same_brand_alone_is_not_product_identity |
| 22 | usda_branded/1107837 — SPACE ADVENTUTES PASTA | usda_branded/1112575 — ALPHABET PASTA | same_brand_alone_is_not_product_identity |
| 23 | usda_branded/1107837 — SPACE ADVENTUTES PASTA | usda_branded/1112576 — THREE LITTLE BEARS PASTA | same_brand_alone_is_not_product_identity |
| 24 | usda_branded/1111089 — LIGHT COCONUT MILK, LIGHT | usda_branded/1112697 — FROSTED CHERRY TOASTER PASTRIES, FROSTED CHERRY | same_brand_alone_is_not_product_identity |
| 25 | usda_branded/1111089 — LIGHT COCONUT MILK, LIGHT | usda_branded/1112698 — FROSTED BROWN SUGAR CINNAMON TOASTER PASTRIES, FROSTED BROWN SUGAR CINNAMON | same_brand_alone_is_not_product_identity |
| 26 | usda_branded/1106864 — CORN FRITTER MIX, CORN FRITTER MIX | usda_branded/1113047 — TOMATO AND ONION SAUCE | same_brand_alone_is_not_product_identity |
| 27 | usda_branded/1112096 — RED VELVET DREAM CAKE | usda_branded/1113344 — LEMON & CREAM SHORTCAKE | same_brand_alone_is_not_product_identity |
| 28 | usda_branded/1112099 — VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | usda_branded/1113345 — CHOCOLATE CUPCAKES, CHOCOLATE | same_brand_alone_is_not_product_identity |
| 29 | usda_branded/1108102 — ORIGINAL WATER CRACKERS, ORIGINAL | usda_branded/1113356 — SOFT YOGURT FILLED BISCUITS, CEREAL & VANILLA YOGURT | same_brand_alone_is_not_product_identity |
| 30 | usda_branded/1113465 — CREAMY ALMOND BUTTER, CREAMY | usda_branded/1113466 — CRUNCHY ALMOND BUTTER, CRUNCHY | same_brand_alone_is_not_product_identity |

## 30 review-required suspicious examples

| # | Left | Right | Method / reason |
|---:|---|---|---|
| 1 | usda_foundation/2727581 — Blackberries, raw | usda_fndds/2709273 — Blackberries, raw | generic_identity_collision |
| 2 | usda_fndds/2705730 — Cheese, Parmesan, hard | usda_sr_legacy/170848 — Cheese, parmesan, hard | generic_identity_collision |
| 3 | usda_fndds/2705644 — Ice cream cookie sandwich | usda_sr_legacy/172227 — Ice cream cookie sandwich | generic_identity_collision |
| 4 | usda_foundation/748278 — Oil, canola | usda_sr_legacy/172336 — Oil, canola | generic_identity_collision |
| 5 | usda_sr_legacy/171853 — Pancakes, whole wheat, dry mix, incomplete | usda_sr_legacy/172776 — Pancakes, whole-wheat, dry mix, incomplete | generic_identity_collision |
| 6 | usda_fndds/2705729 — Cheese, Parmesan, dry grated, reduced fat | usda_sr_legacy/173452 — Cheese, parmesan, dry grated, reduced fat | generic_identity_collision |
| 7 | usda_fndds/2708305 — Pancakes, plain, reduced fat | usda_sr_legacy/174086 — Pancakes, plain, reduced fat | generic_identity_collision |
| 8 | usda_branded/1112099 — VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | usda_branded/1112101 — VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | same_brand_and_name_different_barcode |
| 9 | usda_branded/1112099 — VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | usda_branded/1114186 — VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | same_brand_and_name_different_barcode |
| 10 | usda_branded/1112099 — VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | usda_branded/1114187 — VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | same_brand_and_name_different_barcode |
| 11 | usda_branded/1115041 — BUTTERMILK LIGHT ORIGINAL RANCH DRESSING, BUTTERMILK ORIGINAL RANCH | usda_branded/1115045 — BUTTERMILK LIGHT ORIGINAL RANCH DRESSING, BUTTERMILK ORIGINAL RANCH | same_brand_and_name_different_barcode |
| 12 | usda_branded/1113345 — CHOCOLATE CUPCAKES, CHOCOLATE | usda_branded/1120747 — CHOCOLATE CUPCAKES, CHOCOLATE | same_brand_and_name_different_barcode |
| 13 | usda_branded/1120220 — VANILLA CUPCAKES, VANILLA | usda_branded/1120978 — VANILLA CUPCAKES, VANILLA | same_brand_and_name_different_barcode |
| 14 | usda_branded/1113345 — CHOCOLATE CUPCAKES, CHOCOLATE | usda_branded/1121036 — CHOCOLATE CUPCAKES, CHOCOLATE | same_brand_and_name_different_barcode |
| 15 | usda_branded/1113345 — CHOCOLATE CUPCAKES, CHOCOLATE | usda_branded/1121420 — CHOCOLATE CUPCAKES, CHOCOLATE | same_brand_and_name_different_barcode |
| 16 | usda_branded/1110146 — ORIGINAL POPS, ORIGINAL | usda_branded/1121591 — ORIGINAL POPS, ORIGINAL | same_brand_and_name_different_barcode |
| 17 | usda_branded/1120661 — BROWNIES | usda_branded/1121617 — BROWNIES | same_brand_and_name_different_barcode |
| 18 | usda_branded/1120661 — BROWNIES | usda_branded/1121620 — BROWNIES | same_brand_and_name_different_barcode |
| 19 | usda_branded/1122586 — OVEN ROASTED TURKEY BREAST, OVEN ROASTED | usda_branded/1124073 — OVEN ROASTED TURKEY BREAST, OVEN ROASTED | same_brand_and_name_different_barcode |
| 20 | usda_branded/1126193 — PEANUT BUTTER, NUTS & CACAO NIBS PURE ORGANIC RAW BAR, PEANUT BUTTER, NUTS & CACAO NIBS | usda_branded/1126287 — PEANUT BUTTER, NUTS & CACAO NIBS PURE ORGANIC RAW BAR, PEANUT BUTTER, NUTS & CACAO NIBS | same_brand_and_name_different_barcode |
| 21 | usda_branded/1126388 — CACAO, CACAO NIBS & HAZELNUTS PURE ORGANIC RAW BAR, CACAO, CACAO NIBS & HAZELNUTS | usda_branded/1126434 — CACAO, CACAO NIBS & HAZELNUTS PURE ORGANIC RAW BAR, CACAO, CACAO NIBS & HAZELNUTS | same_brand_and_name_different_barcode |
| 22 | usda_branded/1126439 — COCONUT, VANILLA & LEMON PURE RAW ORGANIC PROTEIN BAR, COCONUT, VANILLA & LEMON | usda_branded/1126532 — COCONUT, VANILLA & LEMON PURE RAW ORGANIC PROTEIN BAR, COCONUT, VANILLA & LEMON | same_brand_and_name_different_barcode |
| 23 | usda_branded/1126863 — CHAI MASALA ORGANIC SPICES MIX | usda_branded/1126865 — CHAI MASALA ORGANIC SPICES MIX | same_brand_and_name_different_barcode |
| 24 | usda_branded/1126843 — HIMALAYAN PINK SALT | usda_branded/1126876 — HIMALAYAN PINK SALT | same_brand_and_name_different_barcode |
| 25 | usda_branded/1126795 — BLACK PEPPER GROUND ORGANIC SPICES | usda_branded/1126967 — BLACK PEPPER GROUND ORGANIC SPICES | same_brand_and_name_different_barcode |
| 26 | usda_branded/1126869 — BLACK PEPPER WHOLE ORGANIC SPICES | usda_branded/1127014 — BLACK PEPPER WHOLE ORGANIC SPICES | same_brand_and_name_different_barcode |
| 27 | usda_branded/1120220 — VANILLA CUPCAKES, VANILLA | usda_branded/1129736 — VANILLA CUPCAKES, VANILLA | same_brand_and_name_different_barcode |
| 28 | usda_branded/1120220 — VANILLA CUPCAKES, VANILLA | usda_branded/1129739 — VANILLA CUPCAKES, VANILLA | same_brand_and_name_different_barcode |
| 29 | usda_branded/1130787 — HIMALAYAN PINK SALT | usda_branded/1130788 — HIMALAYAN PINK SALT | same_brand_and_name_different_barcode |
| 30 | usda_branded/1131665 — LOW SODIUM CHICKEN BROTH, CHICKEN | usda_branded/1131666 — LOW SODIUM CHICKEN BROTH, CHICKEN | same_brand_and_name_different_barcode |

