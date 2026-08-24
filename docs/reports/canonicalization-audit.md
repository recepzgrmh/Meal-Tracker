# Canonicalization Read-Only Quality Audit

Generated: 2026-08-23T00:07:03.603Z  
Mode: **READ-ONLY** — no dataset, mapping, canonical record, pipeline, or database was changed.

## 1. Executive summary

**Current canonicalization is not ready for production database import.** Generic preparation/state safety is good, but the branded GTIN rule needs a contradiction gate before import. The audit found **236 CRITICAL**, **303 HIGH**, and **4,556 MEDIUM** false-merge candidates among existing merged groups. These are risk flags rather than 5,095 confirmed errors; nevertheless several CRITICAL examples contain plainly incompatible product/market identities under the same short or contributor-supplied GTIN.

Generic canonicalization is **too conservative**: only 192 generic reductions were made. The broader lexical/category/nutrition/state audit found **28 VERY HIGH**, **138 HIGH**, **1,072 MEDIUM**, and **3,288 AMBIGUOUS** missed-equivalence candidate pairs. VERY HIGH/HIGH pairs touch 244 records and imply an estimated upper bound of **about 114 additional canonical reductions** after deterministic rule improvements.

The larger immediate risk is **wrong merge**, not missed merge. A missed generic merge hurts search/recall; a false barcode merge can attach the wrong nutrition and product identity to a logged meal. The canonicalization stage should be changed and rerun before database import.

| Question | Answer |
|---|---|
| Production import ready? | **No** |
| Generic side too conservative? | **Yes** |
| Rerun before DB import? | **Yes, after deterministic safety changes** |
| Larger risk? | **False merge severity is larger; missed-merge volume is secondary** |

## 2. Generic canonicalization fazla conservative mi?

Yes. Exact normalized-string matching misses safe token-order variants such as “Worcestershire sauce” ↔ “Sauce, worcestershire”, “Green peas, raw” ↔ “Peas, green, raw”, and oil names whose noun order changes across USDA datasets. The audit did not use name similarity alone: category compatibility, macro similarity, source separation, and explicit preparation/state conflicts were evaluated together.

| Bucket | Candidate pairs | Interpretation |
|---|---:|---|
| VERY HIGH CONFIDENCE | 28 | Strong deterministic-rule candidate |
| HIGH CONFIDENCE | 138 | Likely safe after qualifier-aware guard |
| MEDIUM CONFIDENCE | 1,072 | Review or stricter rule required |
| AMBIGUOUS | 3,288 | Do not merge automatically |

The 166 VERY HIGH/HIGH pairs overlap. They touch 244 records / 236 current canonical IDs, so the estimated reduction is **not 166**; a conservative upper bound is approximately **114 canonical foods**. Candidate counts are prioritization estimates, not ground truth.

## 3. Missed merge tahmini

USDA-only screening audited 13,588 records and found six exact-normalized cross-source names that remain split, plus many name-order/synonym candidates. The strongest pattern is FNDDS ↔ SR Legacy. Nutrition similarity supports identity but does not prove it because survey composites and analytic foods can have different sampling frames.

### 30 missed-merge candidates

| # | Left | Right | Confidence | Evidence |
|---:|---|---|---|---|
| 1 | turkomp/26<br>`cf_477e02bd6e9970228250942b`<br>Yumurta, tavuk, tam | usda_fndds/2707152<br>`cf_b1d437ff8acdac748ecee112`<br>Egg, whole, raw | MEDIUM | egg / yumurta: whole chicken egg in both names; nutrition is close: 140/13.13/0/9.69 versus 143/12.4/0.96/9.96 kcal/protein/carbs/fat; TurKomp preparation state is unspecified while USDA says raw |
| 2 | turkomp/27<br>`cf_70b61e5accb52a965fe72627`<br>Yumurta, tavuk, sarı | usda_fndds/2707172<br>`cf_e475e417dc025d4b88c413be`<br>Egg, yolk only, raw | MEDIUM | egg / yumurta: chicken egg yolk versus egg yolk only; nutrition profile is directionally consistent; TurKomp raw state is not explicit |
| 3 | turkomp/28<br>`cf_be73769c94abd1e3cea68293`<br>Yumurta, tavuk, beyaz (ak) | usda_fndds/2707168<br>`cf_60cacc98c098c5b3c6bdfb75`<br>Egg, white only, raw | MEDIUM | egg / yumurta: chicken egg white/ak versus egg white only; near-zero fat and roughly 11 g protein per 100 g; TurKomp raw state is not explicit |
| 4 | turkomp/17<br>`cf_670839c8fd5a230d1add3dd0`<br>Süt, inek | usda_fndds/2705385<br>`cf_deddcdbc658096abb66d1b75`<br>Milk, whole | MEDIUM | milk / sut: cow milk versus whole milk; 64 versus 61 kcal and 3.57 versus 3.2 g fat; whole-fat interpretation is inferred rather than explicit on the TurKomp name |
| 5 | turkomp/64<br>`cf_eb0b6f5b65e58e990a9f9aa1`<br>Piliç eti, göğüs, derisiz | usda_sr_legacy/171509<br>`cf_ad479c12bc650219e373417a`<br>Chicken, broilers or fryers, breast, skinless, boneless, meat only, with added solution, raw | MEDIUM_HIGH | chicken breast / tavuk gogsu: piliç/chicken, breast, skinless align; 121/21.7/0/3.78 versus 108/20.3/0/3 kcal/protein/carbs/fat; USDA specifies raw, boneless, and added solution; TurKomp does not |
| 6 | turkomp/146<br>`cf_6f9dcc74b8ebd11bfed7833e`<br>Pirinç unu | usda_foundation/790214<br>`cf_7104f6cfc37dded47efffc53`<br>Flour, rice, white, unenriched | MEDIUM_HIGH | rice / pirinc: rice flour in both names; 346/6.72/74.84/1.2 versus 359/6.94/79.8/1.3; USDA specifies white and unenriched |
| 7 | turkomp/332<br>`cf_3036b540cbff14d44a148d5a`<br>Elma, yazlık, Gala çeşidi | usda_sr_legacy/168204<br>`cf_47b9084c3dae5fba5465c118`<br>Apples, raw, gala, with skin (Includes foods for USDA's Food Distribution Program) | HIGH | apple / elma: same Gala cultivar; 58 versus 57 kcal; TurKomp season label and USDA raw/skin label are compatible but not textually identical |
| 8 | turkomp/333<br>`cf_a1654c3ea2ff1295771aa941`<br>Elma, güzlük ve kışlık, Fuji çeşidi | usda_sr_legacy/167793<br>`cf_5a633831871e0147388f292d`<br>Apples, raw, fuji, with skin (Includes foods for USDA's Food Distribution Program) | HIGH | apple / elma: same Fuji cultivar; 56 versus 63 kcal; TurKomp season label and USDA raw/skin label are compatible but not textually identical |
| 9 | turkomp/103<br>`cf_e53b2c95908e1d590b643493`<br>Zeytinyağı, sızma | usda_foundation/748608<br>`cf_786910fdefc8eab3362b4771`<br>Oil, olive, extra virgin | HIGH | olive oil / zeytinyagi: sızma maps directly to extra virgin; USDA Foundation record has no normalized macro values, so confidence comes from semantics rather than nutrition |
| 10 | turkomp/4<br>`cf_2ed3fb15410fa52d67f946f8`<br>Yoğurt, homojenize, tam yağlı (süt yağı ≥ % 3.8) | usda_foundation/2259793<br>`cf_51734673ed10face8a856f71`<br>Yogurt, plain, whole milk | MEDIUM_HIGH | yogurt / yogurt: plain whole/full-fat yogurt semantics align; 69/4.53/4.24/3.8 macro profile is plausible; homogenization and exact milk-fat threshold differ in specificity |
| 11 | turkomp/3<br>`cf_86b366d7dce678e4a84576c8`<br>Yoğurt, homojenize, yarım yağlı (% 2 > süt yağı ≥ % 1.5) | usda_fndds/2705419<br>`cf_7a532066ad85766c6f248463`<br>Yogurt, low fat milk, plain | MEDIUM | yogurt / yogurt: both are plain low/semi-fat yogurt; TurKomp states 1.5-2% fat; USDA name does not expose exact percentage |
| 12 | turkomp/126<br>`cf_d6f43053b707ec9baa319883`<br>Ekmek, beyaz | usda_fndds/2707598<br>`cf_c91f149c6f5ad4f3f21ae41f`<br>Bread, white | HIGH | bread / ekmek: exact white-bread semantic match; 276/9.41/50.13/3.22 versus 267/9.43/49.2/3.59; sodium and fiber vary by regional formulation |
| 13 | turkomp/124<br>`cf_d078e7973ed99c1649f22eac`<br>Ekmek, çavdar | usda_fndds/2707755<br>`cf_4a6f68e50c0ddf3a62658e43`<br>Bread, rye | HIGH | bread / ekmek: exact rye-bread semantic match; nutrient differences are within plausible recipe variation |
| 14 | turkomp/128<br>`cf_14c606fb4308d895e5f58506`<br>Ekmek, tam buğday unlu | usda_fndds/2707709<br>`cf_51db2034f4b909c830138aba`<br>Bread, whole wheat | HIGH | bread / ekmek: whole-wheat bread semantics align; TurKomp sodium is unusually lower, so review rather than blind merge |
| 15 | usda_foundation/2727581<br>`cf_01ee6db9aa9a2ab43033ca74`<br>Blackberries, raw | usda_sr_legacy/173946<br>`cf_821597db34055020a9deb01b`<br>Blackberries, raw | HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |
| 16 | usda_fndds/2705729<br>`cf_c2b7a9e541216bbf4f69501a`<br>Cheese, Parmesan, dry grated, reduced fat | usda_sr_legacy/173452<br>`cf_504337461afdc62fe9cce6c3`<br>Cheese, parmesan, dry grated, reduced fat | AMBIGUOUS | Exact/near-exact identity wording makes this a duplicate candidate, but missing or materially divergent nutrition prevents an automatic merge. |
| 17 | usda_fndds/2705730<br>`cf_3c33b31204ba77e1c98d87bd`<br>Cheese, Parmesan, hard | usda_sr_legacy/170848<br>`cf_ac00ca5dcdca284a6eee987a`<br>Cheese, parmesan, hard | AMBIGUOUS | Exact/near-exact identity wording makes this a duplicate candidate, but missing or materially divergent nutrition prevents an automatic merge. |
| 18 | usda_fndds/2705644<br>`cf_2a1e13b1ea760af7cfda39eb`<br>Ice cream cookie sandwich | usda_sr_legacy/172227<br>`cf_febc53c9d10b83cd8971f113`<br>Ice cream cookie sandwich | AMBIGUOUS | Exact/near-exact identity wording makes this a duplicate candidate, but missing or materially divergent nutrition prevents an automatic merge. |
| 19 | usda_foundation/748278<br>`cf_0e5ed6d08dfcf52d85796a92`<br>Oil, canola | usda_sr_legacy/172336<br>`cf_79223c993c0819475922fbaa`<br>Oil, canola | AMBIGUOUS | Exact/near-exact identity wording makes this a duplicate candidate, but missing or materially divergent nutrition prevents an automatic merge. |
| 20 | usda_fndds/2708305<br>`cf_4da6bdf69c6cef9cdd3ac216`<br>Pancakes, plain, reduced fat | usda_sr_legacy/174086<br>`cf_dd1a7c357a0386414acf55ef`<br>Pancakes, plain, reduced fat | AMBIGUOUS | Exact/near-exact identity wording makes this a duplicate candidate, but missing or materially divergent nutrition prevents an automatic merge. |
| 21 | usda_fndds/2708061<br>`cf_1ae249a2a188b92a3a5d9c93`<br>Danish pastry, with cheese | usda_sr_legacy/172754<br>`cf_1c93aa08e7086251d4bb3702`<br>Danish pastry, cheese | VERY_HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |
| 22 | usda_fndds/2707468<br>`cf_d6d6203c9ddb5c3ebc0b7813`<br>Chicken, meatless, NFS | usda_sr_legacy/169886<br>`cf_1cac85e25feb21ac9597876c`<br>Chicken, meatless | VERY_HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |
| 23 | usda_fndds/2707628<br>`cf_abeff92c5c393c90d02c02f7`<br>Garlic bread, from frozen | usda_sr_legacy/167939<br>`cf_80664f11e92c86752fd504f5`<br>Garlic bread, frozen | VERY_HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |
| 24 | usda_fndds/2708158<br>`cf_bbbead607376ac6a2dab0756`<br>Crackers, matzo | usda_sr_legacy/172740<br>`cf_2fc23b912aebd7444f4ba1d7`<br>Crackers, matzo, plain | VERY_HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |
| 25 | usda_foundation/2259794<br>`cf_9855a53cb940bcac93684583`<br>Yogurt, Greek, plain, whole milk | usda_fndds/2705422<br>`cf_8161da2aafdb471885642e7c`<br>Yogurt, Greek, whole milk, plain | VERY_HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |
| 26 | usda_fndds/2707719<br>`cf_7a9b2a28f8a3e8bc65cf85d0`<br>Bread, sprouted wheat, toasted | usda_sr_legacy/171851<br>`cf_31a31d786b50e326196b90b7`<br>Bread, wheat, sprouted, toasted | VERY_HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |
| 27 | usda_foundation/325198<br>`cf_0bb92a5dba81f04c1e9f5a9a`<br>Cheese, pasteurized process, American, vitamin D fortified | usda_sr_legacy/170853<br>`cf_a375cad2704a5c30f7580fcf`<br>Cheese, pasteurized process, American, fortified with vitamin D | HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |
| 28 | usda_fndds/2705422<br>`cf_8161da2aafdb471885642e7c`<br>Yogurt, Greek, whole milk, plain | usda_sr_legacy/171304<br>`cf_9855a53cb940bcac93684583`<br>Yogurt, Greek, plain, whole milk | HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |
| 29 | usda_foundation/2259793<br>`cf_51734673ed10face8a856f71`<br>Yogurt, plain, whole milk | usda_fndds/2705418<br>`cf_41cea31ab15e73f2cfa4d61a`<br>Yogurt, whole milk, plain | VERY_HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |
| 30 | usda_foundation/2346390<br>`cf_bbde97cd0623d372b7885f34`<br>Lettuce, leaf, red, raw | usda_sr_legacy/168431<br>`cf_28afbec0d7496e4335d86084`<br>Lettuce, red leaf, raw | HIGH | Identity wording, compatible preparation/state, and available nutrition jointly support a likely missed merge; still not proof of equivalence. |

## 4. False merge analizi

All 16,333 merged canonical groups were audited: 16,158 barcode groups and 175 generic groups. Generic merges showed **zero preparation/state conflicts** and only two material nutrition-disagreement candidates. Barcode merges account for 5,093 of 5,095 flagged groups.

| Signal | Barcode groups |
|---|---:|
| Name similarity below 0.5 | 4,480 |
| Brand similarity below 0.4 | 2,462 |
| Ingredient similarity below 0.2 | 174 |
| Material nutrition conflicts | 1,476 |

A mismatch does not automatically prove a false identity: abbreviated names, licensing brands, prepared-vs-dry nutrition basis, and stale contributor data can explain some cases. CRITICAL/HIGH groups must nevertheless be blocked from automatic production promotion until their identity conflict is resolved.

### 30 false-merge candidates

| # | Severity | Canonical ID | Left | Right | Reasons |
|---:|---|---|---|---|---|
| 1 | CRITICAL | `cf_93cb96ae6adeb14509721b6b` | open_food_facts/0038000247415<br>`cf_93cb96ae6adeb14509721b6b`<br>Jumbo snax | usda_branded/2631571<br>`cf_93cb96ae6adeb14509721b6b`<br>CINNABON BAKERY INSPIRED CINNAMON ROLL CEREAL, CINNAMON ROLL | same_gtin_but_unrelated_product_names |
| 2 | CRITICAL | `cf_fab7905211c15f08662034b9` | open_food_facts/0028000466343<br>`cf_fab7905211c15f08662034b9`<br>Ninho | usda_branded/2674631<br>`cf_fab7905211c15f08662034b9`<br>INSTANT DRY WHOLE MILK | same_gtin_but_unrelated_product_names |
| 3 | CRITICAL | `cf_3b11904fb0f48d110434d20a` | open_food_facts/0729955570429<br>`cf_3b11904fb0f48d110434d20a`<br>cancha saladita | usda_branded/2603046<br>`cf_3b11904fb0f48d110434d20a`<br>SALTY FRIED CORN | same_gtin_but_unrelated_product_names |
| 4 | CRITICAL | `cf_f1dade84bdd5a44a29a59285` | open_food_facts/0040000203193<br>`cf_f1dade84bdd5a44a29a59285`<br>Snickers twix musketeers milky way milky way | usda_branded/2547183<br>`cf_f1dade84bdd5a44a29a59285`<br>MARS MINIS CHOCOLATE FAVORITES BARS AND CANDIES, 40.0 OZ | same_gtin_but_unrelated_product_names |
| 5 | CRITICAL | `cf_1ef69e7cc4202bbf5a530373` | open_food_facts/03424704<br>`cf_1ef69e7cc4202bbf5a530373`<br>Whatchamacailit standard | usda_branded/1727774<br>`cf_1ef69e7cc4202bbf5a530373`<br>PEANUT FLAVORED CRISPS AND CARAMEL, PEANUT | same_gtin_but_unrelated_product_names |
| 6 | CRITICAL | `cf_3f8bed58be1f959ac3170ed0` | open_food_facts/20043025<br>`cf_3f8bed58be1f959ac3170ed0`<br>Feine Schokoladenfiguren Vollmilch | usda_branded/479979<br>`cf_3f8bed58be1f959ac3170ed0`<br>TO GO TURKEY CHILI | same_gtin_but_unrelated_product_names |
| 7 | CRITICAL | `cf_5d6f279a7c5f94a9c4d00453` | open_food_facts/0028400679015<br>`cf_5d6f279a7c5f94a9c4d00453`<br>Funyuns | usda_branded/2527800<br>`cf_5d6f279a7c5f94a9c4d00453`<br>ONION FLAVORED RINGS | same_gtin_but_unrelated_product_names |
| 8 | CRITICAL | `cf_8bff42a33225c9bf2870463e` | open_food_facts/0038000234354<br>`cf_8bff42a33225c9bf2870463e`<br>Frosted flakes | usda_branded/2595978<br>`cf_8bff42a33225c9bf2870463e`<br>MARSHMALLOWS CEREAL | same_gtin_but_unrelated_product_names |
| 9 | CRITICAL | `cf_90836430b17621ca33cd8500` | open_food_facts/0070074669731<br>`cf_90836430b17621ca33cd8500`<br>Pedialyte Advanced Care | usda_branded/2567375<br>`cf_90836430b17621ca33cd8500`<br>STRAWBERRY FREEZE ELECTROLYTE POWDER, STRAWBERRY | same_gtin_but_unrelated_product_names |
| 10 | CRITICAL | `cf_c47234985321556e1e61c216` | open_food_facts/20044541<br>`cf_c47234985321556e1e61c216`<br>Sucre de canne Bio | usda_branded/457658<br>`cf_c47234985321556e1e61c216`<br>CHOCOLATE TWIST | same_gtin_but_unrelated_product_names |
| 11 | CRITICAL | `cf_d43f870e4ac901413134990c` | open_food_facts/01200119<br>`cf_d43f870e4ac901413134990c`<br>Nitro Cold Brew Vanilla Sweet Cream | usda_branded/2174184<br>`cf_d43f870e4ac901413134990c`<br>FINELY GROUND DIJON MUSTARD, FINELY GROUND DIJON | same_gtin_but_unrelated_product_names |
| 12 | CRITICAL | `cf_f883d237d85e2769586b7f09` | open_food_facts/5000147026685<br>`cf_f883d237d85e2769586b7f09`<br>Black Bean Stir Fry Sauce | usda_branded/401062<br>`cf_f883d237d85e2769586b7f09`<br>COLMAN'S OF NORWICH, BEEF BOURGUIGNON | same_gtin_but_unrelated_product_names |
| 13 | CRITICAL | `cf_268e9992f73d2b964426bd50` | open_food_facts/20044534<br>`cf_268e9992f73d2b964426bd50`<br>Eucalyptus Menthol Drops | usda_branded/479984<br>`cf_268e9992f73d2b964426bd50`<br>BEAR CLAW | same_gtin_but_unrelated_product_names |
| 14 | CRITICAL | `cf_5f8d7c7004dbb26fc1ce90d1` | open_food_facts/20024291<br>`cf_5f8d7c7004dbb26fc1ce90d1`<br>Marmellata Cadoro Bio arancia e zenzero | usda_branded/486059<br>`cf_5f8d7c7004dbb26fc1ce90d1`<br>BERRY MEDLEY | same_gtin_but_unrelated_product_names |
| 15 | CRITICAL | `cf_8418dd78883e79e588f05caa` | open_food_facts/20737740<br>`cf_8418dd78883e79e588f05caa`<br>Mini Schnitzel Schwein | usda_branded/1063411<br>`cf_8418dd78883e79e588f05caa`<br>CAESAR SALAD ROMAINE LETTUCE, CAESAR DRESSING, SHAVED PARMESAN CHEESE, CROUTONS KIT, CAESAR SALAD | same_gtin_but_unrelated_product_names |
| 16 | CRITICAL | `cf_8a7134912e6325f4023798dd` | open_food_facts/0030800810004<br>`cf_8a7134912e6325f4023798dd`<br>Brisk iced tea | usda_branded/2588463<br>`cf_8a7134912e6325f4023798dd`<br>7UP, A&W ROOT BEER AND DR PEPPER CANDY CANES | same_gtin_but_unrelated_product_names |
| 17 | CRITICAL | `cf_d26daeb548118194cea4780a` | open_food_facts/7753466177153<br>`cf_d26daeb548118194cea4780a`<br>Habas Saladitas | usda_branded/550262<br>`cf_d26daeb548118194cea4780a`<br>TOASTED BROAD BEANS | same_gtin_but_unrelated_product_names |
| 18 | CRITICAL | `cf_d62f380d91c750f4b8479b5b` | open_food_facts/0038000217401<br>`cf_d62f380d91c750f4b8479b5b`<br>Eggo | usda_branded/2615353<br>`cf_d62f380d91c750f4b8479b5b`<br>BLUEBERRY WAFFLE CEREAL, BLUEBERRY | same_gtin_but_unrelated_product_names |
| 19 | CRITICAL | `cf_df66ebe54ea5452f2d6450fb` | open_food_facts/0014800007558<br>`cf_df66ebe54ea5452f2d6450fb`<br>Tomato & basil | usda_branded/2526692<br>`cf_df66ebe54ea5452f2d6450fb`<br>STRAWBERRY, APPLE, MANGO PEACH APPLESAUCE | same_gtin_but_unrelated_product_names |
| 20 | CRITICAL | `cf_3a38fe3b502013b5956de43e` | open_food_facts/01841701<br>`cf_3a38fe3b502013b5956de43e`<br>Tamarind paste | usda_branded/1608519<br>`cf_3a38fe3b502013b5956de43e`<br>BIG CINNAMON ROLLS | same_gtin_but_unrelated_product_names |
| 21 | CRITICAL | `cf_4e57750bc266d4f60c8f92aa` | open_food_facts/0028000080402<br>`cf_4e57750bc266d4f60c8f92aa`<br>Candy theater box | usda_branded/2614839<br>`cf_4e57750bc266d4f60c8f92aa`<br>NESTL RAISINETS MILK CHOCOLATE RAISINS, 3.5 OZ | same_gtin_but_unrelated_product_names |
| 22 | CRITICAL | `cf_6d29ff36b2784dd54aaa0f0b` | open_food_facts/0846548089080<br>`cf_6d29ff36b2784dd54aaa0f0b`<br>Nutella | usda_branded/2604572<br>`cf_6d29ff36b2784dd54aaa0f0b`<br>PROBIOTIC PRUNES | same_gtin_but_unrelated_product_names |
| 23 | CRITICAL | `cf_a143c02814957fdb8f419104` | open_food_facts/20044749<br>`cf_a143c02814957fdb8f419104`<br>Choco Bananas minis | usda_branded/470443<br>`cf_a143c02814957fdb8f419104`<br>BLONDIE | same_gtin_but_unrelated_product_names |
| 24 | CRITICAL | `cf_ba091b500d92dfcb48a7bbc5` | open_food_facts/0024100001521<br>`cf_ba091b500d92dfcb48a7bbc5`<br>Cheezit | usda_branded/2594992<br>`cf_ba091b500d92dfcb48a7bbc5`<br>KELLOGG'S SNACKS MEGA VARIETY PACK, 30 COUNT, 30.1 OZ, WHITE CHEDDAR | same_gtin_but_unrelated_product_names |
| 25 | CRITICAL | `cf_cd3e29ec34af69743b664e3e` | open_food_facts/3850104216770<br>`cf_cd3e29ec34af69743b664e3e`<br>prasak za pecivo | usda_branded/2607922<br>`cf_cd3e29ec34af69743b664e3e`<br>PODRAVKA DOLCELA BAKING POWDER, 0.42 OZ | same_gtin_but_unrelated_product_names |
| 26 | CRITICAL | `cf_d17728af0060791ef6c33e93` | open_food_facts/20044114<br>`cf_d17728af0060791ef6c33e93`<br>plus mandariini | usda_branded/471920<br>`cf_d17728af0060791ef6c33e93`<br>GRILLING CORN NIBLETS | same_gtin_but_unrelated_product_names |
| 27 | CRITICAL | `cf_d87ceca41598c1d8e1fcddfe` | open_food_facts/20014957<br>`cf_d87ceca41598c1d8e1fcddfe`<br>Pork shoulder in slices | usda_branded/477466<br>`cf_d87ceca41598c1d8e1fcddfe`<br>CLASSIC CHINESE CHICKEN SALAD | same_gtin_but_unrelated_product_names |
| 28 | CRITICAL | `cf_e16c5a096096c65260497129` | open_food_facts/8410300353843<br>`cf_e16c5a096096c65260497129`<br>Jumbo Aroma | usda_branded/453464<br>`cf_e16c5a096096c65260497129`<br>DEHYDRATED ALL PURPOSES STOCK | same_gtin_but_unrelated_product_names |
| 29 | CRITICAL | `cf_ed1ebdc3618b1df90e593150` | open_food_facts/0687080623253<br>`cf_ed1ebdc3618b1df90e593150`<br>Manitou trading company, organic royal andean blend | usda_branded/2633925<br>`cf_ed1ebdc3618b1df90e593150`<br>RED LENTIL, GREEN PEA & CHICKPEA TRIO RICED VEGGIES | same_gtin_but_unrelated_product_names |
| 30 | CRITICAL | `cf_00d1d6a79cc08729fb09a55e` | open_food_facts/0014800007114<br>`cf_00d1d6a79cc08729fb09a55e`<br>Mighty | usda_branded/2594503<br>`cf_00d1d6a79cc08729fb09a55e`<br>PINEAPPLE BANANA FLAVORED APPLESAUCE, PINEAPPLE; BANANA | same_gtin_but_unrelated_product_names |

## 5. TR ↔ EN audit

TürKomp and USDA currently share **zero generic canonical IDs**. Ten of eleven requested concept families exist on both sides, yet 0/10 are linked. Eight concept families contain at least one high/medium actionable equivalence candidate. Cheddar has no direct TürKomp record; kaşar was correctly not treated as cheddar.

| Requested concept | Status | Confidence | Verdict |
|---|---|---|---|
| egg / yumurta | missed_candidates_and_correct_separations | MEDIUM_HIGH | Whole, yolk, and white are semantically aligned across languages but unlinked. They must remain three different concepts, and cooked/fried/frozen/dried/pasteurized variants must remain distinct. |
| milk / sut | missed_candidate_with_state_caution | MEDIUM | Plain cow milk has a review-worthy USDA equivalent, but pasteurized, UHT, fat-level, lactose-free, and animal-species variants must not be merged blindly. |
| chicken breast / tavuk gogsu | missed_candidate | HIGH | The TurKomp record uses 'piliç' rather than 'tavuk'; it has a close raw skinless USDA counterpart but is not linked. |
| rice / pirinc | related_but_not_exact | MEDIUM | Osmancik rice is cultivar-specific and uncooked by nutrient profile. Generic USDA white raw rice is useful as a parent/equivalent candidate, not a safe exact merge. |
| banana / muz | correctly_separated_variants | HIGH | Both TurKomp bananas are explicit origin/variety records; USDA generic raw banana is a broader parent, not an exact identity. |
| apple / elma | high_confidence_missed_candidates_and_correct_separations | HIGH | Gala and Fuji cultivar pairs are strong missed equivalence candidates. Juice, dried apple, vinegar, and Atelmasi are correctly separate. |
| olive oil / zeytinyagi | one_high_confidence_candidate_with_refinement_separations | HIGH | Extra virgin olive oil is a strong name-level match. Riviera, refined, generic olive oil, and olive-containing foods must remain distinguishable. |
| yogurt / yogurt | missed_candidates_with_fat_and_style_caution | MEDIUM | Plain whole-milk and low-fat yogurt have review-worthy Turkish counterparts; buffalo, strained/regional, probiotic, and flavored yogurt should retain subtype identity. |
| cheddar | turkomp_direct_record_not_found | HIGH | USDA cheddar records exist, but no TurKomp record names cheddar/çedar. Turkish kaşar is related but not cheddar and must not be used as an automatic translation merge. |
| bread / ekmek | missed_candidates_and_correct_type_separations | MEDIUM_HIGH | White, rye, and whole-wheat bread have plausible bilingual counterparts but no cross-language canonical link. Toasted, flour, salt-free, gluten-free, and grain-type variants require separate identities. |
| potato / patates | related_candidates_with_variety_and_state_caution | MEDIUM_HIGH | Raw table/processing potato varieties are related to generic USDA raw potatoes but should remain cultivar-use variants; starch, frozen frying potatoes, and chips are correctly separate. |

Translation must never erase state. For example, TürKomp whole egg with unspecified preparation remains a review candidate against USDA raw whole egg, while boiled, fried, yolk, and white records stay separate. Similar constraints apply to UHT/fat-level milk, chicken cuts, raw/cooked rice, cultivars, olive-oil grades, yogurt styles, bread types, and potato products.

### Source records found for requested concepts

#### egg / yumurta

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| turkomp | 26 | `cf_477e02bd6e9970228250942b` | Yumurta, tavuk, tam |
| usda_fndds | 2707152 | `cf_b1d437ff8acdac748ecee112` | Egg, whole, raw |
| turkomp | 27 | `cf_70b61e5accb52a965fe72627` | Yumurta, tavuk, sarı |
| usda_fndds | 2707172 | `cf_e475e417dc025d4b88c413be` | Egg, yolk only, raw |
| turkomp | 28 | `cf_be73769c94abd1e3cea68293` | Yumurta, tavuk, beyaz (ak) |
| usda_fndds | 2707168 | `cf_60cacc98c098c5b3c6bdfb75` | Egg, white only, raw |

#### milk / sut

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| turkomp | 17 | `cf_670839c8fd5a230d1add3dd0` | Süt, inek |
| usda_fndds | 2705385 | `cf_deddcdbc658096abb66d1b75` | Milk, whole |
| turkomp | 16 | `cf_951bcf2066719c48102c478c` | Süt, pastörize, tam yağlı (100 ml' de 3 g süt yağı) |
| usda_foundation | 746782 | `cf_04c9c9c058fdd17239688962` | Milk, whole, 3.25% milkfat, with added vitamin D |

#### chicken breast / tavuk gogsu

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| turkomp | 64 | `cf_eb0b6f5b65e58e990a9f9aa1` | Piliç eti, göğüs, derisiz |
| usda_sr_legacy | 171509 | `cf_ad479c12bc650219e373417a` | Chicken, broilers or fryers, breast, skinless, boneless, meat only, with added solution, raw |

#### rice / pirinc

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| turkomp | 144 | `cf_4b83302a94cc949b1feaba29` | Pirinç, Osmancık |
| usda_foundation | 2512381 | `cf_46667f635a6f594a1052c607` | Rice, white, long grain, unenriched, raw |
| turkomp | 146 | `cf_6f9dcc74b8ebd11bfed7833e` | Pirinç unu |
| usda_foundation | 790214 | `cf_7104f6cfc37dded47efffc53` | Flour, rice, white, unenriched |

#### banana / muz

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| turkomp | 395 | `cf_877942721ee16f98c8227ac4` | Muz, Anamur çeşidi |
| turkomp | 396 | `cf_8a46aa2adf7b2a763b38e61d` | Muz, İthal çeşit |
| usda_sr_legacy | 173944 | `cf_71ab2f596cc90f64bbb0bc62` | Bananas, raw |

#### apple / elma

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| turkomp | 332 | `cf_3036b540cbff14d44a148d5a` | Elma, yazlık, Gala çeşidi |
| usda_sr_legacy | 168204 | `cf_47b9084c3dae5fba5465c118` | Apples, raw, gala, with skin (Includes foods for USDA's Food Distribution Program) |
| turkomp | 333 | `cf_a1654c3ea2ff1295771aa941` | Elma, güzlük ve kışlık, Fuji çeşidi |
| usda_sr_legacy | 167793 | `cf_5a633831871e0147388f292d` | Apples, raw, fuji, with skin (Includes foods for USDA's Food Distribution Program) |

#### olive oil / zeytinyagi

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| turkomp | 103 | `cf_e53b2c95908e1d590b643493` | Zeytinyağı, sızma |
| usda_foundation | 748608 | `cf_786910fdefc8eab3362b4771` | Oil, olive, extra virgin |
| turkomp | 104 | `cf_55a71bac23f46c436eac4b18` | Zeytinyağı, riviera |
| turkomp | 105 | `cf_1612287fea993f354036b81c` | Zeytinyağı, rafine |
| usda_sr_legacy | 171413 | `cf_398e4d261ad097a7567ad800` | Oil, olive, salad or cooking |

#### yogurt / yogurt

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| turkomp | 4 | `cf_2ed3fb15410fa52d67f946f8` | Yoğurt, homojenize, tam yağlı (süt yağı ≥ % 3.8) |
| usda_foundation | 2259793 | `cf_51734673ed10face8a856f71` | Yogurt, plain, whole milk |
| turkomp | 3 | `cf_86b366d7dce678e4a84576c8` | Yoğurt, homojenize, yarım yağlı (% 2 > süt yağı ≥ % 1.5) |
| usda_fndds | 2705419 | `cf_7a532066ad85766c6f248463` | Yogurt, low fat milk, plain |

#### cheddar

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| usda_foundation | 328637 | `cf_f82f86b20b953c7ddece1cea` | Cheese, cheddar |
| turkomp | 11 | `cf_2d8c3a55dcefd24bc09ebb14` | Peynir, kaşar, olgunlaştırılmamış (taze) |
| turkomp | 12 | `cf_106b35702926f82c53fa1510` | Peynir, kaşar, olgunlaştırılmış (eski) |

#### bread / ekmek

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| turkomp | 126 | `cf_d6f43053b707ec9baa319883` | Ekmek, beyaz |
| usda_fndds | 2707598 | `cf_c91f149c6f5ad4f3f21ae41f` | Bread, white |
| turkomp | 124 | `cf_d078e7973ed99c1649f22eac` | Ekmek, çavdar |
| usda_fndds | 2707755 | `cf_4a6f68e50c0ddf3a62658e43` | Bread, rye |
| turkomp | 128 | `cf_14c606fb4308d895e5f58506` | Ekmek, tam buğday unlu |
| usda_fndds | 2707709 | `cf_51db2034f4b909c830138aba` | Bread, whole wheat |

#### potato / patates

| Source | Source ID | Canonical ID | Name |
|---|---|---|---|
| turkomp | 281 | `cf_e190029e07b6a7301baedcb4` | Patates, nişastalık, beyaz etli, Lady Rosetta, Hermes |
| turkomp | 282 | `cf_15557c3f4de2ec108f005030` | Patates, sofralık, sarı, Marfona, Granola, Marabel |
| usda_sr_legacy | 170028 | `cf_eeb0ab42349e090aa034cf0a` | Potatoes, white, flesh and skin, raw |
| usda_foundation | 2346403 | `cf_949dede5b9aeb12b6fb31377` | Potatoes, gold, without skin, raw |

## 6. Preparation/state safety

The existing generic high-confidence merges are conservative and state-safe in this audit: **0/175 generic merged groups had a detected preparation/state conflict**. The following examples confirm that meaningful distinctions remain separate.

### 30 correct-separation examples

| # | Category | Left | Right | Reason |
|---:|---|---|---|---|
| 1 | raw_vs_cooked | usda_sr_legacy/167888<br>`cf_1f7ad46a24e02365f79264d9`<br>Pork, fresh, composite of trimmed retail cuts (leg, loin, shoulder, and spareribs), separable lean and fat, raw | usda_sr_legacy/168297<br>`cf_bd621407875643a3bd00d10b`<br>Pork, fresh, composite of trimmed retail cuts (leg, loin, shoulder, and spareribs), separable lean and fat, cooked | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 2 | raw_vs_cooked | usda_sr_legacy/172592<br>`cf_844a9e1ca7a004f5fc3c93ef`<br>Lamb, Australian, imported, fresh, shoulder, whole (arm and blade), separable lean only, trimmed to 1/8" fat, raw | usda_sr_legacy/172593<br>`cf_4c9388758a64b2be77917e40`<br>Lamb, Australian, imported, fresh, shoulder, whole (arm and blade), separable lean only, trimmed to 1/8" fat, cooked | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 3 | raw_vs_cooked | usda_sr_legacy/167855<br>`cf_4b3d972998752b922750bd2a`<br>Pork, fresh, composite of trimmed retail cuts (leg, loin, and shoulder), separable lean only, cooked | usda_sr_legacy/168220<br>`cf_f2dc5de065566d5af2373271`<br>Pork, fresh, composite of trimmed retail cuts (leg, loin, shoulder), separable lean only, raw | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 4 | raw_vs_cooked | usda_sr_legacy/167906<br>`cf_c696523d817a9333d69faf58`<br>Pork, fresh, composite of trimmed retail cuts (loin and shoulder blade), separable lean and fat, cooked | usda_sr_legacy/168316<br>`cf_47af1214b1e353a7dc61f432`<br>Pork, fresh, composite of trimmed retail cuts (loin and shoulder blade), separable lean and fat, raw | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 5 | raw_vs_cooked | usda_sr_legacy/167907<br>`cf_86f8317672e53663ffc880c3`<br>Pork, fresh, composite of trimmed retail cuts (loin and shoulder blade), separable lean only, raw | usda_sr_legacy/167908<br>`cf_0d64062b5d8b73a454b4637a`<br>Pork, fresh, composite of trimmed retail cuts (loin and shoulder blade), separable lean only, cooked | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 6 | boiled_vs_fried | usda_sr_legacy/169370<br>`cf_1f9a50db033205171003e57a`<br>Soybeans, mature seeds, sprouted, cooked, stir-fried, with salt | usda_sr_legacy/174299<br>`cf_e59bf50febe1a242d083eb6b`<br>Soybeans, mature seeds, cooked, boiled, with salt | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 7 | boiled_vs_fried | usda_sr_legacy/168499<br>`cf_7ef728c7a5b1d1a25d6fd079`<br>Mung beans, mature seeds, sprouted, cooked, boiled, drained, with salt | usda_sr_legacy/169138<br>`cf_30156f453f524f699b08302f`<br>Mung beans, mature seeds, sprouted, cooked, stir-fried | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 8 | boiled_vs_fried | usda_sr_legacy/168627<br>`cf_e5389a8414e361fcf2b77e8c`<br>Beef, variety meats and by-products, liver, cooked, pan-fried | usda_sr_legacy/174728<br>`cf_2b1b9d274eb0ab5d00aceb13`<br>Beef, New Zealand, imported, variety meats and by-products liver, cooked, boiled | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 9 | boiled_vs_fried | usda_sr_legacy/168199<br>`cf_3b6a99984018d78cdccf7281`<br>Plantains, green, fried | usda_sr_legacy/168216<br>`cf_44ff8553e4fd708220ecd053`<br>Plantains, green, boiled | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 10 | boiled_vs_fried | usda_sr_legacy/169137<br>`cf_9418ff4f4da39dbbdbb33eec`<br>Mung beans, mature seeds, sprouted, cooked, boiled, drained, without salt | usda_sr_legacy/169138<br>`cf_30156f453f524f699b08302f`<br>Mung beans, mature seeds, sprouted, cooked, stir-fried | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 11 | fresh_vs_dried | usda_fndds/2707348<br>`cf_b3baac2c8429dabbee2f74c6`<br>Beans, from dried, NS as to type, fat added | usda_fndds/2709856<br>`cf_824f5dd2f7ff16ae52d3a3be`<br>Green beans, fresh, cooked, fat added, NS as to fat type | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 12 | fresh_vs_dried | usda_fndds/2707349<br>`cf_6cd2e6db5d2c2fe77f7b1c54`<br>Beans, from dried, NS as to type, no added fat | usda_fndds/2709856<br>`cf_824f5dd2f7ff16ae52d3a3be`<br>Green beans, fresh, cooked, fat added, NS as to fat type | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 13 | fresh_vs_dried | usda_fndds/2707348<br>`cf_b3baac2c8429dabbee2f74c6`<br>Beans, from dried, NS as to type, fat added | usda_fndds/2709580<br>`cf_e916172daf269eb30e200eed`<br>Collards, fresh, cooked, fat added, NS as to fat type | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 14 | fresh_vs_dried | usda_fndds/2707348<br>`cf_b3baac2c8429dabbee2f74c6`<br>Beans, from dried, NS as to type, fat added | usda_fndds/2709621<br>`cf_2e281c0ce5d694b51be36e3e`<br>Spinach, fresh, cooked, fat added, NS as to fat type | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 15 | fresh_vs_dried | usda_fndds/2707348<br>`cf_b3baac2c8429dabbee2f74c6`<br>Beans, from dried, NS as to type, fat added | usda_fndds/2709648<br>`cf_b29f21e05ed044d95d0b9d85`<br>Broccoli, fresh, cooked, fat added, NS as to fat type | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 16 | whole_vs_reduced_fat | usda_fndds/2705438<br>`cf_b9e8398e69d36e5cfa9f195f`<br>Yogurt, Greek, whole milk, flavors other than fruit | usda_fndds/2705440<br>`cf_b4f9cf26354043a93eb13b45`<br>Yogurt, Greek, nonfat milk, flavors other than fruit | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 17 | whole_vs_reduced_fat | usda_fndds/2705434<br>`cf_6d47ad5739e03520ed38f8b5`<br>Yogurt, whole milk, flavors other than fruit | usda_fndds/2705436<br>`cf_1b7b2f2133e4e8ce03a7b7c3`<br>Yogurt, nonfat milk, flavors other than fruit | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 18 | whole_vs_reduced_fat | usda_foundation/2259794<br>`cf_9855a53cb940bcac93684583`<br>Yogurt, Greek, plain, whole milk | usda_fndds/2705424<br>`cf_2f65ca199827e29a5bec538f`<br>Yogurt, Greek, nonfat milk, plain | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 19 | whole_vs_reduced_fat | usda_fndds/2705422<br>`cf_8161da2aafdb471885642e7c`<br>Yogurt, Greek, whole milk, plain | usda_fndds/2705424<br>`cf_2f65ca199827e29a5bec538f`<br>Yogurt, Greek, nonfat milk, plain | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 20 | whole_vs_reduced_fat | usda_fndds/2705424<br>`cf_2f65ca199827e29a5bec538f`<br>Yogurt, Greek, nonfat milk, plain | usda_sr_legacy/171304<br>`cf_9855a53cb940bcac93684583`<br>Yogurt, Greek, plain, whole milk | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 21 | egg_parts | usda_foundation/323697<br>`cf_29c470f0b9950270dca13e45`<br>Egg, white, raw, frozen, pasteurized | usda_foundation/329596<br>`cf_64ddbcdcd6072eb765a912e4`<br>Egg, yolk, raw, frozen, pasteurized | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 22 | egg_parts | usda_foundation/323697<br>`cf_29c470f0b9950270dca13e45`<br>Egg, white, raw, frozen, pasteurized | usda_sr_legacy/173421<br>`cf_64ddbcdcd6072eb765a912e4`<br>Egg, yolk, raw, frozen, pasteurized | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 23 | egg_parts | usda_foundation/329596<br>`cf_64ddbcdcd6072eb765a912e4`<br>Egg, yolk, raw, frozen, pasteurized | usda_sr_legacy/172203<br>`cf_29c470f0b9950270dca13e45`<br>Egg, white, raw, frozen, pasteurized | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 24 | egg_parts | usda_foundation/747997<br>`cf_88545dd64a37615c53abdb3d`<br>Eggs, Grade A, Large, egg white | usda_foundation/748236<br>`cf_7fc946ee51d116e2ea0754a0`<br>Eggs, Grade A, Large, egg yolk | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 25 | egg_parts | usda_sr_legacy/172203<br>`cf_29c470f0b9950270dca13e45`<br>Egg, white, raw, frozen, pasteurized | usda_sr_legacy/173421<br>`cf_64ddbcdcd6072eb765a912e4`<br>Egg, yolk, raw, frozen, pasteurized | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 26 | chicken_cuts | usda_sr_legacy/170344<br>`cf_68245a2558b0f976cf9bf637`<br>KFC, Fried Chicken, EXTRA CRISPY, Breast, meat only, skin and breading removed | usda_sr_legacy/170345<br>`cf_6b90f34ec1448dd1ec2290c5`<br>KFC, Fried Chicken, EXTRA CRISPY, Drumstick, meat only, skin and breading removed | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 27 | chicken_cuts | usda_sr_legacy/170344<br>`cf_68245a2558b0f976cf9bf637`<br>KFC, Fried Chicken, EXTRA CRISPY, Breast, meat only, skin and breading removed | usda_sr_legacy/170742<br>`cf_e69c030962f5f229d9b8414d`<br>KFC, Fried Chicken, EXTRA CRISPY, Thigh, meat only, skin and breading removed | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 28 | chicken_cuts | usda_sr_legacy/170344<br>`cf_68245a2558b0f976cf9bf637`<br>KFC, Fried Chicken, EXTRA CRISPY, Breast, meat only, skin and breading removed | usda_sr_legacy/170743<br>`cf_9bb5a508c7f901d24ef89eda`<br>KFC, Fried Chicken, EXTRA CRISPY, Wing, meat only, skin and breading removed | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 29 | chicken_cuts | usda_sr_legacy/170345<br>`cf_6b90f34ec1448dd1ec2290c5`<br>KFC, Fried Chicken, EXTRA CRISPY, Drumstick, meat only, skin and breading removed | usda_sr_legacy/170742<br>`cf_e69c030962f5f229d9b8414d`<br>KFC, Fried Chicken, EXTRA CRISPY, Thigh, meat only, skin and breading removed | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |
| 30 | chicken_cuts | usda_sr_legacy/170345<br>`cf_6b90f34ec1448dd1ec2290c5`<br>KFC, Fried Chicken, EXTRA CRISPY, Drumstick, meat only, skin and breading removed | usda_sr_legacy/170743<br>`cf_9bb5a508c7f901d24ef89eda`<br>KFC, Fried Chicken, EXTRA CRISPY, Wing, meat only, skin and breading removed | explicit preparation/composition qualifier differs and records retain distinct canonical IDs |

## 7. Review candidate kalitesi

The 153,370-row review queue is materially oversized. Of 153,363 branded same-name candidates, **146,043 pairs already have two different checksum-valid GTINs**. Under the current physical-product identity definition, that is deterministic evidence to keep them separate, not a reason to spend human review capacity. Only approximately **7,327** candidates remain genuinely unresolved from the available fields. No review candidate was classified as deterministically safe to merge from the candidate payload alone.

| Queue class | Count | Action |
|---|---:|---|
| Genuine human review | 7,327 | Retain |
| Deterministically mergeable | 0 | None identified |
| Deterministic keep-separate / irrelevant to merge queue | 146,043 | Remove from human queue |

Estimated human-queue reduction: **95.22%**.

### 30 review-candidate examples

| # | Candidate | Class | Left | Right | Method |
|---:|---|---|---|---|---|
| 1 | `cr_000000001` | human_review | usda_foundation/2727581<br>`cf_01ee6db9aa9a2ab43033ca74`<br>Blackberries, raw | usda_fndds/2709273<br>`cf_821597db34055020a9deb01b`<br>Blackberries, raw | generic_identity_collision |
| 2 | `cr_000000002` | human_review | usda_fndds/2705730<br>`cf_3c33b31204ba77e1c98d87bd`<br>Cheese, Parmesan, hard | usda_sr_legacy/170848<br>`cf_ac00ca5dcdca284a6eee987a`<br>Cheese, parmesan, hard | generic_identity_collision |
| 3 | `cr_000000003` | human_review | usda_fndds/2705644<br>`cf_2a1e13b1ea760af7cfda39eb`<br>Ice cream cookie sandwich | usda_sr_legacy/172227<br>`cf_febc53c9d10b83cd8971f113`<br>Ice cream cookie sandwich | generic_identity_collision |
| 4 | `cr_000000004` | human_review | usda_foundation/748278<br>`cf_0e5ed6d08dfcf52d85796a92`<br>Oil, canola | usda_sr_legacy/172336<br>`cf_79223c993c0819475922fbaa`<br>Oil, canola | generic_identity_collision |
| 5 | `cr_000000005` | human_review | usda_sr_legacy/171853<br>`cf_1eb4f92ed6620ea5e2ac05ed`<br>Pancakes, whole wheat, dry mix, incomplete | usda_sr_legacy/172776<br>`cf_520e49b910908b55cd04f071`<br>Pancakes, whole-wheat, dry mix, incomplete | generic_identity_collision |
| 6 | `cr_000000006` | human_review | usda_fndds/2705729<br>`cf_c2b7a9e541216bbf4f69501a`<br>Cheese, Parmesan, dry grated, reduced fat | usda_sr_legacy/173452<br>`cf_504337461afdc62fe9cce6c3`<br>Cheese, parmesan, dry grated, reduced fat | generic_identity_collision |
| 7 | `cr_000000007` | human_review | usda_fndds/2708305<br>`cf_4da6bdf69c6cef9cdd3ac216`<br>Pancakes, plain, reduced fat | usda_sr_legacy/174086<br>`cf_dd1a7c357a0386414acf55ef`<br>Pancakes, plain, reduced fat | generic_identity_collision |
| 8 | `cr_000000011` | human_review | usda_branded/1115041<br>`cf_21a2fe446957c224027f9d7a`<br>BUTTERMILK LIGHT ORIGINAL RANCH DRESSING, BUTTERMILK ORIGINAL RANCH | usda_branded/1115045<br>`cf_382ac2e39bdf8b2aac2451d6`<br>BUTTERMILK LIGHT ORIGINAL RANCH DRESSING, BUTTERMILK ORIGINAL RANCH | same_brand_and_name_different_barcode |
| 9 | `cr_000000016` | human_review | usda_branded/1110146<br>`cf_d2c49e5bd0d52055d09b6611`<br>ORIGINAL POPS, ORIGINAL | usda_branded/1121591<br>`cf_685dba707451c5b69951e121`<br>ORIGINAL POPS, ORIGINAL | same_brand_and_name_different_barcode |
| 10 | `cr_000000019` | human_review | usda_branded/1122586<br>`cf_13719dec1d508717f2ba8bda`<br>OVEN ROASTED TURKEY BREAST, OVEN ROASTED | usda_branded/1124073<br>`cf_55051d3dbce7f7d89d5cdc7c`<br>OVEN ROASTED TURKEY BREAST, OVEN ROASTED | same_brand_and_name_different_barcode |
| 11 | `cr_000000008` | deterministic_separation | usda_branded/1112099<br>`cf_0c295f53e5b7ee240b10f742`<br>VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | usda_branded/1112101<br>`cf_b13cafb6a2df71ad907dfb48`<br>VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | same_brand_and_name_different_barcode |
| 12 | `cr_000000009` | deterministic_separation | usda_branded/1112099<br>`cf_0c295f53e5b7ee240b10f742`<br>VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | usda_branded/1114186<br>`cf_ebab05a8864ecdaae4cff546`<br>VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | same_brand_and_name_different_barcode |
| 13 | `cr_000000010` | deterministic_separation | usda_branded/1112099<br>`cf_0c295f53e5b7ee240b10f742`<br>VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | usda_branded/1114187<br>`cf_ee2975c57374f1c25ac32784`<br>VANILLA & CHOCOLATE CUPCAKES, VANILLA & CHOCOLATE | same_brand_and_name_different_barcode |
| 14 | `cr_000000012` | deterministic_separation | usda_branded/1113345<br>`cf_3e4c80f557c9dd6a353e5607`<br>CHOCOLATE CUPCAKES, CHOCOLATE | usda_branded/1120747<br>`cf_6a561d3eff9ac602afc21bfb`<br>CHOCOLATE CUPCAKES, CHOCOLATE | same_brand_and_name_different_barcode |
| 15 | `cr_000000013` | deterministic_separation | usda_branded/1120220<br>`cf_020a0e75176c6c902fb5269d`<br>VANILLA CUPCAKES, VANILLA | usda_branded/1120978<br>`cf_5b675672349e87278109a166`<br>VANILLA CUPCAKES, VANILLA | same_brand_and_name_different_barcode |
| 16 | `cr_000000014` | deterministic_separation | usda_branded/1113345<br>`cf_3e4c80f557c9dd6a353e5607`<br>CHOCOLATE CUPCAKES, CHOCOLATE | usda_branded/1121036<br>`cf_7aba7b0cab0b07964be5b2f9`<br>CHOCOLATE CUPCAKES, CHOCOLATE | same_brand_and_name_different_barcode |
| 17 | `cr_000000015` | deterministic_separation | usda_branded/1113345<br>`cf_3e4c80f557c9dd6a353e5607`<br>CHOCOLATE CUPCAKES, CHOCOLATE | usda_branded/1121420<br>`cf_5955484ae53df1c0571ff770`<br>CHOCOLATE CUPCAKES, CHOCOLATE | same_brand_and_name_different_barcode |
| 18 | `cr_000000017` | deterministic_separation | usda_branded/1120661<br>`cf_81faa8a225d82d068bb40cb8`<br>BROWNIES | usda_branded/1121617<br>`cf_9aa8598134762341d6e83dde`<br>BROWNIES | same_brand_and_name_different_barcode |
| 19 | `cr_000000018` | deterministic_separation | usda_branded/1120661<br>`cf_81faa8a225d82d068bb40cb8`<br>BROWNIES | usda_branded/1121620<br>`cf_f259832561469fea1f16fff0`<br>BROWNIES | same_brand_and_name_different_barcode |
| 20 | `cr_000000020` | deterministic_separation | usda_branded/1126193<br>`cf_04221e7bd4e01d1f77425997`<br>PEANUT BUTTER, NUTS & CACAO NIBS PURE ORGANIC RAW BAR, PEANUT BUTTER, NUTS & CACAO NIBS | usda_branded/1126287<br>`cf_db7623328c8a6d1c2d36dde6`<br>PEANUT BUTTER, NUTS & CACAO NIBS PURE ORGANIC RAW BAR, PEANUT BUTTER, NUTS & CACAO NIBS | same_brand_and_name_different_barcode |
| 21 | `cr_000000021` | deterministic_separation | usda_branded/1126388<br>`cf_d50f74d85f4b3209b7084b20`<br>CACAO, CACAO NIBS & HAZELNUTS PURE ORGANIC RAW BAR, CACAO, CACAO NIBS & HAZELNUTS | usda_branded/1126434<br>`cf_be2a1677ea8ce20859da4daa`<br>CACAO, CACAO NIBS & HAZELNUTS PURE ORGANIC RAW BAR, CACAO, CACAO NIBS & HAZELNUTS | same_brand_and_name_different_barcode |
| 22 | `cr_000000022` | deterministic_separation | usda_branded/1126439<br>`cf_9bb035af2a3c5a63e1ba8b3b`<br>COCONUT, VANILLA & LEMON PURE RAW ORGANIC PROTEIN BAR, COCONUT, VANILLA & LEMON | usda_branded/1126532<br>`cf_7ccf895e0aaabb9ab7d94982`<br>COCONUT, VANILLA & LEMON PURE RAW ORGANIC PROTEIN BAR, COCONUT, VANILLA & LEMON | same_brand_and_name_different_barcode |
| 23 | `cr_000000023` | deterministic_separation | usda_branded/1126863<br>`cf_c1002f2f3f694495bee78477`<br>CHAI MASALA ORGANIC SPICES MIX | usda_branded/1126865<br>`cf_bfd9433cd6f2cb7fe85b924d`<br>CHAI MASALA ORGANIC SPICES MIX | same_brand_and_name_different_barcode |
| 24 | `cr_000000024` | deterministic_separation | usda_branded/1126843<br>`cf_ab633c956c89b5ea178cb810`<br>HIMALAYAN PINK SALT | usda_branded/1126876<br>`cf_16d1f2f874d086c74dc09d79`<br>HIMALAYAN PINK SALT | same_brand_and_name_different_barcode |
| 25 | `cr_000000025` | deterministic_separation | usda_branded/1126795<br>`cf_ec1e172cb36695da6e9b7fa9`<br>BLACK PEPPER GROUND ORGANIC SPICES | usda_branded/1126967<br>`cf_7da07dfcdc905d1e0bfc4881`<br>BLACK PEPPER GROUND ORGANIC SPICES | same_brand_and_name_different_barcode |
| 26 | `cr_000000026` | deterministic_separation | usda_branded/1126869<br>`cf_5248db9f48538387d900e6a9`<br>BLACK PEPPER WHOLE ORGANIC SPICES | usda_branded/1127014<br>`cf_90c346065d367f7fec8b4e6e`<br>BLACK PEPPER WHOLE ORGANIC SPICES | same_brand_and_name_different_barcode |
| 27 | `cr_000000027` | deterministic_separation | usda_branded/1120220<br>`cf_020a0e75176c6c902fb5269d`<br>VANILLA CUPCAKES, VANILLA | usda_branded/1129736<br>`cf_a5560338b9b24f42c9818a8e`<br>VANILLA CUPCAKES, VANILLA | same_brand_and_name_different_barcode |
| 28 | `cr_000000028` | deterministic_separation | usda_branded/1120220<br>`cf_020a0e75176c6c902fb5269d`<br>VANILLA CUPCAKES, VANILLA | usda_branded/1129739<br>`cf_b6b4ff0c8f58eb31b9c1ae27`<br>VANILLA CUPCAKES, VANILLA | same_brand_and_name_different_barcode |
| 29 | `cr_000000029` | deterministic_separation | usda_branded/1130787<br>`cf_dcc30ec726cfdcbbea4b2db2`<br>HIMALAYAN PINK SALT | usda_branded/1130788<br>`cf_e623f23fb019f53cc3b48941`<br>HIMALAYAN PINK SALT | same_brand_and_name_different_barcode |
| 30 | `cr_000000030` | deterministic_separation | usda_branded/1131665<br>`cf_2537f12eeabbef3ac9e69d08`<br>LOW SODIUM CHICKEN BROTH, CHICKEN | usda_branded/1131666<br>`cf_3c5aba07f8f38d4273c3a917`<br>LOW SODIUM CHICKEN BROTH, CHICKEN | same_brand_and_name_different_barcode |

## 8. Önerilen canonicalization iyileştirmeleri

1. **Barcode contradiction gate:** exact valid GTIN must not auto-merge when available name, brand, category, or market signals materially conflict. Quarantine the group instead.
2. **Market-scoped short codes:** treat GTIN-8 and retailer/internal short codes as market-scoped unless brand/product compatibility also passes.
3. **Nutrition as supporting evidence:** large macro disagreement should raise a warning, but must not alone split identity because prepared-vs-dry or serving-basis errors exist.
4. **Token-order-invariant generic key:** compare qualifier-preserving token multisets so “oil, canola” and “canola oil” can resolve deterministically.
5. **Explicit qualifier ontology:** preserve raw/cooked/boiled/fried, fresh/dried/frozen, cut/part, fat level, salt, fortification, cultivar, edible fraction, and physical form. Any conflict blocks merge.
6. **Versioned TR/EN identity lexicon:** add auditable mappings such as piliç↔chicken and göğüs↔breast. Unspecified preparation must not auto-merge with explicit raw/cooked states.
7. **Review queue pruning:** different valid GTINs stay separate by rule. Review only missing/invalid barcode collisions, generic identity collisions, and barcode groups with contradictory identity evidence.
8. **Rerun and re-audit before import:** regenerate canonical outputs after these rules, then require zero unresolved CRITICAL/HIGH auto-merge candidates before Supabase promotion.

## Final decision

1. **Production import ready? No.** Cleaned source data can remain as-is, but the current canonical merged catalog should not be promoted.
2. **Generic side too conservative? Yes.** Approximately 114 additional reductions appear achievable after qualifier-safe deterministic rules.
3. **Rerun required? Yes.** Change the canonicalization rules first, then rerun and re-audit.
4. **Rules to add?** Barcode contradiction/market gates, token-order-invariant generic identity, explicit qualifier ontology, curated TR/EN lexicon, and deterministic review pruning.
5. **Larger risk? Wrong merge.** Generic missed merges reduce recall; current barcode conflicts can produce incorrect product identity and nutrition, which is more severe for meal logging.

## Audit limitations

- This was a local read-only structural/content audit, not external manufacturer verification.
- Severity flags identify risk candidates, not confirmed false identities.
- Nutrition similarity supports but cannot prove food identity.
- The missed-merge estimate is heuristic and intentionally conservative.
- No database import, source mutation, canonical merge, or pipeline modification was performed.
