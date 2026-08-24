# Open Food Facts Global Bilingual Catalog Scoring Report

Input değiştirilmeden streaming olarak skorlandı. Türkiye veya İngilizce relevance hiçbir kaydın elenmesinde kullanılmadı; production candidate seçimi yalnız `data_quality_score >= 80` koşuludur.

## Özet

| Metrik | Değer |
|---|---:|
| Toplam scored ürün | 930.895 |
| Production candidate | 772.837 (83.02%) |
| Yalnız düşük quality nedeniyle excluded | 158.058 (16.98%) |
| Ortalama data quality | 89.07 / 100 |
| Ortalama Turkey relevance | 0.43 / 100 |
| Ortalama English relevance | 69.92 / 100 |
| Derived Turkey-associated brand token | 194 |

## Quality threshold senaryoları

| Minimum quality | Kalan ürün | Coverage |
|---:|---:|---:|
| 40 | 930.890 | 100.00% |
| 50 | 930.844 | 99.99% |
| 60 | 929.963 | 99.90% |
| 70 | 908.945 | 97.64% |
| 80 | 772.837 | 83.02% |
| 90 | 609.193 | 65.44% |

## Scoring özeti

Data quality: valid GTIN 15, anlamlı ad 15, calories 15, protein/carbs/fat 10'ar, brand 10, serving 8 ve category 7 puandır. Standard dışı fakat numeric barcode 7 puan alır. OFF source error tag'leri hata başına 10 (maksimum 30), bug tag'leri hata başına 5 (maksimum 15) puan düşürür.

Turkey relevance: Turkey country tag 45, 869 prefix 30, Türkçe metadata 15 ve dataset içinden türetilen Turkey-associated brand 10 puandır. English relevance: primary/declared English language, English metadata ve English-market tag sinyallerinden oluşur. Relevance yalnız ranking içindir.

## Yüksek kaliteli 50 TR ürün

| # | Ürün | Marka | Barcode | Quality | TR | EN |
|---:|---|---|---|---:|---:|---:|
| 1 | Süzeme peynir | Tek süt | `8690158124295` | 100 | 100 | 50 |
| 2 | Banvit piliç yaprak döner | Banvit | `8690451704477` | 100 | 100 | 70 |
| 3 | O'lala Bar Cake koek | ÜLKER | `8690504059424` | 100 | 100 | 50 |
| 4 | Cake fruits | Ülker | `8690504063421` | 100 | 100 | 50 |
| 5 | Altınbaşak Grissini | Ülker | `8690504074380` | 100 | 100 | 0 |
| 6 | Pastamia | Eti | `8690526029733` | 100 | 100 | 40 |
| 7 | Eti Burçak Fıstık Ezmeli Kremalı | ETİ | `8690526062983` | 100 | 100 | 40 |
| 8 | Lifalif Kuru Meyveli | Eti | `8690526064680` | 100 | 100 | 50 |
| 9 | Maximus küçük | eti | `8690526087351` | 100 | 100 | 0 |
| 10 | Lifalif Puffed Granola | Eti | `8690526267937` | 100 | 100 | 0 |
| 11 | Hindi Göğüs Füme | Pınar | `8690527200285` | 100 | 100 | 50 |
| 12 | Kakao | Migros | `8690547188341` | 100 | 100 | 40 |
| 13 | Makarnalı Ton | Dardanel | `8690559019084` | 100 | 100 | 50 |
| 14 | Ekonomik Ton Balığı | Dardanel | `8690559026525` | 100 | 100 | 0 |
| 15 | Az Yağlı Peynir | Pınar | `8690565022849` | 100 | 100 | 40 |
| 16 | Tuna Fish | SuperFresh, Ülker | `8690612314958` | 100 | 100 | 70 |
| 17 | Superton Ton Balığı | Superfresh | `8690612315689` | 100 | 100 | 70 |
| 18 | Nestle nesfit 400 kırmızı meyveli | Nesfit | `8690632760391` | 100 | 100 | 0 |
| 19 | TAT - KETÇAP | tat | `8690635151554` | 100 | 100 | 40 |
| 20 | Tost Ekmeği | Uno | `8690698511661` | 100 | 100 | 40 |
| 21 | Tam buğdaylı ve ciya tohumlu ekmek | Uno | `8690698511692` | 100 | 100 | 50 |
| 22 | Sütaş ayran | Sütaş | `8690767671081` | 100 | 100 | 40 |
| 23 | Cream Cheese | Sütaş | `8690767717000` | 100 | 100 | 70 |
| 24 | Sütaş çikolatalı süt | Sütaş | `8690767774874` | 100 | 100 | 50 |
| 25 | Coarse bulgur with vermicelli | Sera | `8690777432368` | 100 | 100 | 50 |
| 26 | Laktozsuz Dilimli Tost Peyniri | Bahçıvan | `8690843097194` | 100 | 100 | 50 |
| 27 | Doğal zengin mineralli maden suyu | Sırma | `8691058005752` | 100 | 100 | 0 |
| 28 | Walnut Summer Helva | Koska | `8691070634701` | 100 | 100 | 50 |
| 29 | Ayran | Eker | `8691316521512` | 100 | 100 | 60 |
| 30 | Ayran | Eker | `8691316521819` | 100 | 100 | 40 |
| 31 | tatli biber salçasi | Burcu | `8691573007194` | 100 | 100 | 40 |
| 32 | Lactose-free milk | Sek | `8692095342886` | 100 | 100 | 50 |
| 33 | Yarım Yağlı Süt | Migros | `8692971429359` | 100 | 100 | 50 |
| 34 | Sade Kefir | İçim | `8692971429564` | 100 | 100 | 50 |
| 35 | Içim Labne Cream Cheese, Olive and Thyme | İçim | `8692971431079` | 100 | 100 | 70 |
| 36 | İçim Fit Kakaolu | İçim | `8692971434346` | 100 | 100 | 50 |
| 37 | Içim fit çilek | İçim | `8692971434513` | 100 | 100 | 50 |
| 38 | Tarım Kredi Yarım Yağlı UHT Süt | Tarım Kredi | `8694962011024` | 100 | 100 | 0 |
| 39 | Yağsız UHT Süt | Tarım Kredi | `8694962012496` | 100 | 100 | 0 |
| 40 | Krema | Dost | `8695077003843` | 100 | 100 | 50 |
| 41 | Çocuk Devam Sütü | Dost | `8695077005588` | 100 | 100 | 40 |
| 42 | Dilimli Tost Peyniri | Aknaz | `8695077006301` | 100 | 100 | 40 |
| 43 | suzme peynir | Dost | `8695077020512` | 100 | 100 | 50 |
| 44 | Milk | Harras, Harris | `8695077029423` | 100 | 100 | 50 |
| 45 | Enerji İçeceği | Performans | `8695077081131` | 100 | 100 | 40 |
| 46 | Дюрюм чий кюфте | Bim | `8695077087126` | 100 | 100 | 40 |
| 47 | Form Süzme Peynir | Dost,Dost Form | `8695077091741` | 100 | 100 | 40 |
| 48 | Süt | Dost | `8695077092021` | 100 | 100 | 40 |
| 49 | Dost Süt Yarım Yağlı | Dost,Yarım Yağlı Süt | `8695077100092` | 100 | 100 | 0 |
| 50 | Sut | Dost | `8695077102034` | 100 | 100 | 50 |

## Yüksek kaliteli 50 EN/global ürün

| # | Ürün | Marka | Barcode | Quality | TR | EN |
|---:|---|---|---|---:|---:|---:|
| 1 | Canola harvest, buttery spread, with flaxseed oil | Canola Harvest | `0000111301263` | 100 | 0 | 100 |
| 2 | Mcvitie's, digestives cheesecake, lemon | Mcvitie's | `0000168175589` | 100 | 15 | 100 |
| 3 | Mcvitie's, mini gingerbread men, milk chocolate | Mcvitie's | `0000168178238` | 100 | 0 | 100 |
| 4 | Piasten, Chocolate Assortment | Goode's Bakery & Co. Inc. | `0000281756504` | 100 | 0 | 100 |
| 5 | Mt. olive, sweet 'n' hot salad peppers | Mt. Olive | `0000309444901` | 100 | 0 | 100 |
| 6 | Big Papa's, Southern Sauce | Walton's Flies | `0000309512075` | 100 | 0 | 100 |
| 7 | Isagenix | ISAGENIX | `0000390204071` | 100 | 0 | 100 |
| 8 | Funsch, High Quality Marzipan | Petpro Products Inc. | `0000433070274` | 100 | 0 | 100 |
| 9 | Best Sweet-Potato Cookies | Petpro Products Inc. | `0000433906023` | 100 | 0 | 100 |
| 10 | Lactaid, ice cream, vanilla | Lactaid | `0000450193000` | 100 | 0 | 100 |
| 11 | Lactaid, ice cream, butter pecan | Lactaid | `0000450193031` | 100 | 0 | 100 |
| 12 | Lindt williams, liquor chocolate with williams pear | Lindt, Polo Leathergoods | `0000539003206` | 100 | 0 | 100 |
| 13 | Madelaine Chocolate Company, Chocolate | Madelaine Chocolate Novelties | `0000609133703` | 100 | 0 | 100 |
| 14 | The Madelaine Chocolate Company, Solid Milk Chocolate Cigars | Madelaine Chocolate Novelties | `0000609406104` | 100 | 0 | 100 |
| 15 | Madelaine Chocolate, It's A Girl! Solid Milk Chocolate Cigars, Milk Chocolate | Madelaine Chocolate Novelties | `0000609407101` | 100 | 0 | 100 |
| 16 | The Madelaine Chocolate Company, Solid Milk Chocolate | Madelaine Chocolate Novelties | `0000609941001` | 100 | 0 | 100 |
| 17 | The Madelaine Chocolate Company, Solid Dark Chocolate | Madelaine Chocolate Novelties | `0000609941049` | 100 | 0 | 100 |
| 18 | The Madelaine Chocolate Company, Solid Milk Chocolate | Madelaine Chocolate Novelties | `0000609941766` | 100 | 0 | 100 |
| 19 | Solid Milk Chocolate | The Madelaine Chocolate Company | `0000609962037` | 100 | 0 | 100 |
| 20 | The Madelaine Chocolate Company, Solid Dark Chocolate | Madelaine Chocolate Novelties | `0000609962044` | 100 | 0 | 100 |
| 21 | The Madelaine Chocolate Company, Solid Milk Chocolate | Madelaine Chocolate Novelties | `0000609983001` | 100 | 0 | 100 |
| 22 | The Madelaine Chocolate Company, Solid Dark Chocolate | Madelaine Chocolate Novelties | `0000609983032` | 100 | 0 | 100 |
| 23 | The Madelaine Chocolate Company, Solid Milk Chocolate Bunnies | Madelaine Chocolate Novelties | `0000609989010` | 100 | 0 | 100 |
| 24 | The Madelaine Chocolate Company, Solid Milk Chocolate Chicks | Madelaine Chocolate Novelties | `0000609989027` | 100 | 0 | 100 |
| 25 | Feletti, Pralines Candy, Milk Chocolate | Better Ideas | `0000698309041` | 100 | 0 | 100 |
| 26 | Feletti, Milk Chocolate Pralines | Better Ideas | `0000698465815` | 100 | 0 | 100 |
| 27 | Ryan's, Lemonade | Ryan Orchards | `0000764001787` | 100 | 0 | 100 |
| 28 | Ryan's, Spiced Apple Cider | Ryan Orchards | `0000764003033` | 100 | 0 | 100 |
| 29 | Healthy Food Brands, A&W, Soda Bottles Gummy Candies With Real A&W Root Beer | Healthy Food Brands Llc | `0000790105282` | 100 | 0 | 100 |
| 30 | Emojeez, Gummies, Assorted Fruits | Healthy Food Brands Llc | `0000790110002` | 100 | 0 | 100 |
| 31 | Emojeez, Gummies Candy, Fruit | Healthy Food Brands Llc | `0000790110019` | 100 | 0 | 100 |
| 32 | Emojeez, Fruit Flavored Gummies, Green Apple, Orange, Fruit Punch, Lemon, Cherry Blue Raspberry | Healthy Food Brands Llc | `0000790110026` | 100 | 0 | 100 |
| 33 | Emojeez, Fruit Gummies, Assorted | Healthy Food Brands Llc | `0000790110040` | 100 | 0 | 100 |
| 34 | Emojeez, Gummies Candy, Fruit | Healthy Food Brands Llc | `0000790110057` | 100 | 0 | 100 |
| 35 | Fine Chocolate Candy Bar, Dark Chocolate | Simply, Simply Natural Foods Llc. | `0000790200123` | 100 | 0 | 100 |
| 36 | Hfb Candy, Candy Crush Color Bombs | Healthy Food Brands Llc | `0000790350040` | 100 | 0 | 100 |
| 37 | Hfb Candy, Jelly Fish Candy | Healthy Food Brands Llc | `0000790350187` | 100 | 0 | 100 |
| 38 | Angry Birds, Fruit Snack, Cherry, Lemon, Raspberry, Apple, Grape, Strawberry | Healthy Food Brands Llc | `0000790350385` | 100 | 0 | 100 |
| 39 | Welch's, triple fruit treat, mango, cranberries, blueberries | Welch's, Healthy Food Brands Llc | `0000790410553` | 100 | 0 | 100 |
| 40 | Welch's, pb&j trail mix, grape | Welch's, Healthy Food Brands Llc | `0000790430018` | 100 | 15 | 100 |
| 41 | Welch's, pb & j trail mix, strawberry | Welch's, Healthy Food Brands Llc | `0000790430063` | 100 | 15 | 100 |
| 42 | Welch's, pb&j trail mix, grape | Welch's, Healthy Food Brands Llc | `0000790430070` | 100 | 15 | 100 |
| 43 | Fruit gummies | Angry Birds | `0000790500186` | 100 | 0 | 100 |
| 44 | Angry birds, fruit snacks, cherry, lemon, raspberry, apple, grape, strawberry | Angry Birds | `0000790520603` | 100 | 0 | 100 |
| 45 | Creamed honey with cinnamon | Vintage, Vintage Bee | `0000835766331` | 100 | 0 | 100 |
| 46 | Guiltless Gourmet, Organic Unsweetened Coconut Water | Guiltless Gourmet Inc. | `0000901005005` | 100 | 0 | 100 |
| 47 | La Eur, 3 Milk Soft Ripened Cheese | Caseificio Dell'Alta Langa | `0000996284712` | 100 | 0 | 100 |
| 48 | Beef Bologna | Private Selections,Kroger | `0001111052230` | 100 | 0 | 100 |
| 49 | Diet Soda, Cola | Roundy's | `0001115016429` | 100 | 0 | 100 |
| 50 | Instant mashed potatoes, butter & herb | Roundy's | `0001115018195` | 100 | 0 | 100 |

## 20 şüpheli kayıt

| # | Ürün | Marka | Barcode | Quality | TR | EN | Şüphe nedenleri |
|---:|---|---|---|---:|---:|---:|---|
| 1 | hejejje | jzjje | `00111101` | 54 | 0 | 0 | en:energy-value-in-kcal-does-not-match-value-in-kj, en:nutrition-value-total-over-105, en:energy-value-in-kj-does-not-match-value-computed-from-other-nutrients, macro_sum_over_105g, gtin_checksum_or_length_invalid |
| 2 | Oikos Pro 19g protein | — | `10515995` | 37 | 0 | 80 | en:nutrition-value-over-105-calcium, en:nutrition-value-over-105-potassium, en:nutrition-value-over-105-salt, gtin_checksum_or_length_invalid |
| 3 | Activia Expert Cherry flavour | — | `10531039` | 37 | 0 | 80 | en:nutrition-value-over-105-calcium, en:nutrition-value-over-105-potassium, en:nutrition-value-over-105-salt, gtin_checksum_or_length_invalid |
| 4 | Chrome book | — | `20001080` | 37 | 0 | 80 | en:nutrition-value-total-over-105, en:nutrition-value-over-3800-energy, en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients, gtin_checksum_or_length_invalid |
| 5 | gg | uu | `6009836900113` | 60 | 0 | 0 | en:nutrition-value-total-over-105, en:nutrition-saturated-fat-greater-than-fat, en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients, macro_sum_over_105g, weak_or_placeholder_name |
| 6 | gg | hh | `9786045978634` | 60 | 0 | 0 | en:nutrition-value-total-over-105, en:nutrition-saturated-fat-greater-than-fat, en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients, macro_sum_over_105g, weak_or_placeholder_name |
| 7 | 7days | — | `2000000046690` | 44 | 0 | 50 | en:nutrition-value-over-105-salt, en:nutrition-value-total-over-105, en:energy-value-in-kj-does-not-match-value-computed-from-other-nutrients, gtin_checksum_or_length_invalid |
| 8 | almarai double chocolate milk | — | `2000000046691` | 44 | 0 | 70 | en:nutrition-value-over-105-salt, en:nutrition-value-total-over-105, en:energy-value-in-kj-does-not-match-value-computed-from-other-nutrients, gtin_checksum_or_length_invalid |
| 9 | Superfood greens | — | `80002807` | 44 | 0 | 100 | en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients, en:vegan-label-but-non-vegan-ingredient, en:vegetarian-label-but-non-vegetarian-ingredient, gtin_checksum_or_length_invalid |
| 10 | pasta | — | `8901560090284` | 45 | 0 | 50 | en:nutrition-value-total-over-105, en:nutrition-sugars-plus-starch-greater-than-carbohydrates, en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients, macro_sum_over_105g |
| 11 | MuscleBlaze Multivitamin | MuscleBlaze | `0001245192425` | 47 | 0 | 80 | en:nutrition-value-over-105-calcium, en:nutrition-value-over-1000-calcium, en:nutrition-value-over-105-copper, gtin_checksum_or_length_invalid |
| 12 | Изделие сдобное Улитка с маком | — | `2953245003047` | 52 | 0 | 0 | en:nutrition-value-total-over-105, en:energy-value-in-kj-does-not-match-value-computed-from-other-nutrients, en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients, macro_sum_over_105g |
| 13 | Croco | — | `5041194440000` | 52 | 0 | 50 | en:nutrition-value-total-over-105, en:energy-value-in-kj-does-not-match-value-computed-from-other-nutrients, en:product-quantity-over-30kg, macro_sum_over_105g |
| 14 | Arcal8a | — | `5942325003623` | 52 | 0 | 50 | en:nutrition-value-total-over-105, en:energy-value-in-kj-does-not-match-value-computed-from-other-nutrients, en:product-quantity-over-30kg, macro_sum_over_105g |
| 15 | préparation pour flanc | — | `6132066300139` | 52 | 0 | 0 | en:nutrition-value-total-over-105, en:energy-value-in-kj-does-not-match-value-computed-from-other-nutrients, en:energy-value-in-kcal-does-not-match-value-computed-from-other-nutrients, macro_sum_over_105g |
| 16 | Mars | — | `6294001813415` | 52 | 0 | 0 | en:energy-value-in-kcal-does-not-match-value-in-kj, en:nutrition-value-total-over-105, en:nutrition-value-over-3800-energy, macro_sum_over_105g |
| 17 | Oblitas Chocolate | — | `7793123000356` | 52 | 0 | 0 | en:nutrition-value-total-over-105, en:nutrition-saturated-fat-greater-than-fat, en:energy-value-in-kj-does-not-match-value-computed-from-other-nutrients, macro_sum_over_105g |
| 18 | RAW CHIA SEED | — | `8906151000031` | 52 | 0 | 50 | en:energy-value-in-kcal-greater-than-in-kj, en:energy-value-in-kcal-does-not-match-value-in-kj, en:nutrition-value-total-over-105, macro_sum_over_105g |
| 19 | Magdalena Cookie | — | `0850027746418` | 53 | 0 | 50 | en:nutrition-value-total-over-105, en:nutrition-sugars-plus-starch-greater-than-carbohydrates, en:nutrition-saturated-fat-greater-than-fat, macro_sum_over_105g |
| 20 | Clover Chips Cheese | Leslie’s | `0480021611004` | 54 | 0 | 50 | en:energy-value-in-kcal-greater-than-in-kj, en:energy-value-in-kcal-does-not-match-value-in-kj, en:energy-value-in-kj-does-not-match-value-computed-from-other-nutrients, gtin_checksum_or_length_invalid |

## Çıktılar

- Tüm scored kayıtlar: `data/catalog/openfoodfacts-scored.jsonl.gz`
- Quality 80+ production candidates: `data/catalog/openfoodfacts-production.jsonl.gz`
- Metrikler ve örnekler: `data/catalog/openfoodfacts-catalog-metrics.json`

Database import yapılmadı. Normalize input değiştirilmedi.
