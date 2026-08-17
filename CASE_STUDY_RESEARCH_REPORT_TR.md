# EatBetter Case Study — Mobil Ürün, UX ve Teknik Araştırma Raporu

Tarih: 17 Ağustos 2026  
Amaç: Yedi gün içinde, “AI ile yemek loglama” demosundan ziyade doğruluğu ölçülebilen, belirsizliği güvenli biçimde yöneten ve gerçek ürün hissi veren bir mobil MVP çıkarmak.

## 1. Yönetici özeti

Bu case’in en güçlü cevabı, içine mümkün olan her teknolojiyi koymak değildir. En güçlü cevap şudur:

> Kullanıcı yemeğini doğal biçimde anlatır. Sistem gıdayı ve porsiyonu güvenle çözer; besin değerini LLM’den üretmez, doğrulanabilir katalogdan hesaplar. Sonucu anlamlı ölçüde değiştirecek bir belirsizlik varsa kullanıcıya yalnızca o noktayı, tek dokunuşluk normal bir mobil arayüzle doğrulatır.

Önerilen yol **hybrid retrieval + rules + LLM** yaklaşımıdır:

1. Deterministik metin ve ölçü normalizasyonu
2. LLM ile şema kontrollü ingredient/quantity extraction
3. Exact alias + full-text/trigram + gerektiğinde vector candidate retrieval
4. Adaylarla sınırlandırılmış canonical eşleştirme
5. Gıdaya özel portion resolver
6. Etki temelli clarification policy
7. Katalogdan deterministik nutrition hesabı
8. Düzenlenebilir review ve idempotent commit
9. Kullanıcı düzeltmelerinden anonimleştirilmiş eval/feedback kaydı

Mobil teknoloji için başlangıç önerim **Flutter**; backend için **FastAPI + PostgreSQL/Supabase**; ilerideki web istemcisi için **Next.js**. Flutter seçiminin nedeni tek kod tabanında iOS/Android, iyi custom motion ve bu case’de ihtiyaç duyulan görsel kontrol. Ancak ekip React/TypeScript’te belirgin biçimde daha hızlıysa Expo/React Native de aynı ürün mimarisiyle geçerli olur. Değerlendirmede framework değil bitmişlik ve doğruluk kanıtı önemlidir.

## 2. Araştırmadan çıkan ürün gerçeği

Rakiplerin güncel yönü “tek input” değil, ortak bir review yüzeyine çıkan birden fazla input yöntemidir:

- MyFitnessPal bugün meal scan, barcode ve voice logging sunuyor; camera sonucu doğrulanmış food database girdilerine bağlamaya çalışıyor. [MyFitnessPal Premium özellikleri](https://support.myfitnesspal.com/hc/en-us/articles/360032625951-What-are-the-features-of-MyFitnessPal-Premium)
- MacroFactor’ın Describe akışı yazı/sesi common-food database’e eşleyip sonuçları editable plate’e ekliyor; AI photo akışı da sonucu düzenlenebilir food entries olarak açıyor. Bu, “AI sonucu final cevap değil, düzenlenebilir taslak” prensibini doğruluyor. [Describe](https://help.macrofactorapp.com/en/articles/216-log-foods-with-ai-describe), [AI Food Logging](https://help.macrofactorapp.com/en/articles/258-ai-food-logging)
- Lifesum Mart 2026 güncellemesinde text, camera, voice, search ve barcode yollarını tek tracking deneyiminde birleştirdi; typed input için gereksiz mode-selection adımını kaldırdı. [Lifesum güncellemeleri](https://help.lifesum.com/en/article/what-is-new-these-are-the-latest-additions-to-our-app-1vy6mk1/)

Ancak case’de rakiplerin özellik sayısını yakalamaya çalışmak yanlış kapsam olur. İlk sürümde text-first + voice dictation yeterlidir. Photo ve barcode aynı `MealDraft` sözleşmesine bağlanabilecek şekilde mimaride görünmeli, fakat bitmemiş özellik olarak ana demo akışına girmemelidir.

Portion estimation gerçekten zor problemdir. 2026 tarihli geniş sistematik derleme, ölçüm yardımcıları arasında büyük hata aralıkları bulunduğunu ve en iyi görünen yaklaşımın bile her gıda/kullanıcı bağlamında güvenilir olmadığını gösteriyor. Bu nedenle üç görsel göstermek tek başına “doğru ölçüm” değildir; kendi asset’lerimizi hedef kullanıcılarla küçük bir validation çalışmasında test etmeliyiz. [Nutrition Reviews sistematik derlemesi](https://academic.oup.com/nutritionreviews/advance-article/doi/10.1093/nutrit/nuag063/8691563)

## 3. Mevcut mockup’ların dürüst UX/UI denetimi

### Güçlü taraflar

- Beyaz zemin, güçlü siyah tipografi ve tek lime accent doğru bir ürün yönü.
- Food photography işlevsel olarak kullanılabilir; yalnızca dekorasyon olmak zorunda değil.
- AI sonucunu item listesine parçalamak, tek bir “420 kcal” cevabından daha güvenilir ve düzenlenebilir.
- Belirsiz item’i turuncu durumla öne çıkarmak anlaşılır.
- Today → understand → clarify → review → log akışı case’in ana problemini görünür kılıyor.

### Kritik problemler

1. **Sayısal tutarsızlık:** 420 + 610 + 190 = 1.220 kcal, mockup üst toplamı 1.120 kcal. Bu case’de görsel kusurdan daha ağır bir hatadır.
2. **Şüpheli besin değeri:** 30 g white cheese için 170 kcal gösteriliyor. Kaynak ve canonical varyant görünmediği için kullanıcı bunun nedenini anlayamaz.
3. **“Estimated total ~250” semantiği belirsiz:** Belirsiz peynir hesaba dahil değilse “confirmed subtotal” denmeli; dahilse belirsizlik aralığı gösterilmeli.
4. **Review ile detail aynılaşmış:** Log öncesi review’da esas görev düzeltmek ve onaylamaktır; log sonrası detail’da kaynak, zaman ve düzenleme geçmişi önemlidir.
5. **Gereksiz ayrı success ekranı:** Sık tekrarlanan logging işinde tam sayfa başarı ekranı akışı yavaşlatır.
6. **Her şey card:** Hiyerarşi border/radius ile değil spacing, type, divider ve grouped content ile kurulmalı.
7. **Makro renkleri tek başına bilgi taşıyor:** Protein/carbs/fat hem label hem değerle gösterilmeli; yalnızca mavi/turuncu/pembe renge güvenilmemeli.
8. **Clarification asset’i kanıt sanılabilir:** AI ile üretilmiş 15/30/50 g görseller gerçekten tartılmış porsiyonları temsil etmiyorsa yanlış güven verir.

### Tek source of truth kuralı

Mobil istemci hiçbir toplamı ayrı state olarak tutmamalı. Item’ların `nutrition_per_100g × grams` sonuçlarından meal total; meal’lardan daily total türetilmeli. Aynı derivation backend’de de invariant testleriyle doğrulanmalı:

- `meal.total == sum(meal.items)`
- `day.total == sum(day.meals)`
- makrolardan hesaplanan yaklaşık enerji ile katalog enerjisi arasında açıklanabilir tolerans
- miktar değişince meal ve day toplamlarının atomik güncellenmesi

## 4. Önerilen mobil bilgi mimarisi

Ana navigation yalnızca üç tab:

1. **Today** — günlük durum ve meals
2. **History** — gün/öğün geçmişi ve arama
3. **Profile** — hedefler, birimler, gizlilik, veri kaynakları

Logging ayrı bir modal flow’dur; tab değildir.

### Asıl demo akışı

`Today → Meal Composer → Analyzing → Draft Review → [gerekiyorsa Clarification sheet] → Draft Review → Log → Today + success toast`

#### A. Today

- Üstte tarih ve hedef özeti
- Calories için büyük ama abartısız sayı; yanında hedef
- Protein/carbs/fat kompakt satır
- “What did you eat?” composer giriş yüzeyi
- Günün öğünleri border-heavy card yerine list rows
- Alt sabit veya floating olmayan, thumb-reachable `Add meal`
- İlk kullanım boş durumda örnek input: “2 yumurta, yarım simit ve biraz beyaz peynir”

#### B. Meal Composer

- Default keyboard açık, multiline text field
- Tek dokunuş voice dictation
- Meal type otomatik tahmin edilir fakat değiştirilebilir
- Recent meals / repeat last meal ikinci planda
- CTA: `Analyze meal`
- Text boşsa CTA disabled; offline ise açık hata + manual logging alternatifi

#### C. Analyzing state

- Ayrı bir “AI understanding” sayfası olmak zorunda değil; composer’dan review’a shared-axis geçiş
- 3 aşamalı yalın status: “Finding foods → matching portions → checking uncertainties”
- 1.5–2 saniyeyi aşarsa skeleton item’lar ve cancel
- Sahte progress yüzdesi yok

#### D. Draft Review — ürünün kahraman ekranı

Her item satırında:

- Canonical display name
- Normalized portion: `2 adet · 100 g`
- kcal ve kompakt makro
- Durum: `Matched`, `Check type`, `Check amount`, `Not found`
- Tap ile bottom sheet edit
- Swipe-to-delete opsiyonel; görünür remove action erişilebilir olmalı

Üstte kaynak input, altta meal total. Belirsiz item varsa `Review 1 item`; yoksa `Log meal`.

Kullanıcı ham cümlesinden çıkan item ile katalog kaydı arasındaki bağ görünür olmalı: örneğin `“peynir” → Tam yağlı beyaz peynir`.

#### E. Clarification bottom sheet

Tam sayfa yerine mümkünse bottom sheet; kullanıcı meal bağlamını kaybetmez.

Belirsizlik sırası:

1. **Food identity:** “Hangi peynir?” — beyaz peynir, kaşar, labne, başka
2. **Preparation/state:** çiğ/pişmiş, yağlı/yağsız gibi nutrition etkili fark
3. **Portion:** tahmin etrafında `Less / Looks right / More` + exact entry

15/30/50 g üçlüsü yalnızca ilgili gıdada valide edilmişse kullanılmalı. Yumurta adet, ekmek dilim, süt ml/bardak, çorba kase/ml, pilav yemek kaşığı/gram gibi `portion_strategy` food’a göre değişir.

#### F. Success

Tam sayfa yok. Today’e dön, yeni meal row’u kısa bir insert animasyonuyla gelsin, hafif haptic + `Breakfast logged · Undo` toast gösterilsin. Apple, motion’ın kısa, amaçlı ve opsiyonel olmasını; sık işlemlerde gereksiz animasyondan kaçınılmasını öneriyor. [Apple HIG — Motion](https://developer.apple.com/design/human-interface-guidelines/motion)

#### G. Meal Detail/Edit

- Meal photo ancak gerçekten kullanıcıdan geldiyse göster; generic AI görseli “meal photo” gibi sunma
- Items, quantities, source ve totals
- `Edit meal`, `Delete`, `Duplicate`
- Nutrition provenance: `USDA FDC #...`, `curated recipe v3` gibi
- Model/prompt sürümü kullanıcı UI’ında gerekmez; debug panel/observability’de tutulur

## 5. Görsel tasarım sistemi

### Marka yönü

- Background: warm white / very light neutral
- Text: near-black
- Accent: chartreuse/lime; yalnızca primary action, selection ve positive progress
- Warning: amber; error: red; informational: neutral/blue
- Food photography: sıcak gün ışığı, nötr stone/white plate, gerçek doku, kontrollü gölge
- “AI estetiği” yok: mor gradient, sparkles, robot, glassmorphism, chat bubble yok

### Token önerisi

- 4 pt spacing grid; ana yatay margin 20–24
- Radius: küçük controls 10–12, sheets 24–28; her container’a radius verme
- Type: platform/system font veya tek lisanslı grotesk; 4–5 text style yeterli
- Tap targets en az platform erişilebilirlik beklentilerini karşılamalı
- Contrast yalnızca figma görünümüne göre değil automated test ile ölçülmeli
- Dynamic Type / text scaling, screen reader labels ve Reduce Motion ilk sürüm tanımına dahil

Apple HIG; hierarchy, consistency ve platform conventions kullanımını temel prensip olarak konumluyor. “Custom görünmek” sistem davranışlarını bozmak anlamına gelmemeli. [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)

### Motion planı

- Composer → review: shared axis / fade-through, 220–300 ms
- Parsed item appearance: 30–50 ms stagger; maksimum 3–4 item’den sonra stagger yok
- Portion selection: subtle scale + border; haptic
- Total update: number tween, tek sefer
- Log success: row insertion + toast
- Reduce Motion: transform yerine opacity veya anlık state

Rive/Lottie yalnızca onboarding veya boş durum için düşünülebilir. Ana akışta framework animasyonları yeterli ve daha production görünür.

## 6. Asset stratejisi

### Gerekli asset seti

İlk demo için 12–15 “hero foods” seç:

- yumurta
- beyaz peynir
- kaşar
- ekmek/dilim
- simit
- yoğurt
- süt
- pilav
- makarna
- tavuk göğsü
- çorba
- muz/elma
- kuruyemiş
- zeytinyağı/tereyağı gibi görünmeyen ama etkili yağlar için görsel yerine ölçü ikonu

Her gıda için:

- 1 thumbnail
- gerekiyorsa 3 portion reference
- aynı lens/açı/tabak/ışık/arka plan
- görselin temsil ettiği gramaj gerçek tartımla QA edilmiş
- asset manifest: `food_id`, `portion_grams`, `camera_angle`, `asset_version`, `validated_at`

AI ile asset üretilebilir ama sonradan gerçek gram referansıyla manuel doğrulanmalı. Case write-up’ında “generated, then portion-calibrated” denmeli; üretilmiş görsel bilimsel ölçüm gibi sunulmamalı.

## 7. Teknik mimari

```text
Flutter app
  ├─ Presentation (screens, motion, accessibility)
  ├─ Application (use cases/state machine)
  ├─ Domain (MealDraft, FoodMatch, Portion, Confidence)
  └─ Data (API, local cache, mock repository)
           │
           ▼
FastAPI orchestration service
  ├─ auth + request validation
  ├─ meal analysis pipeline
  ├─ clarification policy
  ├─ nutrition calculator
  ├─ idempotent meal commit
  └─ telemetry/eval logging
           │
           ▼
PostgreSQL / Supabase
  ├─ users, goals, meals, meal_items
  ├─ foods, aliases, portions, nutrients, sources
  ├─ analysis_runs, clarification_events, corrections
  └─ pgvector (semantic candidate fallback only)
```

Supabase hızlı case geliştirme için Auth, Postgres, Storage ve RLS’yi tek yerde verir. Exposed tablolarda RLS mutlaka açık olmalı ve her kullanıcı yalnızca kendi meal kayıtlarını görmelidir. [Supabase RLS rehberi](https://supabase.com/docs/guides/database/postgres/row-level-security)

AI orchestration’ı doğrudan mobil istemciden çağırma. Model ve food-provider anahtarları server secret olarak kalmalı. Edge functions kısa AI orchestration için kullanılabilir; ancak ağır veya uzun işler background worker’a taşınmalıdır. [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

### Neden vector DB ana çözüm değil?

100–500 curated food için exact alias, Turkish normalization, trigram/full-text çoğu sorguda daha açıklanabilir ve daha güvenlidir. Vector search şu durumda devreye girsin:

- alias/exact match yok
- lexical sonuç zayıf
- input regional/colloquial: `cızlama`, `gevrek`, `bir avuç çerez`
- candidate set hâlâ katalog içinden gelecek

pgvector similarity threshold mutlaka kendi eval setimizle belirlenmeli; dokümantasyon da eşiğin uygulamaya özel test edilmesini öneriyor. [Supabase vector columns](https://supabase.com/docs/guides/ai/vector-columns)

Bu, klasik “doküman RAG” değil; **catalog-grounded semantic retrieval**. README’de doğru isimle anlatmak daha güçlüdür.

## 8. Food catalog ve veri kaynakları

Önerilen source hierarchy:

1. Curated app records / validated recipes
2. Türkiye’ye özgü generic foods için lisansı doğrulanmış TürKomp kayıtları
3. Generic foods için USDA FoodData Central
4. Branded/barcode ürünler için Open Food Facts
5. Hiçbiri yoksa açıkça `unverified estimate` veya manual entry

USDA FoodData Central search ve food detail endpoint’leri sunuyor, verileri public domain/CC0 olarak yayımlıyor ve varsayılan API limitini 1.000 istek/saat/IP olarak belirtiyor. API anahtarı istemciye konmamalı. [USDA FDC API Guide](https://fdc.nal.usda.gov/api-guide/)

Open Food Facts packaged products için yararlı ama kendi dokümantasyonu verinin kullanıcılar tarafından gönüllü girildiğini ve doğruluk/tamlık garantisi olmadığını açıkça söylüyor. Ayrıca search-as-you-type için düşük rate limits var; mobil UI doğrudan canlı arama yapmamalı, backend cache/local index kullanmalı. [Open Food Facts API](https://openfoodfacts.github.io/openfoodfacts-server/api/)

TürKomp Türkiye’ye özgü güçlü bir referans; 645 food ve yaklaşık 63–65 bin bileşen/enerji değeri bildiriyor. Ancak site ticari kullanımın ücretli olduğunu ve içeriğin izinsiz kopyalanamayacağını söylüyor. Bu nedenle veri scraping yapma; case/noncommercial kullanımını ve lisansı yazılı biçimde doğrula. [TürKomp](https://turkomp.tarimorman.gov.tr/main)

Her `food` kaydı provenance taşımalı:

- `source_name`
- `source_food_id`
- `source_version/retrieved_at`
- `nutrient_basis` (`per_100g`, `per_serving`)
- `data_quality` (`lab`, `label`, `community`, `estimated`)
- `license`

## 9. AI pipeline — derin gidilecek yol

### Aşama 1 — Normalize

- Turkish lower/casefold; noktalama
- `yarım`, `çeyrek`, `bir buçuk`, `biraz`, `avuç`, `dilim`, `adet`
- `gr/gr./gram`, `ml`, `bardak`, `kaşık`
- cooked/raw ve preparation keyword’leri
- Ham input hiçbir zaman kaybolmaz

### Aşama 2 — Structured extraction

LLM yalnızca şunları çıkarsın:

- mention span
- surface name
- explicit quantity/value/unit
- modifiers: cooked, fried, full-fat vb.
- ambiguity flags
- unresolved text

LLM’den calories/macros isteme. OpenAI Structured Outputs, cevabın tanımlı JSON Schema’ya uymasını sağlar ve invalid enum/missing field riskini azaltır. Yine de semantik doğruluk için eval gerekir. [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs)

### Aşama 3 — Candidate generation

Her extracted mention için:

1. exact alias
2. normalized alias
3. Postgres trigram/full-text top-k
4. vector fallback top-k

LLM’ye tüm katalog verilmez; yalnızca top candidates ve source evidence verilir.

### Aşama 4 — Constrained match

Model ya adaylardan bir `food_id` seçer ya `NO_MATCH` döner. Katalog dışı ID üretmesine şema seviyesinde izin verilmez. Sonra server seçilen kaydın gerçekten candidate listesinde olduğunu tekrar doğrular.

### Aşama 5 — Portion resolver

`portion_strategy` örnekleri:

- count: egg
- slice: bread/cheese
- mass: meat/cheese
- volume: milk/soup
- household: rice/nuts
- fraction_of_whole: simit, pizza

Explicit amount varsa deterministik dönüşüm. Vague amount varsa catalog prior + context ile estimate range: örneğin `30 g, plausible 15–50 g`.

### Aşama 6 — Clarification policy

Modelin yazdığı `confidence: 0.93` kalibre edilmiş güven değildir. Karar, ölçülebilir sinyallerden üretilecek:

- candidate top-1 score
- top-1/top-2 margin
- exact alias olup olmaması
- explicit quantity varlığı
- portion range genişliği
- preparation ambiguity
- unknown token/span oranı
- adaylar arasındaki nutrition farkı

Clarification yalnızca beklenen etkisi anlamlıysa göster:

- identity adayları arasında ör. >80 kcal veya >8 g protein farkı
- portion plausible range’i meal calories’i ör. >15% değiştiriyorsa
- görünmeyen yağ/sos mixed dish’te sonucu ciddi değiştiriyorsa

Bu eşikler ilk hipotezdir; eval seti ve kullanıcı friction metriğiyle ayarlanmalıdır.

### Aşama 7 — Nutrition calculation

```text
nutrient_amount = nutrient_per_100g × resolved_grams / 100
```

Tüm yuvarlama en son presentation katmanında yapılır. Veri tabanı hassas decimal değer tutar. Meal/day totals yalnız item results’tan türetilir.

### Aşama 8 — Human correction feedback

Şunları event olarak kaydet:

- system candidate → selected candidate
- estimated grams → confirmed grams
- clarification shown/skipped
- time-to-log
- item deleted/added
- reason code: wrong food, wrong portion, missing ingredient, preparation, catalog miss

Bu kayıtlar prompt’a otomatik geri beslenmez. Önce kişisel veri temizliği, review ve eval dataset versioning yapılır.

## 10. API sözleşmesi ve state machine

Temel endpoint’ler:

- `POST /v1/meal-analyses` — draft oluşturur
- `PATCH /v1/meal-analyses/{id}/items/{itemId}` — clarification/edit
- `POST /v1/meals` — draft’ı idempotent biçimde commit eder
- `GET /v1/days/{date}`
- `GET/PATCH/DELETE /v1/meals/{id}`
- `GET /v1/foods/search?q=` — manual fallback

`MealDraft.status`:

`analyzing | needs_review | ready | committed | failed | expired`

Her analiz response’u şunları taşımalı:

- `analysis_id`
- `input_text`
- `items[]`
- `clarifications[]`
- `confirmed_subtotal`
- `estimated_range`
- `model_version`, `prompt_version`, `catalog_version` (debug metadata)
- `trace_id`

## 11. Reliability ve caching

### Idempotency

- `POST /meals` için client-generated `Idempotency-Key`
- Aynı user + key aynı response’u döndürür
- DB unique constraint; yalnız uygulama koduna güvenme
- Analysis draft’tan commit transaction içinde yapılır
- Retry yalnız network/429/5xx; validation/4xx retry edilmez
- Exponential backoff + jitter; maksimum deneme sınırı

### Cache katmanları

1. Mobil: Today/History stale-while-revalidate; queued retry yalnız güvenli operasyonlarda
2. Backend: normalized query → candidate IDs kısa TTL
3. Food records: source/version ile uzun TTL
4. Embeddings: `normalized_alias + embedding_model_version` key’iyle kalıcı
5. LLM result cache: yalnız aynı normalized input + locale + catalog/prompt/model version için; kullanıcıya özel context yoksa

OpenAI prompt caching exact prefix eşleşmesiyle çalışır; static instructions/schema/examples başta, user input sonda tutulmalı ve `cached_tokens` izlenmelidir. Bu, business-result cache’den farklıdır. [OpenAI Prompt Caching](https://developers.openai.com/api/docs/guides/prompt-caching)

Cache invalidation anahtarında en az `catalog_version`, `prompt_version`, `model_snapshot` ve `locale` olmalı.

## 12. Accuracy evaluation planı

### Gold dataset

İlk sürüm: 150–250 Türkçe meal utterance.

Strata:

- açık miktar: `2 yumurta, 30 g peynir`
- vague portion: `biraz peynir`
- colloquial/regional: `yarım gevrek`
- compound dishes: `bir tabak tavuklu pilav`
- preparation: `yağda iki yumurta`
- negation/correction: `peynir değil lor`
- brand/product
- catalog miss
- typo/ASR transcript
- adversarial: food olmayan metin, prompt injection benzeri cümle

Her örnekte gold:

- spans
- canonical food IDs
- portion value/unit/grams veya acceptable range
- nutrition totals
- clarification expected + reason

### Metrikler

- Food extraction micro/macro F1
- Canonical match top-1 accuracy ve top-k recall
- No-match precision/recall
- Portion MAE ve MAPE (gram bazında; zero-safe raporlama)
- Calories/protein/carbs/fat MAE + median absolute percentage error
- Hallucinated item rate
- Missing item rate
- Clarification precision: sorulanların ne kadarı gerçekten gerekliydi?
- Clarification recall: kritik belirsizliklerin ne kadarı yakalandı?
- Average clarifications per meal
- Correction rate ve time-to-log
- p50/p95 latency, cost/analysis

Tek aggregate accuracy verme. Food family, ambiguity class ve input style bazında breakdown göster. OpenAI’nin eval rehberi de görevi tanımla → test inputs ile çalıştır → sonucu analiz edip iterate et döngüsünü öneriyor. [OpenAI Evals](https://developers.openai.com/api/docs/guides/evals)

### Error taxonomy

- E1 extraction
- E2 food identity
- E3 preparation/state
- E4 portion/unit conversion
- E5 hidden ingredient/oil
- E6 database/source quality
- E7 arithmetic/rounding
- E8 clarification policy
- E9 UI/user correction failure

README ve Loom’da en az üç gerçek failure case göster. Mükemmelmiş gibi sunmak yerine sistemin failure’ı nasıl görünür ve düzeltilebilir yaptığını göstermek daha güçlüdür.

## 13. Observability

Her meal analysis tek trace:

- `normalize`
- `llm.extract`
- `retrieve.lexical`
- `retrieve.vector`
- `rerank/match`
- `portion.resolve`
- `clarification.decide`
- `nutrition.calculate`
- `draft.persist`

Log alanları:

- trace/request/analysis ID
- user için raw ID değil hashed/pseudonymous ID
- stage duration/status/retry count
- token counts/cache hits/model/prompt/catalog versions
- candidate count/top score/margin
- clarification reason
- error code

Raw meal text ve model payload’larını varsayılan production log’a yazma; debug sampling ayrı, redacted ve kısa retention’lı olsun.

Dashboard:

- analysis success rate
- p50/p95 latency
- catalog miss rate
- clarification rate
- correction rate
- nutrition error (offline eval)
- token cost per successful log
- cache hit rate

## 14. Test stratejisi

### Mobil

- Domain unit tests: total derivation, rounding, portion edit
- Widget tests: empty/loading/error/clarification/review
- Golden tests: ana ekranlar, text scaling, dark mode yalnız yapılacaksa
- Integration: input → review → clarify → commit → Today
- Accessibility semantics testleri

### Backend

- Unit: normalization, unit conversions, nutrition math, clarification rules
- Contract/schema tests
- Repository integration tests with local Postgres
- Idempotency/concurrency tests
- Provider failure/timeout/retry tests
- Snapshot/regression evals
- Property tests: totals never negative/NaN; aggregation invariants

### CI gates

- format/lint/typecheck
- unit/integration tests
- mobile golden smoke
- DB migrations on ephemeral database
- eval smoke subset (10–20 deterministic cases) her PR’da
- full eval nightly/manual; model API maliyeti nedeniyle her commit’te değil
- secrets scanning ve dependency audit
- build artifacts: Android APK/AAB, iOS simulator build/TestFlight mümkünse

## 15. Security ve privacy

Başlıca riskler:

- Meal text/photo sağlıkla ilişkili hassas kişisel davranış verisidir
- API key’in mobil binary’de sızması
- Başka kullanıcının meal kayıtlarına erişim
- Raw prompts/outputs’un log ve analytics’e sızması
- Prompt injection ile katalog dışı davranış
- Third-party model/data provider retention
- Account deletion sonrası derived traces/backups’ın kalması
- Kullanıcının nutrition sonucunu tıbbi tavsiye sanması

Kontroller:

- server-side model/provider access
- Supabase RLS + policy tests
- least privilege service roles
- encryption in transit/at rest
- redacted logs, kısa retention, deletion workflow
- consent olmadan correction data’yı training set yapmama
- rate limiting ve abuse controls
- schema-constrained outputs + candidate allowlist
- açık “estimate” dili; teşhis/tedavi iddiası yok
- privacy policy’de data flow ve provider listesi

## 16. Yedi günlük uygulanabilir plan

### Gün 1 — Product contract + design foundation

- Bu rapordan scope freeze
- Domain models ve OpenAPI schema
- Flutter shell, design tokens, navigation
- Today + Composer yüksek kaliteli implementation
- 12 hero food catalog seed

### Gün 2 — Review/clarification UX

- Draft Review
- Item edit/food type/portion sheets
- Loading/error/offline states
- Motion + accessibility pass
- Mock repository ile bütün akış

### Gün 3 — Backend/data

- Supabase schema, migrations, RLS
- FastAPI endpoints
- nutrition calculator ve invariants
- idempotent commit
- USDA-backed curated seed + provenance

### Gün 4 — Hybrid AI pipeline

- structured extraction
- alias/trigram retrieval
- pgvector fallback
- constrained match
- portion resolver + clarification policy
- model/provider abstraction

### Gün 5 — Evals/reliability/observability

- 150+ test case’in en az çekirdek 60–100 tanesi
- metrics script/report
- retries/timeouts/cache
- trace/log dashboard veya export
- failure injection tests

### Gün 6 — Polish + CI/CD

- golden/integration tests
- performance ve accessibility QA
- GitHub Actions
- deploy backend + distributable mobile build
- demo seed/account

### Gün 7 — Communication

- README architecture, trade-offs, eval table, known failures
- Loom 5–10 dakika
- email summary
- son cihaz testi ve temiz repo

### Scope kill order

Zaman daralırsa şu sırayla çıkar:

1. Photo recognition
2. Barcode
3. Full auth onboarding/social login
4. Web app
5. Dark mode
6. Advanced analytics

Şunları çıkarma:

- editable structured result
- ambiguity clarification
- deterministic nutrition
- gold eval set + metrics
- idempotency/error handling
- kaynak/provenance
- çalışan mobil demo

## 17. Case sunumunda “wow” anı

Loom’daki ana demo cümlesi:

> “İki yumurta, biraz peynir ve yarım simit yedim.”

Akış:

1. Sistem yumurta ve simidi otomatik çözer.
2. `peynir` type belirsizliği nutrition’ı etkilediği için önce peynir türünü sorar.
3. Miktar aralığı sonucu etkiliyorsa tek dokunuşla portion doğrulatır.
4. Review ekranında input → canonical mapping ve source görünür.
5. Kullanıcı miktarı düzenleyince bütün totals aynı anda güncellenir.
6. Log iki kez tetiklense de idempotency nedeniyle tek meal oluşur.
7. Ardından eval dashboard’da bu sınıfın önce/sonra metriği gösterilir.

Bu akış; product thinking, AI accuracy, architecture, reliability, observability ve communication kriterlerinin hepsini tek hikâyede gösterir.

## 18. En önemli trade-off ve sonraki üç accuracy iyileştirmesi

### En büyük trade-off

Photo-first “sihir” yerine text-first, katalog-grounded doğruluk seçildi. Daha az gösterişli görünür ama yedi günde ölçülebilir, açıklanabilir ve güvenilir bir sonuç üretir. Photo input mimaride bir sonraki adapter’dır.

### Top 3 next accuracy improvements

1. Kullanıcı correction’larından review edilmiş active-learning dataset; error-class bazlı prompt/retrieval iteration
2. Türkiye’ye özgü yemek ve household portion atlası; gerçek tartımla valide edilmiş portion assets
3. Mixed dishes için recipe decomposition + hidden oil/sauce clarification; restaurant/menu source retrieval

## 19. Başlamadan önce verilecek tek teknik karar

Önerilen default:

- Mobile: Flutter + Riverpod + go_router + freezed/json_serializable
- Backend: Python FastAPI + Pydantic + SQLAlchemy/Alembic
- Data/Auth/Storage: Supabase Postgres
- Vector: pgvector, yalnız fallback
- AI: OpenAI Responses API, Structured Outputs; model seçimi eval ile
- Observability: OpenTelemetry + Sentry veya düşük kurulumlu eşdeğer
- CI/CD: GitHub Actions + Supabase deploy + TestFlight/Firebase App Distribution
- Web later: Next.js, aynı OpenAPI client

Bu karardan sonra ilk implementasyon hedefi backend bekleyen statik ekranlar değil; `MockMealRepository` üzerinden tamamen çalışan mobil vertical slice olmalıdır. Daha sonra repository gerçek API’ye geçirilir. Böylece mobil polish ile AI backend paralel geliştirilebilir ve demo hiçbir aşamada kırık kalmaz.

