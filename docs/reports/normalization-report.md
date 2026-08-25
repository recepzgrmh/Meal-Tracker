# Nutrition Normalization Report

> [!NOTE]
> This is generated pipeline output preserved for audit. See
> `tool/food_import/` for the scripts that produce it.

This report is generated deterministically from `normalization-metrics.json`. No source records are merged, overwritten, or imported into Supabase.

## Schema decisions

Core identity, seven meal-logging nutrients, and the 100 g basis are directly queryable. Source-specific nutrient rows are also retained with their stable source key, unit, derivation, measurement source, data points, and min/max/median when published. Portions remain one-to-many gram conversions. Empty optional values are omitted rather than imputed. USDA kcal precedence is explicit (1008, then 2048, then 2047), so source array order cannot change the selected core value. Negative analytical values remain in the source nutrient detail but are not promoted to meal-logging core fields; zero/non-positive gram conversions are rejected.

## Summary

| Source | Input | Output | Skipped | Nutrition completeness | Portion coverage | Barcode coverage |
|---|---:|---:|---:|---:|---:|---:|
| usda-foundation | 395 | 363 | 32 | 77.84% | 78.51% | 0.00% |
| usda-fndds | 5,432 | 5,432 | 0 | 99.98% | 100.00% | 0.00% |
| usda-sr-legacy | 7,793 | 7,793 | 0 | 95.54% | 96.66% | 0.00% |
| usda-branded | 455,458 | 455,458 | 0 | 95.98% | 100.00% | 100.00% |
| turkomp | 645 | 645 | 0 | 89.57% | 0.00% | 0.00% |
| openfoodfacts | 4,699,315 | 930,895 | 3,768,420 | 90.94% | 68.95% | 100.00% |

## Added fields

| Field | Why useful | Sources | Status |
|---|---|---|---|
| `nutrition.nutrients[]` with source key, unit and derivation/statistics | Preserves micronutrients and evidence needed for accuracy/confidence without flattening unstable source vocabularies | USDA, TürKomp, OFF | Core container; row metadata optional |
| `additional_descriptions`, `aliases` | Improves food matching for synonyms and USDA additional descriptions | USDA FNDDS; OFF | Optional |
| category code/tags/hierarchy and classification codes | Supports category-aware search, WWEIA analysis and LanguaL matching | USDA, TürKomp, OFF | Optional |
| language(s), countries, market_country | Enables locale-aware ranking and market filtering | OFF; USDA Branded | Optional |
| package_size, food_code, scientific/regional names | Helps package/portion resolution and exact source matching | USDA, TürKomp, OFF | Optional |
| quality tags, source completeness and confidence_inputs | Retains source quality signals without inventing a cross-source confidence score | OFF; derived presence signals for all | Core quality object; individual signals optional |
| Nutri-Score, NOVA and environmental score | Useful for future product insights; not used to alter nutrition values | OFF | Optional |
| labels, allergens, traces, ingredient analysis | Useful for dietary filters and warnings | OFF | Optional |
| nutrient conversion factors | Preserves protein/fat calculation context | USDA Foundation/SR; TürKomp | Optional |
| publication/availability/modification and validity dates | Enables freshness checks and reproducible release selection | USDA; OFF modification date | Optional |

## Open Food Facts filtering

The gzip is streamed line-by-line and output is simultaneously gzip-compressed. It is never fully decompressed or loaded into memory. Defaults are: `{"minCoreNutrients":3,"requireEnergy":true,"requireBarcode":true,"maxKcal":1000}`. They can be changed with `OFF_MIN_CORE_NUTRIENTS`, `OFF_REQUIRE_ENERGY`, `OFF_REQUIRE_BARCODE`, and `OFF_MAX_KCAL`. Skip reasons are counted below. OFF sodium uses the export's standardized `sodium_100g` value in grams and is converted to mg; the display-unit field is not used for that conversion.

## usda-foundation

- Dataset version: 2026-04-30
- Input/output/skipped: 395 / 363 / 32
- Skip reasons: `null_or_non_object`: 32
- Nutrition completeness: 77.84%
- Portion coverage: 78.51%
- Barcode coverage: 0.00%

### 10 normalized examples

```json
[
  {
    "schema_version": "1.0.0",
    "name": "Hummus, commercial",
    "source": "usda_foundation",
    "source_id": "321358",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Legumes and Legume Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 3,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 3
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 1.3,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.26,
          "max": 2.47,
          "median": 1.21
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.15,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.12,
          "max": 0.17,
          "median": 0.16
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.115,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.08,
          "max": 0.14,
          "median": 0.12
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 36,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 13,
          "max": 53,
          "median": 41
        },
        {
          "source_key": "1184",
          "name": "Vitamin K (Dihydrophylloquinone)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 17.2,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 11.2,
          "max": 23.3,
          "median": 17.2
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0.018,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 2.22,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.009,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.008,
          "max": 0.01,
          "median": 0.008
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1273",
          "name": "SFA 22:0",
          "amount_100g": 0.044,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.031,
          "max": 0.062,
          "median": 0.042
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1300",
          "name": "SFA 17:0",
          "amount_100g": 0.01,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.006,
          "max": 0.014,
          "median": 0.011
        },
        {
          "source_key": "1301",
          "name": "SFA 24:0",
          "amount_100g": 0.027,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.019,
          "max": 0.044,
          "median": 0.025
        },
        {
          "source_key": "1303",
          "name": "TFA 16:1 t",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1312",
          "name": "MUFA 24:1 c",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0.011,
          "median": 0.004
        },
        {
          "source_key": "1315",
          "name": "MUFA 18:1 c",
          "amount_100g": 6.25,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 4.87,
          "max": 8.73,
          "median": 5.98
        },
        {
          "source_key": "1316",
          "name": "PUFA 18:2 n-6 c,c",
          "amount_100g": 6.81,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 4.78,
          "max": 8.56,
          "median": 7.03
        },
        {
          "source_key": "1317",
          "name": "MUFA 22:1 c",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1323",
          "name": "MUFA 17:1",
          "amount_100g": 0.007,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.005,
          "max": 0.01,
          "median": 0.008
        },
        {
          "source_key": "1329",
          "name": "Fatty acids, total trans-monoenoic",
          "amount_100g": 0.006,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1333",
          "name": "MUFA 15:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1404",
          "name": "PUFA 18:3 n-3 c,c,c (ALA)",
          "amount_100g": 0.637,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.411,
          "max": 0.742,
          "median": 0.668
        },
        {
          "source_key": "1405",
          "name": "PUFA 20:3 n-3",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1411",
          "name": "PUFA 22:4",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 7.35,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "min": 6.2,
          "max": 8.05,
          "median": 7.79
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 1.97,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 1.73,
          "max": 2.12,
          "median": 1.99
        },
        {
          "source_key": "1009",
          "name": "Starch",
          "amount_100g": 8.12,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 7.7,
          "max": 8.8,
          "median": 8
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0.15,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0.3,
          "median": 0.15
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 960,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1075",
          "name": "Galactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 5.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 4.9,
          "max": 5.7,
          "median": 5.5
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 2.41,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 1.87,
          "max": 2.96,
          "median": 2.33
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 71.1,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 56.6,
          "max": 82,
          "median": 70.4
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 166,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 134,
          "max": 190,
          "median": 179
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 438,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 387,
          "max": 489,
          "median": 444
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.348,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 0.27,
          "max": 0.396,
          "median": 0.376
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 1.06,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 0.785,
          "max": 1.21,
          "median": 1.15
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 1,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 12,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 12
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.003,
          "max": 0.006,
          "median": 0.006
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 6.37,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 7.48,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1299",
          "name": "SFA 15:0",
          "amount_100g": 0.004,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.003,
          "max": 0.004,
          "median": 0.004
        },
        {
          "source_key": "1304",
          "name": "TFA 18:1 t",
          "amount_100g": 0.006,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.004,
          "max": 0.009,
          "median": 0.006
        },
        {
          "source_key": "1305",
          "name": "TFA 22:1 t",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1306",
          "name": "TFA 18:2 t not further defined",
          "amount_100g": 0.012,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.008,
          "max": 0.017,
          "median": 0.012
        },
        {
          "source_key": "1311",
          "name": "PUFA 18:2 CLAs",
          "amount_100g": 0.002,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0.003,
          "median": 0.003
        },
        {
          "source_key": "1313",
          "name": "PUFA 20:2 n-6 c,c",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.003,
          "max": 0.006,
          "median": 0.005
        },
        {
          "source_key": "1314",
          "name": "MUFA 16:1 c",
          "amount_100g": 0.021,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.015,
          "max": 0.027,
          "median": 0.02
        },
        {
          "source_key": "1321",
          "name": "PUFA 18:3 n-6 c,c,c",
          "amount_100g": 0.02,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.011,
          "max": 0.029,
          "median": 0.018
        },
        {
          "source_key": "1331",
          "name": "Fatty acids, total trans-polyenoic",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1406",
          "name": "PUFA 20:3 n-6",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 1.41,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 1.05,
          "max": 1.76,
          "median": 1.43
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.634,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.478,
          "max": 0.771,
          "median": 0.654
        },
        {
          "source_key": "1267",
          "name": "SFA 20:0",
          "amount_100g": 0.079,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.072,
          "max": 0.083,
          "median": 0.08
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 258,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 258
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0.31,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.22,
          "max": 0.36,
          "median": 0.34
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 9.47,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 6.32,
          "max": 11.9,
          "median": 9.58
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.948,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.82,
          "max": 1.09,
          "median": 0.95
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.318,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 4,
          "min": 0.26,
          "max": 0.37,
          "median": 0.32
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.143,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.11,
          "max": 0.16,
          "median": 0.15
        },
        {
          "source_key": "1183",
          "name": "Vitamin K (Menaquinone-4)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 17.1,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 11.9,
          "max": 19.1,
          "median": 18.2
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 14.9,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 229,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 0.18,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0.37,
          "median": 0.18
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 58.7,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 56.1,
          "max": 65.6,
          "median": 57.6
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 41,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 26,
          "max": 57,
          "median": 46
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 289,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 231,
          "max": 327,
          "median": 315
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 1.38,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 1.17,
          "max": 1.5,
          "median": 1.45
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 16.2,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 32.3,
          "median": 16.2
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 1.74,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 1.4,
          "max": 2.89,
          "median": 1.53
        },
        {
          "source_key": "1002",
          "name": "Nitrogen",
          "amount_100g": 1.18,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 0.99,
          "max": 1.29,
          "median": 1.25
        },
        {
          "source_key": "2009",
          "name": "MUFA 14:1 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "2012",
          "name": "MUFA 20:1 c",
          "amount_100g": 0.084,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.046,
          "max": 0.126,
          "median": 0.082
        },
        {
          "source_key": "2014",
          "name": "MUFA 22:1 n-9",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0.004,
          "median": 0
        },
        {
          "source_key": "1334",
          "name": "PUFA 22:2",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1335",
          "name": "SFA 11:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "2019",
          "name": "TFA 18:3 t",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1414",
          "name": "PUFA 20:3 n-9",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 46.6,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 46.6
        },
        {
          "source_key": "1197",
          "name": "Choline, from glycerophosphocholine",
          "amount_100g": 1.1,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 1.1
        },
        {
          "source_key": "1198",
          "name": "Betaine",
          "amount_100g": 0.2,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0.2
        },
        {
          "source_key": "1199",
          "name": "Choline, from sphingomyelin",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1194",
          "name": "Choline, free",
          "amount_100g": 22.3,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 22.3
        },
        {
          "source_key": "1196",
          "name": "Choline, from phosphotidyl choline",
          "amount_100g": 0.2,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0.2
        },
        {
          "source_key": "1195",
          "name": "Choline, from phosphocholine",
          "amount_100g": 23,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 23
        },
        {
          "source_key": "1063",
          "name": "Sugars, Total",
          "amount_100g": 0.34,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1050",
          "name": "Carbohydrate, by summation",
          "amount_100g": 13.9,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1330",
          "name": "Fatty acids, total trans-dienoic",
          "amount_100g": 0.012,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2010",
          "name": "MUFA 17:1 c",
          "amount_100g": 0.007,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2016",
          "name": "PUFA 18:2 c",
          "amount_100g": 6.81,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2018",
          "name": "PUFA 18:3 c",
          "amount_100g": 0.656,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2020",
          "name": "PUFA 20:3 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2022",
          "name": "PUFA 20:4c",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2023",
          "name": "PUFA 20:5c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2024",
          "name": "PUFA 22:5 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2025",
          "name": "PUFA 22:6 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2026",
          "name": "PUFA 20:2 c",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1085",
          "name": "Total fat (NLEA)",
          "amount_100g": 16.1,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        }
      ],
      "protein_100g": 7.35,
      "fiber_100g": 5.4,
      "sodium_mg_100g": 438,
      "fat_100g": 17.1,
      "carbs_100g": 14.9,
      "kcal_100g": 229,
      "sugars_100g": 0.34
    },
    "portions": [
      {
        "amount": 2,
        "unit": "tbsp",
        "description": "2 tablespoon",
        "gram_weight": 33.9,
        "source_portion_id": "118804",
        "sequence": 1,
        "min_year_acquired": 2015
      },
      {
        "amount": 1,
        "unit": "RACC",
        "description": "1 RACC",
        "gram_weight": 30,
        "source_portion_id": "312701",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "Foundation",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 3.47,
        "fatValue": 8.37,
        "carbohydrateValue": 4.07
      },
      {
        "type": ".ProteinConversionFactor",
        "value": 6.25
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Tomatoes, grape, raw",
    "source": "usda_foundation",
    "source_id": "321360",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Vegetables and Vegetable Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 92.5,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 18,
          "min": 90.9,
          "max": 93.6,
          "median": 92.7
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 27.2,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 22.4,
          "max": 32.4,
          "median": 26.3
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 0.56,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.51,
          "max": 0.64,
          "median": 0.55
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0.63,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.46,
          "max": 0.82,
          "median": 0.64
        },
        {
          "source_key": "1002",
          "name": "Nitrogen",
          "amount_100g": 0.13,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.12,
          "max": 0.15,
          "median": 0.13
        },
        {
          "source_key": "1198",
          "name": "Betaine",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1194",
          "name": "Choline, free",
          "amount_100g": 8,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 8
        },
        {
          "source_key": "1197",
          "name": "Choline, from glycerophosphocholine",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1196",
          "name": "Choline, from phosphotidyl choline",
          "amount_100g": 1.2,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 1.2
        },
        {
          "source_key": "1195",
          "name": "Choline, from phosphocholine",
          "amount_100g": 0.6,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0.6
        },
        {
          "source_key": "1199",
          "name": "Choline, from sphingomyelin",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 9.8,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 9.8
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 11,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 9,
          "max": 15,
          "median": 10
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.058,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.042,
          "max": 0.085,
          "median": 0.056
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0.33,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.28,
          "max": 0.44,
          "median": 0.31
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 11.9,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 10.7,
          "max": 13.1,
          "median": 11.8
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0.121,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.076,
          "max": 0.219,
          "median": 0.098
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 28,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 23,
          "max": 33,
          "median": 27
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 260,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 239,
          "max": 285,
          "median": 257
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 6,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 3,
          "max": 10,
          "median": 5
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.2,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.18,
          "max": 0.25,
          "median": 0.19
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 2.1,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.9,
          "max": 2.2,
          "median": 2.2
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "2032",
          "name": "Cryptoxanthin, alpha",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "2028",
          "name": "trans-beta-Carotene",
          "amount_100g": 393,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 286,
          "max": 493,
          "median": 399
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1159",
          "name": "cis-beta-Carotene",
          "amount_100g": 49,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 36,
          "max": 67,
          "median": 46
        },
        {
          "source_key": "1161",
          "name": "cis-Lutein/Zeaxanthin",
          "amount_100g": 12,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 9,
          "max": 14,
          "median": 12
        },
        {
          "source_key": "1160",
          "name": "cis-Lycopene",
          "amount_100g": 554,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 524,
          "max": 594,
          "median": 542
        },
        {
          "source_key": "1121",
          "name": "Lutein",
          "amount_100g": 95,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 68,
          "max": 131,
          "median": 84
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 4100,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 3860,
          "max": 4240,
          "median": 4210
        },
        {
          "source_key": "1119",
          "name": "Zeaxanthin",
          "amount_100g": 9,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 8,
          "max": 11,
          "median": 9
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.98,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.85,
          "max": 1.12,
          "median": 0.98
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0.02,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0.04,
          "median": 0.02
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 0.12,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.08,
          "max": 0.15,
          "median": 0.12
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 0.7,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.61,
          "max": 0.8,
          "median": 0.7
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1184",
          "name": "Vitamin K (Dihydrophylloquinone)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1183",
          "name": "Vitamin K (Menaquinone-4)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 4.2,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 3.3,
          "max": 5.2,
          "median": 4.2
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.065,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.06,
          "max": 0.07,
          "median": 0.065
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.075,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.07,
          "max": 0.08,
          "median": 0.075
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.06,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.05,
          "max": 0.07,
          "median": 0.06
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 10,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 9,
          "max": 10,
          "median": 10
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.805,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.8,
          "max": 0.81,
          "median": 0.805
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 0.83,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "min": 0.75,
          "max": 0.94,
          "median": 0.81
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 5.51,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 27,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 113,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        }
      ],
      "fat_100g": 0.63,
      "sodium_mg_100g": 6,
      "fiber_100g": 2.1,
      "protein_100g": 0.83,
      "carbs_100g": 5.51,
      "kcal_100g": 27
    },
    "portions": [
      {
        "amount": 5,
        "unit": "tomatoes",
        "description": "5 tomatoes",
        "gram_weight": 49.7,
        "source_portion_id": "118808",
        "sequence": 1,
        "min_year_acquired": 2016
      },
      {
        "amount": 1,
        "unit": "cup",
        "description": "1 cup",
        "gram_weight": 152,
        "source_portion_id": "118809",
        "sequence": 2,
        "min_year_acquired": 2016
      },
      {
        "amount": 1,
        "unit": "RACC",
        "description": "1 RACC",
        "gram_weight": 85,
        "source_portion_id": "312817",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 0.8571,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "Foundation",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".ProteinConversionFactor",
        "value": 6.25
      },
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 2.44,
        "fatValue": 8.37,
        "carbohydrateValue": 3.57
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Beans, snap, green, canned, regular pack, drained solids",
    "source": "usda_foundation",
    "source_id": "321611",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Vegetables and Vegetable Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1075",
          "name": "Galactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 93.6,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 93,
          "max": 94.2,
          "median": 93.5
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.19,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 0.14,
          "max": 0.27,
          "median": 0.19
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 36,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 26,
          "max": 42,
          "median": 36
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0.39,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 0.3,
          "max": 0.47,
          "median": 0.38
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 4.11,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 21,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 0.65,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.5,
          "max": 0.72,
          "median": 0.67
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 86,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 23,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 18,
          "max": 27,
          "median": 23
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 282,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 183,
          "max": 328,
          "median": 305
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.041,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 0.027,
          "max": 0.058,
          "median": 0.041
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0.176,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 0.137,
          "max": 0.223,
          "median": 0.18
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0.78,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 0.35,
          "max": 1.5,
          "median": 0.61
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0.64,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.48,
          "max": 0.72,
          "median": 0.67
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 1.04,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "min": 0.81,
          "max": 1.25,
          "median": 1.06
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 0.89,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 0.71,
          "max": 1.05,
          "median": 0.92
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 12.7,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 10.7,
          "max": 14.3,
          "median": 12.5
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 97,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 76,
          "max": 114,
          "median": 96
        },
        {
          "source_key": "1002",
          "name": "Nitrogen",
          "amount_100g": 0.17,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 12,
          "min": 0.13,
          "max": 0.2,
          "median": 0.17
        },
        {
          "source_key": "1063",
          "name": "Sugars, Total",
          "amount_100g": 1.29,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        }
      ],
      "fat_100g": 0.39,
      "carbs_100g": 4.11,
      "kcal_100g": 21,
      "sodium_mg_100g": 282,
      "protein_100g": 1.04,
      "sugars_100g": 1.29
    },
    "portions": [
      {
        "amount": 1,
        "unit": "cup",
        "description": "1 cup drained",
        "gram_weight": 129,
        "source_portion_id": "118859",
        "source_modifier": "drained",
        "sequence": 1,
        "min_year_acquired": 2015
      },
      {
        "amount": 1,
        "unit": "RACC",
        "description": "1 RACC",
        "gram_weight": 130,
        "source_portion_id": "312820",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 0.8571,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "Foundation",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 2.44,
        "fatValue": 8.37,
        "carbohydrateValue": 3.57
      },
      {
        "type": ".ProteinConversionFactor",
        "value": 6.25
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Frankfurter, beef, unheated",
    "source": "usda_foundation",
    "source_id": "323121",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Sausages and Luncheon Meats"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 28,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 25.8,
          "max": 31.3,
          "median": 27.4
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 2.89,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 314,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 15,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 7,
          "max": 28,
          "median": 10
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 343,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 173,
          "max": 489,
          "median": 400
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 2.06,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 1.59,
          "max": 2.55,
          "median": 2.04
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 1.17,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.62,
          "max": 1.73,
          "median": 1.16
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0.09,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0.28,
          "median": 0
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 54.6,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 52.2,
          "max": 57.4,
          "median": 54.4
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.51,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0.26,
          "max": 0.77,
          "median": 0.52
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 2.25,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 2.03,
          "max": 2.52,
          "median": 2.15
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.263,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.23,
          "max": 0.38,
          "median": 0.24
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.13,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0.109,
          "max": 0.153,
          "median": 0.128
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.004,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.008,
          "median": 0.004
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.015,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.011,
          "max": 0.02,
          "median": 0.015
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 6.33,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 5.99,
          "max": 6.76,
          "median": 6.36
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 3.66,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 3.21,
          "max": 4.01,
          "median": 3.7
        },
        {
          "source_key": "1267",
          "name": "SFA 20:0",
          "amount_100g": 0.029,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.024,
          "max": 0.034,
          "median": 0.029
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.029,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.024,
          "max": 0.035,
          "median": 0.029
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0.003,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.005,
          "median": 0.003
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 12.1,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.954,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1299",
          "name": "SFA 15:0",
          "amount_100g": 0.138,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.123,
          "max": 0.152,
          "median": 0.142
        },
        {
          "source_key": "1304",
          "name": "TFA 18:1 t",
          "amount_100g": 1.38,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.842,
          "max": 1.93,
          "median": 1.6
        },
        {
          "source_key": "1305",
          "name": "TFA 22:1 t",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1306",
          "name": "TFA 18:2 t not further defined",
          "amount_100g": 0.131,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.107,
          "max": 0.157,
          "median": 0.132
        },
        {
          "source_key": "1311",
          "name": "PUFA 18:2 CLAs",
          "amount_100g": 0.169,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.137,
          "max": 0.199,
          "median": 0.174
        },
        {
          "source_key": "1313",
          "name": "PUFA 20:2 n-6 c,c",
          "amount_100g": 0.008,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.005,
          "max": 0.01,
          "median": 0.008
        },
        {
          "source_key": "1314",
          "name": "MUFA 16:1 c",
          "amount_100g": 0.985,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.782,
          "max": 1.17,
          "median": 0.999
        },
        {
          "source_key": "1321",
          "name": "PUFA 18:3 n-6 c,c,c",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.003,
          "max": 0.008,
          "median": 0.005
        },
        {
          "source_key": "1331",
          "name": "Fatty acids, total trans-polyenoic",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1406",
          "name": "PUFA 20:3 n-6",
          "amount_100g": 0.021,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.017,
          "max": 0.025,
          "median": 0.021
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 0.17,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0,
          "max": 0.37,
          "median": 0.18
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.033,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0.027,
          "max": 0.042,
          "median": 0.03
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.154,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0.11,
          "max": 0.21,
          "median": 0.14
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0.97,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0.84,
          "max": 1.1,
          "median": 0.95
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 1.59,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 11.4,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.014,
          "median": 0.003
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.019,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.017,
          "max": 0.021,
          "median": 0.019
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.84,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.763,
          "max": 0.911,
          "median": 0.841
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1273",
          "name": "SFA 22:0",
          "amount_100g": 0.008,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.005,
          "max": 0.01,
          "median": 0.008
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0.003,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.005,
          "median": 0.004
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0.013,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.011,
          "max": 0.016,
          "median": 0.014
        },
        {
          "source_key": "1300",
          "name": "SFA 17:0",
          "amount_100g": 0.355,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.312,
          "max": 0.407,
          "median": 0.361
        },
        {
          "source_key": "1301",
          "name": "SFA 24:0",
          "amount_100g": 0.002,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.004,
          "median": 0
        },
        {
          "source_key": "1303",
          "name": "TFA 16:1 t",
          "amount_100g": 0.087,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.076,
          "max": 0.098,
          "median": 0.084
        },
        {
          "source_key": "1312",
          "name": "MUFA 24:1 c",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.011,
          "median": 0.003
        },
        {
          "source_key": "1315",
          "name": "MUFA 18:1 c",
          "amount_100g": 10.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 9.64,
          "max": 11.7,
          "median": 10.4
        },
        {
          "source_key": "1316",
          "name": "PUFA 18:2 n-6 c,c",
          "amount_100g": 0.625,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.568,
          "max": 0.723,
          "median": 0.616
        },
        {
          "source_key": "1317",
          "name": "MUFA 22:1 c",
          "amount_100g": 0.064,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1323",
          "name": "MUFA 17:1",
          "amount_100g": 0.257,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.24,
          "max": 0.303,
          "median": 0.251
        },
        {
          "source_key": "1329",
          "name": "Fatty acids, total trans-monoenoic",
          "amount_100g": 1.46,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1333",
          "name": "MUFA 15:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1404",
          "name": "PUFA 18:3 n-3 c,c,c (ALA)",
          "amount_100g": 0.078,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.045,
          "max": 0.114,
          "median": 0.071
        },
        {
          "source_key": "1405",
          "name": "PUFA 20:3 n-3",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.004,
          "median": 0
        },
        {
          "source_key": "1411",
          "name": "PUFA 22:4",
          "amount_100g": 0.008,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.006,
          "max": 0.01,
          "median": 0.008
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 9,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 1310,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 11.7,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "min": 10.7,
          "max": 12.4,
          "median": 11.8
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 2.74,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 1.52,
          "max": 3.34,
          "median": 2.9
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 1.14,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.9,
          "max": 1.46,
          "median": 1.08
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 11.5,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 8.2,
          "max": 16.9,
          "median": 9.5
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 128,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 92,
          "max": 172,
          "median": 126
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 872,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 732,
          "max": 1040,
          "median": 890
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.046,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.025,
          "max": 0.071,
          "median": 0.043
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0.031,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.06,
          "median": 0.022
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 3,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2,
          "max": 5,
          "median": 3
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 3,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1075",
          "name": "Galactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1002",
          "name": "Nitrogen",
          "amount_100g": 1.87,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 1.71,
          "max": 1.98,
          "median": 1.89
        },
        {
          "source_key": "1335",
          "name": "SFA 11:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "2009",
          "name": "MUFA 14:1 c",
          "amount_100g": 0.267,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.238,
          "max": 0.298,
          "median": 0.269
        },
        {
          "source_key": "2019",
          "name": "TFA 18:3 t",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.003,
          "median": 0
        },
        {
          "source_key": "2012",
          "name": "MUFA 20:1 c",
          "amount_100g": 0.117,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0.097,
          "max": 0.147,
          "median": 0.105
        },
        {
          "source_key": "1414",
          "name": "PUFA 20:3 n-9",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "2014",
          "name": "MUFA 22:1 n-9",
          "amount_100g": 0.064,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.149,
          "median": 0.037
        },
        {
          "source_key": "1334",
          "name": "PUFA 22:2",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 17,
          "min": 0,
          "max": 0.003,
          "median": 0
        },
        {
          "source_key": "1063",
          "name": "Sugars, Total",
          "amount_100g": 1.26,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1330",
          "name": "Fatty acids, total trans-dienoic",
          "amount_100g": 0.131,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2010",
          "name": "MUFA 17:1 c",
          "amount_100g": 0.257,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2016",
          "name": "PUFA 18:2 c",
          "amount_100g": 0.794,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2018",
          "name": "PUFA 18:3 c",
          "amount_100g": 0.084,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2020",
          "name": "PUFA 20:3 c",
          "amount_100g": 0.022,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2022",
          "name": "PUFA 20:4c",
          "amount_100g": 0.029,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2023",
          "name": "PUFA 20:5c",
          "amount_100g": 0.003,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2024",
          "name": "PUFA 22:5 c",
          "amount_100g": 0.013,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2025",
          "name": "PUFA 22:6 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2026",
          "name": "PUFA 20:2 c",
          "amount_100g": 0.008,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1085",
          "name": "Total fat (NLEA)",
          "amount_100g": 26,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        }
      ],
      "fat_100g": 28,
      "carbs_100g": 2.89,
      "kcal_100g": 314,
      "protein_100g": 11.7,
      "sodium_mg_100g": 872,
      "sugars_100g": 1.26
    },
    "portions": [
      {
        "amount": 1,
        "unit": "piece",
        "description": "1 piece",
        "gram_weight": 48.6,
        "source_portion_id": "118987",
        "sequence": 1,
        "min_year_acquired": 2015
      },
      {
        "amount": 1,
        "unit": "RACC",
        "description": "1 RACC",
        "gram_weight": 85,
        "source_portion_id": "312745",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 0.8571,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "Foundation",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 4.27,
        "fatValue": 9.02,
        "carbohydrateValue": 3.87
      },
      {
        "type": ".ProteinConversionFactor",
        "value": 6.25
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Nuts, almonds, dry roasted, with salt added",
    "source": "usda_foundation",
    "source_id": "323294",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Nut and Seed Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.004,
          "max": 0.006,
          "median": 0.005
        },
        {
          "source_key": "1299",
          "name": "SFA 15:0",
          "amount_100g": 0.008,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.007,
          "max": 0.009,
          "median": 0.008
        },
        {
          "source_key": "1313",
          "name": "PUFA 20:2 n-6 c,c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0.003,
          "median": 0
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0.003,
          "median": 0
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 17,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 17
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1273",
          "name": "SFA 22:0",
          "amount_100g": 0.042,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.01,
          "max": 0.113,
          "median": 0.024
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1301",
          "name": "SFA 24:0",
          "amount_100g": 0.024,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.006,
          "max": 0.063,
          "median": 0.014
        },
        {
          "source_key": "1312",
          "name": "MUFA 24:1 c",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0.005,
          "median": 0
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0.002,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0.012,
          "median": 0
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 60.8,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 60.8
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 34.2,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 14.5,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1321",
          "name": "PUFA 18:3 n-6 c,c,c",
          "amount_100g": 0.002,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0.006,
          "median": 0
        },
        {
          "source_key": "1304",
          "name": "TFA 18:1 t",
          "amount_100g": 0.016,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.013,
          "max": 0.018,
          "median": 0.016
        },
        {
          "source_key": "1306",
          "name": "TFA 18:2 t not further defined",
          "amount_100g": 0.016,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.013,
          "max": 0.018,
          "median": 0.016
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 273,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 220,
          "max": 301,
          "median": 280
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 684,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 612,
          "max": 744,
          "median": 686
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 2.8,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 2.66,
          "max": 3.04,
          "median": 2.75
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 19,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 16,
          "max": 21.8,
          "median": 19.3
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 57.8,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 53.1,
          "max": 60,
          "median": 59
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 16.2,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0.01,
          "median": 0
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0.18,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.15,
          "max": 0.22,
          "median": 0.17
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 0.92,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.33,
          "max": 1.44,
          "median": 0.96
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 3.1,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 2.65,
          "max": 3.65,
          "median": 3
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.237,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.19,
          "max": 0.29,
          "median": 0.23
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.075,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.06,
          "max": 0.08,
          "median": 0.08
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 3.54,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 3.24,
          "max": 4.04,
          "median": 3.51
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.828,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.731,
          "max": 0.972,
          "median": 0.809
        },
        {
          "source_key": "1267",
          "name": "SFA 20:0",
          "amount_100g": 0.059,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.036,
          "max": 0.083,
          "median": 0.062
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 620,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 4.17,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 3.76,
          "max": 4.47,
          "median": 4.28
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 2.2,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 0.9,
          "max": 2.84,
          "median": 2.16
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.87,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 0.804,
          "max": 0.908,
          "median": 0.874
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 2.02,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 1.67,
          "max": 2.29,
          "median": 2.07
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 2590,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1075",
          "name": "Galactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 3.17,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 2.92,
          "max": 3.55,
          "median": 3.13
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 258,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 242,
          "max": 273,
          "median": 260
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 456,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 436,
          "max": 474,
          "median": 456
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 20.4,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "min": 19.6,
          "max": 22.2,
          "median": 20.2
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 3.47,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 2.78,
          "max": 4.32,
          "median": 3.36
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.079,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.06,
          "max": 0.11,
          "median": 0.08
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 1.57,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 1.32,
          "max": 1.86,
          "median": 1.63
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 35,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 29,
          "max": 44,
          "median": 34
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0.032,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 4.56,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.027,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.016,
          "max": 0.051,
          "median": 0.026
        },
        {
          "source_key": "1300",
          "name": "SFA 17:0",
          "amount_100g": 0.028,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.027,
          "max": 0.03,
          "median": 0.028
        },
        {
          "source_key": "1315",
          "name": "MUFA 18:1 c",
          "amount_100g": 33.8,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 32,
          "max": 35.8,
          "median": 33.6
        },
        {
          "source_key": "1316",
          "name": "PUFA 18:2 n-6 c,c",
          "amount_100g": 14.5,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 13.1,
          "max": 16.1,
          "median": 14.4
        },
        {
          "source_key": "1404",
          "name": "PUFA 18:3 n-3 c,c,c (ALA)",
          "amount_100g": 0.05,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.016,
          "max": 0.106,
          "median": 0.026
        },
        {
          "source_key": "1323",
          "name": "MUFA 17:1",
          "amount_100g": 0.061,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.057,
          "max": 0.066,
          "median": 0.06
        },
        {
          "source_key": "1333",
          "name": "MUFA 15:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 2,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 11,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 10.6,
          "max": 11.5,
          "median": 10.9
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 256,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 55,
          "max": 552,
          "median": 187
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 25,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 25
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 9,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 9
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1002",
          "name": "Nitrogen",
          "amount_100g": 3.94,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 13,
          "min": 3.78,
          "max": 4.29,
          "median": 3.9
        },
        {
          "source_key": "1194",
          "name": "Choline, free",
          "amount_100g": 4.3,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 4.3
        },
        {
          "source_key": "1197",
          "name": "Choline, from glycerophosphocholine",
          "amount_100g": 0.4,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0.4
        },
        {
          "source_key": "1198",
          "name": "Betaine",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1199",
          "name": "Choline, from sphingomyelin",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1195",
          "name": "Choline, from phosphocholine",
          "amount_100g": 56.1,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 56.1
        },
        {
          "source_key": "1196",
          "name": "Choline, from phosphotidyl choline",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "2009",
          "name": "MUFA 14:1 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "2014",
          "name": "MUFA 22:1 n-9",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0.004,
          "median": 0
        },
        {
          "source_key": "2012",
          "name": "MUFA 20:1 c",
          "amount_100g": 0.076,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.038,
          "max": 0.112,
          "median": 0.09
        },
        {
          "source_key": "1311",
          "name": "PUFA 18:2 CLAs",
          "amount_100g": 0.006,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.005,
          "max": 0.007,
          "median": 0.006
        },
        {
          "source_key": "1314",
          "name": "MUFA 16:1 c",
          "amount_100g": 0.259,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.232,
          "max": 0.285,
          "median": 0.26
        },
        {
          "source_key": "1411",
          "name": "PUFA 22:4",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1414",
          "name": "PUFA 20:3 n-9",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1335",
          "name": "SFA 11:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1303",
          "name": "TFA 16:1 t",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "2019",
          "name": "TFA 18:3 t",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1406",
          "name": "PUFA 20:3 n-6",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1305",
          "name": "TFA 22:1 t",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1405",
          "name": "PUFA 20:3 n-3",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1334",
          "name": "PUFA 22:2",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0.28,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0.25,
          "max": 0.32,
          "median": 0.28
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 8,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1183",
          "name": "Vitamin K (Menaquinone-4)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1184",
          "name": "Vitamin K (Dihydrophylloquinone)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1063",
          "name": "Sugars, Total",
          "amount_100g": 4.17,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1329",
          "name": "Fatty acids, total trans-monoenoic",
          "amount_100g": 0.016,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1330",
          "name": "Fatty acids, total trans-dienoic",
          "amount_100g": 0.016,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1331",
          "name": "Fatty acids, total trans-polyenoic",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1317",
          "name": "MUFA 22:1 c",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2010",
          "name": "MUFA 17:1 c",
          "amount_100g": 0.061,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2016",
          "name": "PUFA 18:2 c",
          "amount_100g": 14.5,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2018",
          "name": "PUFA 18:3 c",
          "amount_100g": 0.052,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2020",
          "name": "PUFA 20:3 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2022",
          "name": "PUFA 20:4c",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2023",
          "name": "PUFA 20:5c",
          "amount_100g": 0.002,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2024",
          "name": "PUFA 22:5 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2025",
          "name": "PUFA 22:6 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2026",
          "name": "PUFA 20:2 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1085",
          "name": "Total fat (NLEA)",
          "amount_100g": 53.4,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        }
      ],
      "fat_100g": 57.8,
      "carbs_100g": 16.2,
      "kcal_100g": 620,
      "protein_100g": 20.4,
      "fiber_100g": 11,
      "sodium_mg_100g": 256,
      "sugars_100g": 4.17
    },
    "portions": [
      {
        "amount": 1,
        "unit": "cup",
        "description": "1 cup whole",
        "gram_weight": 135,
        "source_portion_id": "119012",
        "source_modifier": "whole",
        "sequence": 1,
        "min_year_acquired": 2001
      },
      {
        "amount": 1,
        "unit": "RACC",
        "description": "1 RACC",
        "gram_weight": 30,
        "source_portion_id": "312717",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "Foundation",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".ProteinConversionFactor",
        "value": 5.18
      },
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 3.47,
        "fatValue": 8.37,
        "carbohydrateValue": 4.07
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Kale, raw",
    "source": "usda_foundation",
    "source_id": "323505",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Vegetables and Vegetable Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 27,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 19,
          "max": 37,
          "median": 26
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 241,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 2870,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2160,
          "max": 3830,
          "median": 2630
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1184",
          "name": "Vitamin K (Dihydrophylloquinone)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 390,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 369,
          "max": 422,
          "median": 378
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 2.92,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "min": 2.25,
          "max": 3.81,
          "median": 3.06
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 1.54,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 1.26,
          "max": 1.75,
          "median": 1.53
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.31,
          "max": 0.5,
          "median": 0.4
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 93.4,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 84.4,
          "max": 104,
          "median": 95.5
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.113,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.08,
          "max": 0.13,
          "median": 0.13
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.347,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.28,
          "max": 0.43,
          "median": 0.33
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 62,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 53,
          "max": 72,
          "median": 60
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 148,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1075",
          "name": "Galactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 4.1,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 4,
          "max": 4.2,
          "median": 4.1
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 1.6,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 0.77,
          "max": 3.61,
          "median": 1.14
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 32.7,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 28.4,
          "max": 45.8,
          "median": 29.7
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 55,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 47,
          "max": 62,
          "median": 58
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 53,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 16,
          "max": 107,
          "median": 18
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.053,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 0.032,
          "max": 0.075,
          "median": 0.054
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0.92,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 0.512,
          "max": 1.46,
          "median": 0.775
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 1.49,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 1.43,
          "max": 1.56,
          "median": 1.49
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 4.42,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 35,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 0.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.32,
          "max": 0.48,
          "median": 0.4
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 89.6,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 88.8,
          "max": 90.2,
          "median": 89.8
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.66,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.5,
          "max": 0.75,
          "median": 0.74
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 254,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 203,
          "max": 281,
          "median": 264
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 348,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 301,
          "max": 389,
          "median": 352
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.39,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 0.2,
          "max": 0.57,
          "median": 0.4
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 6260,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 4460,
          "max": 8560,
          "median": 5760
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 0.14,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.1,
          "max": 0.2,
          "median": 0.13
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 1.18,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.93,
          "max": 1.59,
          "median": 1.02
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.37,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.37,
          "max": 0.37,
          "median": 0.37
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.147,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.12,
          "max": 0.16,
          "median": 0.16
        },
        {
          "source_key": "1183",
          "name": "Vitamin K (Menaquinone-4)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1002",
          "name": "Nitrogen",
          "amount_100g": 0.47,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 0.36,
          "max": 0.61,
          "median": 0.49
        },
        {
          "source_key": "1063",
          "name": "Sugars, Total",
          "amount_100g": 0.8,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        }
      ],
      "protein_100g": 2.92,
      "fiber_100g": 4.1,
      "sodium_mg_100g": 53,
      "fat_100g": 1.49,
      "carbs_100g": 4.42,
      "kcal_100g": 35,
      "sugars_100g": 0.8
    },
    "portions": [
      {
        "amount": 1,
        "unit": "cup",
        "description": "1 cup pieces of ~1\"",
        "gram_weight": 20.6,
        "source_portion_id": "119057",
        "source_modifier": "pieces of ~1\"",
        "sequence": 1,
        "min_year_acquired": 2015
      },
      {
        "amount": 1,
        "unit": "RACC",
        "description": "1 RACC",
        "gram_weight": 85,
        "source_portion_id": "312819",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "Foundation",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 2.44,
        "fatValue": 8.37,
        "carbohydrateValue": 3.57
      },
      {
        "type": ".ProteinConversionFactor",
        "value": 6.25
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Egg, whole, raw, frozen, pasteurized",
    "source": "usda_foundation",
    "source_id": "323604",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Dairy and Egg Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 11.2,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 10.1,
          "max": 12.4,
          "median": 11.2
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 189,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 178,
          "max": 208,
          "median": 188
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 117,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 109,
          "max": 125,
          "median": 117
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 1.2,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 1.06,
          "max": 1.32,
          "median": 1.21
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 121,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 100,
          "max": 137,
          "median": 121
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 1.77,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 1.56,
          "max": 2.01,
          "median": 1.76
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 627,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 12.3,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "min": 11.8,
          "max": 12.6,
          "median": 12.3
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 1.16,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 1,
          "max": 1.28,
          "median": 1.18
        },
        {
          "source_key": "1111",
          "name": "Vitamin D2 (ergocalciferol)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 75.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 74,
          "max": 76.7,
          "median": 75.4
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 55,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 47,
          "max": 62,
          "median": 56
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 10.3,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 9.39,
          "max": 11.5,
          "median": 10.2
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 0.91,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 150,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1112",
          "name": "Vitamin D3 (cholecalciferol)",
          "amount_100g": 2.3,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 0.8,
          "max": 5.1,
          "median": 1.9
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 2.3,
          "unit": "µg",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1110",
          "name": "Vitamin D (D2 + D3), International Units",
          "amount_100g": 91,
          "unit": "IU",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 420,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 385,
          "max": 463,
          "median": 416
        },
        {
          "source_key": "1113",
          "name": "25-hydroxycholecalciferol",
          "amount_100g": 0.6,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 0.4,
          "max": 0.8,
          "median": 0.6
        },
        {
          "source_key": "1002",
          "name": "Nitrogen",
          "amount_100g": 1.97,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 1.89,
          "max": 2.02,
          "median": 1.98
        },
        {
          "source_key": "1100",
          "name": "Iodine, I",
          "amount_100g": 61.6,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 14,
          "min": 45.1,
          "max": 80.9,
          "median": 56.1
        }
      ],
      "sodium_mg_100g": 121,
      "protein_100g": 12.3,
      "fat_100g": 10.3,
      "carbs_100g": 0.91,
      "kcal_100g": 150
    },
    "portions": [
      {
        "amount": 1,
        "unit": "oz",
        "description": "1 oz",
        "gram_weight": 28.4,
        "source_portion_id": "119060",
        "sequence": 1,
        "min_year_acquired": 2017
      },
      {
        "amount": 1,
        "unit": "RACC",
        "description": "1 RACC",
        "gram_weight": 50,
        "source_portion_id": "312626",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 0.7143,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "Foundation",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".ProteinConversionFactor",
        "value": 6.25
      },
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 4.36,
        "fatValue": 9.02,
        "carbohydrateValue": 3.68
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Egg, white, raw, frozen, pasteurized",
    "source": "usda_foundation",
    "source_id": "323697",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Dairy and Egg Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 130,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 77,
          "max": 176,
          "median": 134
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.02,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 0,
          "max": 0.31,
          "median": 0
        },
        {
          "source_key": "1110",
          "name": "Vitamin D (D2 + D3), International Units",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 144,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 86,
          "max": 164,
          "median": 150
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 10.6,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 9,
          "max": 12,
          "median": 10.5
        },
        {
          "source_key": "1112",
          "name": "Vitamin D3 (cholecalciferol)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 88.3,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 87.9,
          "max": 89,
          "median": 88.3
        },
        {
          "source_key": "1111",
          "name": "Vitamin D2 (ergocalciferol)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 9,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 5,
          "max": 20,
          "median": 8
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0.16,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 0.1,
          "max": 0.26,
          "median": 0.15
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 0.74,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 48,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 201,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 10.1,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "min": 9.5,
          "max": 10.6,
          "median": 10.1
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 0.7,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 0.62,
          "max": 0.77,
          "median": 0.71
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0.18,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 0,
          "max": 1.49,
          "median": 0
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 3,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 1,
          "max": 5,
          "median": 2
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1002",
          "name": "Nitrogen",
          "amount_100g": 1.61,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 16,
          "min": 1.52,
          "max": 1.7,
          "median": 1.62
        },
        {
          "source_key": "1100",
          "name": "Iodine, I",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1113",
          "name": "25-hydroxycholecalciferol",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0,
          "max": 0,
          "median": 0
        }
      ],
      "sodium_mg_100g": 144,
      "fat_100g": 0.16,
      "carbs_100g": 0.74,
      "kcal_100g": 48,
      "protein_100g": 10.1
    },
    "portions": [
      {
        "amount": 1,
        "unit": "oz",
        "description": "1 oz",
        "gram_weight": 28.4,
        "source_portion_id": "119063",
        "sequence": 1,
        "min_year_acquired": 2017
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 0.7143,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "Foundation",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".ProteinConversionFactor",
        "value": 6.25
      },
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 4.36,
        "fatValue": 9.02,
        "carbohydrateValue": 3.68
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Egg, white, dried",
    "source": "usda_foundation",
    "source_id": "323793",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Dairy and Egg Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 1570,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 79.9,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "min": 77.9,
          "max": 82.7,
          "median": 79.8
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 5.47,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 5.01,
          "max": 6.13,
          "median": 5.45
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 87.6,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 82.7,
          "max": 93.6,
          "median": 87.8
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 107,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 97,
          "max": 112,
          "median": 107
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 1250,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 1160,
          "max": 1450,
          "median": 1230
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 17,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 9,
          "max": 26,
          "median": 15
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 104,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 61,
          "max": 168,
          "median": 113
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 959,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 868,
          "max": 1070,
          "median": 953
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.43,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 0,
          "max": 0.65,
          "median": 0.49
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0.65,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 0.34,
          "max": 0.82,
          "median": 0.63
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 6.02,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 376,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 7.98,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 5.96,
          "max": 8.85,
          "median": 8.26
        },
        {
          "source_key": "1110",
          "name": "Vitamin D (D2 + D3), International Units",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1100",
          "name": "Iodine, I",
          "amount_100g": 34,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 22.1,
          "max": 59,
          "median": 29.7
        },
        {
          "source_key": "1112",
          "name": "Vitamin D3 (cholecalciferol)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1113",
          "name": "25-hydroxycholecalciferol",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 0,
          "max": 0.1,
          "median": 0
        },
        {
          "source_key": "1111",
          "name": "Vitamin D2 (ergocalciferol)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1002",
          "name": "Nitrogen",
          "amount_100g": 12.8,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 15,
          "min": 12.5,
          "max": 13.2,
          "median": 12.8
        }
      ],
      "protein_100g": 79.9,
      "sodium_mg_100g": 1250,
      "fat_100g": 0.65,
      "carbs_100g": 6.02,
      "kcal_100g": 376
    },
    "portions": [
      {
        "amount": 1,
        "unit": "tbsp",
        "description": "1 tablespoon",
        "gram_weight": 7,
        "source_portion_id": "119069",
        "sequence": 1,
        "min_year_acquired": 2017
      },
      {
        "amount": 1,
        "unit": "cup",
        "description": "1 cup sifted",
        "gram_weight": 107,
        "source_portion_id": "119070",
        "source_modifier": "sifted",
        "sequence": 2,
        "min_year_acquired": 2017
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 0.7143,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "Foundation",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".ProteinConversionFactor",
        "value": 6.25
      },
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 4.36,
        "fatValue": 9.02,
        "carbohydrateValue": 3.68
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Onion rings, breaded, par fried, frozen, prepared, heated in oven",
    "source": "usda_foundation",
    "source_id": "324317",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Vegetables and Vegetable Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 135,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 110,
          "max": 172,
          "median": 127
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 5.6,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 5.2,
          "max": 6.5,
          "median": 5.5
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.57,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.37,
          "max": 0.73,
          "median": 0.55
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 14.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 12.6,
          "max": 15.8,
          "median": 14.8
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 36.3,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 288,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 1.34,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.3,
          "max": 2.4,
          "median": 1.6
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 1.2,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 1,
          "max": 1.6,
          "median": 1.1
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0.71,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.6,
          "max": 0.8,
          "median": 0.7
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 43.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 37.5,
          "max": 50.5,
          "median": 44
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0.98,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.07,
          "max": 6.31,
          "median": 0.09
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 3.47,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 7.93,
          "median": 2.54
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0.2,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.09,
          "max": 0.32,
          "median": 0.19
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 1.57,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 1.07,
          "max": 1.82,
          "median": 1.6
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.302,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 4,
          "min": 0.26,
          "max": 0.4,
          "median": 0.275
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.127,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.11,
          "max": 0.15,
          "median": 0.13
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 10.7,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 10.7
        },
        {
          "source_key": "1198",
          "name": "Betaine",
          "amount_100g": 36.4,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 36.4
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.012,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.01,
          "max": 0.015,
          "median": 0.011
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 1.45,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 1.26,
          "max": 1.66,
          "median": 1.44
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.559,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.478,
          "max": 0.649,
          "median": 0.557
        },
        {
          "source_key": "1267",
          "name": "SFA 20:0",
          "amount_100g": 0.036,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0.049,
          "median": 0.041
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0.006,
          "median": 0.006
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.041,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.031,
          "max": 0.054,
          "median": 0.042
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 2.87,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 7.58,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1299",
          "name": "SFA 15:0",
          "amount_100g": 0.004,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.003,
          "max": 0.005,
          "median": 0.004
        },
        {
          "source_key": "1304",
          "name": "TFA 18:1 t",
          "amount_100g": 0.008,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.004,
          "max": 0.02,
          "median": 0.007
        },
        {
          "source_key": "1305",
          "name": "TFA 22:1 t",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0.003,
          "median": 0
        },
        {
          "source_key": "1306",
          "name": "TFA 18:2 t not further defined",
          "amount_100g": 0.032,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.022,
          "max": 0.043,
          "median": 0.033
        },
        {
          "source_key": "1311",
          "name": "PUFA 18:2 CLAs",
          "amount_100g": 0.004,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0.006,
          "median": 0.005
        },
        {
          "source_key": "1313",
          "name": "PUFA 20:2 n-6 c,c",
          "amount_100g": 0.003,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0.005,
          "median": 0.004
        },
        {
          "source_key": "1314",
          "name": "MUFA 16:1 c",
          "amount_100g": 0.012,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.01,
          "max": 0.015,
          "median": 0.013
        },
        {
          "source_key": "1321",
          "name": "PUFA 18:3 n-6 c,c,c",
          "amount_100g": 0.047,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.043,
          "max": 0.054,
          "median": 0.045
        },
        {
          "source_key": "1406",
          "name": "PUFA 20:3 n-6",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0.435,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 0.259,
          "max": 0.65,
          "median": 0.36
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 1.96,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 1.05,
          "max": 2.99,
          "median": 1.61
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 1.6,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 1.6,
          "max": 1.7,
          "median": 1.6
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.196,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.16,
          "max": 0.25,
          "median": 0.17
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.116,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.09,
          "max": 0.14,
          "median": 0.12
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 31,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 20,
          "max": 41,
          "median": 28
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0.041,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 2.15,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.006,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0.019,
          "median": 0.005
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.003,
          "max": 0.006,
          "median": 0.005
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.011,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.01,
          "max": 0.013,
          "median": 0.011
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1273",
          "name": "SFA 22:0",
          "amount_100g": 0.04,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.035,
          "max": 0.045,
          "median": 0.039
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1300",
          "name": "SFA 17:0",
          "amount_100g": 0.014,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.011,
          "max": 0.016,
          "median": 0.014
        },
        {
          "source_key": "1301",
          "name": "SFA 24:0",
          "amount_100g": 0.015,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.014,
          "max": 0.016,
          "median": 0.015
        },
        {
          "source_key": "1303",
          "name": "TFA 16:1 t",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1312",
          "name": "MUFA 24:1 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1315",
          "name": "MUFA 18:1 c",
          "amount_100g": 2.81,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 2.41,
          "max": 3.26,
          "median": 2.79
        },
        {
          "source_key": "1316",
          "name": "PUFA 18:2 n-6 c,c",
          "amount_100g": 6.66,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 5.77,
          "max": 7.82,
          "median": 6.44
        },
        {
          "source_key": "1317",
          "name": "MUFA 22:1 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1323",
          "name": "MUFA 17:1",
          "amount_100g": 0.007,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.006,
          "max": 0.008,
          "median": 0.008
        },
        {
          "source_key": "1329",
          "name": "Fatty acids, total trans-monoenoic",
          "amount_100g": 0.01,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1333",
          "name": "MUFA 15:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1404",
          "name": "PUFA 18:3 n-3 c,c,c (ALA)",
          "amount_100g": 0.859,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0.734,
          "max": 1.03,
          "median": 0.829
        },
        {
          "source_key": "1405",
          "name": "PUFA 20:3 n-3",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1409",
          "name": "PUFA 18:3i",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1411",
          "name": "PUFA 22:4",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 20.4,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 13.9,
          "max": 29,
          "median": 16.8
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 75,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 56,
          "max": 98,
          "median": 78
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 374,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 259,
          "max": 552,
          "median": 351
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.081,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 0.054,
          "max": 0.122,
          "median": 0.074
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 1210,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed"
        },
        {
          "source_key": "1075",
          "name": "Galactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 2.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 1.8,
          "max": 2.8,
          "median": 2.5
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 1.14,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 0.79,
          "max": 1.53,
          "median": 1.07
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 4.52,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "min": 3.1,
          "max": 5.52,
          "median": 4.25
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 1.44,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 1.15,
          "max": 1.89,
          "median": 1.39
        },
        {
          "source_key": "1009",
          "name": "Starch",
          "amount_100g": 27.2,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 21.4,
          "max": 30.9,
          "median": 28.1
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 1.21,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 1.1,
          "max": 1.4,
          "median": 1.2
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 0.03,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0.2,
          "median": 0
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 28,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 20,
          "max": 53,
          "median": 23
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.59,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 0.3,
          "max": 1.02,
          "median": 0.37
        },
        {
          "source_key": "1002",
          "name": "Nitrogen",
          "amount_100g": 0.74,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 11,
          "min": 0.51,
          "max": 0.91,
          "median": 0.7
        },
        {
          "source_key": "1335",
          "name": "SFA 11:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1414",
          "name": "PUFA 20:3 n-9",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1334",
          "name": "PUFA 22:2",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 7,
          "min": 0,
          "max": 0,
          "median": 0
        },
        {
          "source_key": "1194",
          "name": "Choline, free",
          "amount_100g": 4.9,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 4.9
        },
        {
          "source_key": "1197",
          "name": "Choline, from glycerophosphocholine",
          "amount_100g": 2,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 2
        },
        {
          "source_key": "1195",
          "name": "Choline, from phosphocholine",
          "amount_100g": 0.5,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0.5
        },
        {
          "source_key": "1196",
          "name": "Choline, from phosphotidyl choline",
          "amount_100g": 3.3,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 3.3
        },
        {
          "source_key": "1199",
          "name": "Choline, from sphingomyelin",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1,
          "median": 0
        },
        {
          "source_key": "1063",
          "name": "Sugars, Total",
          "amount_100g": 4.5,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1050",
          "name": "Carbohydrate, by summation",
          "amount_100g": 34,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1330",
          "name": "Fatty acids, total trans-dienoic",
          "amount_100g": 0.032,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2009",
          "name": "MUFA 14:1 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2010",
          "name": "MUFA 17:1 c",
          "amount_100g": 0.007,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2012",
          "name": "MUFA 20:1 c",
          "amount_100g": 0.041,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2016",
          "name": "PUFA 18:2 c",
          "amount_100g": 6.66,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2018",
          "name": "PUFA 18:3 c",
          "amount_100g": 0.906,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2020",
          "name": "PUFA 20:3 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2022",
          "name": "PUFA 20:4c",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2023",
          "name": "PUFA 20:5c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2024",
          "name": "PUFA 22:5 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2025",
          "name": "PUFA 22:6 c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "2026",
          "name": "PUFA 20:2 c",
          "amount_100g": 0.003,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        },
        {
          "source_key": "1085",
          "name": "Total fat (NLEA)",
          "amount_100g": 12.6,
          "unit": "g",
          "derivation_code": "AS",
          "derivation_description": "Summed",
          "measurement_source": "Analytical or derived from analytical"
        }
      ],
      "fat_100g": 14.4,
      "carbs_100g": 36.3,
      "kcal_100g": 288,
      "sodium_mg_100g": 374,
      "fiber_100g": 2.4,
      "protein_100g": 4.52,
      "sugars_100g": 4.5
    },
    "portions": [
      {
        "amount": 1,
        "unit": "piece",
        "description": "1 piece",
        "gram_weight": 20.2,
        "source_portion_id": "119129",
        "sequence": 1,
        "min_year_acquired": 2012
      },
      {
        "amount": 1,
        "unit": "RACC",
        "description": "1 RACC",
        "gram_weight": 85,
        "source_portion_id": "312821",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "Foundation",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 3.7,
        "fatValue": 8.8,
        "carbohydrateValue": 4
      },
      {
        "type": ".ProteinConversionFactor",
        "value": 6.07
      }
    ]
  }
]
```

## usda-fndds

- Dataset version: 2024-10-31 (FNDDS 2021-2023)
- Input/output/skipped: 5,432 / 5,432 / 0
- Skip reasons: none
- Nutrition completeness: 99.98%
- Portion coverage: 100.00%
- Barcode coverage: 0.00%

### 10 normalized examples

```json
[
  {
    "schema_version": "1.0.0",
    "name": "Milk, human",
    "source": "usda_fndds",
    "source_id": "2705383",
    "dataset_version": "2024-10-31 (FNDDS 2021-2023)",
    "category": {
      "name": "Human milk",
      "code": "3298314"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": []
    },
    "portions": [
      {
        "unit": "undetermined",
        "description": "1 cup",
        "gram_weight": 246,
        "source_portion_id": "290506",
        "source_modifier": "10205",
        "sequence": 1
      },
      {
        "unit": "undetermined",
        "description": "1 fl oz",
        "gram_weight": 30.8,
        "source_portion_id": "290508",
        "source_modifier": "30000",
        "sequence": 3
      }
    ],
    "additional_descriptions": [],
    "food_code": "11000000",
    "quality": {
      "nutrition_completeness": 0,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions"
      ]
    },
    "provenance": {
      "publication_date": "10/31/2024",
      "valid_from": "1/1/2021",
      "valid_to": "12/31/2023",
      "source_data_type": "Survey (FNDDS)",
      "source_food_class": "Survey",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "Milk, NFS",
    "source": "usda_fndds",
    "source_id": "2705384",
    "dataset_version": "2024-10-31 (FNDDS 2021-2023)",
    "category": {
      "name": "Milk, reduced fat",
      "code": "3298316"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 3.33,
          "unit": "g"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 2.14,
          "unit": "g"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 4.83,
          "unit": "g"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 52,
          "unit": "kcal"
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 88.9,
          "unit": "g"
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.88,
          "unit": "g"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 125,
          "unit": "mg"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 103,
          "unit": "mg"
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 156,
          "unit": "mg"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 39,
          "unit": "mg"
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.43,
          "unit": "mg"
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.001,
          "unit": "mg"
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 1.9,
          "unit": "µg"
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 57,
          "unit": "µg"
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 58,
          "unit": "µg"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 4,
          "unit": "µg"
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.03,
          "unit": "mg"
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 1.1,
          "unit": "µg"
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0.1,
          "unit": "mg"
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.057,
          "unit": "mg"
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.137,
          "unit": "mg"
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.11,
          "unit": "mg"
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.061,
          "unit": "mg"
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 1,
          "unit": "µg"
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0.56,
          "unit": "µg"
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 17.9,
          "unit": "mg"
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 0.2,
          "unit": "µg"
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 1,
          "unit": "µg"
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 1,
          "unit": "µg"
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 9,
          "unit": "mg"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 1.25,
          "unit": "g"
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.046,
          "unit": "g"
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.036,
          "unit": "g"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.023,
          "unit": "g"
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.056,
          "unit": "g"
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.065,
          "unit": "g"
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.204,
          "unit": "g"
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.576,
          "unit": "g"
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.208,
          "unit": "g"
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 0.465,
          "unit": "g"
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 0.074,
          "unit": "g"
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.008,
          "unit": "g"
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.003,
          "unit": "g"
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.032,
          "unit": "g"
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.002,
          "unit": "g"
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 0.458,
          "unit": "g"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.07,
          "unit": "g"
        }
      ],
      "protein_100g": 3.33,
      "fat_100g": 2.14,
      "carbs_100g": 4.83,
      "kcal_100g": 52,
      "sugars_100g": 4.88,
      "fiber_100g": 0,
      "sodium_mg_100g": 39
    },
    "portions": [
      {
        "unit": "undetermined",
        "description": "Guideline amount per fl oz of beverage",
        "gram_weight": 2.5,
        "source_portion_id": "290512",
        "source_modifier": "63480",
        "sequence": 4
      },
      {
        "unit": "undetermined",
        "description": "1 fl oz",
        "gram_weight": 30.5,
        "source_portion_id": "290510",
        "source_modifier": "30000",
        "sequence": 2
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per cup of hot cereal",
        "gram_weight": 61,
        "source_portion_id": "290513",
        "source_modifier": "63546",
        "sequence": 5
      },
      {
        "unit": "undetermined",
        "description": "1 cup",
        "gram_weight": 244,
        "source_portion_id": "290509",
        "source_modifier": "10205",
        "sequence": 1
      },
      {
        "unit": "undetermined",
        "description": "1 individual school container",
        "gram_weight": 244,
        "source_portion_id": "290511",
        "source_modifier": "64294",
        "sequence": 3
      },
      {
        "unit": "undetermined",
        "description": "Quantity not specified",
        "gram_weight": 244,
        "source_portion_id": "290514",
        "source_modifier": "90000",
        "sequence": 6
      }
    ],
    "additional_descriptions": [],
    "food_code": "11100000",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions"
      ]
    },
    "provenance": {
      "publication_date": "10/31/2024",
      "valid_from": "1/1/2021",
      "valid_to": "12/31/2023",
      "source_data_type": "Survey (FNDDS)",
      "source_food_class": "Survey",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "Milk, whole",
    "source": "usda_fndds",
    "source_id": "2705385",
    "dataset_version": "2024-10-31 (FNDDS 2021-2023)",
    "category": {
      "name": "Milk, whole",
      "code": "3298318"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 3.27,
          "unit": "g"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 3.2,
          "unit": "g"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 4.63,
          "unit": "g"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 61,
          "unit": "kcal"
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 88.1,
          "unit": "g"
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.81,
          "unit": "g"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 123,
          "unit": "mg"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 101,
          "unit": "mg"
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 150,
          "unit": "mg"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 38,
          "unit": "mg"
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.42,
          "unit": "mg"
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.001,
          "unit": "mg"
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 1.9,
          "unit": "µg"
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 31,
          "unit": "µg"
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 32,
          "unit": "µg"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 7,
          "unit": "µg"
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.05,
          "unit": "mg"
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 1.1,
          "unit": "µg"
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.056,
          "unit": "mg"
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.138,
          "unit": "mg"
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.105,
          "unit": "mg"
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.061,
          "unit": "mg"
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0.54,
          "unit": "µg"
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 17.8,
          "unit": "mg"
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 0.3,
          "unit": "µg"
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 1.86,
          "unit": "g"
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.067,
          "unit": "g"
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.054,
          "unit": "g"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.034,
          "unit": "g"
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.084,
          "unit": "g"
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.097,
          "unit": "g"
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.303,
          "unit": "g"
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.857,
          "unit": "g"
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.309,
          "unit": "g"
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 0.694,
          "unit": "g"
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 0.115,
          "unit": "g"
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.013,
          "unit": "g"
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.004,
          "unit": "g"
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.047,
          "unit": "g"
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.004,
          "unit": "g"
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0.002,
          "unit": "g"
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 0.688,
          "unit": "g"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.108,
          "unit": "g"
        }
      ],
      "protein_100g": 3.27,
      "fat_100g": 3.2,
      "carbs_100g": 4.63,
      "kcal_100g": 61,
      "sugars_100g": 4.81,
      "fiber_100g": 0,
      "sodium_mg_100g": 38
    },
    "portions": [
      {
        "unit": "undetermined",
        "description": "Guideline amount per fl oz of beverage",
        "gram_weight": 2.5,
        "source_portion_id": "290518",
        "source_modifier": "63480",
        "sequence": 4
      },
      {
        "unit": "undetermined",
        "description": "Quantity not specified",
        "gram_weight": 244,
        "source_portion_id": "290520",
        "source_modifier": "90000",
        "sequence": 6
      },
      {
        "unit": "undetermined",
        "description": "1 individual school container",
        "gram_weight": 244,
        "source_portion_id": "290517",
        "source_modifier": "64294",
        "sequence": 3
      },
      {
        "unit": "undetermined",
        "description": "1 cup",
        "gram_weight": 244,
        "source_portion_id": "290515",
        "source_modifier": "10205",
        "sequence": 1
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per cup of hot cereal",
        "gram_weight": 61,
        "source_portion_id": "290519",
        "source_modifier": "63546",
        "sequence": 5
      },
      {
        "unit": "undetermined",
        "description": "1 fl oz",
        "gram_weight": 30.5,
        "source_portion_id": "290516",
        "source_modifier": "30000",
        "sequence": 2
      }
    ],
    "additional_descriptions": [
      "leche fresca"
    ],
    "food_code": "11111000",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions"
      ]
    },
    "provenance": {
      "publication_date": "10/31/2024",
      "valid_from": "1/1/2021",
      "valid_to": "12/31/2023",
      "source_data_type": "Survey (FNDDS)",
      "source_food_class": "Survey",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "Milk, reduced fat (2%)",
    "source": "usda_fndds",
    "source_id": "2705386",
    "dataset_version": "2024-10-31 (FNDDS 2021-2023)",
    "category": {
      "name": "Milk, reduced fat",
      "code": "3298320"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 3.36,
          "unit": "g"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 1.9,
          "unit": "g"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 4.9,
          "unit": "g"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 50,
          "unit": "kcal"
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 89.1,
          "unit": "g"
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.89,
          "unit": "g"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 126,
          "unit": "mg"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 103,
          "unit": "mg"
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 159,
          "unit": "mg"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 39,
          "unit": "mg"
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.43,
          "unit": "mg"
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.001,
          "unit": "mg"
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 1.8,
          "unit": "µg"
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 83,
          "unit": "µg"
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 83,
          "unit": "µg"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 3,
          "unit": "µg"
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.03,
          "unit": "mg"
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 1.1,
          "unit": "µg"
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0.2,
          "unit": "mg"
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.059,
          "unit": "mg"
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.137,
          "unit": "mg"
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.112,
          "unit": "mg"
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.061,
          "unit": "mg"
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0.55,
          "unit": "µg"
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 18.2,
          "unit": "mg"
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 0.2,
          "unit": "µg"
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 8,
          "unit": "mg"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 1.11,
          "unit": "g"
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.041,
          "unit": "g"
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.032,
          "unit": "g"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.021,
          "unit": "g"
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.049,
          "unit": "g"
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.058,
          "unit": "g"
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.181,
          "unit": "g"
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.512,
          "unit": "g"
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.184,
          "unit": "g"
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 0.41,
          "unit": "g"
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 0.061,
          "unit": "g"
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.007,
          "unit": "g"
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.003,
          "unit": "g"
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.029,
          "unit": "g"
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.002,
          "unit": "g"
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 0.4,
          "unit": "g"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.058,
          "unit": "g"
        }
      ],
      "protein_100g": 3.36,
      "fat_100g": 1.9,
      "carbs_100g": 4.9,
      "kcal_100g": 50,
      "sugars_100g": 4.89,
      "fiber_100g": 0,
      "sodium_mg_100g": 39
    },
    "portions": [
      {
        "unit": "undetermined",
        "description": "1 individual school container",
        "gram_weight": 244,
        "source_portion_id": "290523",
        "source_modifier": "64294",
        "sequence": 3
      },
      {
        "unit": "undetermined",
        "description": "1 fl oz",
        "gram_weight": 30.5,
        "source_portion_id": "290522",
        "source_modifier": "30000",
        "sequence": 2
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per fl oz of beverage",
        "gram_weight": 2.5,
        "source_portion_id": "290524",
        "source_modifier": "63480",
        "sequence": 4
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per cup of hot cereal",
        "gram_weight": 61,
        "source_portion_id": "290525",
        "source_modifier": "63546",
        "sequence": 5
      },
      {
        "unit": "undetermined",
        "description": "Quantity not specified",
        "gram_weight": 244,
        "source_portion_id": "290526",
        "source_modifier": "90000",
        "sequence": 6
      },
      {
        "unit": "undetermined",
        "description": "1 cup",
        "gram_weight": 244,
        "source_portion_id": "290521",
        "source_modifier": "10205",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "food_code": "11112110",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions"
      ]
    },
    "provenance": {
      "publication_date": "10/31/2024",
      "valid_from": "1/1/2021",
      "valid_to": "12/31/2023",
      "source_data_type": "Survey (FNDDS)",
      "source_food_class": "Survey",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "Milk, low fat (1%)",
    "source": "usda_fndds",
    "source_id": "2705387",
    "dataset_version": "2024-10-31 (FNDDS 2021-2023)",
    "category": {
      "name": "Milk, lowfat",
      "code": "3298322"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 3.38,
          "unit": "g"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0.95,
          "unit": "g"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 5.18,
          "unit": "g"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 43,
          "unit": "kcal"
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 89.7,
          "unit": "g"
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.96,
          "unit": "g"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 126,
          "unit": "mg"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 103,
          "unit": "mg"
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 159,
          "unit": "mg"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 39,
          "unit": "mg"
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.43,
          "unit": "mg"
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.001,
          "unit": "mg"
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 2.1,
          "unit": "µg"
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 58,
          "unit": "µg"
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 58,
          "unit": "µg"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 1,
          "unit": "µg"
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.02,
          "unit": "mg"
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 1.1,
          "unit": "µg"
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.057,
          "unit": "mg"
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.14,
          "unit": "mg"
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.113,
          "unit": "mg"
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.06,
          "unit": "mg"
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0.61,
          "unit": "µg"
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 17.4,
          "unit": "mg"
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 0.1,
          "unit": "µg"
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 5,
          "unit": "mg"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0.568,
          "unit": "g"
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.022,
          "unit": "g"
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.015,
          "unit": "g"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.011,
          "unit": "g"
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.023,
          "unit": "g"
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.026,
          "unit": "g"
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.093,
          "unit": "g"
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.265,
          "unit": "g"
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.096,
          "unit": "g"
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 0.214,
          "unit": "g"
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 0.033,
          "unit": "g"
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.004,
          "unit": "g"
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.014,
          "unit": "g"
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 0.21,
          "unit": "g"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.032,
          "unit": "g"
        }
      ],
      "protein_100g": 3.38,
      "fat_100g": 0.95,
      "carbs_100g": 5.18,
      "kcal_100g": 43,
      "sugars_100g": 4.96,
      "fiber_100g": 0,
      "sodium_mg_100g": 39
    },
    "portions": [
      {
        "unit": "undetermined",
        "description": "1 cup",
        "gram_weight": 244,
        "source_portion_id": "290527",
        "source_modifier": "10205",
        "sequence": 1
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per cup of hot cereal",
        "gram_weight": 61,
        "source_portion_id": "290531",
        "source_modifier": "63546",
        "sequence": 5
      },
      {
        "unit": "undetermined",
        "description": "1 fl oz",
        "gram_weight": 30.5,
        "source_portion_id": "290528",
        "source_modifier": "30000",
        "sequence": 2
      },
      {
        "unit": "undetermined",
        "description": "1 individual school container",
        "gram_weight": 244,
        "source_portion_id": "290529",
        "source_modifier": "64294",
        "sequence": 3
      },
      {
        "unit": "undetermined",
        "description": "Quantity not specified",
        "gram_weight": 244,
        "source_portion_id": "290532",
        "source_modifier": "90000",
        "sequence": 6
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per fl oz of beverage",
        "gram_weight": 2.5,
        "source_portion_id": "290530",
        "source_modifier": "63480",
        "sequence": 4
      }
    ],
    "additional_descriptions": [],
    "food_code": "11112210",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions"
      ]
    },
    "provenance": {
      "publication_date": "10/31/2024",
      "valid_from": "1/1/2021",
      "valid_to": "12/31/2023",
      "source_data_type": "Survey (FNDDS)",
      "source_food_class": "Survey",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "Milk, fat free (skim)",
    "source": "usda_fndds",
    "source_id": "2705388",
    "dataset_version": "2024-10-31 (FNDDS 2021-2023)",
    "category": {
      "name": "Milk, nonfat",
      "code": "3298324"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 3.43,
          "unit": "g"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0.08,
          "unit": "g"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 4.92,
          "unit": "g"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 34,
          "unit": "kcal"
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 90.8,
          "unit": "g"
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 5.05,
          "unit": "g"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 132,
          "unit": "mg"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 107,
          "unit": "mg"
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 167,
          "unit": "mg"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 41,
          "unit": "mg"
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.45,
          "unit": "mg"
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.002,
          "unit": "mg"
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 64,
          "unit": "µg"
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 64,
          "unit": "µg"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 1.1,
          "unit": "µg"
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.056,
          "unit": "mg"
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.131,
          "unit": "mg"
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.118,
          "unit": "mg"
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.058,
          "unit": "mg"
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0.58,
          "unit": "µg"
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 18.2,
          "unit": "mg"
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 3,
          "unit": "mg"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0.049,
          "unit": "g"
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.003,
          "unit": "g"
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.002,
          "unit": "g"
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.002,
          "unit": "g"
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.008,
          "unit": "g"
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.021,
          "unit": "g"
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.009,
          "unit": "g"
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 0.018,
          "unit": "g"
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 0.005,
          "unit": "g"
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 0.017,
          "unit": "g"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.006,
          "unit": "g"
        }
      ],
      "protein_100g": 3.43,
      "fat_100g": 0.08,
      "carbs_100g": 4.92,
      "kcal_100g": 34,
      "sugars_100g": 5.05,
      "fiber_100g": 0,
      "sodium_mg_100g": 41
    },
    "portions": [
      {
        "unit": "undetermined",
        "description": "1 fl oz",
        "gram_weight": 30.5,
        "source_portion_id": "290534",
        "source_modifier": "30000",
        "sequence": 2
      },
      {
        "unit": "undetermined",
        "description": "1 cup",
        "gram_weight": 244,
        "source_portion_id": "290533",
        "source_modifier": "10205",
        "sequence": 1
      },
      {
        "unit": "undetermined",
        "description": "Quantity not specified",
        "gram_weight": 244,
        "source_portion_id": "290538",
        "source_modifier": "90000",
        "sequence": 6
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per cup of hot cereal",
        "gram_weight": 61,
        "source_portion_id": "290537",
        "source_modifier": "63546",
        "sequence": 5
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per fl oz of beverage",
        "gram_weight": 2.5,
        "source_portion_id": "290536",
        "source_modifier": "63480",
        "sequence": 4
      },
      {
        "unit": "undetermined",
        "description": "1 individual school container",
        "gram_weight": 244,
        "source_portion_id": "290535",
        "source_modifier": "64294",
        "sequence": 3
      }
    ],
    "additional_descriptions": [],
    "food_code": "11113000",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions"
      ]
    },
    "provenance": {
      "publication_date": "10/31/2024",
      "valid_from": "1/1/2021",
      "valid_to": "12/31/2023",
      "source_data_type": "Survey (FNDDS)",
      "source_food_class": "Survey",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "Milk, lactose free, low fat (1%)",
    "source": "usda_fndds",
    "source_id": "2705389",
    "dataset_version": "2024-10-31 (FNDDS 2021-2023)",
    "category": {
      "name": "Milk, lowfat",
      "code": "3298326"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 3.38,
          "unit": "g"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0.95,
          "unit": "g"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 5.18,
          "unit": "g"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 43,
          "unit": "kcal"
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 89.7,
          "unit": "g"
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.96,
          "unit": "g"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 126,
          "unit": "mg"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 103,
          "unit": "mg"
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 159,
          "unit": "mg"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 39,
          "unit": "mg"
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.43,
          "unit": "mg"
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.001,
          "unit": "mg"
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 2.1,
          "unit": "µg"
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 58,
          "unit": "µg"
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 58,
          "unit": "µg"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 1,
          "unit": "µg"
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.02,
          "unit": "mg"
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 1.1,
          "unit": "µg"
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.057,
          "unit": "mg"
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.14,
          "unit": "mg"
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.113,
          "unit": "mg"
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.06,
          "unit": "mg"
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0.61,
          "unit": "µg"
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 17.4,
          "unit": "mg"
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 0.1,
          "unit": "µg"
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 5,
          "unit": "mg"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0.568,
          "unit": "g"
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.022,
          "unit": "g"
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.015,
          "unit": "g"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.011,
          "unit": "g"
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.023,
          "unit": "g"
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.026,
          "unit": "g"
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.093,
          "unit": "g"
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.265,
          "unit": "g"
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.096,
          "unit": "g"
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 0.214,
          "unit": "g"
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 0.033,
          "unit": "g"
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.004,
          "unit": "g"
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.014,
          "unit": "g"
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 0.21,
          "unit": "g"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.032,
          "unit": "g"
        }
      ],
      "protein_100g": 3.38,
      "fat_100g": 0.95,
      "carbs_100g": 5.18,
      "kcal_100g": 43,
      "sugars_100g": 4.96,
      "fiber_100g": 0,
      "sodium_mg_100g": 39
    },
    "portions": [
      {
        "unit": "undetermined",
        "description": "Quantity not specified",
        "gram_weight": 244,
        "source_portion_id": "290543",
        "source_modifier": "90000",
        "sequence": 5
      },
      {
        "unit": "undetermined",
        "description": "1 fl oz",
        "gram_weight": 30.5,
        "source_portion_id": "290540",
        "source_modifier": "30000",
        "sequence": 2
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per cup of hot cereal",
        "gram_weight": 61,
        "source_portion_id": "290542",
        "source_modifier": "63546",
        "sequence": 4
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per fl oz of beverage",
        "gram_weight": 2.5,
        "source_portion_id": "290541",
        "source_modifier": "63480",
        "sequence": 3
      },
      {
        "unit": "undetermined",
        "description": "1 cup",
        "gram_weight": 244,
        "source_portion_id": "290539",
        "source_modifier": "10205",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "food_code": "11114300",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions"
      ]
    },
    "provenance": {
      "publication_date": "10/31/2024",
      "valid_from": "1/1/2021",
      "valid_to": "12/31/2023",
      "source_data_type": "Survey (FNDDS)",
      "source_food_class": "Survey",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "Milk, lactose free, fat free (skim)",
    "source": "usda_fndds",
    "source_id": "2705390",
    "dataset_version": "2024-10-31 (FNDDS 2021-2023)",
    "category": {
      "name": "Milk, nonfat",
      "code": "3298328"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 3.43,
          "unit": "g"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0.08,
          "unit": "g"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 4.92,
          "unit": "g"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 34,
          "unit": "kcal"
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 90.8,
          "unit": "g"
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 5.05,
          "unit": "g"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 132,
          "unit": "mg"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 107,
          "unit": "mg"
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 167,
          "unit": "mg"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 41,
          "unit": "mg"
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.45,
          "unit": "mg"
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.002,
          "unit": "mg"
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 64,
          "unit": "µg"
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 64,
          "unit": "µg"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 1.1,
          "unit": "µg"
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.056,
          "unit": "mg"
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.131,
          "unit": "mg"
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.118,
          "unit": "mg"
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.058,
          "unit": "mg"
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0.58,
          "unit": "µg"
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 18.2,
          "unit": "mg"
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 3,
          "unit": "mg"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0.049,
          "unit": "g"
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.003,
          "unit": "g"
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.002,
          "unit": "g"
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.002,
          "unit": "g"
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.008,
          "unit": "g"
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.021,
          "unit": "g"
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.009,
          "unit": "g"
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 0.018,
          "unit": "g"
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 0.005,
          "unit": "g"
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 0.017,
          "unit": "g"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.006,
          "unit": "g"
        }
      ],
      "protein_100g": 3.43,
      "fat_100g": 0.08,
      "carbs_100g": 4.92,
      "kcal_100g": 34,
      "sugars_100g": 5.05,
      "fiber_100g": 0,
      "sodium_mg_100g": 41
    },
    "portions": [
      {
        "unit": "undetermined",
        "description": "Guideline amount per cup of hot cereal",
        "gram_weight": 61,
        "source_portion_id": "290547",
        "source_modifier": "63546",
        "sequence": 4
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per fl oz of beverage",
        "gram_weight": 2.5,
        "source_portion_id": "290546",
        "source_modifier": "63480",
        "sequence": 3
      },
      {
        "unit": "undetermined",
        "description": "1 fl oz",
        "gram_weight": 30.5,
        "source_portion_id": "290545",
        "source_modifier": "30000",
        "sequence": 2
      },
      {
        "unit": "undetermined",
        "description": "Quantity not specified",
        "gram_weight": 244,
        "source_portion_id": "290548",
        "source_modifier": "90000",
        "sequence": 5
      },
      {
        "unit": "undetermined",
        "description": "1 cup",
        "gram_weight": 244,
        "source_portion_id": "290544",
        "source_modifier": "10205",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "food_code": "11114320",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions"
      ]
    },
    "provenance": {
      "publication_date": "10/31/2024",
      "valid_from": "1/1/2021",
      "valid_to": "12/31/2023",
      "source_data_type": "Survey (FNDDS)",
      "source_food_class": "Survey",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "Milk, lactose free, reduced fat (2%)",
    "source": "usda_fndds",
    "source_id": "2705391",
    "dataset_version": "2024-10-31 (FNDDS 2021-2023)",
    "category": {
      "name": "Milk, reduced fat",
      "code": "3298330"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 3.36,
          "unit": "g"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 1.9,
          "unit": "g"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 4.9,
          "unit": "g"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 50,
          "unit": "kcal"
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 89.1,
          "unit": "g"
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.89,
          "unit": "g"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 126,
          "unit": "mg"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 103,
          "unit": "mg"
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 159,
          "unit": "mg"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 39,
          "unit": "mg"
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.43,
          "unit": "mg"
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.001,
          "unit": "mg"
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 1.8,
          "unit": "µg"
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 83,
          "unit": "µg"
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 83,
          "unit": "µg"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 3,
          "unit": "µg"
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.03,
          "unit": "mg"
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 1.1,
          "unit": "µg"
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0.2,
          "unit": "mg"
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.059,
          "unit": "mg"
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.137,
          "unit": "mg"
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.112,
          "unit": "mg"
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.061,
          "unit": "mg"
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0.55,
          "unit": "µg"
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 18.2,
          "unit": "mg"
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 0.2,
          "unit": "µg"
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 2,
          "unit": "µg"
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 8,
          "unit": "mg"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 1.11,
          "unit": "g"
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.041,
          "unit": "g"
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.032,
          "unit": "g"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.021,
          "unit": "g"
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.049,
          "unit": "g"
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.058,
          "unit": "g"
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.181,
          "unit": "g"
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.512,
          "unit": "g"
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.184,
          "unit": "g"
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 0.41,
          "unit": "g"
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 0.061,
          "unit": "g"
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.007,
          "unit": "g"
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.003,
          "unit": "g"
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.029,
          "unit": "g"
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.002,
          "unit": "g"
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 0.4,
          "unit": "g"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.058,
          "unit": "g"
        }
      ],
      "protein_100g": 3.36,
      "fat_100g": 1.9,
      "carbs_100g": 4.9,
      "kcal_100g": 50,
      "sugars_100g": 4.89,
      "fiber_100g": 0,
      "sodium_mg_100g": 39
    },
    "portions": [
      {
        "unit": "undetermined",
        "description": "Guideline amount per fl oz of beverage",
        "gram_weight": 2.5,
        "source_portion_id": "290551",
        "source_modifier": "63480",
        "sequence": 3
      },
      {
        "unit": "undetermined",
        "description": "1 fl oz",
        "gram_weight": 30.5,
        "source_portion_id": "290550",
        "source_modifier": "30000",
        "sequence": 2
      },
      {
        "unit": "undetermined",
        "description": "Quantity not specified",
        "gram_weight": 244,
        "source_portion_id": "290553",
        "source_modifier": "90000",
        "sequence": 5
      },
      {
        "unit": "undetermined",
        "description": "1 cup",
        "gram_weight": 244,
        "source_portion_id": "290549",
        "source_modifier": "10205",
        "sequence": 1
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per cup of hot cereal",
        "gram_weight": 61,
        "source_portion_id": "290552",
        "source_modifier": "63546",
        "sequence": 4
      }
    ],
    "additional_descriptions": [
      "lactose free milk, NS as to fat content"
    ],
    "food_code": "11114330",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions"
      ]
    },
    "provenance": {
      "publication_date": "10/31/2024",
      "valid_from": "1/1/2021",
      "valid_to": "12/31/2023",
      "source_data_type": "Survey (FNDDS)",
      "source_food_class": "Survey",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "Milk, lactose free, whole",
    "source": "usda_fndds",
    "source_id": "2705392",
    "dataset_version": "2024-10-31 (FNDDS 2021-2023)",
    "category": {
      "name": "Milk, whole",
      "code": "3298332"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 3.27,
          "unit": "g"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 3.2,
          "unit": "g"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 4.63,
          "unit": "g"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 61,
          "unit": "kcal"
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 88.1,
          "unit": "g"
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.81,
          "unit": "g"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 123,
          "unit": "mg"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 101,
          "unit": "mg"
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 150,
          "unit": "mg"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 38,
          "unit": "mg"
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.42,
          "unit": "mg"
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.001,
          "unit": "mg"
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 1.9,
          "unit": "µg"
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 31,
          "unit": "µg"
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 32,
          "unit": "µg"
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 7,
          "unit": "µg"
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.05,
          "unit": "mg"
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 1.1,
          "unit": "µg"
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.056,
          "unit": "mg"
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.138,
          "unit": "mg"
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 0.105,
          "unit": "mg"
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.061,
          "unit": "mg"
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0.54,
          "unit": "µg"
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 17.8,
          "unit": "mg"
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 0.3,
          "unit": "µg"
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg"
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 12,
          "unit": "mg"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 1.86,
          "unit": "g"
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.067,
          "unit": "g"
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.054,
          "unit": "g"
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0.034,
          "unit": "g"
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0.084,
          "unit": "g"
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0.097,
          "unit": "g"
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.303,
          "unit": "g"
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.857,
          "unit": "g"
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.309,
          "unit": "g"
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 0.694,
          "unit": "g"
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 0.115,
          "unit": "g"
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.013,
          "unit": "g"
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.004,
          "unit": "g"
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.047,
          "unit": "g"
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.004,
          "unit": "g"
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0.001,
          "unit": "g"
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g"
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0.002,
          "unit": "g"
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 0.688,
          "unit": "g"
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.108,
          "unit": "g"
        }
      ],
      "protein_100g": 3.27,
      "fat_100g": 3.2,
      "carbs_100g": 4.63,
      "kcal_100g": 61,
      "sugars_100g": 4.81,
      "fiber_100g": 0,
      "sodium_mg_100g": 38
    },
    "portions": [
      {
        "unit": "undetermined",
        "description": "Quantity not specified",
        "gram_weight": 244,
        "source_portion_id": "290558",
        "source_modifier": "90000",
        "sequence": 5
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per cup of hot cereal",
        "gram_weight": 61,
        "source_portion_id": "290557",
        "source_modifier": "63546",
        "sequence": 4
      },
      {
        "unit": "undetermined",
        "description": "1 fl oz",
        "gram_weight": 30.5,
        "source_portion_id": "290555",
        "source_modifier": "30000",
        "sequence": 2
      },
      {
        "unit": "undetermined",
        "description": "1 cup",
        "gram_weight": 244,
        "source_portion_id": "290554",
        "source_modifier": "10205",
        "sequence": 1
      },
      {
        "unit": "undetermined",
        "description": "Guideline amount per fl oz of beverage",
        "gram_weight": 2.5,
        "source_portion_id": "290556",
        "source_modifier": "63480",
        "sequence": 3
      }
    ],
    "additional_descriptions": [],
    "food_code": "11114350",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions"
      ]
    },
    "provenance": {
      "publication_date": "10/31/2024",
      "valid_from": "1/1/2021",
      "valid_to": "12/31/2023",
      "source_data_type": "Survey (FNDDS)",
      "source_food_class": "Survey",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    }
  }
]
```

## usda-sr-legacy

- Dataset version: 2018-04 (final release of Standard Reference)
- Input/output/skipped: 7,793 / 7,793 / 0
- Skip reasons: none
- Nutrition completeness: 95.54%
- Portion coverage: 96.66%
- Barcode coverage: 0.00%

### 10 normalized examples

```json
[
  {
    "schema_version": "1.0.0",
    "name": "Pillsbury Golden Layer Buttermilk Biscuits, Artificial Flavor, refrigerated dough",
    "source": "usda_sr_legacy",
    "source_id": "167512",
    "dataset_version": "2018-04 (final release of Standard Reference)",
    "category": {
      "name": "Baked Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 5.88,
          "unit": "g",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 3.5,
          "unit": "g",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 1290,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 1.2,
          "unit": "g",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 2.12,
          "unit": "mg",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 1060,
          "unit": "mg",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 4.41,
          "unit": "g",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 2.94,
          "unit": "g",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 13.2,
          "unit": "g",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 41.2,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 307,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 35.5,
          "unit": "g",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 5.88,
          "unit": "g",
          "derivation_code": "MA",
          "derivation_description": "Manufacturer supplied(industry or trade association), Analytical data, incomplete documentation",
          "measurement_source": "Manufacturer's analytical; partial documentation",
          "data_points": 1
        }
      ],
      "protein_100g": 5.88,
      "fiber_100g": 1.2,
      "sodium_mg_100g": 1060,
      "fat_100g": 13.2,
      "carbs_100g": 41.2,
      "kcal_100g": 307,
      "sugars_100g": 5.88
    },
    "portions": [
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined serving",
        "gram_weight": 34,
        "source_portion_id": "81549",
        "source_modifier": "serving",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "SR Legacy",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".ProteinConversionFactor",
        "value": 6.25
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Pillsbury, Cinnamon Rolls with Icing, refrigerated dough",
    "source": "usda_sr_legacy",
    "source_id": "167513",
    "dataset_version": "2018-04 (final release of Standard Reference)",
    "category": {
      "name": "Baked Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 4.34,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 3.08,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 1380,
          "unit": "kJ",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 1.4,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 1.93,
          "unit": "mg",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 780,
          "unit": "mg",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 1,
          "unit": "IU",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "NR",
          "derivation_description": "Nutrient that is based on other nutrient/s; value used directly, ex. Nut.#204 from Nut.#298",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0.1,
          "unit": "mg",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 4.29,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 3.25,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 11.3,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 53.4,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 330,
          "unit": "kcal",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 27.9,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 21.3,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 28,
          "unit": "mg",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        }
      ],
      "protein_100g": 4.34,
      "fiber_100g": 1.4,
      "sodium_mg_100g": 780,
      "fat_100g": 11.3,
      "carbs_100g": 53.4,
      "kcal_100g": 330,
      "sugars_100g": 21.3
    },
    "portions": [
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined serving 1 roll with icing",
        "gram_weight": 44,
        "source_portion_id": "81550",
        "source_modifier": "serving 1 roll with icing",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "SR Legacy",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".ProteinConversionFactor",
        "value": 6.25
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Kraft Foods, Shake N Bake Original Recipe, Coating for Pork, dry",
    "source": "usda_sr_legacy",
    "source_id": "167514",
    "dataset_version": "2018-04 (final release of Standard Reference)",
    "category": {
      "name": "Baked Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 1580,
          "unit": "kJ",
          "data_points": 0
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 2180,
          "unit": "mg",
          "derivation_code": "LC",
          "derivation_description": "Label claim (back calculated from label by NDL staff; Calculated from label claim/serving (g or %RDI)",
          "measurement_source": "Calculated from nutrient label by NDL",
          "data_points": 0
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 3.7,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 79.8,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 377,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 3.2,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 6.1,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 7.2,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        }
      ],
      "sodium_mg_100g": 2180,
      "fat_100g": 3.7,
      "carbs_100g": 79.8,
      "kcal_100g": 377,
      "protein_100g": 6.1
    },
    "portions": [
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined serving",
        "gram_weight": 28,
        "source_portion_id": "81551",
        "source_modifier": "serving",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 0.7143,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "SR Legacy",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": []
  },
  {
    "schema_version": "1.0.0",
    "name": "George Weston Bakeries, Thomas English Muffins",
    "source": "usda_sr_legacy",
    "source_id": "167515",
    "dataset_version": "2018-04 (final release of Standard Reference)",
    "category": {
      "name": "Baked Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "Z",
          "derivation_description": "Assumed zero (Insignificant amount or not naturally occurring in a food, such as fiber in meat)",
          "measurement_source": "Assumed zero",
          "data_points": 0
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 1.6,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 42.6,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 972,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 1.4,
          "unit": "mg",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 345,
          "unit": "mg",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 0,
          "unit": "IU",
          "data_points": 0
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 0,
          "unit": "µg",
          "data_points": 0
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 40,
          "unit": "µg",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0.082,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0.308,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 8,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 180,
          "unit": "mg",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.308,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 0.303,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 0.841,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.079,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 0.303,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 0.92,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 1.8,
          "unit": "g",
          "derivation_code": "MC",
          "derivation_description": "Manufacturer supplied; Calculated by manufacturer or unknown if analytical or calculated",
          "measurement_source": "Calculated by manufacturer, not adjusted or rounded for NLEA",
          "data_points": 1
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 46,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 1
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 232,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 1
        }
      ],
      "sodium_mg_100g": 345,
      "protein_100g": 8,
      "fat_100g": 1.8,
      "carbs_100g": 46,
      "kcal_100g": 232
    },
    "portions": [
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined serving",
        "gram_weight": 57,
        "source_portion_id": "81552",
        "source_modifier": "serving",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 0.7143,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "SR Legacy",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": []
  },
  {
    "schema_version": "1.0.0",
    "name": "Waffles, buttermilk, frozen, ready-to-heat",
    "source": "usda_sr_legacy",
    "source_id": "167516",
    "dataset_version": "2018-04 (final release of Standard Reference)",
    "category": {
      "name": "Baked Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 1.9,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 1340,
          "unit": "IU",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 401,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 1.44,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 96,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.665,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.66,
          "max": 0.67
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 63,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 57,
          "max": 68
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 2.86,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 2.33,
          "max": 3.39
        },
        {
          "source_key": "1184",
          "name": "Vitamin K (Dihydrophylloquinone)",
          "amount_100g": 17.9,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 10.5,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 14,
          "unit": "µg",
          "data_points": 0
        },
        {
          "source_key": "1210",
          "name": "Tryptophan",
          "amount_100g": 0.074,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1211",
          "name": "Threonine",
          "amount_100g": 0.225,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1215",
          "name": "Methionine",
          "amount_100g": 0.133,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1217",
          "name": "Phenylalanine",
          "amount_100g": 0.304,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 2,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 2,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 1.27,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 1.12,
          "max": 1.43
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.499,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.423,
          "max": 0.576
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 6.58,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 6.44,
          "max": 6.72
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 2.81,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 2.63,
          "max": 2.99
        },
        {
          "source_key": "1009",
          "name": "Starch",
          "amount_100g": 35.5,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 35.2,
          "max": 35.8
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 1.35,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.71,
          "max": 1.98
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 1140,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1075",
          "name": "Galactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 2.2,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 1.9,
          "max": 2.4
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 6.04,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 5.69,
          "max": 6.39
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 19,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 18,
          "max": 19
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 388,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 373,
          "max": 403
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 621,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 555,
          "max": 687
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.04,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.02,
          "max": 0.06
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0.215,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.201,
          "max": 0.228
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 401,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 191,
          "max": 610
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.021,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.021,
          "max": 0.022
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0.007,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1273",
          "name": "SFA 22:0",
          "amount_100g": 0.03,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.029,
          "max": 0.031
        },
        {
          "source_key": "1274",
          "name": "MUFA 14:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.022,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.016,
          "max": 0.028
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0.012,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1300",
          "name": "SFA 17:0",
          "amount_100g": 0.01,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.01,
          "max": 0.011
        },
        {
          "source_key": "1323",
          "name": "MUFA 17:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1333",
          "name": "MUFA 15:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1218",
          "name": "Tyrosine",
          "amount_100g": 0.154,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1222",
          "name": "Alanine",
          "amount_100g": 0.249,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1224",
          "name": "Glutamic acid",
          "amount_100g": 1.61,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1225",
          "name": "Glycine",
          "amount_100g": 0.214,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1226",
          "name": "Proline",
          "amount_100g": 0.559,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 2.7,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 15,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 7,
          "max": 24
        },
        {
          "source_key": "1299",
          "name": "SFA 15:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1313",
          "name": "PUFA 20:2 n-6 c,c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1321",
          "name": "PUFA 18:3 n-6 c,c,c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1325",
          "name": "PUFA 20:3",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1219",
          "name": "Valine",
          "amount_100g": 0.326,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1220",
          "name": "Arginine",
          "amount_100g": 0.282,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1221",
          "name": "Histidine",
          "amount_100g": 0.143,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1223",
          "name": "Aspartic acid",
          "amount_100g": 0.406,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1227",
          "name": "Serine",
          "amount_100g": 0.347,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.003,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 1.02,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.933,
          "max": 1.12
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.772,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.763,
          "max": 0.781
        },
        {
          "source_key": "1267",
          "name": "SFA 20:0",
          "amount_100g": 0.031,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.031,
          "max": 0.032
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 4.47,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 3.75,
          "max": 5.19
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 1.41,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 1.14,
          "max": 1.68
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0,
          "unit": "g",
          "data_points": 0
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.009,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.007,
          "max": 0.011
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0.002,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.039,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.038,
          "max": 0.041
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 4.53,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 273,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 2.67,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 2.38,
          "max": 2.95
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0.29,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.27,
          "max": 0.3
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 40.3,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 40.2,
          "max": 40.4
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.3,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 3.36,
          "max": 5.24
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 279,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 116,
          "max": 441
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 126,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 109,
          "max": 142
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.48,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.43,
          "max": 0.53
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 9.5,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 9,
          "max": 10.1
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.62,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.56,
          "max": 0.67
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 63,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0.07,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.07,
          "max": 0.08
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 4.03,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 3.64,
          "max": 4.42
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0.03,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.02,
          "max": 0.05
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 6.68,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 5.87,
          "max": 7.48
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.24,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.22,
          "max": 0.26
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.972,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.864,
          "max": 1.08
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 49,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 43,
          "max": 54
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 9.22,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 8.71,
          "max": 9.73
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 41,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1212",
          "name": "Isoleucine",
          "amount_100g": 0.281,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1213",
          "name": "Leucine",
          "amount_100g": 0.489,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1214",
          "name": "Lysine",
          "amount_100g": 0.296,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1216",
          "name": "Cystine",
          "amount_100g": 0.154,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        }
      ],
      "protein_100g": 6.58,
      "fiber_100g": 2.2,
      "sodium_mg_100g": 621,
      "kcal_100g": 273,
      "sugars_100g": 4.3,
      "fat_100g": 9.22,
      "carbs_100g": 41
    },
    "portions": [
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined waffle, round",
        "gram_weight": 38,
        "source_portion_id": "81554",
        "source_modifier": "waffle, round",
        "sequence": 2
      },
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined waffle, square",
        "gram_weight": 39,
        "source_portion_id": "81553",
        "source_modifier": "waffle, square",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "SR Legacy",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": []
  },
  {
    "schema_version": "1.0.0",
    "name": "Waffle, buttermilk, frozen, ready-to-heat, toasted",
    "source": "usda_sr_legacy",
    "source_id": "167517",
    "dataset_version": "2018-04 (final release of Standard Reference)",
    "category": {
      "name": "Baked Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1110",
          "name": "Vitamin D (D2 + D3), International Units",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "Z",
          "derivation_description": "Assumed zero (Insignificant amount or not naturally occurring in a food, such as fiber in meat)",
          "measurement_source": "Assumed zero",
          "data_points": 0
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 1.62,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.95,
          "max": 2.94
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 28.1,
          "unit": "mg",
          "derivation_code": "NR",
          "derivation_description": "Nutrient that is based on other nutrient/s; value used directly, ex. Nut.#204 from Nut.#298",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 107,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 13,
          "unit": "µg",
          "data_points": 0
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 5.29,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 710,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 589,
          "max": 824
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 438,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 1.51,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.33,
          "max": 1.68
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1184",
          "name": "Vitamin K (Dihydrophylloquinone)",
          "amount_100g": 16.9,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 2.28,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 3,
          "unit": "µg",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 1.5,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0.09,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.08,
          "max": 0.1
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 4.62,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 4.17,
          "max": 4.89
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0.01,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0.04
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0.003,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.04,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.028,
          "max": 0.046
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1299",
          "name": "SFA 15:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1313",
          "name": "PUFA 20:2 n-6 c,c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1321",
          "name": "PUFA 18:3 n-6 c,c,c",
          "amount_100g": 0.003,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0.01
        },
        {
          "source_key": "1325",
          "name": "PUFA 20:3",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 7.94,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 6.04,
          "max": 10.6
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.217,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.18,
          "max": 0.24
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 1.11,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.85,
          "max": 1.28
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 55,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 45,
          "max": 63
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 66,
          "unit": "µg",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 9.49,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 9.27,
          "max": 9.63
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 48.4,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 309,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 2.85,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2.38,
          "max": 3.33
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 0.05,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0.14
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0.17,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.07,
          "max": 0.31
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 31.6,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 29.6,
          "max": 33.3
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.41,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 3.49,
          "max": 4.94
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 299,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 82,
          "max": 511
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 138,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 93,
          "max": 192
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.48,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.24,
          "max": 0.55
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 10.3,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 9.6,
          "max": 10.8
        },
        {
          "source_key": "1212",
          "name": "Isoleucine",
          "amount_100g": 0.312,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1213",
          "name": "Leucine",
          "amount_100g": 0.544,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1214",
          "name": "Lysine",
          "amount_100g": 0.329,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1216",
          "name": "Cystine",
          "amount_100g": 0.172,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1219",
          "name": "Valine",
          "amount_100g": 0.362,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1220",
          "name": "Arginine",
          "amount_100g": 0.314,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1221",
          "name": "Histidine",
          "amount_100g": 0.159,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1223",
          "name": "Aspartic acid",
          "amount_100g": 0.451,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1227",
          "name": "Serine",
          "amount_100g": 0.385,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0.003,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 1.2,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.1,
          "max": 1.26
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.967,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.864,
          "max": 1.11
        },
        {
          "source_key": "1267",
          "name": "SFA 20:0",
          "amount_100g": 0.031,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.029,
          "max": 0.032
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 5.23,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 4.47,
          "max": 5.88
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 1.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.953,
          "max": 1.94
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.099,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.037,
          "max": 0.214
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.004,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0.012
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.68,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.55,
          "max": 0.77
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 13,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 6,
          "max": 26
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.027,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.024,
          "max": 0.031
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0.008,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1273",
          "name": "SFA 22:0",
          "amount_100g": 0.036,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.035,
          "max": 0.037
        },
        {
          "source_key": "1274",
          "name": "MUFA 14:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 12.5,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 2,
          "unit": "µg",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 2,
          "unit": "µg",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.563,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 0.446,
          "max": 0.733
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.648,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 5,
          "min": 0.38,
          "max": 0.8
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 68,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 55,
          "max": 76
        },
        {
          "source_key": "1210",
          "name": "Tryptophan",
          "amount_100g": 0.082,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1211",
          "name": "Threonine",
          "amount_100g": 0.25,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1215",
          "name": "Methionine",
          "amount_100g": 0.148,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1217",
          "name": "Phenylalanine",
          "amount_100g": 0.337,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1218",
          "name": "Tyrosine",
          "amount_100g": 0.172,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1222",
          "name": "Alanine",
          "amount_100g": 0.276,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1224",
          "name": "Glutamic acid",
          "amount_100g": 1.79,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1225",
          "name": "Glycine",
          "amount_100g": 0.237,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1226",
          "name": "Proline",
          "amount_100g": 0.621,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.022,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.015,
          "max": 0.032
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0.013,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1300",
          "name": "SFA 17:0",
          "amount_100g": 0.013,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.012,
          "max": 0.013
        },
        {
          "source_key": "1323",
          "name": "MUFA 17:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1333",
          "name": "MUFA 15:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.037,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.021,
          "max": 0.076
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0.223,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 0.037,
          "max": 0.278
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 1460,
          "unit": "IU",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 437,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 210,
          "max": 685
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 7.42,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 7.07,
          "max": 7.74
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 3.13,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 2.84,
          "max": 3.5
        },
        {
          "source_key": "1009",
          "name": "Starch",
          "amount_100g": 39.7,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 38.6,
          "max": 41.1
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 1.35,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.8,
          "max": 2.04
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "RA",
          "derivation_description": "Recipe; Approximate ingredient proportions (ex. combination of several recipes)",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 1290,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1075",
          "name": "Galactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 2.6,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2.4,
          "max": 2.9
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 6.59,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 4.53,
          "max": 7.58
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 22,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 15,
          "max": 29
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 444,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 6,
          "min": 429,
          "max": 458
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "Z",
          "derivation_description": "Assumed zero (Insignificant amount or not naturally occurring in a food, such as fiber in meat)",
          "measurement_source": "Assumed zero",
          "data_points": 0
        }
      ],
      "sodium_mg_100g": 710,
      "fat_100g": 9.49,
      "carbs_100g": 48.4,
      "kcal_100g": 309,
      "sugars_100g": 4.41,
      "protein_100g": 7.42,
      "fiber_100g": 2.6
    },
    "portions": [
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined waffle round (4\" dia)",
        "gram_weight": 33,
        "source_portion_id": "81556",
        "source_modifier": "waffle round (4\" dia)",
        "sequence": 2
      },
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined oz",
        "gram_weight": 28,
        "source_portion_id": "81555",
        "source_modifier": "oz",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "SR Legacy",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": []
  },
  {
    "schema_version": "1.0.0",
    "name": "Waffle, buttermilk, frozen, ready-to-heat, microwaved",
    "source": "usda_sr_legacy",
    "source_id": "167518",
    "dataset_version": "2018-04 (final release of Standard Reference)",
    "category": {
      "name": "Baked Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 6.92,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 6.85,
          "max": 7
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 3.04,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 2.82,
          "max": 3.26
        },
        {
          "source_key": "1009",
          "name": "Starch",
          "amount_100g": 38.6,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 37.9,
          "max": 39.2
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 1.39,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.78,
          "max": 2
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 1210,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1075",
          "name": "Galactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 2.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 2,
          "max": 2.9
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 6.53,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 6.3,
          "max": 6.77
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 20,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 20,
          "max": 20
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 410,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 382,
          "max": 438
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 663,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 581,
          "max": 745
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.063,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.06,
          "max": 0.066
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0.235,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.224,
          "max": 0.246
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 1430,
          "unit": "IU",
          "data_points": 0
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 429,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 212,
          "max": 646
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 429,
          "unit": "µg",
          "data_points": 0
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 1.33,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 1.15,
          "max": 1.52
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.576,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.564,
          "max": 0.587
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.695,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.69,
          "max": 0.7
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 64,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 59,
          "max": 68
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 2.44,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 1.37,
          "max": 3.52
        },
        {
          "source_key": "1184",
          "name": "Vitamin K (Dihydrophylloquinone)",
          "amount_100g": 20.8,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 10.8,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 14,
          "unit": "µg",
          "data_points": 0
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 16,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 7,
          "max": 25
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 2.06,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.023,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.022,
          "max": 0.024
        },
        {
          "source_key": "1273",
          "name": "SFA 22:0",
          "amount_100g": 0.035,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.035,
          "max": 0.035
        },
        {
          "source_key": "1274",
          "name": "MUFA 14:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.024,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.018,
          "max": 0.03
        },
        {
          "source_key": "1300",
          "name": "SFA 17:0",
          "amount_100g": 0.011,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.011,
          "max": 0.012
        },
        {
          "source_key": "1323",
          "name": "MUFA 17:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1333",
          "name": "MUFA 15:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 9.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 9.23,
          "max": 9.57
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 44.2,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 289,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 2.77,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 2.44,
          "max": 3.11
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0.34,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.32,
          "max": 0.35
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 36.5,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 35.8,
          "max": 37.1
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.5,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 3.54,
          "max": 5.45
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 125,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 110,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 103,
          "max": 116
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.58,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.57,
          "max": 0.6
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 10.1,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 9.6,
          "max": 10.5
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.63,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.56,
          "max": 0.7
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0.08,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.08,
          "max": 0.09
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 4.21,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 3.87,
          "max": 4.55
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 6.73,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 6.2,
          "max": 7.26
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.24,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.23,
          "max": 0.25
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 1.1,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.87,
          "max": 1.34
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 50,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 48,
          "max": 52
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 99,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 1.11,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 1.03,
          "max": 1.19
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.843,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.811,
          "max": 0.875
        },
        {
          "source_key": "1267",
          "name": "SFA 20:0",
          "amount_100g": 0.032,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.032,
          "max": 0.033
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 4.8,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 4.07,
          "max": 5.52
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 1.48,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 1.18,
          "max": 1.78
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.123,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.043,
          "max": 0.202
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0.011
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.043,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.042,
          "max": 0.044
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 4.86,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 1.62,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1299",
          "name": "SFA 15:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1313",
          "name": "PUFA 20:2 n-6 c,c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1321",
          "name": "PUFA 18:3 n-6 c,c,c",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0.01
        },
        {
          "source_key": "1325",
          "name": "PUFA 20:3",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        }
      ],
      "protein_100g": 6.92,
      "fiber_100g": 2.4,
      "sodium_mg_100g": 663,
      "fat_100g": 9.4,
      "carbs_100g": 44.2,
      "kcal_100g": 289,
      "sugars_100g": 4.5
    },
    "portions": [
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined waffle",
        "gram_weight": 35,
        "source_portion_id": "81557",
        "source_modifier": "waffle",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "SR Legacy",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": [
      {
        "type": ".CalorieConversionFactor",
        "proteinValue": 4,
        "fatValue": 9,
        "carbohydrateValue": 4
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Waffle, plain, frozen, ready-to-heat, microwave",
    "source": "usda_sr_legacy",
    "source_id": "167519",
    "dataset_version": "2018-04 (final release of Standard Reference)",
    "category": {
      "name": "Baked Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 106,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 0.909,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.902,
          "max": 1.3
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 0.576,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.487,
          "max": 0.909
        },
        {
          "source_key": "1267",
          "name": "SFA 20:0",
          "amount_100g": 0.042,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.038,
          "max": 0.065
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 5.1,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 6.08,
          "max": 6.27
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 1.86,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 1.37,
          "max": 3.13
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.371,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.048,
          "max": 0.85
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0.013
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.07,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.042,
          "max": 0.128
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 5.2,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 2.24,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1299",
          "name": "SFA 15:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1313",
          "name": "PUFA 20:2 n-6 c,c",
          "amount_100g": 0.007,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0.017
        },
        {
          "source_key": "1321",
          "name": "PUFA 18:3 n-6 c,c,c",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1325",
          "name": "PUFA 20:3",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 9.91,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 9.58,
          "max": 10.2
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 45.4,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 298,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 3.31,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 2.21,
          "max": 4.41
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0.28,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.26,
          "max": 0.29
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 35,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 32.8,
          "max": 37.1
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 5.04,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 3.63,
          "max": 6.46
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 197,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 148,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 127,
          "max": 169
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 0.45,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.35,
          "max": 0.56
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 12.8,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 8.7,
          "max": 16.9
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 0.95,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.6,
          "max": 1.31
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0.07,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.06,
          "max": 0.08
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 4.52,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 4.03,
          "max": 5.02
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 7.78,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 6.95,
          "max": 8.62
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.325,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.3,
          "max": 0.35
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 1.02,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.882,
          "max": 1.15
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 56,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1273",
          "name": "SFA 22:0",
          "amount_100g": 0.035,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.037,
          "max": 0.047
        },
        {
          "source_key": "1274",
          "name": "MUFA 14:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.026,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.032,
          "max": 0.032
        },
        {
          "source_key": "1300",
          "name": "SFA 17:0",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0.013
        },
        {
          "source_key": "1323",
          "name": "MUFA 17:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1333",
          "name": "MUFA 15:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 6.71,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 6.34,
          "max": 7.08
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 3.02,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 2.78,
          "max": 3.26
        },
        {
          "source_key": "1009",
          "name": "Starch",
          "amount_100g": 38.6,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 38.1,
          "max": 39.2
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 1.46,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 1.16,
          "max": 1.76
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 1240,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1075",
          "name": "Galactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 2.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 2.1,
          "max": 2.7
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 5.81,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 5.61,
          "max": 6.01
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 25,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 21,
          "max": 29
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 410,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 398,
          "max": 422
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 682,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 649,
          "max": 714
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.038,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 0.154,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.037,
          "max": 0.271
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 1.18,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.73,
          "max": 1.62
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.544,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.472,
          "max": 0.615
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.655,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.6,
          "max": 0.71
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 67,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 2.18,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.96,
          "max": 3.4
        },
        {
          "source_key": "1184",
          "name": "Vitamin K (Dihydrophylloquinone)",
          "amount_100g": 23,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 8.1,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 11,
          "unit": "µg",
          "data_points": 0
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 16,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 7,
          "max": 24
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 1.58,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.012,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 0.014,
          "max": 0.015
        }
      ],
      "fat_100g": 9.91,
      "carbs_100g": 45.4,
      "kcal_100g": 298,
      "sugars_100g": 5.04,
      "protein_100g": 6.71,
      "fiber_100g": 2.4,
      "sodium_mg_100g": 682
    },
    "portions": [
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined waffle, round (4\"dia)",
        "gram_weight": 32,
        "source_portion_id": "81558",
        "source_modifier": "waffle, round (4\"dia)",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "SR Legacy",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": []
  },
  {
    "schema_version": "1.0.0",
    "name": "Pie Crust, Cookie-type, Graham Cracker, Ready Crust",
    "source": "usda_sr_legacy",
    "source_id": "167520",
    "dataset_version": "2018-04 (final release of Standard Reference)",
    "category": {
      "name": "Baked Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 64.3,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 501,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 18.1,
          "unit": "g",
          "derivation_code": "NR",
          "derivation_description": "Nutrient that is based on other nutrient/s; value used directly, ex. Nut.#204 from Nut.#298",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1110",
          "name": "Vitamin D (D2 + D3), International Units",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 23,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 16.9,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 1.67,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 97,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 5,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 2100,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 1,
          "unit": "IU",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 24.8,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 21.8,
          "max": 27.3
        },
        {
          "source_key": "1299",
          "name": "SFA 15:0",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0.002
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 2.78,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2.34,
          "max": 3.29
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 1.97,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.73,
          "max": 2.18
        },
        {
          "source_key": "1267",
          "name": "SFA 20:0",
          "amount_100g": 0.096,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.08,
          "max": 0.112
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 16.9,
          "unit": "g",
          "data_points": 3,
          "min": 15,
          "max": 18.2
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 1.61,
          "unit": "g",
          "data_points": 3,
          "min": 1.44,
          "max": 1.81
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.06,
          "unit": "g",
          "data_points": 3,
          "min": 0.048,
          "max": 0.07
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.034,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.029,
          "max": 0.037
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 3.22,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 3.13,
          "max": 3.29
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.178,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.15,
          "max": 0.202
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.076,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.052,
          "max": 0.097
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 17.7,
          "unit": "mg",
          "data_points": 0
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 29,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 19,
          "max": 38
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 113,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 90,
          "max": 130
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 1.25,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.75,
          "max": 1.6
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 2.6,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2.2,
          "max": 3.3
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 1.85,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.39,
          "max": 2.56
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 18.1,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 16,
          "max": 20.3
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 4.37,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 4.14,
          "max": 4.67
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 5.1,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 4.75,
          "max": 5.38
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.02,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.017,
          "max": 0.023
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1273",
          "name": "SFA 22:0",
          "amount_100g": 0.102,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.082,
          "max": 0.118
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.011,
          "unit": "g",
          "data_points": 3,
          "min": 0.002,
          "max": 0.017
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1300",
          "name": "SFA 17:0",
          "amount_100g": 0.031,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.023,
          "max": 0.036
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.223,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.148,
          "max": 0.28
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 1.29,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.66,
          "max": 1.9
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 21.8,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 14.9,
          "max": 25.5
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 19,
          "unit": "µg",
          "data_points": 3,
          "min": 14,
          "max": 22
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.184,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.093,
          "max": 0.276
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.213,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.2,
          "max": 0.225
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 65,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 50,
          "max": 80
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 1.9,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.2,
          "max": 2.3
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 2.6,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2.5,
          "max": 2.8
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 23,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 16,
          "max": 29
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 117,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 96,
          "max": 160
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 1.39,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.16,
          "max": 1.73
        },
        {
          "source_key": "1009",
          "name": "Starch",
          "amount_100g": 35.9,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 35.7,
          "max": 36.1
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 471,
          "unit": "mg",
          "derivation_code": "LC",
          "derivation_description": "Label claim (back calculated from label by NDL staff; Calculated from label claim/serving (g or %RDI)",
          "measurement_source": "Calculated from nutrient label by NDL",
          "data_points": 0
        },
        {
          "source_key": "1198",
          "name": "Betaine",
          "amount_100g": 38.8,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 46,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 36,
          "max": 58
        }
      ],
      "carbs_100g": 64.3,
      "kcal_100g": 501,
      "sugars_100g": 18.1,
      "fat_100g": 24.8,
      "protein_100g": 5.1,
      "fiber_100g": 1.9,
      "sodium_mg_100g": 471
    },
    "portions": [
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined crust",
        "gram_weight": 183,
        "source_portion_id": "81560",
        "source_modifier": "crust",
        "sequence": 2
      },
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined oz",
        "gram_weight": 28.35,
        "source_portion_id": "81559",
        "source_modifier": "oz",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "SR Legacy",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": []
  },
  {
    "schema_version": "1.0.0",
    "name": "Pie Crust, Cookie-type, Chocolate, Ready Crust",
    "source": "usda_sr_legacy",
    "source_id": "167521",
    "dataset_version": "2018-04 (final release of Standard Reference)",
    "category": {
      "name": "Baked Products"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 26.3,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1190",
          "name": "Folate, DFE",
          "amount_100g": 108,
          "unit": "µg",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1314",
          "name": "MUFA 16:1 c",
          "amount_100g": 0.019,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.015,
          "max": 0.023
        },
        {
          "source_key": "1292",
          "name": "Fatty acids, total monounsaturated",
          "amount_100g": 14.5,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1011",
          "name": "Glucose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1014",
          "name": "Maltose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1057",
          "name": "Caffeine",
          "amount_100g": 8,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 6,
          "max": 9
        },
        {
          "source_key": "1110",
          "name": "Vitamin D (D2 + D3), International Units",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "BFFN",
          "derivation_description": "Based on another form of the food or similar food; Concentration adjustment; Fat; Retention factors not used",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1125",
          "name": "Tocopherol, beta",
          "amount_100g": 0.17,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.14,
          "max": 0.21
        },
        {
          "source_key": "1126",
          "name": "Tocopherol, gamma",
          "amount_100g": 11.8,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 11.2,
          "max": 12.7
        },
        {
          "source_key": "1128",
          "name": "Tocotrienol, alpha",
          "amount_100g": 0.04,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.03,
          "max": 0.05
        },
        {
          "source_key": "1129",
          "name": "Tocotrienol, beta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1114",
          "name": "Vitamin D (D2 + D3)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "BFFN",
          "derivation_description": "Based on another form of the food or similar food; Concentration adjustment; Fat; Retention factors not used",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1127",
          "name": "Tocopherol, delta",
          "amount_100g": 3.49,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 3.33,
          "max": 3.6
        },
        {
          "source_key": "1130",
          "name": "Tocotrienol, gamma",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1131",
          "name": "Tocotrienol, delta",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1184",
          "name": "Vitamin K (Dihydrophylloquinone)",
          "amount_100g": 64.1,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 47.4,
          "max": 77.6
        },
        {
          "source_key": "1012",
          "name": "Fructose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1013",
          "name": "Lactose",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1010",
          "name": "Sucrose",
          "amount_100g": 19.5,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 14.6,
          "max": 21.9
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "NR",
          "derivation_description": "Nutrient that is based on other nutrient/s; value used directly, ex. Nut.#204 from Nut.#298",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1051",
          "name": "Water",
          "amount_100g": 4.99,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 4.26,
          "max": 6.19
        },
        {
          "source_key": "1123",
          "name": "Lutein + zeaxanthin",
          "amount_100g": 12,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1058",
          "name": "Theobromine",
          "amount_100g": 100,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 69,
          "max": 148
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 32,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 19,
          "max": 46
        },
        {
          "source_key": "1092",
          "name": "Potassium, K",
          "amount_100g": 187,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 170,
          "max": 200
        },
        {
          "source_key": "1095",
          "name": "Zinc, Zn",
          "amount_100g": 2.1,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.8,
          "max": 2.3
        },
        {
          "source_key": "1103",
          "name": "Selenium, Se",
          "amount_100g": 2.5,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2.2,
          "max": 3
        },
        {
          "source_key": "1109",
          "name": "Vitamin E (alpha-tocopherol)",
          "amount_100g": 1.79,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.36,
          "max": 2.33
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 22.4,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 21.1,
          "max": 23.8
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 64.5,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 484,
          "unit": "kcal",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1167",
          "name": "Niacin",
          "amount_100g": 3.07,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2.88,
          "max": 3.27
        },
        {
          "source_key": "1170",
          "name": "Pantothenic acid",
          "amount_100g": 0.168,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.148,
          "max": 0.196
        },
        {
          "source_key": "1175",
          "name": "Vitamin B-6",
          "amount_100g": 0.043,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.028,
          "max": 0.059
        },
        {
          "source_key": "1180",
          "name": "Choline, total",
          "amount_100g": 16.4,
          "unit": "mg",
          "data_points": 0
        },
        {
          "source_key": "1183",
          "name": "Vitamin K (Menaquinone-4)",
          "amount_100g": 0.6,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 1
        },
        {
          "source_key": "1186",
          "name": "Folic acid",
          "amount_100g": 50,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 36,
          "max": 63
        },
        {
          "source_key": "1198",
          "name": "Betaine",
          "amount_100g": 21.3,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 1
        },
        {
          "source_key": "1212",
          "name": "Isoleucine",
          "amount_100g": 0.225,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1213",
          "name": "Leucine",
          "amount_100g": 0.382,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1214",
          "name": "Lysine",
          "amount_100g": 0.245,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1216",
          "name": "Cystine",
          "amount_100g": 0.108,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1219",
          "name": "Valine",
          "amount_100g": 0.316,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1220",
          "name": "Arginine",
          "amount_100g": 0.29,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1221",
          "name": "Histidine",
          "amount_100g": 0.112,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1223",
          "name": "Aspartic acid",
          "amount_100g": 0.454,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1227",
          "name": "Serine",
          "amount_100g": 0.26,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1242",
          "name": "Vitamin E, added",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1259",
          "name": "SFA 4:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1260",
          "name": "SFA 6:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1262",
          "name": "SFA 10:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1265",
          "name": "SFA 16:0",
          "amount_100g": 2.59,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2.37,
          "max": 2.7
        },
        {
          "source_key": "1266",
          "name": "SFA 18:0",
          "amount_100g": 1.91,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.78,
          "max": 2.06
        },
        {
          "source_key": "1267",
          "name": "SFA 20:0",
          "amount_100g": 0.088,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.081,
          "max": 0.096
        },
        {
          "source_key": "1268",
          "name": "MUFA 18:1",
          "amount_100g": 14.4,
          "unit": "g",
          "data_points": 3,
          "min": 14.1,
          "max": 15
        },
        {
          "source_key": "1269",
          "name": "PUFA 18:2",
          "amount_100g": 1.97,
          "unit": "g",
          "data_points": 3,
          "min": 1.36,
          "max": 2.71
        },
        {
          "source_key": "1270",
          "name": "PUFA 18:3",
          "amount_100g": 0.063,
          "unit": "g",
          "data_points": 3,
          "min": 0.038,
          "max": 0.076
        },
        {
          "source_key": "1271",
          "name": "PUFA 20:4",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1276",
          "name": "PUFA 18:4",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1277",
          "name": "MUFA 20:1",
          "amount_100g": 0.029,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.026,
          "max": 0.037
        },
        {
          "source_key": "1279",
          "name": "MUFA 22:1",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1293",
          "name": "Fatty acids, total polyunsaturated",
          "amount_100g": 2.04,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1299",
          "name": "SFA 15:0",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0.002
        },
        {
          "source_key": "1120",
          "name": "Cryptoxanthin, beta",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1122",
          "name": "Lycopene",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 6.08,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 5.69,
          "max": 6.81
        },
        {
          "source_key": "1007",
          "name": "Ash",
          "amount_100g": 2.03,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.66,
          "max": 2.46
        },
        {
          "source_key": "1009",
          "name": "Starch",
          "amount_100g": 34.7,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 31.9,
          "max": 39.2
        },
        {
          "source_key": "1185",
          "name": "Vitamin K (phylloquinone)",
          "amount_100g": 18.2,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 15,
          "max": 22.5
        },
        {
          "source_key": "1187",
          "name": "Folate, food",
          "amount_100g": 22,
          "unit": "µg",
          "data_points": 3,
          "min": 21,
          "max": 23
        },
        {
          "source_key": "1210",
          "name": "Tryptophan",
          "amount_100g": 0.08,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1211",
          "name": "Threonine",
          "amount_100g": 0.205,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1215",
          "name": "Methionine",
          "amount_100g": 0.073,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1217",
          "name": "Phenylalanine",
          "amount_100g": 0.277,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1218",
          "name": "Tyrosine",
          "amount_100g": 0.164,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1222",
          "name": "Alanine",
          "amount_100g": 0.238,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1224",
          "name": "Glutamic acid",
          "amount_100g": 1.32,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1225",
          "name": "Glycine",
          "amount_100g": 0.243,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1226",
          "name": "Proline",
          "amount_100g": 0.419,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1246",
          "name": "Vitamin B-12, added",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1165",
          "name": "Thiamin",
          "amount_100g": 0.336,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.158,
          "max": 0.435
        },
        {
          "source_key": "1166",
          "name": "Riboflavin",
          "amount_100g": 0.265,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.216,
          "max": 0.301
        },
        {
          "source_key": "1177",
          "name": "Folate, total",
          "amount_100g": 72,
          "unit": "µg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 59,
          "max": 85
        },
        {
          "source_key": "1178",
          "name": "Vitamin B-12",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1018",
          "name": "Alcohol, ethyl",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1062",
          "name": "Energy",
          "amount_100g": 2020,
          "unit": "kJ",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 2.7,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 2.3,
          "max": 3.2
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 4.3,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 2,
          "min": 3.7,
          "max": 4.9
        },
        {
          "source_key": "1090",
          "name": "Magnesium, Mg",
          "amount_100g": 40,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 37,
          "max": 46
        },
        {
          "source_key": "1091",
          "name": "Phosphorus, P",
          "amount_100g": 120,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 100,
          "max": 130
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 503,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 450,
          "max": 600
        },
        {
          "source_key": "1098",
          "name": "Copper, Cu",
          "amount_100g": 0.77,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.6,
          "max": 0.98
        },
        {
          "source_key": "1101",
          "name": "Manganese, Mn",
          "amount_100g": 1.83,
          "unit": "mg",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 1.4,
          "max": 2.2
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1105",
          "name": "Retinol",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1106",
          "name": "Vitamin A, RAE",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1107",
          "name": "Carotene, beta",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1108",
          "name": "Carotene, alpha",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "FLA",
          "derivation_description": "Estimated formulation based on ingredient list; Linear program used to estimate ingredients; Analytical data",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 4.72,
          "unit": "g",
          "derivation_code": "NC",
          "derivation_description": "Calculated",
          "measurement_source": "Calculated or imputed",
          "data_points": 0
        },
        {
          "source_key": "1261",
          "name": "SFA 8:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1263",
          "name": "SFA 12:0",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1264",
          "name": "SFA 14:0",
          "amount_100g": 0.023,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.02,
          "max": 0.029
        },
        {
          "source_key": "1272",
          "name": "PUFA 22:6 n-3 (DHA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1273",
          "name": "SFA 22:0",
          "amount_100g": 0.086,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.079,
          "max": 0.094
        },
        {
          "source_key": "1275",
          "name": "MUFA 16:1",
          "amount_100g": 0.019,
          "unit": "g",
          "data_points": 3,
          "min": 0.015,
          "max": 0.023
        },
        {
          "source_key": "1278",
          "name": "PUFA 20:5 n-3 (EPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1280",
          "name": "PUFA 22:5 n-3 (DPA)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0,
          "max": 0
        },
        {
          "source_key": "1300",
          "name": "SFA 17:0",
          "amount_100g": 0.028,
          "unit": "g",
          "derivation_code": "A",
          "derivation_description": "Analytical",
          "measurement_source": "Analytical or derived from analytical",
          "data_points": 3,
          "min": 0.028,
          "max": 0.029
        }
      ],
      "sugars_100g": 26.3,
      "fat_100g": 22.4,
      "carbs_100g": 64.5,
      "kcal_100g": 484,
      "protein_100g": 6.08,
      "fiber_100g": 2.7,
      "sodium_mg_100g": 503
    },
    "portions": [
      {
        "amount": 1,
        "unit": "undetermined",
        "description": "1 undetermined crust",
        "gram_weight": 182,
        "source_portion_id": "81561",
        "source_modifier": "crust",
        "sequence": 1
      }
    ],
    "additional_descriptions": [],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_data_points",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "4/1/2019",
      "source_data_type": "SR Legacy",
      "source_food_class": "FinalFood",
      "is_historical_reference": false,
      "attribution": "USDA FoodData Central"
    },
    "nutrient_conversion_factors": []
  }
]
```

## usda-branded

- Dataset version: 2026-04-30
- Input/output/skipped: 455,458 / 455,458 / 0
- Skip reasons: none
- Nutrition completeness: 95.98%
- Portion coverage: 100.00%
- Barcode coverage: 100.00%

### 10 normalized examples

```json
[
  {
    "schema_version": "1.0.0",
    "name": "GRANOLA, CINNAMON, RAISIN, CINNAMON, RAISIN",
    "source": "usda_branded",
    "source_id": "1106281",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Cereal"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 10.7,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 25,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 57.1,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 500,
          "unit": "kcal",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 21.4,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 7.1,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 71,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 3.86,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 161,
          "unit": "mg",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 7.14,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        }
      ],
      "protein_100g": 10.7,
      "fat_100g": 25,
      "carbs_100g": 57.1,
      "kcal_100g": 500,
      "sugars_100g": 21.4,
      "fiber_100g": 7.1,
      "sodium_mg_100g": 161
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "0.25 cup",
        "gram_weight": 28
      }
    ],
    "serving_size": 28,
    "serving_unit": "g",
    "household_serving_description": "0.25 cup",
    "brand": "MICHELE'S",
    "brand_owner": "MICHELE'S",
    "barcode": "1633636543505",
    "ingredients": "ORGANIC ROLLED OATS, ORGANIC UNSWEETENED COCONUT, ORGANIC BROWN SUGAR, ORGANIC SEEDLESS RAISINS, SUNFLOWER SEEDS, WALNUTS, EXPELLER-PRESSED NON-GMO CANOLA OIL, FILTERED WATER, PURE VANILLA EXTRACT, SPICES, SEA SALT.",
    "additional_descriptions": [],
    "market_country": "United States",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "11/13/2020",
      "available_date": "4/26/2020",
      "modified_date": "4/26/2020",
      "source_data_type": "Branded",
      "source_food_class": "Branded",
      "is_historical_reference": false,
      "nutrient_basis_note": "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields.",
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "SUPREME BASMATI RICE",
    "source": "usda_branded",
    "source_id": "1106304",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Rice"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 8.89,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 80,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 356,
          "unit": "kcal",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 4.44,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 4.4,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0.8,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        }
      ],
      "protein_100g": 8.89,
      "fat_100g": 0,
      "carbs_100g": 80,
      "kcal_100g": 356,
      "sugars_100g": 4.44,
      "fiber_100g": 4.4,
      "sodium_mg_100g": 0
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "0.25 cup",
        "gram_weight": 45
      }
    ],
    "serving_size": 45,
    "serving_unit": "g",
    "household_serving_description": "0.25 cup",
    "brand": "VEETEE",
    "brand_owner": "VEETEE",
    "barcode": "8906004982514",
    "ingredients": "RIZ BASMATI RICE.",
    "additional_descriptions": [],
    "market_country": "United States",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "11/13/2020",
      "available_date": "4/26/2020",
      "modified_date": "4/26/2020",
      "source_data_type": "Branded",
      "source_food_class": "Branded",
      "is_historical_reference": false,
      "nutrient_basis_note": "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields.",
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "ORIGINAL SWEET & SMOKY BAR \"\"B\"\" \"\"Q\"\" SAUCE, ORIGINAL",
    "source": "usda_branded",
    "source_id": "1106312",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Ketchup, Mustard, BBQ & Cheese Sauce"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 26.7,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 117,
          "unit": "kcal",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 23.3,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 3.3,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 700,
          "unit": "mg",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 667,
          "unit": "IU",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        }
      ],
      "protein_100g": 0,
      "fat_100g": 0,
      "carbs_100g": 26.7,
      "kcal_100g": 117,
      "sugars_100g": 23.3,
      "fiber_100g": 3.3,
      "sodium_mg_100g": 700
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1.07 ONZ",
        "gram_weight": 30
      }
    ],
    "serving_size": 30,
    "serving_unit": "g",
    "household_serving_description": "1.07 ONZ",
    "brand": "Cookies Food Products Inc.",
    "brand_owner": "Cookies Food Products Inc.",
    "barcode": "076014101088",
    "ingredients": "TOMATO PASTE, WATER, SUGAR, VINEGAR, CORN SYRUP, SALT, LIQUID SMOKE, WORCESTERSHIRE SAUCE (WATER, VINEGAR, SALT, SUGAR, MALIC ACID, MOLASSES, CITRIC ACID, DEHYDRATED ONION AND GARLIC, FOOD GUMS (ARABIC, XANTHAN, GUAR, CELLULOSE), SPICES, DEXTROSE, NATURAL FLAVORS, AND SMOKE FLAVOR), SPICES AND SODIUM BENZOATE AS A PRESERVATIVE.",
    "additional_descriptions": [],
    "market_country": "United States",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "11/13/2020",
      "available_date": "4/26/2020",
      "modified_date": "4/26/2020",
      "source_data_type": "Branded",
      "source_food_class": "Branded",
      "is_historical_reference": false,
      "nutrient_basis_note": "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields.",
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "EGGS, EGG SHAPED BUBBLE GUM FILLED WITH EXTRA SOUR FLAVOR CRYSTALS",
    "source": "usda_branded",
    "source_id": "1106456",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Candy"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 83.3,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 333,
          "unit": "kcal",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 66.7,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        }
      ],
      "protein_100g": 0,
      "fat_100g": 0,
      "carbs_100g": 83.3,
      "kcal_100g": 333,
      "sugars_100g": 66.7,
      "sodium_mg_100g": 0
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1 PIECE",
        "gram_weight": 6
      }
    ],
    "serving_size": 6,
    "serving_unit": "g",
    "household_serving_description": "1 PIECE",
    "brand": "CRY BABY",
    "brand_owner": "CRY BABY",
    "barcode": "059642000503",
    "ingredients": "SUGAR, CORN SYRUP (GLUCOSE), GUM BASE, DEXTROSE, CITRIC ACID, TAPIOCA DEXTRIN, CONFECTIONERS GLAZE, CARNAUBA WAX, ARTIFICIAL FLAVORS, ARTIFICIAL COLORS,(FD&C RD 40, BLUE 1, YELLOW 5, YELLOW 6), CORN STARCH, BHT (TO MAINTAIN FRESHNESS). SOY MAY BE PRESENT.",
    "additional_descriptions": [],
    "market_country": "United States",
    "quality": {
      "nutrition_completeness": 0.8571,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "11/13/2020",
      "available_date": "4/26/2020",
      "modified_date": "4/26/2020",
      "source_data_type": "Branded",
      "source_food_class": "Branded",
      "is_historical_reference": false,
      "nutrient_basis_note": "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields.",
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "DUBBLE BUBBLE, BUBBLE GUM",
    "source": "usda_branded",
    "source_id": "1106457",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Chewing Gum & Mints"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 83.3,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 333,
          "unit": "kcal",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 83.3,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        }
      ],
      "protein_100g": 0,
      "fat_100g": 0,
      "carbs_100g": 83.3,
      "kcal_100g": 333,
      "sugars_100g": 83.3,
      "sodium_mg_100g": 0
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1 PIECE",
        "gram_weight": 6
      }
    ],
    "serving_size": 6,
    "serving_unit": "g",
    "household_serving_description": "1 PIECE",
    "brand": "DUBBLE BUBBLE",
    "brand_owner": "DUBBLE BUBBLE",
    "barcode": "059642932491",
    "ingredients": "SUGAR, DEXTROSE, CORN SYRUP (GLUCOSE), GUM BASE, HIGH FRUCTOSE CORN SYRUP, ARTIFICIAL FLAVORS, ARTIFICIAL COLOR (FD&C RED 3), CORN STARCH, BHT (TO MAINTAIN FRESHNESS).",
    "additional_descriptions": [],
    "market_country": "United States",
    "quality": {
      "nutrition_completeness": 0.8571,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "11/13/2020",
      "available_date": "4/15/2020",
      "modified_date": "4/15/2020",
      "source_data_type": "Branded",
      "source_food_class": "Branded",
      "is_historical_reference": false,
      "nutrient_basis_note": "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields.",
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "ROASTED SEAWEED",
    "source": "usda_branded",
    "source_id": "1106573",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Vegetable and Lentil Mixes"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 40,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 40,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 400,
          "unit": "kcal",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 14.4,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 800,
          "unit": "mg",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 40000,
          "unit": "IU",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        }
      ],
      "protein_100g": 40,
      "fat_100g": 0,
      "carbs_100g": 40,
      "kcal_100g": 400,
      "sugars_100g": 0,
      "fiber_100g": 0,
      "sodium_mg_100g": 800
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1 SHEET",
        "gram_weight": 2.5
      }
    ],
    "serving_size": 2.5,
    "serving_unit": "g",
    "household_serving_description": "1 SHEET",
    "brand": "YAMAMOTOYAMA",
    "brand_owner": "YAMAMOTOYAMA",
    "barcode": "911152013582",
    "ingredients": "SEAWEED",
    "additional_descriptions": [],
    "market_country": "United States",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "11/13/2020",
      "available_date": "4/15/2020",
      "modified_date": "4/15/2020",
      "source_data_type": "Branded",
      "source_food_class": "Branded",
      "is_historical_reference": false,
      "nutrient_basis_note": "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields.",
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "BUBBLE GUM, ORIGINAL & BLUE RAZZ",
    "source": "usda_branded",
    "source_id": "1106608",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Chewing Gum & Mints"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 83.3,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 333,
          "unit": "kcal",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 66.7,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        }
      ],
      "protein_100g": 0,
      "fat_100g": 0,
      "carbs_100g": 83.3,
      "kcal_100g": 333,
      "sugars_100g": 66.7,
      "sodium_mg_100g": 0
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1 PIECE",
        "gram_weight": 6
      }
    ],
    "serving_size": 6,
    "serving_unit": "g",
    "household_serving_description": "1 PIECE",
    "brand": "BAZOOKA",
    "brand_owner": "BAZOOKA",
    "barcode": "3927783004056",
    "ingredients": "ALL FLAVORS CONTAIN: SUGAR, ADDITIONALLY: ORIGINAL: GUM BASE, GLUCOSE SYRUP, NATURAL &ARTIFICIAL FLAVORS, GLYCERINE CITRIC ACID, TITANIUM DIOXIDE, BHT (PRESERVATIVE), RED 40 LAKE, RED 40, BLUE RASPBERRY: GLUCOSE SYRUP, GUM BASE, ARTIFICIAL FLAVORS, CITRIC ACID, GLYCERINE, MALIC ACID, ASPARTAME, BLUE 1 LAKE, ACESULFAME POTASSIUM, TITANIUM DIOXIDE, BHT (PRESERVATIVE),",
    "additional_descriptions": [],
    "market_country": "United States",
    "quality": {
      "nutrition_completeness": 0.8571,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "11/13/2020",
      "available_date": "4/26/2020",
      "modified_date": "4/26/2020",
      "source_data_type": "Branded",
      "source_food_class": "Branded",
      "is_historical_reference": false,
      "nutrient_basis_note": "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields.",
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "SPRING ROLL SKIN",
    "source": "usda_branded",
    "source_id": "1106628",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Crusts & Dough"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 2.13,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0.22,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 82.5,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 340,
          "unit": "kcal",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 860,
          "unit": "mg",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0.13,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        }
      ],
      "protein_100g": 2.13,
      "fat_100g": 0.22,
      "carbs_100g": 82.5,
      "kcal_100g": 340,
      "sugars_100g": 0,
      "fiber_100g": 0,
      "sodium_mg_100g": 860
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "100 GRM",
        "gram_weight": 100
      }
    ],
    "serving_size": 100,
    "serving_unit": "g",
    "household_serving_description": "100 GRM",
    "brand": "NOT A BRANDED ITEM",
    "brand_owner": "NOT A BRANDED ITEM",
    "barcode": "627404030169",
    "ingredients": "RICE FLOUR, TAPIOCA STARCH, WATER, SALT",
    "additional_descriptions": [],
    "market_country": "United States",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "11/13/2020",
      "available_date": "4/13/2020",
      "modified_date": "4/13/2020",
      "source_data_type": "Branded",
      "source_food_class": "Branded",
      "is_historical_reference": false,
      "nutrient_basis_note": "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields.",
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "CORN FRITTER MIX, CORN FRITTER MIX",
    "source": "usda_branded",
    "source_id": "1106864",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Cake, Cookie & Cupcake Mixes"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 85.7,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 343,
          "unit": "kcal",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 5.71,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 331,
          "unit": "mg",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        }
      ],
      "protein_100g": 0,
      "fat_100g": 0,
      "carbs_100g": 85.7,
      "kcal_100g": 343,
      "sugars_100g": 5.71,
      "fiber_100g": 0,
      "sodium_mg_100g": 331
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "17.5 GRM",
        "gram_weight": 17.5
      }
    ],
    "serving_size": 17.5,
    "serving_unit": "g",
    "household_serving_description": "17.5 GRM",
    "brand": "DEL SUR",
    "brand_owner": "DEL SUR",
    "barcode": "884789500506",
    "ingredients": "CORN STARCH, NATURAL MODIFIED TAPIOCA STARCH, DEXTROSE, SALT (SODIUM CHLORIDE) AND LEUDANTS (SODIUM BICARBOBNATE)",
    "additional_descriptions": [],
    "market_country": "United States",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "11/13/2020",
      "available_date": "4/26/2020",
      "modified_date": "4/26/2020",
      "source_data_type": "Branded",
      "source_food_class": "Branded",
      "is_historical_reference": false,
      "nutrient_basis_note": "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields.",
      "attribution": "USDA FoodData Central"
    }
  },
  {
    "schema_version": "1.0.0",
    "name": "PINEAPPLE & ORANGE HABANERO HOT SAUCE, PINEAPPLE & ORANGE HABANERO",
    "source": "usda_branded",
    "source_id": "1106915",
    "dataset_version": "2026-04-30",
    "category": {
      "name": "Ketchup, Mustard, BBQ & Cheese Sauce"
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "USDA FoodData Central nutrients per 100 g"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "1003",
          "name": "Protein",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1004",
          "name": "Total lipid (fat)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1005",
          "name": "Carbohydrate, by difference",
          "amount_100g": 13.3,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1008",
          "name": "Energy",
          "amount_100g": 67,
          "unit": "kcal",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "2000",
          "name": "Total Sugars",
          "amount_100g": 13.3,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1079",
          "name": "Fiber, total dietary",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1087",
          "name": "Calcium, Ca",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1089",
          "name": "Iron, Fe",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1093",
          "name": "Sodium, Na",
          "amount_100g": 200,
          "unit": "mg",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1104",
          "name": "Vitamin A, IU",
          "amount_100g": 667,
          "unit": "IU",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1162",
          "name": "Vitamin C, total ascorbic acid",
          "amount_100g": 16,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1253",
          "name": "Cholesterol",
          "amount_100g": 0,
          "unit": "mg",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1257",
          "name": "Fatty acids, total trans",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCS",
          "derivation_description": "Calculated from value per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        },
        {
          "source_key": "1258",
          "name": "Fatty acids, total saturated",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "LCCD",
          "derivation_description": "Calculated from a daily value percentage per serving size measure",
          "measurement_source": "Manufacturer's analytical; partial documentation"
        }
      ],
      "protein_100g": 0,
      "fat_100g": 0,
      "carbs_100g": 13.3,
      "kcal_100g": 67,
      "sugars_100g": 13.3,
      "fiber_100g": 0,
      "sodium_mg_100g": 200
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1 Tbsp",
        "gram_weight": 15
      }
    ],
    "serving_size": 15,
    "serving_unit": "g",
    "household_serving_description": "1 Tbsp",
    "brand": "GUNTHER'S GOURMET",
    "brand_owner": "GUNTHER'S GOURMET",
    "barcode": "813090000000",
    "ingredients": "CRUSHED PINEAPPLE, ORANGE JUICE, MANGO PUREE, DISTILLED VINEGAR, APPLE SAUCE, LEMON JUICE, SOY SAUCE (WATER, NON-GMO SOYBEANS, WHEAT, SALT), PURE HONEY, HABANERO PEPPERS, ROASTED GARLIC, SPICES AND SALT.",
    "additional_descriptions": [],
    "market_country": "United States",
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "usda_fdc_id",
        "per_100g_nutrients",
        "gram_portions",
        "nutrient_derivation"
      ]
    },
    "provenance": {
      "publication_date": "11/13/2020",
      "available_date": "9/12/2020",
      "modified_date": "9/12/2020",
      "source_data_type": "Branded",
      "source_food_class": "Branded",
      "is_historical_reference": false,
      "nutrient_basis_note": "Food nutrient amounts are USDA-normalized per 100 g; labelNutrients remain serving-basis and are not copied into per-100 g fields.",
      "attribution": "USDA FoodData Central"
    }
  }
]
```

## turkomp

- Dataset version: Site state as of 2026-08-22
- Input/output/skipped: 645 / 645 / 0
- Skip reasons: none
- Nutrition completeness: 89.57%
- Portion coverage: 0.00%
- Barcode coverage: 0.00%

### 10 normalized examples

```json
[
  {
    "schema_version": "1.0.0",
    "name": "Sütlü buz, vanilya aromalı",
    "source": "turkomp",
    "source_id": "1",
    "dataset_version": "Site state as of 2026-08-22",
    "category": {
      "name": "Süt ve süt ürünleri",
      "hierarchy": [
        "Süt ve süt ürünleri"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "edible portion"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2",
          "name": "Enerji",
          "amount_100g": 144,
          "unit": "kcal",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 144,
          "max": 144
        },
        {
          "source_key": "559",
          "name": "Enerji",
          "amount_100g": 602,
          "unit": "kJ",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 602,
          "max": 602
        },
        {
          "source_key": "1",
          "name": "Su",
          "amount_100g": 68.8,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 68.8,
          "max": 68.8
        },
        {
          "source_key": "5",
          "name": "Kül",
          "amount_100g": 0.79,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.79,
          "max": 0.79
        },
        {
          "source_key": "3",
          "name": "Protein",
          "amount_100g": 3.76,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.76,
          "max": 3.76
        },
        {
          "source_key": "109",
          "name": "Azot",
          "amount_100g": 0.59,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.59,
          "max": 0.59
        },
        {
          "source_key": "4",
          "name": "Yağ, toplam",
          "amount_100g": 4.44,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.44,
          "max": 4.44
        },
        {
          "source_key": "155",
          "name": "Karbonhidrat",
          "amount_100g": 22.21,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 22.21,
          "max": 22.21
        },
        {
          "source_key": "11",
          "name": "Lif, toplam diyet",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "10",
          "name": "Sakaroz",
          "amount_100g": 13.05,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 13.05,
          "max": 13.05
        },
        {
          "source_key": "100",
          "name": "Glukoz",
          "amount_100g": 1.1,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.1,
          "max": 1.1
        },
        {
          "source_key": "6",
          "name": "Fruktoz",
          "amount_100g": 1.22,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.22,
          "max": 1.22
        },
        {
          "source_key": "8",
          "name": "Laktoz",
          "amount_100g": 5.24,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 5.24,
          "max": 5.24
        },
        {
          "source_key": "9",
          "name": "Maltoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "35",
          "name": "Tiamin",
          "amount_100g": 0.061,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.061,
          "max": 0.061
        },
        {
          "source_key": "36",
          "name": "Riboflavin",
          "amount_100g": 0.179,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.179,
          "max": 0.179
        },
        {
          "source_key": "465",
          "name": "Niasin eşdeğerleri, toplam",
          "amount_100g": 1.115,
          "unit": "NE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.115,
          "max": 1.115
        },
        {
          "source_key": "37",
          "name": "Niasin",
          "amount_100g": 0.078,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.078,
          "max": 0.078
        },
        {
          "source_key": "38",
          "name": "B-6 vitamini, toplam",
          "amount_100g": 0.049,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.049,
          "max": 0.049
        },
        {
          "source_key": "105",
          "name": "Triptofan",
          "amount_100g": 62,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 62,
          "max": 62
        },
        {
          "source_key": "94",
          "name": "Treonin",
          "amount_100g": 106,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 106,
          "max": 106
        },
        {
          "source_key": "93",
          "name": "Izolosin",
          "amount_100g": 158,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 158,
          "max": 158
        },
        {
          "source_key": "92",
          "name": "Lösin",
          "amount_100g": 291,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 291,
          "max": 291
        },
        {
          "source_key": "102",
          "name": "Lizin",
          "amount_100g": 320,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 320,
          "max": 320
        },
        {
          "source_key": "98",
          "name": "Metiyonin",
          "amount_100g": 90,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 90,
          "max": 90
        },
        {
          "source_key": "106",
          "name": "Sistin",
          "amount_100g": 43,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 43,
          "max": 43
        },
        {
          "source_key": "101",
          "name": "Fenilalanin",
          "amount_100g": 131,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 131,
          "max": 131
        },
        {
          "source_key": "104",
          "name": "Tirozin",
          "amount_100g": 121,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 121,
          "max": 121
        },
        {
          "source_key": "91",
          "name": "Valin",
          "amount_100g": 187,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 187,
          "max": 187
        },
        {
          "source_key": "153",
          "name": "Arjinin",
          "amount_100g": 43,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 43,
          "max": 43
        },
        {
          "source_key": "103",
          "name": "Histidin",
          "amount_100g": 77,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 77,
          "max": 77
        },
        {
          "source_key": "89",
          "name": "Alanin",
          "amount_100g": 96,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 96,
          "max": 96
        },
        {
          "source_key": "97",
          "name": "Aspartik asit",
          "amount_100g": 127,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 127,
          "max": 127
        },
        {
          "source_key": "154",
          "name": "Glutamik asit",
          "amount_100g": 486,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 486,
          "max": 486
        },
        {
          "source_key": "90",
          "name": "Glisin",
          "amount_100g": 62,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 62,
          "max": 62
        },
        {
          "source_key": "96",
          "name": "Prolin",
          "amount_100g": 319,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 319,
          "max": 319
        },
        {
          "source_key": "95",
          "name": "Serin",
          "amount_100g": 131,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 131,
          "max": 131
        },
        {
          "source_key": "derived:sugars_sum",
          "name": "Total sugars (sum of published mono/disaccharides)",
          "amount_100g": 20.61,
          "unit": "g",
          "derivation_code": "SUM_COMPONENTS",
          "derivation_description": "Sum of 5 available TürKomp sugar components; not a separately published total"
        }
      ],
      "kcal_100g": 144,
      "protein_100g": 3.76,
      "fat_100g": 4.44,
      "carbs_100g": 22.21,
      "fiber_100g": 0,
      "sugars_100g": 20.61
    },
    "portions": [],
    "food_code": "01.02.0001",
    "classification_codes": [
      {
        "system": "LanguaL",
        "codes": [
          "A0227",
          "A0452",
          "A0719",
          "A0724",
          "A0740",
          "A0789",
          "A1080",
          "A1259",
          "B1161",
          "C0235",
          "E0119",
          "F0022",
          "G0001",
          "H0001",
          "J0142",
          "K0001",
          "M0001",
          "N0001",
          "P0026",
          "R0403",
          "Z0112"
        ]
      }
    ],
    "quality": {
      "nutrition_completeness": 0.8571,
      "confidence_inputs": [
        "published_average",
        "published_min_max",
        "per_100g_edible_portion",
        "derived_sugar_component_sum"
      ]
    },
    "provenance": {
      "source_url": "https://turkomp.tarimorman.gov.tr/food-sutlu-buz-vanilya-aromali-1",
      "nutrient_basis_note": "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.",
      "attribution": "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı"
    },
    "nutrient_conversion_factors": [
      {
        "type": "nitrogen",
        "value": 6.38
      },
      {
        "type": "fat",
        "value": 0.945
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Yoğurt, kaymaklı",
    "source": "turkomp",
    "source_id": "2",
    "dataset_version": "Site state as of 2026-08-22",
    "category": {
      "name": "Süt ve süt ürünleri",
      "hierarchy": [
        "Süt ve süt ürünleri"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "edible portion"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2",
          "name": "Enerji",
          "amount_100g": 77,
          "unit": "kcal",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 77,
          "max": 77
        },
        {
          "source_key": "559",
          "name": "Enerji",
          "amount_100g": 320,
          "unit": "kJ",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 320,
          "max": 320
        },
        {
          "source_key": "1",
          "name": "Su",
          "amount_100g": 86.02,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 86.02,
          "max": 86.02
        },
        {
          "source_key": "5",
          "name": "Kül",
          "amount_100g": 1.12,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.12,
          "max": 1.12
        },
        {
          "source_key": "3",
          "name": "Protein",
          "amount_100g": 4.91,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.91,
          "max": 4.91
        },
        {
          "source_key": "109",
          "name": "Azot",
          "amount_100g": 0.77,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.77,
          "max": 0.77
        },
        {
          "source_key": "4",
          "name": "Yağ, toplam",
          "amount_100g": 5.02,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 5.02,
          "max": 5.02
        },
        {
          "source_key": "155",
          "name": "Karbonhidrat",
          "amount_100g": 2.93,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.93,
          "max": 2.93
        },
        {
          "source_key": "11",
          "name": "Lif, toplam diyet",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "8",
          "name": "Laktoz",
          "amount_100g": 2.93,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.93,
          "max": 2.93
        },
        {
          "source_key": "461",
          "name": "Tuz",
          "amount_100g": 129,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 129,
          "max": 129
        },
        {
          "source_key": "22",
          "name": "Demir, Fe",
          "amount_100g": 0.04,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.04,
          "max": 0.04
        },
        {
          "source_key": "24",
          "name": "Fosfor, P",
          "amount_100g": 104,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 104,
          "max": 104
        },
        {
          "source_key": "21",
          "name": "Kalsiyum, Ca",
          "amount_100g": 126,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 126,
          "max": 126
        },
        {
          "source_key": "23",
          "name": "Magnezyum, Mg",
          "amount_100g": 13,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 13,
          "max": 13
        },
        {
          "source_key": "25",
          "name": "Potasyum, K",
          "amount_100g": 179,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 179,
          "max": 179
        },
        {
          "source_key": "26",
          "name": "Sodyum, Na",
          "amount_100g": 52,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 52,
          "max": 52
        },
        {
          "source_key": "27",
          "name": "Çinko, Zn",
          "amount_100g": 0.38,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.38,
          "max": 0.38
        },
        {
          "source_key": "30",
          "name": "Selenyum, Se",
          "amount_100g": 1.3,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.3,
          "max": 1.3
        },
        {
          "source_key": "35",
          "name": "Tiamin",
          "amount_100g": 0.054,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.054,
          "max": 0.054
        },
        {
          "source_key": "36",
          "name": "Riboflavin",
          "amount_100g": 0.231,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.231,
          "max": 0.231
        },
        {
          "source_key": "465",
          "name": "Niasin eşdeğerleri, toplam",
          "amount_100g": 0.795,
          "unit": "NE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.795,
          "max": 0.795
        },
        {
          "source_key": "38",
          "name": "B-6 vitamini, toplam",
          "amount_100g": 0.035,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.035,
          "max": 0.035
        },
        {
          "source_key": "562",
          "name": "Folat, gıda",
          "amount_100g": 6,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6,
          "max": 6
        },
        {
          "source_key": "41",
          "name": "B-12 vitamini",
          "amount_100g": 0.42,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.42,
          "max": 0.42
        },
        {
          "source_key": "139",
          "name": "A vitamini",
          "amount_100g": 40,
          "unit": "RE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 40,
          "max": 40
        },
        {
          "source_key": "43",
          "name": "Retinol",
          "amount_100g": 40,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 40,
          "max": 40
        },
        {
          "source_key": "561",
          "name": "D vitamini, IU",
          "amount_100g": 74,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 74,
          "max": 74
        },
        {
          "source_key": "50",
          "name": "D-3 vitamini (kolekalsiferol)",
          "amount_100g": 1.9,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.9,
          "max": 1.9
        },
        {
          "source_key": "540",
          "name": "E vitamini",
          "amount_100g": 0.14,
          "unit": "α-TE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.14,
          "max": 0.14
        },
        {
          "source_key": "560",
          "name": "E vitamini, IU",
          "amount_100g": 0.21,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.21,
          "max": 0.21
        },
        {
          "source_key": "49",
          "name": "Alfa-tokoferol",
          "amount_100g": 0.14,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.14,
          "max": 0.14
        },
        {
          "source_key": "54",
          "name": "K-2 vitamini",
          "amount_100g": 1.9,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.9,
          "max": 1.9
        },
        {
          "source_key": "145",
          "name": "Yağ asitleri, toplam doymuş",
          "amount_100g": 2.72,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.72,
          "max": 2.72
        },
        {
          "source_key": "146",
          "name": "Yağ asitleri, toplam tekli doymamış",
          "amount_100g": 0.8,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.8,
          "max": 0.8
        },
        {
          "source_key": "147",
          "name": "Yağ asitleri, toplam çoklu doymamış",
          "amount_100g": 0.078,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.078,
          "max": 0.078
        },
        {
          "source_key": "55",
          "name": "Yağ asidi 4:0 (bütirik asit)",
          "amount_100g": 0.112,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.112,
          "max": 0.112
        },
        {
          "source_key": "56",
          "name": "Yağ asidi 6:0 (kaproik asit)",
          "amount_100g": 0.062,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.062,
          "max": 0.062
        },
        {
          "source_key": "57",
          "name": "Yağ asidi 8:0 (kaprilik asit)",
          "amount_100g": 0.041,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.041,
          "max": 0.041
        },
        {
          "source_key": "58",
          "name": "Yağ asidi 10:0 (kaprik asit)",
          "amount_100g": 0.081,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.081,
          "max": 0.081
        },
        {
          "source_key": "59",
          "name": "Yağ asidi 12:0 (laurik asit)",
          "amount_100g": 0.125,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.125,
          "max": 0.125
        },
        {
          "source_key": "60",
          "name": "Yağ asidi 14:0 (miristik asit)",
          "amount_100g": 0.402,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.402,
          "max": 0.402
        },
        {
          "source_key": "62",
          "name": "Yağ asidi 16:0 (palmitik asit)",
          "amount_100g": 1.309,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.309,
          "max": 1.309
        },
        {
          "source_key": "64",
          "name": "Yağ asidi 18:0 (stearik asit)",
          "amount_100g": 0.587,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.587,
          "max": 0.587
        },
        {
          "source_key": "67",
          "name": "Yağ asidi 24:0 (lignoserik asit)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "70",
          "name": "Yağ asidi 18:1 n-9 cis (oleik asit)",
          "amount_100g": 0.8,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.8,
          "max": 0.8
        },
        {
          "source_key": "75",
          "name": "Yağ asidi 18:2 n-6 cis,cis",
          "amount_100g": 0.078,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.078,
          "max": 0.078
        },
        {
          "source_key": "557",
          "name": "Kolesterol",
          "amount_100g": 12,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 12,
          "max": 12
        },
        {
          "source_key": "105",
          "name": "Triptofan",
          "amount_100g": 48,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 48,
          "max": 48
        },
        {
          "source_key": "94",
          "name": "Treonin",
          "amount_100g": 154,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 154,
          "max": 154
        },
        {
          "source_key": "93",
          "name": "Izolosin",
          "amount_100g": 181,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 181,
          "max": 181
        },
        {
          "source_key": "92",
          "name": "Lösin",
          "amount_100g": 386,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 386,
          "max": 386
        },
        {
          "source_key": "102",
          "name": "Lizin",
          "amount_100g": 594,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 594,
          "max": 594
        },
        {
          "source_key": "98",
          "name": "Metiyonin",
          "amount_100g": 103,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 103,
          "max": 103
        },
        {
          "source_key": "106",
          "name": "Sistin",
          "amount_100g": 50,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 50,
          "max": 50
        },
        {
          "source_key": "101",
          "name": "Fenilalanin",
          "amount_100g": 201,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 201,
          "max": 201
        },
        {
          "source_key": "104",
          "name": "Tirozin",
          "amount_100g": 188,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 188,
          "max": 188
        },
        {
          "source_key": "91",
          "name": "Valin",
          "amount_100g": 193,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 193,
          "max": 193
        },
        {
          "source_key": "153",
          "name": "Arjinin",
          "amount_100g": 97,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 97,
          "max": 97
        },
        {
          "source_key": "103",
          "name": "Histidin",
          "amount_100g": 112,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 112,
          "max": 112
        },
        {
          "source_key": "89",
          "name": "Alanin",
          "amount_100g": 158,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 158,
          "max": 158
        },
        {
          "source_key": "97",
          "name": "Aspartik asit",
          "amount_100g": 353,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 353,
          "max": 353
        },
        {
          "source_key": "154",
          "name": "Glutamik asit",
          "amount_100g": 860,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 860,
          "max": 860
        },
        {
          "source_key": "90",
          "name": "Glisin",
          "amount_100g": 84,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 84,
          "max": 84
        },
        {
          "source_key": "96",
          "name": "Prolin",
          "amount_100g": 504,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 504,
          "max": 504
        },
        {
          "source_key": "95",
          "name": "Serin",
          "amount_100g": 210,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 210,
          "max": 210
        },
        {
          "source_key": "derived:sugars_sum",
          "name": "Total sugars (sum of published mono/disaccharides)",
          "amount_100g": 2.93,
          "unit": "g",
          "derivation_code": "SUM_COMPONENTS",
          "derivation_description": "Sum of 1 available TürKomp sugar components; not a separately published total"
        }
      ],
      "kcal_100g": 77,
      "protein_100g": 4.91,
      "fat_100g": 5.02,
      "carbs_100g": 2.93,
      "fiber_100g": 0,
      "sodium_mg_100g": 52,
      "sugars_100g": 2.93
    },
    "portions": [],
    "food_code": "01.02.0019",
    "classification_codes": [
      {
        "system": "LanguaL",
        "codes": [
          "A0452",
          "A0783",
          "A1049",
          "B1161",
          "C0235",
          "E0119",
          "F0022",
          "G0001",
          "H0753",
          "J0120",
          "K0001",
          "M0001",
          "N0001",
          "P0026",
          "P0195",
          "Z0109",
          "Z0112"
        ]
      }
    ],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "published_average",
        "published_min_max",
        "per_100g_edible_portion",
        "derived_sugar_component_sum"
      ]
    },
    "provenance": {
      "source_url": "https://turkomp.tarimorman.gov.tr/food-yogurt-kaymakli-2",
      "nutrient_basis_note": "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.",
      "attribution": "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı"
    },
    "nutrient_conversion_factors": [
      {
        "type": "nitrogen",
        "value": 6.38
      },
      {
        "type": "fat",
        "value": 0.945
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Yoğurt, homojenize, yarım yağlı (% 2 > süt yağı ≥ % 1.5)",
    "source": "turkomp",
    "source_id": "3",
    "dataset_version": "Site state as of 2026-08-22",
    "category": {
      "name": "Süt ve süt ürünleri",
      "hierarchy": [
        "Süt ve süt ürünleri"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "edible portion"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2",
          "name": "Enerji",
          "amount_100g": 49,
          "unit": "kcal",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 49,
          "max": 49
        },
        {
          "source_key": "559",
          "name": "Enerji",
          "amount_100g": 203,
          "unit": "kJ",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 203,
          "max": 203
        },
        {
          "source_key": "1",
          "name": "Su",
          "amount_100g": 89.02,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 89.02,
          "max": 89.02
        },
        {
          "source_key": "5",
          "name": "Kül",
          "amount_100g": 1.04,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.04,
          "max": 1.04
        },
        {
          "source_key": "3",
          "name": "Protein",
          "amount_100g": 4.27,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.27,
          "max": 4.27
        },
        {
          "source_key": "109",
          "name": "Azot",
          "amount_100g": 0.67,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.67,
          "max": 0.67
        },
        {
          "source_key": "4",
          "name": "Yağ, toplam",
          "amount_100g": 1.76,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.76,
          "max": 1.76
        },
        {
          "source_key": "155",
          "name": "Karbonhidrat",
          "amount_100g": 3.91,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.91,
          "max": 3.91
        },
        {
          "source_key": "11",
          "name": "Lif, toplam diyet",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "8",
          "name": "Laktoz",
          "amount_100g": 3.38,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.38,
          "max": 3.38
        },
        {
          "source_key": "461",
          "name": "Tuz",
          "amount_100g": 129,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 129,
          "max": 129
        },
        {
          "source_key": "22",
          "name": "Demir, Fe",
          "amount_100g": 0.03,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.03,
          "max": 0.03
        },
        {
          "source_key": "24",
          "name": "Fosfor, P",
          "amount_100g": 104,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 104,
          "max": 104
        },
        {
          "source_key": "21",
          "name": "Kalsiyum, Ca",
          "amount_100g": 130,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 130,
          "max": 130
        },
        {
          "source_key": "23",
          "name": "Magnezyum, Mg",
          "amount_100g": 13,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 13,
          "max": 13
        },
        {
          "source_key": "25",
          "name": "Potasyum, K",
          "amount_100g": 189,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 189,
          "max": 189
        },
        {
          "source_key": "26",
          "name": "Sodyum, Na",
          "amount_100g": 51,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 51,
          "max": 51
        },
        {
          "source_key": "27",
          "name": "Çinko, Zn",
          "amount_100g": 0.39,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.39,
          "max": 0.39
        },
        {
          "source_key": "30",
          "name": "Selenyum, Se",
          "amount_100g": 1.4,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.4,
          "max": 1.4
        },
        {
          "source_key": "35",
          "name": "Tiamin",
          "amount_100g": 0.047,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.047,
          "max": 0.047
        },
        {
          "source_key": "36",
          "name": "Riboflavin",
          "amount_100g": 0.21,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.21,
          "max": 0.21
        },
        {
          "source_key": "465",
          "name": "Niasin eşdeğerleri, toplam",
          "amount_100g": 0.765,
          "unit": "NE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.765,
          "max": 0.765
        },
        {
          "source_key": "37",
          "name": "Niasin",
          "amount_100g": 0.142,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.142,
          "max": 0.142
        },
        {
          "source_key": "38",
          "name": "B-6 vitamini, toplam",
          "amount_100g": 0.028,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.028,
          "max": 0.028
        },
        {
          "source_key": "562",
          "name": "Folat, gıda",
          "amount_100g": 4,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4,
          "max": 4
        },
        {
          "source_key": "41",
          "name": "B-12 vitamini",
          "amount_100g": 0.44,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.44,
          "max": 0.44
        },
        {
          "source_key": "139",
          "name": "A vitamini",
          "amount_100g": 14,
          "unit": "RE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 14,
          "max": 14
        },
        {
          "source_key": "43",
          "name": "Retinol",
          "amount_100g": 14,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 14,
          "max": 14
        },
        {
          "source_key": "561",
          "name": "D vitamini, IU",
          "amount_100g": 29,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 29,
          "max": 29
        },
        {
          "source_key": "50",
          "name": "D-3 vitamini (kolekalsiferol)",
          "amount_100g": 0.7,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.7,
          "max": 0.7
        },
        {
          "source_key": "540",
          "name": "E vitamini",
          "amount_100g": 0.05,
          "unit": "α-TE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.05,
          "max": 0.05
        },
        {
          "source_key": "560",
          "name": "E vitamini, IU",
          "amount_100g": 0.08,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.08,
          "max": 0.08
        },
        {
          "source_key": "49",
          "name": "Alfa-tokoferol",
          "amount_100g": 0.05,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.05,
          "max": 0.05
        },
        {
          "source_key": "54",
          "name": "K-2 vitamini",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "557",
          "name": "Kolesterol",
          "amount_100g": 6,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6,
          "max": 6
        },
        {
          "source_key": "105",
          "name": "Triptofan",
          "amount_100g": 37,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 37,
          "max": 37
        },
        {
          "source_key": "94",
          "name": "Treonin",
          "amount_100g": 136,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 136,
          "max": 136
        },
        {
          "source_key": "93",
          "name": "Izolosin",
          "amount_100g": 160,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 160,
          "max": 160
        },
        {
          "source_key": "92",
          "name": "Lösin",
          "amount_100g": 344,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 344,
          "max": 344
        },
        {
          "source_key": "102",
          "name": "Lizin",
          "amount_100g": 514,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 514,
          "max": 514
        },
        {
          "source_key": "98",
          "name": "Metiyonin",
          "amount_100g": 92,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 92,
          "max": 92
        },
        {
          "source_key": "106",
          "name": "Sistin",
          "amount_100g": 44,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 44,
          "max": 44
        },
        {
          "source_key": "101",
          "name": "Fenilalanin",
          "amount_100g": 176,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 176,
          "max": 176
        },
        {
          "source_key": "104",
          "name": "Tirozin",
          "amount_100g": 171,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 171,
          "max": 171
        },
        {
          "source_key": "91",
          "name": "Valin",
          "amount_100g": 174,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 174,
          "max": 174
        },
        {
          "source_key": "153",
          "name": "Arjinin",
          "amount_100g": 91,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 91,
          "max": 91
        },
        {
          "source_key": "103",
          "name": "Histidin",
          "amount_100g": 103,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 103,
          "max": 103
        },
        {
          "source_key": "89",
          "name": "Alanin",
          "amount_100g": 152,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 152,
          "max": 152
        },
        {
          "source_key": "97",
          "name": "Aspartik asit",
          "amount_100g": 303,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 303,
          "max": 303
        },
        {
          "source_key": "154",
          "name": "Glutamik asit",
          "amount_100g": 753,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 753,
          "max": 753
        },
        {
          "source_key": "90",
          "name": "Glisin",
          "amount_100g": 77,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 77,
          "max": 77
        },
        {
          "source_key": "96",
          "name": "Prolin",
          "amount_100g": 436,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 436,
          "max": 436
        },
        {
          "source_key": "95",
          "name": "Serin",
          "amount_100g": 191,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 191,
          "max": 191
        },
        {
          "source_key": "derived:sugars_sum",
          "name": "Total sugars (sum of published mono/disaccharides)",
          "amount_100g": 3.38,
          "unit": "g",
          "derivation_code": "SUM_COMPONENTS",
          "derivation_description": "Sum of 1 available TürKomp sugar components; not a separately published total"
        }
      ],
      "kcal_100g": 49,
      "protein_100g": 4.27,
      "fat_100g": 1.76,
      "carbs_100g": 3.91,
      "fiber_100g": 0,
      "sodium_mg_100g": 51,
      "sugars_100g": 3.38
    },
    "portions": [],
    "food_code": "01.02.0016",
    "classification_codes": [
      {
        "system": "LanguaL",
        "codes": [
          "A0452",
          "A0783",
          "A1049",
          "A1271",
          "B1201",
          "C0235",
          "E0119",
          "F0022",
          "G0001",
          "H0247",
          "H0753",
          "J0120",
          "K0001",
          "M0172",
          "M0208",
          "N0001",
          "P0026",
          "R0403",
          "Z0112"
        ]
      }
    ],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "published_average",
        "published_min_max",
        "per_100g_edible_portion",
        "derived_sugar_component_sum"
      ]
    },
    "provenance": {
      "source_url": "https://turkomp.tarimorman.gov.tr/food-yogurt-homojenize-yarim-yagli--2--sut-yagi---1-5-3",
      "nutrient_basis_note": "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.",
      "attribution": "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı"
    },
    "nutrient_conversion_factors": [
      {
        "type": "nitrogen",
        "value": 6.38
      },
      {
        "type": "fat",
        "value": 0.945
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Yoğurt, homojenize, tam yağlı (süt yağı ≥ % 3.8)",
    "source": "turkomp",
    "source_id": "4",
    "dataset_version": "Site state as of 2026-08-22",
    "category": {
      "name": "Süt ve süt ürünleri",
      "hierarchy": [
        "Süt ve süt ürünleri"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "edible portion"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2",
          "name": "Enerji",
          "amount_100g": 69,
          "unit": "kcal",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 69,
          "max": 69
        },
        {
          "source_key": "559",
          "name": "Enerji",
          "amount_100g": 290,
          "unit": "kJ",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 290,
          "max": 290
        },
        {
          "source_key": "1",
          "name": "Su",
          "amount_100g": 86.39,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 86.39,
          "max": 86.39
        },
        {
          "source_key": "5",
          "name": "Kül",
          "amount_100g": 1.04,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.04,
          "max": 1.04
        },
        {
          "source_key": "3",
          "name": "Protein",
          "amount_100g": 4.53,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.53,
          "max": 4.53
        },
        {
          "source_key": "109",
          "name": "Azot",
          "amount_100g": 0.71,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.71,
          "max": 0.71
        },
        {
          "source_key": "4",
          "name": "Yağ, toplam",
          "amount_100g": 3.8,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.8,
          "max": 3.8
        },
        {
          "source_key": "155",
          "name": "Karbonhidrat",
          "amount_100g": 4.24,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.24,
          "max": 4.24
        },
        {
          "source_key": "12",
          "name": "Lif, suda çözünür",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "8",
          "name": "Laktoz",
          "amount_100g": 4.28,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.28,
          "max": 4.28
        },
        {
          "source_key": "461",
          "name": "Tuz",
          "amount_100g": 132,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 132,
          "max": 132
        },
        {
          "source_key": "22",
          "name": "Demir, Fe",
          "amount_100g": 0.03,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.03,
          "max": 0.03
        },
        {
          "source_key": "24",
          "name": "Fosfor, P",
          "amount_100g": 110,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 110,
          "max": 110
        },
        {
          "source_key": "21",
          "name": "Kalsiyum, Ca",
          "amount_100g": 132,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 132,
          "max": 132
        },
        {
          "source_key": "23",
          "name": "Magnezyum, Mg",
          "amount_100g": 13,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 13,
          "max": 13
        },
        {
          "source_key": "25",
          "name": "Potasyum, K",
          "amount_100g": 191,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 191,
          "max": 191
        },
        {
          "source_key": "26",
          "name": "Sodyum, Na",
          "amount_100g": 53,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 53,
          "max": 53
        },
        {
          "source_key": "27",
          "name": "Çinko, Zn",
          "amount_100g": 0.4,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.4,
          "max": 0.4
        },
        {
          "source_key": "30",
          "name": "Selenyum, Se",
          "amount_100g": 1.7,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.7,
          "max": 1.7
        },
        {
          "source_key": "35",
          "name": "Tiamin",
          "amount_100g": 0.048,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.048,
          "max": 0.048
        },
        {
          "source_key": "36",
          "name": "Riboflavin",
          "amount_100g": 0.2,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.2,
          "max": 0.2
        },
        {
          "source_key": "465",
          "name": "Niasin eşdeğerleri, toplam",
          "amount_100g": 0.846,
          "unit": "NE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.846,
          "max": 0.846
        },
        {
          "source_key": "37",
          "name": "Niasin",
          "amount_100g": 0.166,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.166,
          "max": 0.166
        },
        {
          "source_key": "38",
          "name": "B-6 vitamini, toplam",
          "amount_100g": 0.023,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.023,
          "max": 0.023
        },
        {
          "source_key": "562",
          "name": "Folat, gıda",
          "amount_100g": 18,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 18,
          "max": 18
        },
        {
          "source_key": "41",
          "name": "B-12 vitamini",
          "amount_100g": 0.42,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.42,
          "max": 0.42
        },
        {
          "source_key": "139",
          "name": "A vitamini",
          "amount_100g": 30,
          "unit": "RE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 30,
          "max": 30
        },
        {
          "source_key": "43",
          "name": "Retinol",
          "amount_100g": 30,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 30,
          "max": 30
        },
        {
          "source_key": "561",
          "name": "D vitamini, IU",
          "amount_100g": 44,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 44,
          "max": 44
        },
        {
          "source_key": "50",
          "name": "D-3 vitamini (kolekalsiferol)",
          "amount_100g": 1.1,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.1,
          "max": 1.1
        },
        {
          "source_key": "540",
          "name": "E vitamini",
          "amount_100g": 0.11,
          "unit": "α-TE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.11,
          "max": 0.11
        },
        {
          "source_key": "560",
          "name": "E vitamini, IU",
          "amount_100g": 0.16,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.16,
          "max": 0.16
        },
        {
          "source_key": "49",
          "name": "Alfa-tokoferol",
          "amount_100g": 0.11,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.11,
          "max": 0.11
        },
        {
          "source_key": "54",
          "name": "K-2 vitamini",
          "amount_100g": 1.8,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.8,
          "max": 1.8
        },
        {
          "source_key": "145",
          "name": "Yağ asitleri, toplam doymuş",
          "amount_100g": 2.265,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.265,
          "max": 2.265
        },
        {
          "source_key": "146",
          "name": "Yağ asitleri, toplam tekli doymamış",
          "amount_100g": 1.058,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.058,
          "max": 1.058
        },
        {
          "source_key": "147",
          "name": "Yağ asitleri, toplam çoklu doymamış",
          "amount_100g": 0.083,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.083,
          "max": 0.083
        },
        {
          "source_key": "55",
          "name": "Yağ asidi 4:0 (bütirik asit)",
          "amount_100g": 0.076,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.076,
          "max": 0.076
        },
        {
          "source_key": "56",
          "name": "Yağ asidi 6:0 (kaproik asit)",
          "amount_100g": 0.054,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.054,
          "max": 0.054
        },
        {
          "source_key": "57",
          "name": "Yağ asidi 8:0 (kaprilik asit)",
          "amount_100g": 0.033,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.033,
          "max": 0.033
        },
        {
          "source_key": "58",
          "name": "Yağ asidi 10:0 (kaprik asit)",
          "amount_100g": 0.077,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.077,
          "max": 0.077
        },
        {
          "source_key": "59",
          "name": "Yağ asidi 12:0 (laurik asit)",
          "amount_100g": 0.095,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.095,
          "max": 0.095
        },
        {
          "source_key": "60",
          "name": "Yağ asidi 14:0 (miristik asit)",
          "amount_100g": 0.364,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.364,
          "max": 0.364
        },
        {
          "source_key": "61",
          "name": "Yağ asidi 15:0 (pentadesilik asit )",
          "amount_100g": 0.041,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.041,
          "max": 0.041
        },
        {
          "source_key": "62",
          "name": "Yağ asidi 16:0 (palmitik asit)",
          "amount_100g": 1.083,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.083,
          "max": 1.083
        },
        {
          "source_key": "63",
          "name": "Yağ asidi 17:0 (margarik asit)",
          "amount_100g": 0.024,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.024,
          "max": 0.024
        },
        {
          "source_key": "64",
          "name": "Yağ asidi 18:0 (stearik asit)",
          "amount_100g": 0.409,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.409,
          "max": 0.409
        },
        {
          "source_key": "65",
          "name": "Yağ asidi 20:0 (araşidik asit)",
          "amount_100g": 0.006,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.006,
          "max": 0.006
        },
        {
          "source_key": "66",
          "name": "Yağ asidi 22:0 (behenik asit)",
          "amount_100g": 0.003,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.003,
          "max": 0.003
        },
        {
          "source_key": "67",
          "name": "Yağ asidi 24:0 (lignoserik asit)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "68",
          "name": "Yağ asidi 14:1 n-5 cis (miristoleik asit)",
          "amount_100g": 0.056,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.056,
          "max": 0.056
        },
        {
          "source_key": "69",
          "name": "Yağ asidi 16:1 n-7 cis (palmitoleik asit)",
          "amount_100g": 0.021,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.021,
          "max": 0.021
        },
        {
          "source_key": "70",
          "name": "Yağ asidi 18:1 n-9 cis (oleik asit)",
          "amount_100g": 0.846,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.846,
          "max": 0.846
        },
        {
          "source_key": "71",
          "name": "Yağ asidi 18:1 n-9 trans (elaidik asit)",
          "amount_100g": 0.1,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.1,
          "max": 0.1
        },
        {
          "source_key": "344",
          "name": "Yağ asidi 20:1 n-9 cis",
          "amount_100g": 0.036,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.036,
          "max": 0.036
        },
        {
          "source_key": "73",
          "name": "Yağ asidi 22:1 n-9 cis (erüsik asit)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "74",
          "name": "Yağ asidi 24:1 n-9 cis",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "75",
          "name": "Yağ asidi 18:2 n-6 cis,cis",
          "amount_100g": 0.068,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.068,
          "max": 0.068
        },
        {
          "source_key": "76",
          "name": "Yağ asidi 18:3 n-3 all-cis",
          "amount_100g": 0.01,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.01,
          "max": 0.01
        },
        {
          "source_key": "77",
          "name": "Yağ asidi 18:3 n-6 all-cis",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "358",
          "name": "Yağ asidi 20:4 n-6 all-cis",
          "amount_100g": 0.005,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.005,
          "max": 0.005
        },
        {
          "source_key": "80",
          "name": "Yağ asidi 20:5 n-3 all-cis",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "83",
          "name": "Yağ asidi 22:6 n-3 all-cis",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "557",
          "name": "Kolesterol",
          "amount_100g": 10,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 10,
          "max": 10
        },
        {
          "source_key": "105",
          "name": "Triptofan",
          "amount_100g": 41,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 41,
          "max": 41
        },
        {
          "source_key": "94",
          "name": "Treonin",
          "amount_100g": 153,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 153,
          "max": 153
        },
        {
          "source_key": "93",
          "name": "Izolosin",
          "amount_100g": 168,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 168,
          "max": 168
        },
        {
          "source_key": "92",
          "name": "Lösin",
          "amount_100g": 359,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 359,
          "max": 359
        },
        {
          "source_key": "102",
          "name": "Lizin",
          "amount_100g": 552,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 552,
          "max": 552
        },
        {
          "source_key": "98",
          "name": "Metiyonin",
          "amount_100g": 97,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 97,
          "max": 97
        },
        {
          "source_key": "106",
          "name": "Sistin",
          "amount_100g": 47,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 47,
          "max": 47
        },
        {
          "source_key": "101",
          "name": "Fenilalanin",
          "amount_100g": 186,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 186,
          "max": 186
        },
        {
          "source_key": "104",
          "name": "Tirozin",
          "amount_100g": 174,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 174,
          "max": 174
        },
        {
          "source_key": "91",
          "name": "Valin",
          "amount_100g": 181,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 181,
          "max": 181
        },
        {
          "source_key": "153",
          "name": "Arjinin",
          "amount_100g": 93,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 93,
          "max": 93
        },
        {
          "source_key": "103",
          "name": "Histidin",
          "amount_100g": 102,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 102,
          "max": 102
        },
        {
          "source_key": "89",
          "name": "Alanin",
          "amount_100g": 147,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 147,
          "max": 147
        },
        {
          "source_key": "97",
          "name": "Aspartik asit",
          "amount_100g": 331,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 331,
          "max": 331
        },
        {
          "source_key": "154",
          "name": "Glutamik asit",
          "amount_100g": 804,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 804,
          "max": 804
        },
        {
          "source_key": "90",
          "name": "Glisin",
          "amount_100g": 78,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 78,
          "max": 78
        },
        {
          "source_key": "96",
          "name": "Prolin",
          "amount_100g": 468,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 468,
          "max": 468
        },
        {
          "source_key": "95",
          "name": "Serin",
          "amount_100g": 197,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 197,
          "max": 197
        },
        {
          "source_key": "derived:sugars_sum",
          "name": "Total sugars (sum of published mono/disaccharides)",
          "amount_100g": 4.28,
          "unit": "g",
          "derivation_code": "SUM_COMPONENTS",
          "derivation_description": "Sum of 1 available TürKomp sugar components; not a separately published total"
        }
      ],
      "kcal_100g": 69,
      "protein_100g": 4.53,
      "fat_100g": 3.8,
      "carbs_100g": 4.24,
      "sodium_mg_100g": 53,
      "sugars_100g": 4.28
    },
    "portions": [],
    "food_code": "01.02.0015",
    "classification_codes": [
      {
        "system": "LanguaL",
        "codes": [
          "A0452",
          "A0783",
          "A1049",
          "B1201",
          "C0235",
          "E0135",
          "F0022",
          "G0001",
          "H0753",
          "J0120",
          "K0001",
          "M0172",
          "M0194",
          "M0208",
          "N0001",
          "P0026",
          "P0195",
          "R0403",
          "Z0112"
        ]
      }
    ],
    "quality": {
      "nutrition_completeness": 0.8571,
      "confidence_inputs": [
        "published_average",
        "published_min_max",
        "per_100g_edible_portion",
        "derived_sugar_component_sum"
      ]
    },
    "provenance": {
      "source_url": "https://turkomp.tarimorman.gov.tr/food-yogurt-homojenize-tam-yagli-sut-yagi---3-8-4",
      "nutrient_basis_note": "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.",
      "attribution": "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı"
    },
    "nutrient_conversion_factors": [
      {
        "type": "nitrogen",
        "value": 6.38
      },
      {
        "type": "fat",
        "value": 0.945
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Kaymak, pastörize (süt yağı ≥ % 60)",
    "source": "turkomp",
    "source_id": "5",
    "dataset_version": "Site state as of 2026-08-22",
    "category": {
      "name": "Süt ve süt ürünleri",
      "hierarchy": [
        "Süt ve süt ürünleri"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "edible portion"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2",
          "name": "Enerji",
          "amount_100g": 585,
          "unit": "kcal",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 585,
          "max": 585
        },
        {
          "source_key": "559",
          "name": "Enerji",
          "amount_100g": 2448,
          "unit": "kJ",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2448,
          "max": 2448
        },
        {
          "source_key": "1",
          "name": "Su",
          "amount_100g": 32.4,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 32.4,
          "max": 32.4
        },
        {
          "source_key": "5",
          "name": "Kül",
          "amount_100g": 0.23,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.23,
          "max": 0.23
        },
        {
          "source_key": "3",
          "name": "Protein",
          "amount_100g": 0.96,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.96,
          "max": 0.96
        },
        {
          "source_key": "109",
          "name": "Azot",
          "amount_100g": 0.15,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.15,
          "max": 0.15
        },
        {
          "source_key": "4",
          "name": "Yağ, toplam",
          "amount_100g": 63.1,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 63.1,
          "max": 63.1
        },
        {
          "source_key": "155",
          "name": "Karbonhidrat",
          "amount_100g": 3.31,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.31,
          "max": 3.31
        },
        {
          "source_key": "11",
          "name": "Lif, toplam diyet",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "10",
          "name": "Sakaroz",
          "amount_100g": 0.39,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.39,
          "max": 0.39
        },
        {
          "source_key": "100",
          "name": "Glukoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "6",
          "name": "Fruktoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "8",
          "name": "Laktoz",
          "amount_100g": 0.91,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.91,
          "max": 0.91
        },
        {
          "source_key": "9",
          "name": "Maltoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "461",
          "name": "Tuz",
          "amount_100g": 47,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 47,
          "max": 47
        },
        {
          "source_key": "22",
          "name": "Demir, Fe",
          "amount_100g": 0.14,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.14,
          "max": 0.14
        },
        {
          "source_key": "24",
          "name": "Fosfor, P",
          "amount_100g": 70,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 70,
          "max": 70
        },
        {
          "source_key": "21",
          "name": "Kalsiyum, Ca",
          "amount_100g": 45,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 45,
          "max": 45
        },
        {
          "source_key": "23",
          "name": "Magnezyum, Mg",
          "amount_100g": 6,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6,
          "max": 6
        },
        {
          "source_key": "25",
          "name": "Potasyum, K",
          "amount_100g": 91,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 91,
          "max": 91
        },
        {
          "source_key": "26",
          "name": "Sodyum, Na",
          "amount_100g": 19,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 19,
          "max": 19
        },
        {
          "source_key": "27",
          "name": "Çinko, Zn",
          "amount_100g": 2.93,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.93,
          "max": 2.93
        },
        {
          "source_key": "30",
          "name": "Selenyum, Se",
          "amount_100g": 14.3,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 14.3,
          "max": 14.3
        },
        {
          "source_key": "35",
          "name": "Tiamin",
          "amount_100g": 0.013,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.013,
          "max": 0.013
        },
        {
          "source_key": "36",
          "name": "Riboflavin",
          "amount_100g": 0.113,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.113,
          "max": 0.113
        },
        {
          "source_key": "38",
          "name": "B-6 vitamini, toplam",
          "amount_100g": 0.008,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.008,
          "max": 0.008
        },
        {
          "source_key": "562",
          "name": "Folat, gıda",
          "amount_100g": 10,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 10,
          "max": 10
        },
        {
          "source_key": "41",
          "name": "B-12 vitamini",
          "amount_100g": 0.41,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.41,
          "max": 0.41
        },
        {
          "source_key": "139",
          "name": "A vitamini",
          "amount_100g": 691,
          "unit": "RE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 691,
          "max": 691
        },
        {
          "source_key": "43",
          "name": "Retinol",
          "amount_100g": 691,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 691,
          "max": 691
        },
        {
          "source_key": "561",
          "name": "D vitamini, IU",
          "amount_100g": 25,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 25,
          "max": 25
        },
        {
          "source_key": "50",
          "name": "D-3 vitamini (kolekalsiferol)",
          "amount_100g": 0.6,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.6,
          "max": 0.6
        },
        {
          "source_key": "540",
          "name": "E vitamini",
          "amount_100g": 2.36,
          "unit": "α-TE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.36,
          "max": 2.36
        },
        {
          "source_key": "560",
          "name": "E vitamini, IU",
          "amount_100g": 3.51,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.51,
          "max": 3.51
        },
        {
          "source_key": "49",
          "name": "Alfa-tokoferol",
          "amount_100g": 2.36,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.36,
          "max": 2.36
        },
        {
          "source_key": "54",
          "name": "K-2 vitamini",
          "amount_100g": 11.2,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 11.2,
          "max": 11.2
        },
        {
          "source_key": "145",
          "name": "Yağ asitleri, toplam doymuş",
          "amount_100g": 37.656,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 37.656,
          "max": 37.656
        },
        {
          "source_key": "146",
          "name": "Yağ asitleri, toplam tekli doymamış",
          "amount_100g": 16.509,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 16.509,
          "max": 16.509
        },
        {
          "source_key": "147",
          "name": "Yağ asitleri, toplam çoklu doymamış",
          "amount_100g": 1.45,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.45,
          "max": 1.45
        },
        {
          "source_key": "55",
          "name": "Yağ asidi 4:0 (bütirik asit)",
          "amount_100g": 1.462,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.462,
          "max": 1.462
        },
        {
          "source_key": "56",
          "name": "Yağ asidi 6:0 (kaproik asit)",
          "amount_100g": 0.995,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.995,
          "max": 0.995
        },
        {
          "source_key": "57",
          "name": "Yağ asidi 8:0 (kaprilik asit)",
          "amount_100g": 0.601,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.601,
          "max": 0.601
        },
        {
          "source_key": "58",
          "name": "Yağ asidi 10:0 (kaprik asit)",
          "amount_100g": 1.349,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.349,
          "max": 1.349
        },
        {
          "source_key": "59",
          "name": "Yağ asidi 12:0 (laurik asit)",
          "amount_100g": 1.653,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.653,
          "max": 1.653
        },
        {
          "source_key": "60",
          "name": "Yağ asidi 14:0 (miristik asit)",
          "amount_100g": 6.054,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6.054,
          "max": 6.054
        },
        {
          "source_key": "61",
          "name": "Yağ asidi 15:0 (pentadesilik asit )",
          "amount_100g": 0.613,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.613,
          "max": 0.613
        },
        {
          "source_key": "62",
          "name": "Yağ asidi 16:0 (palmitik asit)",
          "amount_100g": 17.544,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 17.544,
          "max": 17.544
        },
        {
          "source_key": "63",
          "name": "Yağ asidi 17:0 (margarik asit)",
          "amount_100g": 0.377,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.377,
          "max": 0.377
        },
        {
          "source_key": "64",
          "name": "Yağ asidi 18:0 (stearik asit)",
          "amount_100g": 6.571,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6.571,
          "max": 6.571
        },
        {
          "source_key": "65",
          "name": "Yağ asidi 20:0 (araşidik asit)",
          "amount_100g": 0.438,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.438,
          "max": 0.438
        },
        {
          "source_key": "68",
          "name": "Yağ asidi 14:1 n-5 cis (miristoleik asit)",
          "amount_100g": 0.697,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.697,
          "max": 0.697
        },
        {
          "source_key": "69",
          "name": "Yağ asidi 16:1 n-7 cis (palmitoleik asit)",
          "amount_100g": 0.809,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.809,
          "max": 0.809
        },
        {
          "source_key": "70",
          "name": "Yağ asidi 18:1 n-9 cis (oleik asit)",
          "amount_100g": 15.003,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 15.003,
          "max": 15.003
        },
        {
          "source_key": "75",
          "name": "Yağ asidi 18:2 n-6 cis,cis",
          "amount_100g": 1.355,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.355,
          "max": 1.355
        },
        {
          "source_key": "76",
          "name": "Yağ asidi 18:3 n-3 all-cis",
          "amount_100g": 0.096,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.096,
          "max": 0.096
        },
        {
          "source_key": "557",
          "name": "Kolesterol",
          "amount_100g": 54,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 54,
          "max": 54
        },
        {
          "source_key": "derived:sugars_sum",
          "name": "Total sugars (sum of published mono/disaccharides)",
          "amount_100g": 1.3,
          "unit": "g",
          "derivation_code": "SUM_COMPONENTS",
          "derivation_description": "Sum of 5 available TürKomp sugar components; not a separately published total"
        }
      ],
      "kcal_100g": 585,
      "protein_100g": 0.96,
      "fat_100g": 63.1,
      "carbs_100g": 3.31,
      "fiber_100g": 0,
      "sodium_mg_100g": 19,
      "sugars_100g": 1.3
    },
    "portions": [],
    "food_code": "01.02.0002",
    "classification_codes": [
      {
        "system": "LanguaL",
        "codes": [
          "A0123",
          "A0452",
          "A0627",
          "A0702",
          "A0728",
          "A0809",
          "A1259",
          "A1271",
          "B1201",
          "C0235",
          "E0119",
          "F0001",
          "G0001",
          "H0001",
          "J0001",
          "K0001",
          "M0172",
          "N0001",
          "P0026",
          "P0162",
          "R0403",
          "Z0112",
          "%60\" style=\"width:auto; margin-right: 12px;\" title=\"Gruba ait gıdaları görmek için tıklayın.\" style=\"color:#297d82\">Z0194"
        ]
      }
    ],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "published_average",
        "published_min_max",
        "per_100g_edible_portion",
        "derived_sugar_component_sum"
      ]
    },
    "provenance": {
      "source_url": "https://turkomp.tarimorman.gov.tr/food-kaymak-pastorize-sut-yagi---60-5",
      "nutrient_basis_note": "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.",
      "attribution": "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı"
    },
    "nutrient_conversion_factors": [
      {
        "type": "nitrogen",
        "value": 6.38
      },
      {
        "type": "fat",
        "value": 0.945
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Yoğurt, manda sütü",
    "source": "turkomp",
    "source_id": "6",
    "dataset_version": "Site state as of 2026-08-22",
    "category": {
      "name": "Süt ve süt ürünleri",
      "hierarchy": [
        "Süt ve süt ürünleri"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "edible portion"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2",
          "name": "Enerji",
          "amount_100g": 112,
          "unit": "kcal",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 86,
          "max": 124
        },
        {
          "source_key": "559",
          "name": "Enerji",
          "amount_100g": 468,
          "unit": "kJ",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 359,
          "max": 517
        },
        {
          "source_key": "1",
          "name": "Su",
          "amount_100g": 81.56,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 77.2,
          "max": 86.29
        },
        {
          "source_key": "5",
          "name": "Kül",
          "amount_100g": 0.76,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.65,
          "max": 0.86
        },
        {
          "source_key": "3",
          "name": "Protein",
          "amount_100g": 4.82,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.74,
          "max": 5.36
        },
        {
          "source_key": "109",
          "name": "Azot",
          "amount_100g": 0.76,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.59,
          "max": 0.84
        },
        {
          "source_key": "4",
          "name": "Yağ, toplam",
          "amount_100g": 8.21,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6.7,
          "max": 9.7
        },
        {
          "source_key": "155",
          "name": "Karbonhidrat",
          "amount_100g": 4.65,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.13,
          "max": 10.26
        },
        {
          "source_key": "8",
          "name": "Laktoz",
          "amount_100g": 2.47,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.12,
          "max": 2.8
        },
        {
          "source_key": "461",
          "name": "Tuz",
          "amount_100g": 100,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 60,
          "max": 154
        },
        {
          "source_key": "22",
          "name": "Demir, Fe",
          "amount_100g": 0.05,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.02,
          "max": 0.1
        },
        {
          "source_key": "24",
          "name": "Fosfor, P",
          "amount_100g": 140,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 88,
          "max": 175
        },
        {
          "source_key": "21",
          "name": "Kalsiyum, Ca",
          "amount_100g": 152,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 72,
          "max": 206
        },
        {
          "source_key": "23",
          "name": "Magnezyum, Mg",
          "amount_100g": 10,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2,
          "max": 13
        },
        {
          "source_key": "25",
          "name": "Potasyum, K",
          "amount_100g": 95,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 48,
          "max": 126
        },
        {
          "source_key": "26",
          "name": "Sodyum, Na",
          "amount_100g": 40,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 24,
          "max": 62
        },
        {
          "source_key": "27",
          "name": "Çinko, Zn",
          "amount_100g": 0.57,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.26,
          "max": 0.89
        },
        {
          "source_key": "30",
          "name": "Selenyum, Se",
          "amount_100g": 2.6,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.9,
          "max": 3.7
        },
        {
          "source_key": "35",
          "name": "Tiamin",
          "amount_100g": 0.026,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.013,
          "max": 0.042
        },
        {
          "source_key": "36",
          "name": "Riboflavin",
          "amount_100g": 0.148,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.116,
          "max": 0.171
        },
        {
          "source_key": "465",
          "name": "Niasin eşdeğerleri, toplam",
          "amount_100g": 1.142,
          "unit": "NE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.986,
          "max": 1.453
        },
        {
          "source_key": "37",
          "name": "Niasin",
          "amount_100g": 0.094,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.077,
          "max": 0.11
        },
        {
          "source_key": "38",
          "name": "B-6 vitamini, toplam",
          "amount_100g": 0.03,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.022,
          "max": 0.044
        },
        {
          "source_key": "562",
          "name": "Folat, gıda",
          "amount_100g": 11,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 5,
          "max": 16
        },
        {
          "source_key": "41",
          "name": "B-12 vitamini",
          "amount_100g": 0.51,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.4,
          "max": 0.59
        },
        {
          "source_key": "139",
          "name": "A vitamini",
          "amount_100g": 43,
          "unit": "RE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 35,
          "max": 52
        },
        {
          "source_key": "43",
          "name": "Retinol",
          "amount_100g": 43,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 35,
          "max": 52
        },
        {
          "source_key": "561",
          "name": "D vitamini, IU",
          "amount_100g": 32,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 18,
          "max": 44
        },
        {
          "source_key": "50",
          "name": "D-3 vitamini (kolekalsiferol)",
          "amount_100g": 0.8,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.4,
          "max": 1.1
        },
        {
          "source_key": "540",
          "name": "E vitamini",
          "amount_100g": 0.08,
          "unit": "α-TE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.05,
          "max": 0.1
        },
        {
          "source_key": "560",
          "name": "E vitamini, IU",
          "amount_100g": 0.12,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.07,
          "max": 0.15
        },
        {
          "source_key": "49",
          "name": "Alfa-tokoferol",
          "amount_100g": 0.08,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.05,
          "max": 0.1
        },
        {
          "source_key": "54",
          "name": "K-2 vitamini",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "145",
          "name": "Yağ asitleri, toplam doymuş",
          "amount_100g": 5.123,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.1,
          "max": 6.074
        },
        {
          "source_key": "146",
          "name": "Yağ asitleri, toplam tekli doymamış",
          "amount_100g": 2.415,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.949,
          "max": 2.922
        },
        {
          "source_key": "147",
          "name": "Yağ asitleri, toplam çoklu doymamış",
          "amount_100g": 0.203,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.131,
          "max": 0.234
        },
        {
          "source_key": "55",
          "name": "Yağ asidi 4:0 (bütirik asit)",
          "amount_100g": 0.158,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.019,
          "max": 0.278
        },
        {
          "source_key": "56",
          "name": "Yağ asidi 6:0 (kaproik asit)",
          "amount_100g": 0.102,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.034,
          "max": 0.145
        },
        {
          "source_key": "57",
          "name": "Yağ asidi 8:0 (kaprilik asit)",
          "amount_100g": 0.064,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.036,
          "max": 0.092
        },
        {
          "source_key": "58",
          "name": "Yağ asidi 10:0 (kaprik asit)",
          "amount_100g": 0.14,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.098,
          "max": 0.203
        },
        {
          "source_key": "59",
          "name": "Yağ asidi 12:0 (laurik asit)",
          "amount_100g": 0.176,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.148,
          "max": 0.203
        },
        {
          "source_key": "60",
          "name": "Yağ asidi 14:0 (miristik asit)",
          "amount_100g": 0.803,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.607,
          "max": 0.951
        },
        {
          "source_key": "61",
          "name": "Yağ asidi 15:0 (pentadesilik asit )",
          "amount_100g": 0.106,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.083,
          "max": 0.127
        },
        {
          "source_key": "62",
          "name": "Yağ asidi 16:0 (palmitik asit)",
          "amount_100g": 2.32,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.668,
          "max": 2.808
        },
        {
          "source_key": "63",
          "name": "Yağ asidi 17:0 (margarik asit)",
          "amount_100g": 0.069,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.044,
          "max": 0.09
        },
        {
          "source_key": "64",
          "name": "Yağ asidi 18:0 (stearik asit)",
          "amount_100g": 1.149,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.861,
          "max": 1.339
        },
        {
          "source_key": "65",
          "name": "Yağ asidi 20:0 (araşidik asit)",
          "amount_100g": 0.023,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.017,
          "max": 0.03
        },
        {
          "source_key": "66",
          "name": "Yağ asidi 22:0 (behenik asit)",
          "amount_100g": 0.014,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.011,
          "max": 0.017
        },
        {
          "source_key": "67",
          "name": "Yağ asidi 24:0 (lignoserik asit)",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "68",
          "name": "Yağ asidi 14:1 n-5 cis (miristoleik asit)",
          "amount_100g": 0.102,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.079,
          "max": 0.119
        },
        {
          "source_key": "69",
          "name": "Yağ asidi 16:1 n-7 cis (palmitoleik asit)",
          "amount_100g": 0.096,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.037,
          "max": 0.133
        },
        {
          "source_key": "70",
          "name": "Yağ asidi 18:1 n-9 cis (oleik asit)",
          "amount_100g": 1.938,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.359,
          "max": 2.426
        },
        {
          "source_key": "71",
          "name": "Yağ asidi 18:1 n-9 trans (elaidik asit)",
          "amount_100g": 0.188,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.01,
          "max": 0.308
        },
        {
          "source_key": "344",
          "name": "Yağ asidi 20:1 n-9 cis",
          "amount_100g": 0.09,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.05,
          "max": 0.138
        },
        {
          "source_key": "73",
          "name": "Yağ asidi 22:1 n-9 cis (erüsik asit)",
          "amount_100g": 0.001,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0.002
        },
        {
          "source_key": "74",
          "name": "Yağ asidi 24:1 n-9 cis",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "75",
          "name": "Yağ asidi 18:2 n-6 cis,cis",
          "amount_100g": 0.143,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.079,
          "max": 0.17
        },
        {
          "source_key": "76",
          "name": "Yağ asidi 18:3 n-3 all-cis",
          "amount_100g": 0.048,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.041,
          "max": 0.051
        },
        {
          "source_key": "77",
          "name": "Yağ asidi 18:3 n-6 all-cis",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "358",
          "name": "Yağ asidi 20:4 n-6 all-cis",
          "amount_100g": 0.012,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.005,
          "max": 0.016
        },
        {
          "source_key": "80",
          "name": "Yağ asidi 20:5 n-3 all-cis",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "83",
          "name": "Yağ asidi 22:6 n-3 all-cis",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "557",
          "name": "Kolesterol",
          "amount_100g": 9,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 9,
          "max": 9
        },
        {
          "source_key": "105",
          "name": "Triptofan",
          "amount_100g": 63,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 53,
          "max": 82
        },
        {
          "source_key": "94",
          "name": "Treonin",
          "amount_100g": 166,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 119,
          "max": 231
        },
        {
          "source_key": "93",
          "name": "Izolosin",
          "amount_100g": 183,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 142,
          "max": 244
        },
        {
          "source_key": "92",
          "name": "Lösin",
          "amount_100g": 372,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 256,
          "max": 525
        },
        {
          "source_key": "102",
          "name": "Lizin",
          "amount_100g": 297,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 111,
          "max": 585
        },
        {
          "source_key": "98",
          "name": "Metiyonin",
          "amount_100g": 62,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 35,
          "max": 92
        },
        {
          "source_key": "106",
          "name": "Sistin",
          "amount_100g": 26,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 20,
          "max": 35
        },
        {
          "source_key": "101",
          "name": "Fenilalanin",
          "amount_100g": 206,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 118,
          "max": 284
        },
        {
          "source_key": "104",
          "name": "Tirozin",
          "amount_100g": 207,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 147,
          "max": 305
        },
        {
          "source_key": "91",
          "name": "Valin",
          "amount_100g": 194,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 126,
          "max": 269
        },
        {
          "source_key": "153",
          "name": "Arjinin",
          "amount_100g": 72,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 33,
          "max": 166
        },
        {
          "source_key": "103",
          "name": "Histidin",
          "amount_100g": 121,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 84,
          "max": 153
        },
        {
          "source_key": "89",
          "name": "Alanin",
          "amount_100g": 131,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 94,
          "max": 177
        },
        {
          "source_key": "97",
          "name": "Aspartik asit",
          "amount_100g": 158,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 73,
          "max": 251
        },
        {
          "source_key": "154",
          "name": "Glutamik asit",
          "amount_100g": 590,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 291,
          "max": 828
        },
        {
          "source_key": "90",
          "name": "Glisin",
          "amount_100g": 81,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 59,
          "max": 118
        },
        {
          "source_key": "96",
          "name": "Prolin",
          "amount_100g": 459,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 307,
          "max": 580
        },
        {
          "source_key": "95",
          "name": "Serin",
          "amount_100g": 180,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 130,
          "max": 241
        },
        {
          "source_key": "derived:sugars_sum",
          "name": "Total sugars (sum of published mono/disaccharides)",
          "amount_100g": 2.47,
          "unit": "g",
          "derivation_code": "SUM_COMPONENTS",
          "derivation_description": "Sum of 1 available TürKomp sugar components; not a separately published total"
        }
      ],
      "kcal_100g": 112,
      "protein_100g": 4.82,
      "fat_100g": 8.21,
      "carbs_100g": 4.65,
      "sodium_mg_100g": 40,
      "sugars_100g": 2.47
    },
    "portions": [],
    "food_code": "01.02.0018",
    "classification_codes": [
      {
        "system": "LanguaL",
        "codes": [
          "A0452",
          "A0783",
          "A1049",
          "B2095",
          "C0235",
          "E0119",
          "F0022",
          "G0001",
          "H0247",
          "H0753",
          "J0120",
          "K0001",
          "M0001",
          "N0001",
          "P0026",
          "R0403",
          "Z0112"
        ]
      }
    ],
    "quality": {
      "nutrition_completeness": 0.8571,
      "confidence_inputs": [
        "published_average",
        "published_min_max",
        "per_100g_edible_portion",
        "derived_sugar_component_sum"
      ]
    },
    "provenance": {
      "source_url": "https://turkomp.tarimorman.gov.tr/food-yogurt-manda-sutu-6",
      "nutrient_basis_note": "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.",
      "attribution": "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı"
    },
    "nutrient_conversion_factors": [
      {
        "type": "nitrogen",
        "value": 6.38
      },
      {
        "type": "fat",
        "value": 0.945
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Peynir, beyaz, az yağlı-yağsız (yağ, kuru maddede < % 20)",
    "source": "turkomp",
    "source_id": "7",
    "dataset_version": "Site state as of 2026-08-22",
    "category": {
      "name": "Süt ve süt ürünleri",
      "hierarchy": [
        "Süt ve süt ürünleri"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "edible portion"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2",
          "name": "Enerji",
          "amount_100g": 185,
          "unit": "kcal",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 185,
          "max": 185
        },
        {
          "source_key": "559",
          "name": "Enerji",
          "amount_100g": 776,
          "unit": "kJ",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 776,
          "max": 776
        },
        {
          "source_key": "1",
          "name": "Su",
          "amount_100g": 60.45,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 60.45,
          "max": 60.45
        },
        {
          "source_key": "5",
          "name": "Kül",
          "amount_100g": 2.9,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.9,
          "max": 2.9
        },
        {
          "source_key": "3",
          "name": "Protein",
          "amount_100g": 16.52,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 16.52,
          "max": 16.52
        },
        {
          "source_key": "109",
          "name": "Azot",
          "amount_100g": 2.59,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.59,
          "max": 2.59
        },
        {
          "source_key": "4",
          "name": "Yağ, toplam",
          "amount_100g": 7.76,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 7.76,
          "max": 7.76
        },
        {
          "source_key": "155",
          "name": "Karbonhidrat",
          "amount_100g": 12.37,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 12.37,
          "max": 12.37
        },
        {
          "source_key": "11",
          "name": "Lif, toplam diyet",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "10",
          "name": "Sakaroz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "100",
          "name": "Glukoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "6",
          "name": "Fruktoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "8",
          "name": "Laktoz",
          "amount_100g": 3.32,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.32,
          "max": 3.32
        },
        {
          "source_key": "9",
          "name": "Maltoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "461",
          "name": "Tuz",
          "amount_100g": 1964,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1964,
          "max": 1964
        },
        {
          "source_key": "22",
          "name": "Demir, Fe",
          "amount_100g": 0.13,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.13,
          "max": 0.13
        },
        {
          "source_key": "24",
          "name": "Fosfor, P",
          "amount_100g": 334,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 334,
          "max": 334
        },
        {
          "source_key": "21",
          "name": "Kalsiyum, Ca",
          "amount_100g": 504,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 504,
          "max": 504
        },
        {
          "source_key": "23",
          "name": "Magnezyum, Mg",
          "amount_100g": 21,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 21,
          "max": 21
        },
        {
          "source_key": "25",
          "name": "Potasyum, K",
          "amount_100g": 130,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 130,
          "max": 130
        },
        {
          "source_key": "26",
          "name": "Sodyum, Na",
          "amount_100g": 785,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 785,
          "max": 785
        },
        {
          "source_key": "27",
          "name": "Çinko, Zn",
          "amount_100g": 1.87,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.87,
          "max": 1.87
        },
        {
          "source_key": "30",
          "name": "Selenyum, Se",
          "amount_100g": 3.5,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.5,
          "max": 3.5
        },
        {
          "source_key": "35",
          "name": "Tiamin",
          "amount_100g": 0.024,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.024,
          "max": 0.024
        },
        {
          "source_key": "36",
          "name": "Riboflavin",
          "amount_100g": 0.191,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.191,
          "max": 0.191
        },
        {
          "source_key": "465",
          "name": "Niasin eşdeğerleri, toplam",
          "amount_100g": 4.333,
          "unit": "NE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.333,
          "max": 4.333
        },
        {
          "source_key": "37",
          "name": "Niasin",
          "amount_100g": 0.103,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.103,
          "max": 0.103
        },
        {
          "source_key": "38",
          "name": "B-6 vitamini, toplam",
          "amount_100g": 0.083,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.083,
          "max": 0.083
        },
        {
          "source_key": "562",
          "name": "Folat, gıda",
          "amount_100g": 8,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 8,
          "max": 8
        },
        {
          "source_key": "41",
          "name": "B-12 vitamini",
          "amount_100g": 0.71,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.71,
          "max": 0.71
        },
        {
          "source_key": "139",
          "name": "A vitamini",
          "amount_100g": 59,
          "unit": "RE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 59,
          "max": 59
        },
        {
          "source_key": "43",
          "name": "Retinol",
          "amount_100g": 59,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 59,
          "max": 59
        },
        {
          "source_key": "561",
          "name": "D vitamini, IU",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "50",
          "name": "D-3 vitamini (kolekalsiferol)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "540",
          "name": "E vitamini",
          "amount_100g": 0.42,
          "unit": "α-TE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.42,
          "max": 0.42
        },
        {
          "source_key": "560",
          "name": "E vitamini, IU",
          "amount_100g": 0.63,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.63,
          "max": 0.63
        },
        {
          "source_key": "49",
          "name": "Alfa-tokoferol",
          "amount_100g": 0.42,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.42,
          "max": 0.42
        },
        {
          "source_key": "54",
          "name": "K-2 vitamini",
          "amount_100g": 2.5,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.5,
          "max": 2.5
        },
        {
          "source_key": "145",
          "name": "Yağ asitleri, toplam doymuş",
          "amount_100g": 6.536,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6.536,
          "max": 6.536
        },
        {
          "source_key": "146",
          "name": "Yağ asitleri, toplam tekli doymamış",
          "amount_100g": 2.675,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.675,
          "max": 2.675
        },
        {
          "source_key": "147",
          "name": "Yağ asitleri, toplam çoklu doymamış",
          "amount_100g": 0.23,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.23,
          "max": 0.23
        },
        {
          "source_key": "55",
          "name": "Yağ asidi 4:0 (bütirik asit)",
          "amount_100g": 0.224,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.224,
          "max": 0.224
        },
        {
          "source_key": "56",
          "name": "Yağ asidi 6:0 (kaproik asit)",
          "amount_100g": 0.16,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.16,
          "max": 0.16
        },
        {
          "source_key": "57",
          "name": "Yağ asidi 8:0 (kaprilik asit)",
          "amount_100g": 0.103,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.103,
          "max": 0.103
        },
        {
          "source_key": "58",
          "name": "Yağ asidi 10:0 (kaprik asit)",
          "amount_100g": 0.238,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.238,
          "max": 0.238
        },
        {
          "source_key": "59",
          "name": "Yağ asidi 12:0 (laurik asit)",
          "amount_100g": 0.292,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.292,
          "max": 0.292
        },
        {
          "source_key": "60",
          "name": "Yağ asidi 14:0 (miristik asit)",
          "amount_100g": 1.066,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.066,
          "max": 1.066
        },
        {
          "source_key": "61",
          "name": "Yağ asidi 15:0 (pentadesilik asit )",
          "amount_100g": 0.113,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.113,
          "max": 0.113
        },
        {
          "source_key": "62",
          "name": "Yağ asidi 16:0 (palmitik asit)",
          "amount_100g": 3.191,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.191,
          "max": 3.191
        },
        {
          "source_key": "63",
          "name": "Yağ asidi 17:0 (margarik asit)",
          "amount_100g": 0.065,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.065,
          "max": 0.065
        },
        {
          "source_key": "64",
          "name": "Yağ asidi 18:0 (stearik asit)",
          "amount_100g": 1.016,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.016,
          "max": 1.016
        },
        {
          "source_key": "65",
          "name": "Yağ asidi 20:0 (araşidik asit)",
          "amount_100g": 0.07,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.07,
          "max": 0.07
        },
        {
          "source_key": "68",
          "name": "Yağ asidi 14:1 n-5 cis (miristoleik asit)",
          "amount_100g": 0.13,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.13,
          "max": 0.13
        },
        {
          "source_key": "69",
          "name": "Yağ asidi 16:1 n-7 cis (palmitoleik asit)",
          "amount_100g": 0.157,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.157,
          "max": 0.157
        },
        {
          "source_key": "70",
          "name": "Yağ asidi 18:1 n-9 cis (oleik asit)",
          "amount_100g": 2.388,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.388,
          "max": 2.388
        },
        {
          "source_key": "75",
          "name": "Yağ asidi 18:2 n-6 cis,cis",
          "amount_100g": 0.21,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.21,
          "max": 0.21
        },
        {
          "source_key": "76",
          "name": "Yağ asidi 18:3 n-3 all-cis",
          "amount_100g": 0.02,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.02,
          "max": 0.02
        },
        {
          "source_key": "557",
          "name": "Kolesterol",
          "amount_100g": 37,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 37,
          "max": 37
        },
        {
          "source_key": "105",
          "name": "Triptofan",
          "amount_100g": 254,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 254,
          "max": 254
        },
        {
          "source_key": "94",
          "name": "Treonin",
          "amount_100g": 592,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 592,
          "max": 592
        },
        {
          "source_key": "93",
          "name": "Izolosin",
          "amount_100g": 703,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 703,
          "max": 703
        },
        {
          "source_key": "92",
          "name": "Lösin",
          "amount_100g": 1473,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1473,
          "max": 1473
        },
        {
          "source_key": "102",
          "name": "Lizin",
          "amount_100g": 2269,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2269,
          "max": 2269
        },
        {
          "source_key": "98",
          "name": "Metiyonin",
          "amount_100g": 231,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 231,
          "max": 231
        },
        {
          "source_key": "106",
          "name": "Sistin",
          "amount_100g": 77,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 77,
          "max": 77
        },
        {
          "source_key": "101",
          "name": "Fenilalanin",
          "amount_100g": 864,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 864,
          "max": 864
        },
        {
          "source_key": "104",
          "name": "Tirozin",
          "amount_100g": 900,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 900,
          "max": 900
        },
        {
          "source_key": "91",
          "name": "Valin",
          "amount_100g": 895,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 895,
          "max": 895
        },
        {
          "source_key": "153",
          "name": "Arjinin",
          "amount_100g": 374,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 374,
          "max": 374
        },
        {
          "source_key": "103",
          "name": "Histidin",
          "amount_100g": 660,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 660,
          "max": 660
        },
        {
          "source_key": "89",
          "name": "Alanin",
          "amount_100g": 472,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 472,
          "max": 472
        },
        {
          "source_key": "97",
          "name": "Aspartik asit",
          "amount_100g": 613,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 613,
          "max": 613
        },
        {
          "source_key": "154",
          "name": "Glutamik asit",
          "amount_100g": 2574,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2574,
          "max": 2574
        },
        {
          "source_key": "90",
          "name": "Glisin",
          "amount_100g": 288,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 288,
          "max": 288
        },
        {
          "source_key": "96",
          "name": "Prolin",
          "amount_100g": 1856,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1856,
          "max": 1856
        },
        {
          "source_key": "95",
          "name": "Serin",
          "amount_100g": 808,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 808,
          "max": 808
        },
        {
          "source_key": "derived:sugars_sum",
          "name": "Total sugars (sum of published mono/disaccharides)",
          "amount_100g": 3.32,
          "unit": "g",
          "derivation_code": "SUM_COMPONENTS",
          "derivation_description": "Sum of 5 available TürKomp sugar components; not a separately published total"
        }
      ],
      "kcal_100g": 185,
      "protein_100g": 16.52,
      "fat_100g": 7.76,
      "carbs_100g": 12.37,
      "fiber_100g": 0,
      "sodium_mg_100g": 785,
      "sugars_100g": 3.32
    },
    "portions": [],
    "food_code": "01.02.0003",
    "classification_codes": [
      {
        "system": "LanguaL",
        "codes": [
          "A0117",
          "A0312",
          "A0452",
          "A0720",
          "A0724",
          "A0787",
          "B1201",
          "C0235",
          "E0119",
          "F0018",
          "G0001",
          "H0173",
          "H0247",
          "H0753",
          "J0135",
          "J0137",
          "K0018",
          "M0172",
          "N0001",
          "P0026",
          "P0040",
          "R0403",
          "Z0112"
        ]
      }
    ],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "published_average",
        "published_min_max",
        "per_100g_edible_portion",
        "derived_sugar_component_sum"
      ]
    },
    "provenance": {
      "source_url": "https://turkomp.tarimorman.gov.tr/food-peynir-beyaz-az-yagli-yagsiz-yag-kuru-maddede---20-7",
      "nutrient_basis_note": "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.",
      "attribution": "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı"
    },
    "nutrient_conversion_factors": [
      {
        "type": "nitrogen",
        "value": 6.38
      },
      {
        "type": "fat",
        "value": 0.945
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Peynir, beyaz, tam yağlı (yağ, kuru maddede > % 45)",
    "source": "turkomp",
    "source_id": "8",
    "dataset_version": "Site state as of 2026-08-22",
    "category": {
      "name": "Süt ve süt ürünleri",
      "hierarchy": [
        "Süt ve süt ürünleri"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "edible portion"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2",
          "name": "Enerji",
          "amount_100g": 309,
          "unit": "kcal",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 309,
          "max": 309
        },
        {
          "source_key": "559",
          "name": "Enerji",
          "amount_100g": 1292,
          "unit": "kJ",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1292,
          "max": 1292
        },
        {
          "source_key": "1",
          "name": "Su",
          "amount_100g": 48.91,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 48.91,
          "max": 48.91
        },
        {
          "source_key": "5",
          "name": "Kül",
          "amount_100g": 3.32,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.32,
          "max": 3.32
        },
        {
          "source_key": "3",
          "name": "Protein",
          "amount_100g": 16.01,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 16.01,
          "max": 16.01
        },
        {
          "source_key": "109",
          "name": "Azot",
          "amount_100g": 2.51,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.51,
          "max": 2.51
        },
        {
          "source_key": "4",
          "name": "Yağ, toplam",
          "amount_100g": 23.55,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 23.55,
          "max": 23.55
        },
        {
          "source_key": "155",
          "name": "Karbonhidrat",
          "amount_100g": 8.21,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 8.21,
          "max": 8.21
        },
        {
          "source_key": "11",
          "name": "Lif, toplam diyet",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "10",
          "name": "Sakaroz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "100",
          "name": "Glukoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "6",
          "name": "Fruktoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "8",
          "name": "Laktoz",
          "amount_100g": 2.25,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.25,
          "max": 2.25
        },
        {
          "source_key": "9",
          "name": "Maltoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "461",
          "name": "Tuz",
          "amount_100g": 3203,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3203,
          "max": 3203
        },
        {
          "source_key": "22",
          "name": "Demir, Fe",
          "amount_100g": 0.3,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.3,
          "max": 0.3
        },
        {
          "source_key": "24",
          "name": "Fosfor, P",
          "amount_100g": 282,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 282,
          "max": 282
        },
        {
          "source_key": "21",
          "name": "Kalsiyum, Ca",
          "amount_100g": 422,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 422,
          "max": 422
        },
        {
          "source_key": "23",
          "name": "Magnezyum, Mg",
          "amount_100g": 18,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 18,
          "max": 18
        },
        {
          "source_key": "25",
          "name": "Potasyum, K",
          "amount_100g": 103,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 103,
          "max": 103
        },
        {
          "source_key": "26",
          "name": "Sodyum, Na",
          "amount_100g": 1281,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1281,
          "max": 1281
        },
        {
          "source_key": "27",
          "name": "Çinko, Zn",
          "amount_100g": 1.63,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.63,
          "max": 1.63
        },
        {
          "source_key": "30",
          "name": "Selenyum, Se",
          "amount_100g": 5,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 5,
          "max": 5
        },
        {
          "source_key": "35",
          "name": "Tiamin",
          "amount_100g": 0.027,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.027,
          "max": 0.027
        },
        {
          "source_key": "36",
          "name": "Riboflavin",
          "amount_100g": 0.152,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.152,
          "max": 0.152
        },
        {
          "source_key": "465",
          "name": "Niasin eşdeğerleri, toplam",
          "amount_100g": 4.335,
          "unit": "NE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.335,
          "max": 4.335
        },
        {
          "source_key": "37",
          "name": "Niasin",
          "amount_100g": 0.167,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.167,
          "max": 0.167
        },
        {
          "source_key": "38",
          "name": "B-6 vitamini, toplam",
          "amount_100g": 0.044,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.044,
          "max": 0.044
        },
        {
          "source_key": "562",
          "name": "Folat, gıda",
          "amount_100g": 12,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 12,
          "max": 12
        },
        {
          "source_key": "41",
          "name": "B-12 vitamini",
          "amount_100g": 0.62,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.62,
          "max": 0.62
        },
        {
          "source_key": "139",
          "name": "A vitamini",
          "amount_100g": 223,
          "unit": "RE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 223,
          "max": 223
        },
        {
          "source_key": "43",
          "name": "Retinol",
          "amount_100g": 223,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 223,
          "max": 223
        },
        {
          "source_key": "561",
          "name": "D vitamini, IU",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "50",
          "name": "D-3 vitamini (kolekalsiferol)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "540",
          "name": "E vitamini",
          "amount_100g": 1.39,
          "unit": "α-TE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.39,
          "max": 1.39
        },
        {
          "source_key": "560",
          "name": "E vitamini, IU",
          "amount_100g": 2.08,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.08,
          "max": 2.08
        },
        {
          "source_key": "49",
          "name": "Alfa-tokoferol",
          "amount_100g": 1.39,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.39,
          "max": 1.39
        },
        {
          "source_key": "54",
          "name": "K-2 vitamini",
          "amount_100g": 6.8,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6.8,
          "max": 6.8
        },
        {
          "source_key": "145",
          "name": "Yağ asitleri, toplam doymuş",
          "amount_100g": 15.198,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 15.198,
          "max": 15.198
        },
        {
          "source_key": "146",
          "name": "Yağ asitleri, toplam tekli doymamış",
          "amount_100g": 6.461,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6.461,
          "max": 6.461
        },
        {
          "source_key": "147",
          "name": "Yağ asitleri, toplam çoklu doymamış",
          "amount_100g": 0.574,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.574,
          "max": 0.574
        },
        {
          "source_key": "55",
          "name": "Yağ asidi 4:0 (bütirik asit)",
          "amount_100g": 0.556,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.556,
          "max": 0.556
        },
        {
          "source_key": "56",
          "name": "Yağ asidi 6:0 (kaproik asit)",
          "amount_100g": 0.385,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.385,
          "max": 0.385
        },
        {
          "source_key": "57",
          "name": "Yağ asidi 8:0 (kaprilik asit)",
          "amount_100g": 0.245,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.245,
          "max": 0.245
        },
        {
          "source_key": "58",
          "name": "Yağ asidi 10:0 (kaprik asit)",
          "amount_100g": 0.561,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.561,
          "max": 0.561
        },
        {
          "source_key": "59",
          "name": "Yağ asidi 12:0 (laurik asit)",
          "amount_100g": 0.692,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.692,
          "max": 0.692
        },
        {
          "source_key": "60",
          "name": "Yağ asidi 14:0 (miristik asit)",
          "amount_100g": 2.475,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.475,
          "max": 2.475
        },
        {
          "source_key": "61",
          "name": "Yağ asidi 15:0 (pentadesilik asit )",
          "amount_100g": 0.269,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.269,
          "max": 0.269
        },
        {
          "source_key": "62",
          "name": "Yağ asidi 16:0 (palmitik asit)",
          "amount_100g": 7.264,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 7.264,
          "max": 7.264
        },
        {
          "source_key": "63",
          "name": "Yağ asidi 17:0 (margarik asit)",
          "amount_100g": 0.156,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.156,
          "max": 0.156
        },
        {
          "source_key": "64",
          "name": "Yağ asidi 18:0 (stearik asit)",
          "amount_100g": 2.415,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.415,
          "max": 2.415
        },
        {
          "source_key": "65",
          "name": "Yağ asidi 20:0 (araşidik asit)",
          "amount_100g": 0.18,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.18,
          "max": 0.18
        },
        {
          "source_key": "68",
          "name": "Yağ asidi 14:1 n-5 cis (miristoleik asit)",
          "amount_100g": 0.3,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.3,
          "max": 0.3
        },
        {
          "source_key": "69",
          "name": "Yağ asidi 16:1 n-7 cis (palmitoleik asit)",
          "amount_100g": 0.356,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.356,
          "max": 0.356
        },
        {
          "source_key": "70",
          "name": "Yağ asidi 18:1 n-9 cis (oleik asit)",
          "amount_100g": 5.804,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 5.804,
          "max": 5.804
        },
        {
          "source_key": "75",
          "name": "Yağ asidi 18:2 n-6 cis,cis",
          "amount_100g": 0.521,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.521,
          "max": 0.521
        },
        {
          "source_key": "76",
          "name": "Yağ asidi 18:3 n-3 all-cis",
          "amount_100g": 0.053,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.053,
          "max": 0.053
        },
        {
          "source_key": "557",
          "name": "Kolesterol",
          "amount_100g": 53,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 53,
          "max": 53
        },
        {
          "source_key": "105",
          "name": "Triptofan",
          "amount_100g": 250,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 250,
          "max": 250
        },
        {
          "source_key": "94",
          "name": "Treonin",
          "amount_100g": 652,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 652,
          "max": 652
        },
        {
          "source_key": "93",
          "name": "Izolosin",
          "amount_100g": 758,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 758,
          "max": 758
        },
        {
          "source_key": "92",
          "name": "Lösin",
          "amount_100g": 1602,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1602,
          "max": 1602
        },
        {
          "source_key": "102",
          "name": "Lizin",
          "amount_100g": 2165,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2165,
          "max": 2165
        },
        {
          "source_key": "98",
          "name": "Metiyonin",
          "amount_100g": 302,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 302,
          "max": 302
        },
        {
          "source_key": "106",
          "name": "Sistin",
          "amount_100g": 103,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 103,
          "max": 103
        },
        {
          "source_key": "101",
          "name": "Fenilalanin",
          "amount_100g": 939,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 939,
          "max": 939
        },
        {
          "source_key": "104",
          "name": "Tirozin",
          "amount_100g": 959,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 959,
          "max": 959
        },
        {
          "source_key": "91",
          "name": "Valin",
          "amount_100g": 976,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 976,
          "max": 976
        },
        {
          "source_key": "153",
          "name": "Arjinin",
          "amount_100g": 307,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 307,
          "max": 307
        },
        {
          "source_key": "103",
          "name": "Histidin",
          "amount_100g": 349,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 349,
          "max": 349
        },
        {
          "source_key": "89",
          "name": "Alanin",
          "amount_100g": 499,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 499,
          "max": 499
        },
        {
          "source_key": "97",
          "name": "Aspartik asit",
          "amount_100g": 354,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 354,
          "max": 354
        },
        {
          "source_key": "154",
          "name": "Glutamik asit",
          "amount_100g": 2166,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2166,
          "max": 2166
        },
        {
          "source_key": "90",
          "name": "Glisin",
          "amount_100g": 289,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 289,
          "max": 289
        },
        {
          "source_key": "96",
          "name": "Prolin",
          "amount_100g": 1897,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1897,
          "max": 1897
        },
        {
          "source_key": "95",
          "name": "Serin",
          "amount_100g": 877,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 877,
          "max": 877
        },
        {
          "source_key": "derived:sugars_sum",
          "name": "Total sugars (sum of published mono/disaccharides)",
          "amount_100g": 2.25,
          "unit": "g",
          "derivation_code": "SUM_COMPONENTS",
          "derivation_description": "Sum of 5 available TürKomp sugar components; not a separately published total"
        }
      ],
      "kcal_100g": 309,
      "protein_100g": 16.01,
      "fat_100g": 23.55,
      "carbs_100g": 8.21,
      "fiber_100g": 0,
      "sodium_mg_100g": 1281,
      "sugars_100g": 2.25
    },
    "portions": [],
    "food_code": "01.02.0004",
    "classification_codes": [
      {
        "system": "LanguaL",
        "codes": [
          "A0117",
          "A0312",
          "A0452",
          "A0720",
          "A0724",
          "A0787",
          "B1201",
          "C0235",
          "E0119",
          "F0018",
          "G0001",
          "H0173",
          "H0247",
          "H0753",
          "J0135",
          "J0137",
          "K0018",
          "M0172",
          "N0001",
          "P0026",
          "R0403",
          "Z0112"
        ]
      }
    ],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "published_average",
        "published_min_max",
        "per_100g_edible_portion",
        "derived_sugar_component_sum"
      ]
    },
    "provenance": {
      "source_url": "https://turkomp.tarimorman.gov.tr/food-peynir-beyaz-tam-yagli-yag-kuru-maddede---45-8",
      "nutrient_basis_note": "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.",
      "attribution": "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı"
    },
    "nutrient_conversion_factors": [
      {
        "type": "nitrogen",
        "value": 6.38
      },
      {
        "type": "fat",
        "value": 0.945
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Peynir, beyaz, yarım yağlı (yağ, kuru maddede > % 20)",
    "source": "turkomp",
    "source_id": "9",
    "dataset_version": "Site state as of 2026-08-22",
    "category": {
      "name": "Süt ve süt ürünleri",
      "hierarchy": [
        "Süt ve süt ürünleri"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "edible portion"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2",
          "name": "Enerji",
          "amount_100g": 202,
          "unit": "kcal",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 202,
          "max": 202
        },
        {
          "source_key": "559",
          "name": "Enerji",
          "amount_100g": 846,
          "unit": "kJ",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 846,
          "max": 846
        },
        {
          "source_key": "1",
          "name": "Su",
          "amount_100g": 59.2,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 59.2,
          "max": 59.2
        },
        {
          "source_key": "5",
          "name": "Kül",
          "amount_100g": 2.93,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.93,
          "max": 2.93
        },
        {
          "source_key": "3",
          "name": "Protein",
          "amount_100g": 15.57,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 15.57,
          "max": 15.57
        },
        {
          "source_key": "109",
          "name": "Azot",
          "amount_100g": 2.44,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.44,
          "max": 2.44
        },
        {
          "source_key": "4",
          "name": "Yağ, toplam",
          "amount_100g": 10.12,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 10.12,
          "max": 10.12
        },
        {
          "source_key": "155",
          "name": "Karbonhidrat",
          "amount_100g": 12.18,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 12.18,
          "max": 12.18
        },
        {
          "source_key": "11",
          "name": "Lif, toplam diyet",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "10",
          "name": "Sakaroz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "100",
          "name": "Glukoz",
          "amount_100g": 0.64,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.64,
          "max": 0.64
        },
        {
          "source_key": "6",
          "name": "Fruktoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "8",
          "name": "Laktoz",
          "amount_100g": 2.93,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.93,
          "max": 2.93
        },
        {
          "source_key": "9",
          "name": "Maltoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "461",
          "name": "Tuz",
          "amount_100g": 1960,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1960,
          "max": 1960
        },
        {
          "source_key": "22",
          "name": "Demir, Fe",
          "amount_100g": 0.14,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.14,
          "max": 0.14
        },
        {
          "source_key": "24",
          "name": "Fosfor, P",
          "amount_100g": 282,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 282,
          "max": 282
        },
        {
          "source_key": "21",
          "name": "Kalsiyum, Ca",
          "amount_100g": 126,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 126,
          "max": 126
        },
        {
          "source_key": "23",
          "name": "Magnezyum, Mg",
          "amount_100g": 20,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 20,
          "max": 20
        },
        {
          "source_key": "25",
          "name": "Potasyum, K",
          "amount_100g": 126,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 126,
          "max": 126
        },
        {
          "source_key": "26",
          "name": "Sodyum, Na",
          "amount_100g": 784,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 784,
          "max": 784
        },
        {
          "source_key": "27",
          "name": "Çinko, Zn",
          "amount_100g": 1.65,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.65,
          "max": 1.65
        },
        {
          "source_key": "30",
          "name": "Selenyum, Se",
          "amount_100g": 2.9,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.9,
          "max": 2.9
        },
        {
          "source_key": "35",
          "name": "Tiamin",
          "amount_100g": 0.044,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.044,
          "max": 0.044
        },
        {
          "source_key": "36",
          "name": "Riboflavin",
          "amount_100g": 0.211,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.211,
          "max": 0.211
        },
        {
          "source_key": "465",
          "name": "Niasin eşdeğerleri, toplam",
          "amount_100g": 4.718,
          "unit": "NE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.718,
          "max": 4.718
        },
        {
          "source_key": "37",
          "name": "Niasin",
          "amount_100g": 0.1,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.1,
          "max": 0.1
        },
        {
          "source_key": "38",
          "name": "B-6 vitamini, toplam",
          "amount_100g": 0.039,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.039,
          "max": 0.039
        },
        {
          "source_key": "562",
          "name": "Folat, gıda",
          "amount_100g": 10,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 10,
          "max": 10
        },
        {
          "source_key": "41",
          "name": "B-12 vitamini",
          "amount_100g": 0.85,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.85,
          "max": 0.85
        },
        {
          "source_key": "139",
          "name": "A vitamini",
          "amount_100g": 78,
          "unit": "RE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 78,
          "max": 78
        },
        {
          "source_key": "43",
          "name": "Retinol",
          "amount_100g": 78,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 78,
          "max": 78
        },
        {
          "source_key": "561",
          "name": "D vitamini, IU",
          "amount_100g": 0,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "50",
          "name": "D-3 vitamini (kolekalsiferol)",
          "amount_100g": 0,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "540",
          "name": "E vitamini",
          "amount_100g": 0.76,
          "unit": "α-TE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.76,
          "max": 0.76
        },
        {
          "source_key": "560",
          "name": "E vitamini, IU",
          "amount_100g": 1.13,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.13,
          "max": 1.13
        },
        {
          "source_key": "49",
          "name": "Alfa-tokoferol",
          "amount_100g": 0.76,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.76,
          "max": 0.76
        },
        {
          "source_key": "54",
          "name": "K-2 vitamini",
          "amount_100g": 2.8,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.8,
          "max": 2.8
        },
        {
          "source_key": "145",
          "name": "Yağ asitleri, toplam doymuş",
          "amount_100g": 6.469,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6.469,
          "max": 6.469
        },
        {
          "source_key": "146",
          "name": "Yağ asitleri, toplam tekli doymamış",
          "amount_100g": 2.786,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.786,
          "max": 2.786
        },
        {
          "source_key": "147",
          "name": "Yağ asitleri, toplam çoklu doymamış",
          "amount_100g": 0.229,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.229,
          "max": 0.229
        },
        {
          "source_key": "55",
          "name": "Yağ asidi 4:0 (bütirik asit)",
          "amount_100g": 0.234,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.234,
          "max": 0.234
        },
        {
          "source_key": "56",
          "name": "Yağ asidi 6:0 (kaproik asit)",
          "amount_100g": 0.164,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.164,
          "max": 0.164
        },
        {
          "source_key": "57",
          "name": "Yağ asidi 8:0 (kaprilik asit)",
          "amount_100g": 0.104,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.104,
          "max": 0.104
        },
        {
          "source_key": "58",
          "name": "Yağ asidi 10:0 (kaprik asit)",
          "amount_100g": 0.238,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.238,
          "max": 0.238
        },
        {
          "source_key": "59",
          "name": "Yağ asidi 12:0 (laurik asit)",
          "amount_100g": 0.287,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.287,
          "max": 0.287
        },
        {
          "source_key": "60",
          "name": "Yağ asidi 14:0 (miristik asit)",
          "amount_100g": 1.057,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.057,
          "max": 1.057
        },
        {
          "source_key": "61",
          "name": "Yağ asidi 15:0 (pentadesilik asit )",
          "amount_100g": 0.106,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.106,
          "max": 0.106
        },
        {
          "source_key": "62",
          "name": "Yağ asidi 16:0 (palmitik asit)",
          "amount_100g": 3.026,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.026,
          "max": 3.026
        },
        {
          "source_key": "63",
          "name": "Yağ asidi 17:0 (margarik asit)",
          "amount_100g": 0.064,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.064,
          "max": 0.064
        },
        {
          "source_key": "64",
          "name": "Yağ asidi 18:0 (stearik asit)",
          "amount_100g": 1.114,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.114,
          "max": 1.114
        },
        {
          "source_key": "65",
          "name": "Yağ asidi 20:0 (araşidik asit)",
          "amount_100g": 0.074,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.074,
          "max": 0.074
        },
        {
          "source_key": "68",
          "name": "Yağ asidi 14:1 n-5 cis (miristoleik asit)",
          "amount_100g": 0.124,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.124,
          "max": 0.124
        },
        {
          "source_key": "69",
          "name": "Yağ asidi 16:1 n-7 cis (palmitoleik asit)",
          "amount_100g": 0.142,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.142,
          "max": 0.142
        },
        {
          "source_key": "70",
          "name": "Yağ asidi 18:1 n-9 cis (oleik asit)",
          "amount_100g": 2.52,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.52,
          "max": 2.52
        },
        {
          "source_key": "75",
          "name": "Yağ asidi 18:2 n-6 cis,cis",
          "amount_100g": 0.212,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.212,
          "max": 0.212
        },
        {
          "source_key": "76",
          "name": "Yağ asidi 18:3 n-3 all-cis",
          "amount_100g": 0.016,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.016,
          "max": 0.016
        },
        {
          "source_key": "557",
          "name": "Kolesterol",
          "amount_100g": 39,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 39,
          "max": 39
        },
        {
          "source_key": "105",
          "name": "Triptofan",
          "amount_100g": 277,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 277,
          "max": 277
        },
        {
          "source_key": "94",
          "name": "Treonin",
          "amount_100g": 606,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 606,
          "max": 606
        },
        {
          "source_key": "93",
          "name": "Izolosin",
          "amount_100g": 691,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 691,
          "max": 691
        },
        {
          "source_key": "92",
          "name": "Lösin",
          "amount_100g": 1489,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1489,
          "max": 1489
        },
        {
          "source_key": "102",
          "name": "Lizin",
          "amount_100g": 2015,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2015,
          "max": 2015
        },
        {
          "source_key": "98",
          "name": "Metiyonin",
          "amount_100g": 282,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 282,
          "max": 282
        },
        {
          "source_key": "106",
          "name": "Sistin",
          "amount_100g": 92,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 92,
          "max": 92
        },
        {
          "source_key": "101",
          "name": "Fenilalanin",
          "amount_100g": 882,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 882,
          "max": 882
        },
        {
          "source_key": "104",
          "name": "Tirozin",
          "amount_100g": 900,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 900,
          "max": 900
        },
        {
          "source_key": "91",
          "name": "Valin",
          "amount_100g": 912,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 912,
          "max": 912
        },
        {
          "source_key": "153",
          "name": "Arjinin",
          "amount_100g": 293,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 293,
          "max": 293
        },
        {
          "source_key": "103",
          "name": "Histidin",
          "amount_100g": 335,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 335,
          "max": 335
        },
        {
          "source_key": "89",
          "name": "Alanin",
          "amount_100g": 466,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 466,
          "max": 466
        },
        {
          "source_key": "97",
          "name": "Aspartik asit",
          "amount_100g": 2,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2,
          "max": 2
        },
        {
          "source_key": "154",
          "name": "Glutamik asit",
          "amount_100g": 2026,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2026,
          "max": 2026
        },
        {
          "source_key": "90",
          "name": "Glisin",
          "amount_100g": 269,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 269,
          "max": 269
        },
        {
          "source_key": "96",
          "name": "Prolin",
          "amount_100g": 1767,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1767,
          "max": 1767
        },
        {
          "source_key": "95",
          "name": "Serin",
          "amount_100g": 819,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 819,
          "max": 819
        },
        {
          "source_key": "derived:sugars_sum",
          "name": "Total sugars (sum of published mono/disaccharides)",
          "amount_100g": 3.57,
          "unit": "g",
          "derivation_code": "SUM_COMPONENTS",
          "derivation_description": "Sum of 5 available TürKomp sugar components; not a separately published total"
        }
      ],
      "kcal_100g": 202,
      "protein_100g": 15.57,
      "fat_100g": 10.12,
      "carbs_100g": 12.18,
      "fiber_100g": 0,
      "sodium_mg_100g": 784,
      "sugars_100g": 3.57
    },
    "portions": [],
    "food_code": "01.02.0020",
    "classification_codes": [
      {
        "system": "LanguaL",
        "codes": [
          "A0117",
          "A0312",
          "A0452",
          "A0720",
          "A0724",
          "A0787",
          "B1201",
          "C0235",
          "E0119",
          "F0018",
          "G0001",
          "H0173",
          "H0247",
          "H0753",
          "J0135",
          "J0137",
          "K0018",
          "M0172",
          "N0001",
          "P0026",
          "P0162",
          "R0403",
          "Z0112"
        ]
      }
    ],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "published_average",
        "published_min_max",
        "per_100g_edible_portion",
        "derived_sugar_component_sum"
      ]
    },
    "provenance": {
      "source_url": "https://turkomp.tarimorman.gov.tr/food-peynir-beyaz-yarim-yagli-yag-kuru-maddede---20-9",
      "nutrient_basis_note": "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.",
      "attribution": "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı"
    },
    "nutrient_conversion_factors": [
      {
        "type": "nitrogen",
        "value": 6.38
      },
      {
        "type": "fat",
        "value": 0.945
      }
    ]
  },
  {
    "schema_version": "1.0.0",
    "name": "Peynir, kaşar, olgunlaştırılmamış (taze)",
    "source": "turkomp",
    "source_id": "11",
    "dataset_version": "Site state as of 2026-08-22",
    "category": {
      "name": "Süt ve süt ürünleri",
      "hierarchy": [
        "Süt ve süt ürünleri"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "edible portion"
    },
    "nutrition": {
      "nutrients": [
        {
          "source_key": "2",
          "name": "Enerji",
          "amount_100g": 353,
          "unit": "kcal",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 353,
          "max": 353
        },
        {
          "source_key": "559",
          "name": "Enerji",
          "amount_100g": 1476,
          "unit": "kJ",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1476,
          "max": 1476
        },
        {
          "source_key": "1",
          "name": "Su",
          "amount_100g": 40.7,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 40.7,
          "max": 40.7
        },
        {
          "source_key": "5",
          "name": "Kül",
          "amount_100g": 3.69,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.69,
          "max": 3.69
        },
        {
          "source_key": "3",
          "name": "Protein",
          "amount_100g": 26.99,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 26.99,
          "max": 26.99
        },
        {
          "source_key": "109",
          "name": "Azot",
          "amount_100g": 4.23,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 4.23,
          "max": 4.23
        },
        {
          "source_key": "4",
          "name": "Yağ, toplam",
          "amount_100g": 26.06,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 26.06,
          "max": 26.06
        },
        {
          "source_key": "155",
          "name": "Karbonhidrat",
          "amount_100g": 2.56,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.56,
          "max": 2.56
        },
        {
          "source_key": "11",
          "name": "Lif, toplam diyet",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "10",
          "name": "Sakaroz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "100",
          "name": "Glukoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "6",
          "name": "Fruktoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "8",
          "name": "Laktoz",
          "amount_100g": 0.15,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.15,
          "max": 0.15
        },
        {
          "source_key": "9",
          "name": "Maltoz",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0,
          "max": 0
        },
        {
          "source_key": "461",
          "name": "Tuz",
          "amount_100g": 1620,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1620,
          "max": 1620
        },
        {
          "source_key": "22",
          "name": "Demir, Fe",
          "amount_100g": 0.13,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.13,
          "max": 0.13
        },
        {
          "source_key": "24",
          "name": "Fosfor, P",
          "amount_100g": 521,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 521,
          "max": 521
        },
        {
          "source_key": "21",
          "name": "Kalsiyum, Ca",
          "amount_100g": 668,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 668,
          "max": 668
        },
        {
          "source_key": "23",
          "name": "Magnezyum, Mg",
          "amount_100g": 25,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 25,
          "max": 25
        },
        {
          "source_key": "25",
          "name": "Potasyum, K",
          "amount_100g": 78,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 78,
          "max": 78
        },
        {
          "source_key": "26",
          "name": "Sodyum, Na",
          "amount_100g": 648,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 648,
          "max": 648
        },
        {
          "source_key": "27",
          "name": "Çinko, Zn",
          "amount_100g": 3.35,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.35,
          "max": 3.35
        },
        {
          "source_key": "30",
          "name": "Selenyum, Se",
          "amount_100g": 7.2,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 7.2,
          "max": 7.2
        },
        {
          "source_key": "35",
          "name": "Tiamin",
          "amount_100g": 0.03,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.03,
          "max": 0.03
        },
        {
          "source_key": "36",
          "name": "Riboflavin",
          "amount_100g": 0.296,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.296,
          "max": 0.296
        },
        {
          "source_key": "465",
          "name": "Niasin eşdeğerleri, toplam",
          "amount_100g": 5.872,
          "unit": "NE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 5.872,
          "max": 5.872
        },
        {
          "source_key": "37",
          "name": "Niasin",
          "amount_100g": 0.086,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.086,
          "max": 0.086
        },
        {
          "source_key": "38",
          "name": "B-6 vitamini, toplam",
          "amount_100g": 0.055,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.055,
          "max": 0.055
        },
        {
          "source_key": "562",
          "name": "Folat, gıda",
          "amount_100g": 6,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6,
          "max": 6
        },
        {
          "source_key": "41",
          "name": "B-12 vitamini",
          "amount_100g": 1.36,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.36,
          "max": 1.36
        },
        {
          "source_key": "139",
          "name": "A vitamini",
          "amount_100g": 175,
          "unit": "RE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 175,
          "max": 175
        },
        {
          "source_key": "43",
          "name": "Retinol",
          "amount_100g": 175,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 175,
          "max": 175
        },
        {
          "source_key": "561",
          "name": "D vitamini, IU",
          "amount_100g": 131,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 131,
          "max": 131
        },
        {
          "source_key": "50",
          "name": "D-3 vitamini (kolekalsiferol)",
          "amount_100g": 3.3,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3.3,
          "max": 3.3
        },
        {
          "source_key": "540",
          "name": "E vitamini",
          "amount_100g": 1,
          "unit": "α-TE",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1,
          "max": 1
        },
        {
          "source_key": "560",
          "name": "E vitamini, IU",
          "amount_100g": 1.48,
          "unit": "IU",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1.48,
          "max": 1.48
        },
        {
          "source_key": "49",
          "name": "Alfa-tokoferol",
          "amount_100g": 1,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1,
          "max": 1
        },
        {
          "source_key": "54",
          "name": "K-2 vitamini",
          "amount_100g": 2.7,
          "unit": "µg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.7,
          "max": 2.7
        },
        {
          "source_key": "145",
          "name": "Yağ asitleri, toplam doymuş",
          "amount_100g": 17.63,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 17.63,
          "max": 17.63
        },
        {
          "source_key": "146",
          "name": "Yağ asitleri, toplam tekli doymamış",
          "amount_100g": 7.626,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 7.626,
          "max": 7.626
        },
        {
          "source_key": "147",
          "name": "Yağ asitleri, toplam çoklu doymamış",
          "amount_100g": 0.632,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.632,
          "max": 0.632
        },
        {
          "source_key": "55",
          "name": "Yağ asidi 4:0 (bütirik asit)",
          "amount_100g": 0.632,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.632,
          "max": 0.632
        },
        {
          "source_key": "56",
          "name": "Yağ asidi 6:0 (kaproik asit)",
          "amount_100g": 0.44,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.44,
          "max": 0.44
        },
        {
          "source_key": "57",
          "name": "Yağ asidi 8:0 (kaprilik asit)",
          "amount_100g": 0.28,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.28,
          "max": 0.28
        },
        {
          "source_key": "58",
          "name": "Yağ asidi 10:0 (kaprik asit)",
          "amount_100g": 0.637,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.637,
          "max": 0.637
        },
        {
          "source_key": "59",
          "name": "Yağ asidi 12:0 (laurik asit)",
          "amount_100g": 0.777,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.777,
          "max": 0.777
        },
        {
          "source_key": "60",
          "name": "Yağ asidi 14:0 (miristik asit)",
          "amount_100g": 2.845,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.845,
          "max": 2.845
        },
        {
          "source_key": "61",
          "name": "Yağ asidi 15:0 (pentadesilik asit )",
          "amount_100g": 0.301,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.301,
          "max": 0.301
        },
        {
          "source_key": "62",
          "name": "Yağ asidi 16:0 (palmitik asit)",
          "amount_100g": 8.481,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 8.481,
          "max": 8.481
        },
        {
          "source_key": "63",
          "name": "Yağ asidi 17:0 (margarik asit)",
          "amount_100g": 0.179,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.179,
          "max": 0.179
        },
        {
          "source_key": "64",
          "name": "Yağ asidi 18:0 (stearik asit)",
          "amount_100g": 2.855,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2.855,
          "max": 2.855
        },
        {
          "source_key": "65",
          "name": "Yağ asidi 20:0 (araşidik asit)",
          "amount_100g": 0.202,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.202,
          "max": 0.202
        },
        {
          "source_key": "68",
          "name": "Yağ asidi 14:1 n-5 cis (miristoleik asit)",
          "amount_100g": 0.342,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.342,
          "max": 0.342
        },
        {
          "source_key": "69",
          "name": "Yağ asidi 16:1 n-7 cis (palmitoleik asit)",
          "amount_100g": 0.42,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.42,
          "max": 0.42
        },
        {
          "source_key": "70",
          "name": "Yağ asidi 18:1 n-9 cis (oleik asit)",
          "amount_100g": 6.864,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 6.864,
          "max": 6.864
        },
        {
          "source_key": "75",
          "name": "Yağ asidi 18:2 n-6 cis,cis",
          "amount_100g": 0.567,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.567,
          "max": 0.567
        },
        {
          "source_key": "76",
          "name": "Yağ asidi 18:3 n-3 all-cis",
          "amount_100g": 0.065,
          "unit": "g",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 0.065,
          "max": 0.065
        },
        {
          "source_key": "557",
          "name": "Kolesterol",
          "amount_100g": 70,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 70,
          "max": 70
        },
        {
          "source_key": "105",
          "name": "Triptofan",
          "amount_100g": 347,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 347,
          "max": 347
        },
        {
          "source_key": "94",
          "name": "Treonin",
          "amount_100g": 821,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 821,
          "max": 821
        },
        {
          "source_key": "93",
          "name": "Izolosin",
          "amount_100g": 880,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 880,
          "max": 880
        },
        {
          "source_key": "92",
          "name": "Lösin",
          "amount_100g": 2178,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2178,
          "max": 2178
        },
        {
          "source_key": "102",
          "name": "Lizin",
          "amount_100g": 3205,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 3205,
          "max": 3205
        },
        {
          "source_key": "98",
          "name": "Metiyonin",
          "amount_100g": 475,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 475,
          "max": 475
        },
        {
          "source_key": "106",
          "name": "Sistin",
          "amount_100g": 131,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 131,
          "max": 131
        },
        {
          "source_key": "101",
          "name": "Fenilalanin",
          "amount_100g": 1251,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1251,
          "max": 1251
        },
        {
          "source_key": "104",
          "name": "Tirozin",
          "amount_100g": 1433,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1433,
          "max": 1433
        },
        {
          "source_key": "91",
          "name": "Valin",
          "amount_100g": 1112,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1112,
          "max": 1112
        },
        {
          "source_key": "153",
          "name": "Arjinin",
          "amount_100g": 465,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 465,
          "max": 465
        },
        {
          "source_key": "103",
          "name": "Histidin",
          "amount_100g": 882,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 882,
          "max": 882
        },
        {
          "source_key": "89",
          "name": "Alanin",
          "amount_100g": 777,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 777,
          "max": 777
        },
        {
          "source_key": "97",
          "name": "Aspartik asit",
          "amount_100g": 1078,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1078,
          "max": 1078
        },
        {
          "source_key": "154",
          "name": "Glutamik asit",
          "amount_100g": 5149,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 5149,
          "max": 5149
        },
        {
          "source_key": "90",
          "name": "Glisin",
          "amount_100g": 450,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 450,
          "max": 450
        },
        {
          "source_key": "96",
          "name": "Prolin",
          "amount_100g": 2820,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 2820,
          "max": 2820
        },
        {
          "source_key": "95",
          "name": "Serin",
          "amount_100g": 1528,
          "unit": "mg",
          "derivation_code": "TURKOMP_AVERAGE",
          "derivation_description": "Published TürKomp average per 100 g edible portion",
          "min": 1528,
          "max": 1528
        },
        {
          "source_key": "derived:sugars_sum",
          "name": "Total sugars (sum of published mono/disaccharides)",
          "amount_100g": 0.15,
          "unit": "g",
          "derivation_code": "SUM_COMPONENTS",
          "derivation_description": "Sum of 5 available TürKomp sugar components; not a separately published total"
        }
      ],
      "kcal_100g": 353,
      "protein_100g": 26.99,
      "fat_100g": 26.06,
      "carbs_100g": 2.56,
      "fiber_100g": 0,
      "sodium_mg_100g": 648,
      "sugars_100g": 0.15
    },
    "portions": [],
    "food_code": "01.02.0006",
    "classification_codes": [
      {
        "system": "LanguaL",
        "codes": [
          "A0117",
          "A0311",
          "A0452",
          "A0720",
          "A0724",
          "A0787",
          "B1201",
          "C0235",
          "E0119",
          "F0018",
          "G0001",
          "H0247",
          "H0753",
          "J0135",
          "J0137",
          "K0003",
          "M0003",
          "N0001",
          "P0026",
          "R0403",
          "Z0112"
        ]
      }
    ],
    "quality": {
      "nutrition_completeness": 1,
      "confidence_inputs": [
        "published_average",
        "published_min_max",
        "per_100g_edible_portion",
        "derived_sugar_component_sum"
      ]
    },
    "provenance": {
      "source_url": "https://turkomp.tarimorman.gov.tr/food-peynir-kasar-olgunlastirilmamis-taze-11",
      "nutrient_basis_note": "Values are per 100 g edible food. Numeric average/min/max are retained without imputation.",
      "attribution": "TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı"
    },
    "nutrient_conversion_factors": [
      {
        "type": "nitrogen",
        "value": 6.38
      },
      {
        "type": "fat",
        "value": 0.945
      }
    ]
  }
]
```

## openfoodfacts

- Dataset version: Daily export, downloaded 2026-08-22
- Input/output/skipped: 4,699,315 / 930,895 / 3,768,420
- Skip reasons: `missing_energy`: 2,727,591, `implausible_core_nutrition`: 16,163, `missing_nutriments`: 625,550, `missing_name`: 324,502, `insufficient_core_nutrition`: 5,422, `invalid_or_missing_barcode`: 69,192
- Nutrition completeness: 90.94%
- Portion coverage: 68.95%
- Barcode coverage: 100.00%

### 10 normalized examples

```json
[
  {
    "schema_version": "1.0.0",
    "name": "Lagg's, herbal tea, peppermint",
    "source": "open_food_facts",
    "source_id": "0000105000042",
    "dataset_version": "Daily export, downloaded 2026-08-22",
    "category": {
      "name": "Plant-based foods and beverages, Beverages, Hot beverages, Plant-based beverages, Teas, Tea bags",
      "tags": [
        "en:plant-based-foods-and-beverages",
        "en:beverages",
        "en:hot-beverages",
        "en:plant-based-beverages",
        "en:teas",
        "en:tea-bags"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "Open Food Facts nutriments *_100g fields"
    },
    "nutrition": {
      "kcal_100g": 0,
      "protein_100g": 0,
      "carbs_100g": 1.47,
      "fat_100g": 0,
      "sodium_mg_100g": 4,
      "nutrients": [
        {
          "source_key": "sodium",
          "name": "sodium",
          "amount_100g": 0.004,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "fruits-vegetables-legumes-estimate-from-ingredients",
          "name": "fruits vegetables legumes estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "carbohydrates",
          "name": "carbohydrates",
          "amount_100g": 1.47,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "nova-group",
          "name": "nova group",
          "amount_100g": 1,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-nuts-estimate-from-ingredients",
          "name": "fruits vegetables nuts estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "salt",
          "name": "salt",
          "amount_100g": 0.01,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "potassium",
          "name": "potassium",
          "amount_100g": 0.02,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "fat",
          "name": "fat",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "proteins",
          "name": "proteins",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy",
          "name": "energy",
          "amount_100g": 0,
          "unit": "kJ",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: kcal"
        },
        {
          "source_key": "energy-kcal",
          "name": "energy kcal",
          "amount_100g": 0,
          "unit": "kcal",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        }
      ]
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1.61 ONZ (45 g)",
        "gram_weight": 45
      }
    ],
    "serving_size": 45,
    "serving_unit": "g",
    "household_serving_description": "1.61 ONZ (45 g)",
    "brand": "Lagg's",
    "barcode": "0000105000042",
    "ingredients": "Peppermint.",
    "aliases": [],
    "language": "en",
    "languages": [
      "en"
    ],
    "countries": [
      "en:united-states"
    ],
    "quality": {
      "nutrition_completeness": 0.7143,
      "source_completeness": 0.5,
      "source_quality_tags": [
        "en:no-packaging-data",
        "en:ingredients-percent-analysis-ok",
        "en:all-but-one-ingredient-with-specified-percent",
        "en:ecoscore-extended-data-not-computed",
        "en:food-groups-1-known",
        "en:food-groups-2-known",
        "en:food-groups-3-unknown",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "source_warning_tags": [
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "confidence_inputs": [
        "barcode",
        "per_100g_nutrients",
        "serving_text",
        "off_completeness",
        "off_quality_tags"
      ]
    },
    "provenance": {
      "modified_date": "2020-04-22T16:31:58.000Z",
      "source_url": "https://world.openfoodfacts.org/product/0000105000042",
      "source_data_type": "food",
      "attribution": "Open Food Facts contributors"
    },
    "scores": {
      "nutriscore_grade": "unknown",
      "nutriscore_version": "2021",
      "nova_group": 1
    },
    "ingredient_analysis_tags": [
      "en:palm-oil-free",
      "en:vegan",
      "en:vegetarian"
    ],
    "popularity": {}
  },
  {
    "schema_version": "1.0.0",
    "name": "Herbal Tea, Hibiscus",
    "source": "open_food_facts",
    "source_id": "0000105000073",
    "dataset_version": "Daily export, downloaded 2026-08-22",
    "category": {},
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "Open Food Facts nutriments *_100g fields"
    },
    "nutrition": {
      "kcal_100g": 267,
      "protein_100g": 66.67,
      "carbs_100g": 60,
      "fat_100g": 0,
      "sodium_mg_100g": 135.128,
      "nutrients": [
        {
          "source_key": "energy",
          "name": "energy",
          "amount_100g": 1117,
          "unit": "kJ",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: kcal"
        },
        {
          "source_key": "energy-kcal",
          "name": "energy kcal",
          "amount_100g": 267,
          "unit": "kcal",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "potassium",
          "name": "potassium",
          "amount_100g": 1.533,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "fat",
          "name": "fat",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "proteins",
          "name": "proteins",
          "amount_100g": 66.67,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "salt",
          "name": "salt",
          "amount_100g": 0.33782,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-nuts-estimate-from-ingredients",
          "name": "fruits vegetables nuts estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "carbohydrates",
          "name": "carbohydrates",
          "amount_100g": 60,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-legumes-estimate-from-ingredients",
          "name": "fruits vegetables legumes estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "sodium",
          "name": "sodium",
          "amount_100g": 0.135128,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        }
      ]
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1.5 g (1 TEA BAG)",
        "gram_weight": 1.5
      }
    ],
    "serving_size": 1.5,
    "household_serving_description": "1.5 g (1 TEA BAG)",
    "brand": "Lagg's",
    "barcode": "0000105000073",
    "ingredients": "Hibiscus flowers.",
    "aliases": [],
    "language": "en",
    "languages": [
      "en"
    ],
    "countries": [
      "en:united-states"
    ],
    "quality": {
      "nutrition_completeness": 0.7143,
      "source_completeness": 0.4,
      "source_quality_tags": [
        "en:no-packaging-data",
        "en:ingredients-percent-analysis-ok",
        "en:all-but-one-ingredient-with-specified-percent",
        "en:ecoscore-extended-data-not-computed",
        "en:food-groups-1-unknown",
        "en:food-groups-2-unknown",
        "en:food-groups-3-unknown",
        "en:energy-value-in-kcal-may-not-match-value-computed-from-other-nutrients",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label",
        "en:nutrition-value-total-over-105",
        "en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients"
      ],
      "source_warning_tags": [
        "en:energy-value-in-kcal-may-not-match-value-computed-from-other-nutrients",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "source_error_tags": [
        "en:nutrition-value-total-over-105",
        "en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients"
      ],
      "confidence_inputs": [
        "barcode",
        "per_100g_nutrients",
        "serving_text",
        "off_completeness",
        "off_quality_tags"
      ]
    },
    "provenance": {
      "modified_date": "2017-03-09T21:56:11.000Z",
      "source_url": "https://world.openfoodfacts.org/product/0000105000073",
      "source_data_type": "food",
      "attribution": "Open Food Facts contributors"
    },
    "scores": {
      "nutriscore_grade": "unknown",
      "nutriscore_version": "2021"
    },
    "ingredient_analysis_tags": [
      "en:palm-oil-free",
      "en:vegan",
      "en:vegetarian"
    ],
    "popularity": {}
  },
  {
    "schema_version": "1.0.0",
    "name": "Green Tea",
    "source": "open_food_facts",
    "source_id": "0000105000219",
    "dataset_version": "Daily export, downloaded 2026-08-22",
    "category": {
      "name": "null",
      "tags": [
        "en:null"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "Open Food Facts nutriments *_100g fields"
    },
    "nutrition": {
      "kcal_100g": 35.5,
      "protein_100g": 0,
      "carbs_100g": 8.89,
      "fat_100g": 0,
      "sodium_mg_100g": 0,
      "nutrients": [
        {
          "source_key": "salt",
          "name": "salt",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "potassium",
          "name": "potassium",
          "amount_100g": 0.256,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "proteins",
          "name": "proteins",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "sodium",
          "name": "sodium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "energy-kcal",
          "name": "energy kcal",
          "amount_100g": 35.5,
          "unit": "kcal",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy",
          "name": "energy",
          "amount_100g": 150,
          "unit": "kJ",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: kcal"
        },
        {
          "source_key": "carbohydrates",
          "name": "carbohydrates",
          "amount_100g": 8.89,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "nova-group",
          "name": "nova group",
          "amount_100g": 1,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-legumes-estimate-from-ingredients",
          "name": "fruits vegetables legumes estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fat",
          "name": "fat",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-nuts-estimate-from-ingredients",
          "name": "fruits vegetables nuts estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        }
      ]
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "30.05047g",
        "gram_weight": 30.05047
      }
    ],
    "serving_size": 30.05047,
    "serving_unit": "g",
    "household_serving_description": "30.05047g",
    "brand": "Lagg's",
    "barcode": "0000105000219",
    "ingredients": "GREEN TEA.",
    "aliases": [],
    "language": "en",
    "languages": [
      "en"
    ],
    "countries": [
      "en:united-states"
    ],
    "package_size": "30 g",
    "quality": {
      "nutrition_completeness": 0.7143,
      "source_completeness": 0.6,
      "source_quality_tags": [
        "en:no-packaging-data",
        "en:ingredients-percent-analysis-ok",
        "en:all-but-one-ingredient-with-specified-percent",
        "en:environmental-score-extended-data-not-computed",
        "en:food-groups-1-unknown",
        "en:food-groups-2-unknown",
        "en:food-groups-3-unknown",
        "en:serving-quantity-over-product-quantity",
        "en:environmental-score-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:environmental-score-packaging-packaging-data-missing",
        "en:environmental-score-production-system-no-label"
      ],
      "source_warning_tags": [
        "en:serving-quantity-over-product-quantity",
        "en:environmental-score-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:environmental-score-packaging-packaging-data-missing",
        "en:environmental-score-production-system-no-label"
      ],
      "confidence_inputs": [
        "barcode",
        "per_100g_nutrients",
        "serving_text",
        "off_completeness",
        "off_quality_tags"
      ]
    },
    "provenance": {
      "modified_date": "2025-02-21T23:16:38.000Z",
      "source_url": "https://world.openfoodfacts.org/product/0000105000219",
      "source_data_type": "food",
      "attribution": "Open Food Facts contributors"
    },
    "scores": {
      "nutriscore_grade": "unknown",
      "nutriscore_version": "2023",
      "nova_group": 1,
      "environmental_score_grade": "unknown"
    },
    "ingredient_analysis_tags": [
      "en:palm-oil-free",
      "en:vegan",
      "en:vegetarian"
    ],
    "popularity": {}
  },
  {
    "schema_version": "1.0.0",
    "name": "Shave Grass Herbal Tea",
    "source": "open_food_facts",
    "source_id": "0000105000318",
    "dataset_version": "Daily export, downloaded 2026-08-22",
    "category": {
      "name": "null",
      "tags": [
        "en:null"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "Open Food Facts nutriments *_100g fields"
    },
    "nutrition": {
      "kcal_100g": 44.3,
      "protein_100g": 0,
      "carbs_100g": 11.1,
      "fat_100g": 0,
      "sodium_mg_100g": 0,
      "nutrients": [
        {
          "source_key": "potassium",
          "name": "potassium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "proteins",
          "name": "proteins",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "sodium",
          "name": "sodium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "salt",
          "name": "salt",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "energy-kcal",
          "name": "energy kcal",
          "amount_100g": 44.3,
          "unit": "kcal",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy",
          "name": "energy",
          "amount_100g": 186,
          "unit": "kJ",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: kcal"
        },
        {
          "source_key": "carbohydrates",
          "name": "carbohydrates",
          "amount_100g": 11.1,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-legumes-estimate-from-ingredients",
          "name": "fruits vegetables legumes estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fat",
          "name": "fat",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-nuts-estimate-from-ingredients",
          "name": "fruits vegetables nuts estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        }
      ]
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "30.05047g",
        "gram_weight": 30.05047
      }
    ],
    "serving_size": 30.05047,
    "serving_unit": "g",
    "household_serving_description": "30.05047g",
    "brand": "Lagg's",
    "barcode": "0000105000318",
    "ingredients": "SHAVE GRASS.",
    "aliases": [],
    "language": "en",
    "languages": [
      "en"
    ],
    "countries": [
      "en:united-states"
    ],
    "package_size": "30 g",
    "quality": {
      "nutrition_completeness": 0.7143,
      "source_completeness": 0.6,
      "source_quality_tags": [
        "en:no-packaging-data",
        "en:ingredients-percent-analysis-ok",
        "en:all-but-one-ingredient-with-specified-percent",
        "en:environmental-score-extended-data-not-computed",
        "en:food-groups-1-unknown",
        "en:food-groups-2-unknown",
        "en:food-groups-3-unknown",
        "en:ingredients-unknown-score-above-0",
        "en:ingredients-100-percent-unknown",
        "en:serving-quantity-over-product-quantity",
        "en:environmental-score-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:environmental-score-packaging-packaging-data-missing",
        "en:environmental-score-production-system-no-label"
      ],
      "source_warning_tags": [
        "en:ingredients-unknown-score-above-0",
        "en:ingredients-100-percent-unknown",
        "en:serving-quantity-over-product-quantity",
        "en:environmental-score-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:environmental-score-packaging-packaging-data-missing",
        "en:environmental-score-production-system-no-label"
      ],
      "confidence_inputs": [
        "barcode",
        "per_100g_nutrients",
        "serving_text",
        "off_completeness",
        "off_quality_tags"
      ]
    },
    "provenance": {
      "modified_date": "2025-02-21T23:16:38.000Z",
      "source_url": "https://world.openfoodfacts.org/product/0000105000318",
      "source_data_type": "food",
      "attribution": "Open Food Facts contributors"
    },
    "scores": {
      "nutriscore_grade": "unknown",
      "nutriscore_version": "2023",
      "environmental_score_grade": "unknown"
    },
    "ingredient_analysis_tags": [
      "en:palm-oil-content-unknown",
      "en:vegan-status-unknown",
      "en:vegetarian-status-unknown"
    ],
    "popularity": {}
  },
  {
    "schema_version": "1.0.0",
    "name": "Lagg's, herbal tea, chamomile * mint",
    "source": "open_food_facts",
    "source_id": "0000105000356",
    "dataset_version": "Daily export, downloaded 2026-08-22",
    "category": {
      "name": "Plant-based foods and beverages, Beverages, Hot beverages, Plant-based beverages, Teas, Tea bags",
      "tags": [
        "en:plant-based-foods-and-beverages",
        "en:beverages",
        "en:hot-beverages",
        "en:plant-based-beverages",
        "en:teas",
        "en:tea-bags"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "Open Food Facts nutriments *_100g fields"
    },
    "nutrition": {
      "kcal_100g": 0,
      "protein_100g": 0,
      "carbs_100g": 3.33,
      "fat_100g": 0,
      "sodium_mg_100g": 0,
      "nutrients": [
        {
          "source_key": "sodium",
          "name": "sodium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "carbohydrates",
          "name": "carbohydrates",
          "amount_100g": 3.33,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-legumes-estimate-from-ingredients",
          "name": "fruits vegetables legumes estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-nuts-estimate-from-ingredients",
          "name": "fruits vegetables nuts estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy",
          "name": "energy",
          "amount_100g": 0,
          "unit": "kJ",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: kcal"
        },
        {
          "source_key": "energy-kcal",
          "name": "energy kcal",
          "amount_100g": 0,
          "unit": "kcal",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "potassium",
          "name": "potassium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "fat",
          "name": "fat",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "proteins",
          "name": "proteins",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "salt",
          "name": "salt",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        }
      ]
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1.06 ONZ (30 g)",
        "gram_weight": 30
      }
    ],
    "serving_size": 30,
    "serving_unit": "g",
    "household_serving_description": "1.06 ONZ (30 g)",
    "brand": "Lagg's",
    "barcode": "0000105000356",
    "ingredients": "Chamomile spearmint.",
    "aliases": [],
    "language": "en",
    "languages": [
      "en"
    ],
    "countries": [
      "en:united-states"
    ],
    "quality": {
      "nutrition_completeness": 0.7143,
      "source_completeness": 0.5,
      "source_quality_tags": [
        "en:no-packaging-data",
        "en:ingredients-percent-analysis-ok",
        "en:all-but-one-ingredient-with-specified-percent",
        "en:ecoscore-extended-data-not-computed",
        "en:food-groups-1-known",
        "en:food-groups-2-known",
        "en:food-groups-3-unknown",
        "en:ingredients-unknown-score-above-0",
        "en:ingredients-100-percent-unknown",
        "en:energy-value-in-kcal-may-not-match-value-computed-from-other-nutrients",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label",
        "en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients"
      ],
      "source_warning_tags": [
        "en:ingredients-unknown-score-above-0",
        "en:ingredients-100-percent-unknown",
        "en:energy-value-in-kcal-may-not-match-value-computed-from-other-nutrients",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "source_error_tags": [
        "en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients"
      ],
      "confidence_inputs": [
        "barcode",
        "per_100g_nutrients",
        "serving_text",
        "off_completeness",
        "off_quality_tags"
      ]
    },
    "provenance": {
      "modified_date": "2020-04-22T16:31:58.000Z",
      "source_url": "https://world.openfoodfacts.org/product/0000105000356",
      "source_data_type": "food",
      "attribution": "Open Food Facts contributors"
    },
    "scores": {
      "nutriscore_grade": "unknown",
      "nutriscore_version": "2021"
    },
    "ingredient_analysis_tags": [
      "en:palm-oil-content-unknown",
      "en:vegan-status-unknown",
      "en:vegetarian-status-unknown"
    ],
    "popularity": {}
  },
  {
    "schema_version": "1.0.0",
    "name": "Artichoke Herbal Tea",
    "source": "open_food_facts",
    "source_id": "0000105000363",
    "dataset_version": "Daily export, downloaded 2026-08-22",
    "category": {
      "name": "null",
      "tags": [
        "en:null"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "Open Food Facts nutriments *_100g fields"
    },
    "nutrition": {
      "kcal_100g": 44.3,
      "protein_100g": 0,
      "carbs_100g": 11.1,
      "fat_100g": 0,
      "sodium_mg_100g": 0,
      "nutrients": [
        {
          "source_key": "carbohydrates",
          "name": "carbohydrates",
          "amount_100g": 11.1,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-legumes-estimate-from-ingredients",
          "name": "fruits vegetables legumes estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fat",
          "name": "fat",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-nuts-estimate-from-ingredients",
          "name": "fruits vegetables nuts estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "potassium",
          "name": "potassium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "proteins",
          "name": "proteins",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "sodium",
          "name": "sodium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "salt",
          "name": "salt",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy-kcal",
          "name": "energy kcal",
          "amount_100g": 44.3,
          "unit": "kcal",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy",
          "name": "energy",
          "amount_100g": 186,
          "unit": "kJ",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: kcal"
        }
      ]
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "30.05047g",
        "gram_weight": 30.05047
      }
    ],
    "serving_size": 30.05047,
    "serving_unit": "g",
    "household_serving_description": "30.05047g",
    "brand": "Lagg's",
    "barcode": "0000105000363",
    "ingredients": "ARTICHOKE MALVA SENNA LEAF HIBISCUS CHAMOMILE NATURAL APPLE FLAVOR.",
    "aliases": [],
    "language": "en",
    "languages": [
      "en"
    ],
    "countries": [
      "en:united-states"
    ],
    "package_size": "30 g",
    "quality": {
      "nutrition_completeness": 0.7143,
      "source_completeness": 0.6,
      "source_quality_tags": [
        "en:no-packaging-data",
        "en:ingredients-percent-analysis-ok",
        "en:all-but-one-ingredient-with-specified-percent",
        "en:environmental-score-extended-data-not-computed",
        "en:food-groups-1-unknown",
        "en:food-groups-2-unknown",
        "en:food-groups-3-unknown",
        "en:ingredients-unknown-score-above-0",
        "en:ingredients-100-percent-unknown",
        "en:ingredients-ingredient-tag-length-greater-than-50",
        "en:serving-quantity-over-product-quantity",
        "en:environmental-score-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:environmental-score-packaging-packaging-data-missing",
        "en:environmental-score-production-system-no-label"
      ],
      "source_warning_tags": [
        "en:ingredients-unknown-score-above-0",
        "en:ingredients-100-percent-unknown",
        "en:ingredients-ingredient-tag-length-greater-than-50",
        "en:serving-quantity-over-product-quantity",
        "en:environmental-score-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:environmental-score-packaging-packaging-data-missing",
        "en:environmental-score-production-system-no-label"
      ],
      "confidence_inputs": [
        "barcode",
        "per_100g_nutrients",
        "serving_text",
        "off_completeness",
        "off_quality_tags"
      ]
    },
    "provenance": {
      "modified_date": "2025-02-21T23:16:39.000Z",
      "source_url": "https://world.openfoodfacts.org/product/0000105000363",
      "source_data_type": "food",
      "attribution": "Open Food Facts contributors"
    },
    "scores": {
      "nutriscore_grade": "unknown",
      "nutriscore_version": "2023",
      "environmental_score_grade": "unknown"
    },
    "ingredient_analysis_tags": [
      "en:palm-oil-content-unknown",
      "en:vegan-status-unknown",
      "en:vegetarian-status-unknown"
    ],
    "popularity": {}
  },
  {
    "schema_version": "1.0.0",
    "name": "Lagg's, dieter's herbal tea",
    "source": "open_food_facts",
    "source_id": "0000105000417",
    "dataset_version": "Daily export, downloaded 2026-08-22",
    "category": {
      "name": "Plant-based foods and beverages, Beverages, Hot beverages, Plant-based beverages, Teas, Tea bags",
      "tags": [
        "en:plant-based-foods-and-beverages",
        "en:beverages",
        "en:hot-beverages",
        "en:plant-based-beverages",
        "en:teas",
        "en:tea-bags"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "Open Food Facts nutriments *_100g fields"
    },
    "nutrition": {
      "kcal_100g": 0,
      "protein_100g": 0,
      "carbs_100g": 0,
      "fat_100g": 0,
      "sodium_mg_100g": 0,
      "nutrients": [
        {
          "source_key": "sodium",
          "name": "sodium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "fruits-vegetables-legumes-estimate-from-ingredients",
          "name": "fruits vegetables legumes estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "carbohydrates",
          "name": "carbohydrates",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "nutrition-score-fr",
          "name": "nutrition score fr",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "nova-group",
          "name": "nova group",
          "amount_100g": 1,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-nuts-estimate-from-ingredients",
          "name": "fruits vegetables nuts estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "salt",
          "name": "salt",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "proteins",
          "name": "proteins",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fat",
          "name": "fat",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "potassium",
          "name": "potassium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "energy-kcal",
          "name": "energy kcal",
          "amount_100g": 0,
          "unit": "kcal",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy",
          "name": "energy",
          "amount_100g": 0,
          "unit": "kJ",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: kcal"
        }
      ]
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1.61 ONZ (45 g)",
        "gram_weight": 45
      }
    ],
    "serving_size": 45,
    "serving_unit": "g",
    "household_serving_description": "1.61 ONZ (45 g)",
    "brand": "Lagg's",
    "barcode": "0000105000417",
    "ingredients": "Andropogon citratus, uva ursi, hibiscus flowers, cinnamon, equisetum arvense, flourensia cernua.",
    "aliases": [],
    "language": "en",
    "languages": [
      "en"
    ],
    "countries": [
      "en:united-states"
    ],
    "quality": {
      "nutrition_completeness": 0.7143,
      "source_completeness": 0.5,
      "source_quality_tags": [
        "en:no-packaging-data",
        "en:ingredients-percent-analysis-ok",
        "en:ecoscore-extended-data-not-computed",
        "en:food-groups-1-known",
        "en:food-groups-2-known",
        "en:food-groups-3-unknown",
        "en:ingredients-50-percent-unknown",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "source_warning_tags": [
        "en:ingredients-50-percent-unknown",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "confidence_inputs": [
        "barcode",
        "per_100g_nutrients",
        "serving_text",
        "off_completeness",
        "off_quality_tags"
      ]
    },
    "provenance": {
      "modified_date": "2020-04-22T16:31:58.000Z",
      "source_url": "https://world.openfoodfacts.org/product/0000105000417",
      "source_data_type": "food",
      "attribution": "Open Food Facts contributors"
    },
    "scores": {
      "nutriscore_grade": "b",
      "nutriscore_score": 0,
      "nutriscore_version": "2023",
      "nova_group": 1
    },
    "ingredient_analysis_tags": [
      "en:palm-oil-content-unknown",
      "en:vegan-status-unknown",
      "en:vegetarian-status-unknown"
    ],
    "popularity": {}
  },
  {
    "schema_version": "1.0.0",
    "name": "Lagg's, kidneytea, herbal tea",
    "source": "open_food_facts",
    "source_id": "0000105200923",
    "dataset_version": "Daily export, downloaded 2026-08-22",
    "category": {
      "name": "Plant-based foods and beverages, Beverages, Hot beverages, Plant-based beverages, Teas, Tea bags",
      "tags": [
        "en:plant-based-foods-and-beverages",
        "en:beverages",
        "en:hot-beverages",
        "en:plant-based-beverages",
        "en:teas",
        "en:tea-bags"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "Open Food Facts nutriments *_100g fields"
    },
    "nutrition": {
      "kcal_100g": 0,
      "protein_100g": 0,
      "carbs_100g": 3.33,
      "fat_100g": 0,
      "sodium_mg_100g": 0,
      "nutrients": [
        {
          "source_key": "fruits-vegetables-legumes-estimate-from-ingredients",
          "name": "fruits vegetables legumes estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "carbohydrates",
          "name": "carbohydrates",
          "amount_100g": 3.33,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "sodium",
          "name": "sodium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "salt",
          "name": "salt",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "potassium",
          "name": "potassium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "proteins",
          "name": "proteins",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fat",
          "name": "fat",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy",
          "name": "energy",
          "amount_100g": 0,
          "unit": "kJ",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: kcal"
        },
        {
          "source_key": "energy-kcal",
          "name": "energy kcal",
          "amount_100g": 0,
          "unit": "kcal",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-nuts-estimate-from-ingredients",
          "name": "fruits vegetables nuts estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        }
      ]
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1.06 ONZ (30 g)",
        "gram_weight": 30
      }
    ],
    "serving_size": 30,
    "serving_unit": "g",
    "household_serving_description": "1.06 ONZ (30 g)",
    "brand": "Lagg's",
    "barcode": "0000105200923",
    "ingredients": "Shave grass, corn silk, uva ursi, juliana adstringen, boldo, hibiscus flowers, orange blossom.",
    "aliases": [],
    "language": "en",
    "languages": [
      "en"
    ],
    "countries": [
      "en:united-states"
    ],
    "quality": {
      "nutrition_completeness": 0.7143,
      "source_completeness": 0.5,
      "source_quality_tags": [
        "en:no-packaging-data",
        "en:ingredients-percent-analysis-ok",
        "en:ecoscore-extended-data-not-computed",
        "en:food-groups-1-known",
        "en:food-groups-2-known",
        "en:food-groups-3-unknown",
        "en:ingredients-unknown-score-above-0",
        "en:ingredients-70-percent-unknown",
        "en:energy-value-in-kcal-may-not-match-value-computed-from-other-nutrients",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label",
        "en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients"
      ],
      "source_warning_tags": [
        "en:ingredients-unknown-score-above-0",
        "en:ingredients-70-percent-unknown",
        "en:energy-value-in-kcal-may-not-match-value-computed-from-other-nutrients",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "source_error_tags": [
        "en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients"
      ],
      "confidence_inputs": [
        "barcode",
        "per_100g_nutrients",
        "serving_text",
        "off_completeness",
        "off_quality_tags"
      ]
    },
    "provenance": {
      "modified_date": "2020-04-22T16:31:58.000Z",
      "source_url": "https://world.openfoodfacts.org/product/0000105200923",
      "source_data_type": "food",
      "attribution": "Open Food Facts contributors"
    },
    "scores": {
      "nutriscore_grade": "unknown",
      "nutriscore_version": "2021"
    },
    "ingredient_analysis_tags": [
      "en:palm-oil-content-unknown",
      "en:vegan-status-unknown",
      "en:vegetarian-status-unknown"
    ],
    "popularity": {}
  },
  {
    "schema_version": "1.0.0",
    "name": "100% Pure Canola Oil",
    "source": "open_food_facts",
    "source_id": "0000111048403",
    "dataset_version": "Daily export, downloaded 2026-08-22",
    "category": {
      "name": "Plant-based foods and beverages, Plant-based foods, Fats, Vegetable fats, Vegetable oils",
      "tags": [
        "en:plant-based-foods-and-beverages",
        "en:plant-based-foods",
        "en:fats",
        "en:vegetable-fats",
        "en:vegetable-oils"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "Open Food Facts nutriments *_100g fields"
    },
    "nutrition": {
      "kcal_100g": 857,
      "protein_100g": 0,
      "carbs_100g": 0,
      "fat_100g": 100,
      "sodium_mg_100g": 0,
      "nutrients": [
        {
          "source_key": "sodium",
          "name": "sodium",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "nova-group",
          "name": "nova group",
          "amount_100g": 2,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "nutrition-score-fr",
          "name": "nutrition score fr",
          "amount_100g": 2,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "carbohydrates",
          "name": "carbohydrates",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-legumes-estimate-from-ingredients",
          "name": "fruits vegetables legumes estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "monounsaturated-fat",
          "name": "monounsaturated fat",
          "amount_100g": 64.29,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-nuts-estimate-from-ingredients",
          "name": "fruits vegetables nuts estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "saturated-fat",
          "name": "saturated fat",
          "amount_100g": 7.14,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "trans-fat",
          "name": "trans fat",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy",
          "name": "energy",
          "amount_100g": 3586,
          "unit": "kJ",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: kcal"
        },
        {
          "source_key": "energy-kcal",
          "name": "energy kcal",
          "amount_100g": 857,
          "unit": "kcal",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "polyunsaturated-fat",
          "name": "polyunsaturated fat",
          "amount_100g": 25,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fat",
          "name": "fat",
          "amount_100g": 100,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "proteins",
          "name": "proteins",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "salt",
          "name": "salt",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        }
      ]
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1 Tbsp (14 g)",
        "gram_weight": 14
      }
    ],
    "serving_size": 14,
    "serving_unit": "g",
    "household_serving_description": "1 Tbsp (14 g)",
    "brand": "Canola Harvest",
    "barcode": "0000111048403",
    "ingredients": "100% canola oil no additives or preservatives",
    "aliases": [],
    "language": "en",
    "languages": [
      "en"
    ],
    "countries": [
      "en:united-states"
    ],
    "quality": {
      "nutrition_completeness": 0.7143,
      "source_completeness": 0.5,
      "source_quality_tags": [
        "en:no-packaging-data",
        "en:ingredients-percent-analysis-ok",
        "en:all-ingredients-with-specified-percent",
        "en:sum-of-ingredients-with-unspecified-percent-lesser-than-10",
        "en:ecoscore-extended-data-not-computed",
        "en:food-groups-1-known",
        "en:food-groups-2-known",
        "en:food-groups-3-unknown",
        "en:ingredients-50-percent-unknown",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "source_warning_tags": [
        "en:ingredients-50-percent-unknown",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "confidence_inputs": [
        "barcode",
        "per_100g_nutrients",
        "serving_text",
        "off_completeness",
        "off_quality_tags"
      ]
    },
    "provenance": {
      "modified_date": "2020-04-23T16:07:15.000Z",
      "source_url": "https://world.openfoodfacts.org/product/0000111048403",
      "source_data_type": "food",
      "attribution": "Open Food Facts contributors"
    },
    "scores": {
      "nutriscore_grade": "b",
      "nutriscore_score": 2,
      "nutriscore_version": "2023",
      "nova_group": 2
    },
    "ingredient_analysis_tags": [
      "en:palm-oil-content-unknown",
      "en:vegan-status-unknown",
      "en:vegetarian-status-unknown"
    ],
    "popularity": {}
  },
  {
    "schema_version": "1.0.0",
    "name": "Canola harvest, buttery spread, with flaxseed oil",
    "source": "open_food_facts",
    "source_id": "0000111301263",
    "dataset_version": "Daily export, downloaded 2026-08-22",
    "category": {
      "name": "Fats",
      "tags": [
        "en:fats"
      ]
    },
    "nutrition_basis": {
      "amount": 100,
      "unit": "g",
      "description": "Open Food Facts nutriments *_100g fields"
    },
    "nutrition": {
      "kcal_100g": 571,
      "protein_100g": 0,
      "carbs_100g": 0,
      "fat_100g": 57.14,
      "fiber_100g": 0,
      "sugars_100g": 0,
      "sodium_mg_100g": 536,
      "nutrients": [
        {
          "source_key": "vitamin-a",
          "name": "vitamin a",
          "amount_100g": 0.0010712999999999999,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: IU"
        },
        {
          "source_key": "sugars",
          "name": "sugars",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fiber",
          "name": "fiber",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "nova-group",
          "name": "nova group",
          "amount_100g": 4,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "saturated-fat",
          "name": "saturated fat",
          "amount_100g": 10.71,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "monounsaturated-fat",
          "name": "monounsaturated fat",
          "amount_100g": 32.14,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "cholesterol",
          "name": "cholesterol",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "proteins",
          "name": "proteins",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "salt",
          "name": "salt",
          "amount_100g": 1.34,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "trans-fat",
          "name": "trans fat",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy-kcal",
          "name": "energy kcal",
          "amount_100g": 571,
          "unit": "kcal",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "sodium",
          "name": "sodium",
          "amount_100g": 0.536,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: mg"
        },
        {
          "source_key": "fruits-vegetables-legumes-estimate-from-ingredients",
          "name": "fruits vegetables legumes estimate from ingredients",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "carbohydrates",
          "name": "carbohydrates",
          "amount_100g": 0,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "nutrition-score-fr",
          "name": "nutrition score fr",
          "amount_100g": 11,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fruits-vegetables-nuts-estimate-from-ingredients",
          "name": "fruits vegetables nuts estimate from ingredients",
          "amount_100g": 52.94117647058823,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "vitamin-d",
          "name": "vitamin d",
          "amount_100g": 0.000010725000000000001,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: IU"
        },
        {
          "source_key": "polyunsaturated-fat",
          "name": "polyunsaturated fat",
          "amount_100g": 14.29,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "fat",
          "name": "fat",
          "amount_100g": 57.14,
          "unit": "g",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value"
        },
        {
          "source_key": "energy",
          "name": "energy",
          "amount_100g": 2389,
          "unit": "kJ",
          "derivation_code": "OFF_CONTRIBUTED",
          "derivation_description": "OFF *_100g standardized value; source display unit: kcal"
        }
      ]
    },
    "portions": [
      {
        "amount": 1,
        "unit": "serving",
        "description": "1 Tbsp (14 g)",
        "gram_weight": 14
      }
    ],
    "serving_size": 14,
    "serving_unit": "g",
    "household_serving_description": "1 Tbsp (14 g)",
    "brand": "Canola Harvest",
    "barcode": "0000111301263",
    "ingredients": "Canola oil, water, palm oil, flax oil, palm kernel oil, whey powder (milk), salt, vegetable mono and diglycerides, soybean lecithin, potassium sorbate (preservative), citric acid, artificial flavor, vitamin e (dl-alpha-tocopherol acetate), calcium disodium edta (to preserve freshness), vitamin a palmitate, beta-carotene, vitamin d3.",
    "aliases": [],
    "language": "en",
    "languages": [
      "en"
    ],
    "countries": [
      "en:united-states"
    ],
    "quality": {
      "nutrition_completeness": 1,
      "source_completeness": 0.5,
      "source_quality_tags": [
        "en:no-packaging-data",
        "en:ingredients-percent-analysis-ok",
        "en:ecoscore-extended-data-not-computed",
        "en:food-groups-1-known",
        "en:food-groups-2-known",
        "en:food-groups-3-unknown",
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "source_warning_tags": [
        "en:serving-quantity-defined-but-quantity-undefined",
        "en:ecoscore-origins-of-ingredients-origins-are-100-percent-unknown",
        "en:ecoscore-packaging-packaging-data-missing",
        "en:ecoscore-production-system-no-label"
      ],
      "confidence_inputs": [
        "barcode",
        "per_100g_nutrients",
        "serving_text",
        "off_completeness",
        "off_quality_tags"
      ]
    },
    "provenance": {
      "modified_date": "2020-04-22T16:19:52.000Z",
      "source_url": "https://world.openfoodfacts.org/product/0000111301263",
      "source_data_type": "food",
      "attribution": "Open Food Facts contributors"
    },
    "scores": {
      "nutriscore_grade": "d",
      "nutriscore_score": 11,
      "nutriscore_version": "2023",
      "nova_group": 4
    },
    "allergens": [
      "en:milk",
      "en:soybeans"
    ],
    "ingredient_analysis_tags": [
      "en:palm-oil",
      "en:non-vegan",
      "en:vegetarian-status-unknown"
    ],
    "popularity": {}
  }
]
```

