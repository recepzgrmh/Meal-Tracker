# Nutrition Data Cleaning Report

Generated: 2026-08-22T23:46:46.187Z

The cleaning stage is deterministic and source-preserving. Existing normalized fields are not overwritten; display/search fields and flags are appended. Nutrition values are never repaired or imputed.

## Metrics

| Source | Input | Output | Cleaned names | Cleaned brands | Weak names | Nutrition warnings | Portion cleanups | Duplicate candidates |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| usda-foundation | 363 | 363 | 363 | 0 | 0 | 0 | 292 | 0 |
| usda-fndds | 5,432 | 5,432 | 5,432 | 0 | 0 | 26 | 5,578 | 0 |
| usda-sr-legacy | 7,793 | 7,793 | 7,793 | 0 | 0 | 26 | 4,378 | 1 |
| usda-branded | 455,458 | 455,458 | 455,454 | 454,220 | 26 | 7,867 | 143,749 | 54,714 |
| turkomp | 645 | 645 | 645 | 0 | 0 | 3 | 0 | 0 |
| openfoodfacts | 772,837 | 772,837 | 751,924 | 604,479 | 3,514 | 6,206 | 515,054 | 97,670 |
| **Total** | **1,242,528** | **1,242,528** | **1,221,611** | **1,058,699** | **3,540** | **14,128** | **669,051** | **152,385** |

## Rules and decisions

- NFC Unicode normalization, control-character removal and whitespace collapse are applied to derived display/search fields.
- ASCII-folded search aliases preserve a separate native-diacritic alias. Source names and brands remain unchanged.
- Placeholder or brand-only names are flagged with `weak_product_name` and `needs_name_review`; records are retained.
- Portion labels and common units are standardized only in appended fields. Unknown gram weights are not inferred.
- Negative/non-finite values, macros over 100 g, macro sum over 105 g, large kcal-vs-macro differences and suspicious sodium scale are flags only.
- Duplicate candidates are exact `normalized_brand + normalized_name` collisions inside each source; they are not deleted.

## 30 before → after examples

| # | Source / ID | Original name | Display name | Normalized name | Original brand | Display / normalized brand |
|---:|---|---|---|---|---|---|
| 1 | usda_foundation / 321358 | Hummus, commercial | Hummus, commercial | hummus commercial | — | — / — |
| 2 | usda_foundation / 321360 | Tomatoes, grape, raw | Tomatoes, grape, raw | tomatoes grape raw | — | — / — |
| 3 | usda_foundation / 321611 | Beans, snap, green, canned, regular pack, drained solids | Beans, snap, green, canned, regular pack, drained solids | beans snap green canned regular pack drained solids | — | — / — |
| 4 | usda_foundation / 323121 | Frankfurter, beef, unheated | Frankfurter, beef, unheated | frankfurter beef unheated | — | — / — |
| 5 | usda_foundation / 323294 | Nuts, almonds, dry roasted, with salt added | Nuts, almonds, dry roasted, with salt added | nuts almonds dry roasted with salt added | — | — / — |
| 6 | usda_fndds / 2705383 | Milk, human | Milk, human | milk human | — | — / — |
| 7 | usda_fndds / 2705384 | Milk, NFS | Milk, NFS | milk nfs | — | — / — |
| 8 | usda_fndds / 2705385 | Milk, whole | Milk, whole | milk whole | — | — / — |
| 9 | usda_fndds / 2705386 | Milk, reduced fat (2%) | Milk, reduced fat (2%) | milk reduced fat 2 | — | — / — |
| 10 | usda_fndds / 2705387 | Milk, low fat (1%) | Milk, low fat (1%) | milk low fat 1 | — | — / — |
| 11 | usda_sr_legacy / 167512 | Pillsbury Golden Layer Buttermilk Biscuits, Artificial Flavor, refrigerated dough | Pillsbury Golden Layer Buttermilk Biscuits, Artificial Flavor, refrigerated dough | pillsbury golden layer buttermilk biscuits artificial flavor refrigerated dough | — | — / — |
| 12 | usda_sr_legacy / 167513 | Pillsbury, Cinnamon Rolls with Icing, refrigerated dough | Pillsbury, Cinnamon Rolls with Icing, refrigerated dough | pillsbury cinnamon rolls with icing refrigerated dough | — | — / — |
| 13 | usda_sr_legacy / 167514 | Kraft Foods, Shake N Bake Original Recipe, Coating for Pork, dry | Kraft Foods, Shake N Bake Original Recipe, Coating for Pork, dry | kraft foods shake n bake original recipe coating for pork dry | — | — / — |
| 14 | usda_sr_legacy / 167515 | George Weston Bakeries, Thomas English Muffins | George Weston Bakeries, Thomas English Muffins | george weston bakeries thomas english muffins | — | — / — |
| 15 | usda_sr_legacy / 167516 | Waffles, buttermilk, frozen, ready-to-heat | Waffles, buttermilk, frozen, ready-to-heat | waffles buttermilk frozen ready to heat | — | — / — |
| 16 | usda_branded / 1106281 | GRANOLA, CINNAMON, RAISIN, CINNAMON, RAISIN | Granola, Cinnamon, Raisin, Cinnamon, Raisin | granola cinnamon raisin cinnamon raisin | MICHELE'S | Michele's / micheles |
| 17 | usda_branded / 1106304 | SUPREME BASMATI RICE | Supreme Basmati Rice | supreme basmati rice | VEETEE | Veetee / veetee |
| 18 | usda_branded / 1106312 | ORIGINAL SWEET & SMOKY BAR ""B"" ""Q"" SAUCE, ORIGINAL | Original Sweet & Smoky Bar ""b"" ""q"" Sauce, Original | original sweet smoky bar b q sauce original | Cookies Food Products Inc. | Cookies Food Products Inc. / cookies food products inc |
| 19 | usda_branded / 1106456 | EGGS, EGG SHAPED BUBBLE GUM FILLED WITH EXTRA SOUR FLAVOR CRYSTALS | Eggs, Egg Shaped Bubble Gum Filled With Extra Sour Flavor Crystals | eggs egg shaped bubble gum filled with extra sour flavor crystals | CRY BABY | Cry Baby / cry baby |
| 20 | usda_branded / 1106457 | DUBBLE BUBBLE, BUBBLE GUM | Dubble Bubble, Bubble Gum | dubble bubble bubble gum | DUBBLE BUBBLE | Dubble Bubble / dubble bubble |
| 21 | turkomp / 1 | Sütlü buz, vanilya aromalı | Sütlü buz, vanilya aromalı | sutlu buz vanilya aromali | — | — / — |
| 22 | turkomp / 2 | Yoğurt, kaymaklı | Yoğurt, kaymaklı | yogurt kaymakli | — | — / — |
| 23 | turkomp / 3 | Yoğurt, homojenize, yarım yağlı (% 2 > süt yağı ≥ % 1.5) | Yoğurt, homojenize, yarım yağlı (% 2 > süt yağı ≥ % 1.5) | yogurt homojenize yarim yagli 2 sut yagi 1 5 | — | — / — |
| 24 | turkomp / 4 | Yoğurt, homojenize, tam yağlı (süt yağı ≥ % 3.8) | Yoğurt, homojenize, tam yağlı (süt yağı ≥ % 3.8) | yogurt homojenize tam yagli sut yagi 3 8 | — | — / — |
| 25 | turkomp / 5 | Kaymak, pastörize (süt yağı ≥ % 60) | Kaymak, pastörize (süt yağı ≥ % 60) | kaymak pastorize sut yagi 60 | — | — / — |
| 26 | open_food_facts / 0000105000042 | Lagg's, herbal tea, peppermint | Lagg's, herbal tea, peppermint | laggs herbal tea peppermint | Lagg's | Lagg's / laggs |
| 27 | open_food_facts / 0000105000219 | Green Tea | Green Tea | green tea | Lagg's | Lagg's / laggs |
| 28 | open_food_facts / 0000105000318 | Shave Grass Herbal Tea | Shave Grass Herbal Tea | shave grass herbal tea | Lagg's | Lagg's / laggs |
| 29 | open_food_facts / 0000105000356 | Lagg's, herbal tea, chamomile * mint | Lagg's, herbal tea, chamomile * mint | laggs herbal tea chamomile mint | Lagg's | Lagg's / laggs |
| 30 | open_food_facts / 0000105000363 | Artichoke Herbal Tea | Artichoke Herbal Tea | artichoke herbal tea | Lagg's | Lagg's / laggs |
