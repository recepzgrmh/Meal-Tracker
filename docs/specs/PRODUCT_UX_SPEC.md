# Meal Clarity — Product & UX Specification

Status: implementation-ready draft  
Date: 17 August 2026  
Owner: Mobile / Product  
Scope: onboarding, authentication, meal logging, offline states, and mobile UX

## 1. Product statement

Meal Clarity turns messy natural-language meal descriptions into editable,
catalog-grounded food and portion records. It automatically resolves high-
confidence details and asks the user only about ambiguity that materially
changes nutrition.

The product must feel like a calm nutrition tracker, not a chatbot or an “AI
demo.” AI is an implementation detail. The visible product promise is:

> Say what you ate naturally. Check only what matters. Log with confidence.

## 2. Success definition

The MVP succeeds when a first-time user can:

1. Understand the value in under 20 seconds.
2. Create an account without choosing a password.
3. Enter `2 yumurta, biraz beyaz peynir ve yarım simit`.
4. See the input decomposed into canonical foods.
5. Clarify only the uncertain cheese amount.
6. Log the meal once, even if a retry or double tap occurs.
7. Reopen the app offline and still see the last known day.
8. Understand whether an unsynced change is queued, failed, or complete.

Primary product metrics:

- first-meal completion rate
- median time from composer open to committed meal
- average clarification count per meal
- user correction rate after AI review
- sync success rate within 60 seconds
- day-one return rate (not a case-study gate, but instrumented)

Accuracy metrics are specified separately in `AI_ACCURACY_SPEC.md`.

## 3. MVP boundaries

### In scope

- iOS and Android Flutter app
- three-step onboarding
- passwordless email OTP authentication
- session restore and sign-out
- text meal input and OS dictation entry point
- structured AI result and human-in-the-loop clarification
- meal create/read/edit/delete
- Today and basic History
- private meal-photo storage contract, upload UI behind a feature flag
- local read cache and mutation outbox
- visible sync state and retry
- accessibility and reduced-motion behavior

### Explicitly not in the first production slice

- automatic photo recognition
- barcode scanning
- social feed or gamification
- automatic medical or weight-loss prescriptions
- HealthKit / Health Connect synchronization
- complex recipe builder
- restaurant menu ingestion
- dark mode unless the light theme is complete and tested

The architecture leaves adapters for photo, barcode, and web, but the primary
case-study path remains text-first.

## 4. Information architecture

Authenticated shell:

```text
Today
├── Add meal (modal flow)
├── Meal detail / edit
└── Date picker

History
├── Day list
├── Search (stretch)
└── Meal detail / edit

Profile
├── Goal and targets
├── Units and locale
├── Data & privacy
└── Sign out / delete account
```

Meal logging is a modal task, not a navigation tab:

```text
Composer → Analyze → Draft review → Clarification(s) → Commit → Today
```

## 5. App bootstrap state machine

```text
booting
├── configuration_invalid → blocking developer-safe error
├── no_session
│   ├── onboarding_incomplete → onboarding
│   └── onboarding_complete → auth
└── authenticated
    ├── profile_incomplete → minimal profile completion
    └── ready → app shell
```

Rules:

- Never briefly render Today before redirecting to auth.
- Restore the last local day before the first remote refresh completes.
- On expired auth, preserve the local cache and queued mutations but require
  reauthentication before remote access.
- A different authenticated user must never see the prior user's cached rows.
  Local data is partitioned by `user_id` and cleared or cryptographically
  isolated on account switch.

## 6. Onboarding specification

Apple recommends onboarding that is fast, optional where possible, and teaches
through interaction. Android recommends collecting only critical information,
showing value before registration, and requesting permissions just in time.
Sources: [Apple Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding),
[Android Authentication & Onboarding](https://developer.android.com/design/ui/mobile/guides/patterns/onboarding).

### OB-01 — Welcome / value

Purpose: establish the outcome, not list features.

Content:

- wordmark: `Meal Clarity`
- headline: `Yemeğini anlat. Gerisini birlikte netleştirelim.`
- body: `Doğal şekilde yaz; yalnızca sonucu gerçekten etkileyen noktaları kontrol et.`
- primary CTA: `Nasıl çalıştığını gör`
- secondary action: `Zaten hesabım var`
- progress: `1 / 3`, accessible label `3 adımdan 1.si`

Visual:

- one premium breakfast photograph or code-native food composition
- no robot, sparkles, chat bubbles, purple gradient, or nutrition claims
- asset can be omitted for the first implementation; layout must not depend on
  a downloaded image

Motion:

- food elements enter with a 220 ms fade/translate
- no infinite animation
- Reduce Motion: static first frame

Acceptance criteria:

- primary CTA visible without scroll at 320×568 logical pixels
- text remains usable at 200% text scale
- user can go directly to sign in

### OB-02 — Interactive accuracy demo

Purpose: demonstrate the differentiator instead of explaining it.

Initial state:

```text
“2 yumurta, biraz peynir ve yarım simit”
```

After tapping `Örneği analiz et`, a deterministic local animation creates:

- `2 Yumurta · 100 g` — matched
- `Simit · ½ adet` — matched
- `Beyaz peynir · miktarı kontrol et` — needs review

Then a compact inline choice appears:

```text
Az · 15 g | Tahmin · 30 g | Fazla · 50 g
```

This screen is a local scripted demonstration and must not call the AI API.

Copy:

- headline: `Emin olduğumuzu çözeriz.`
- body: `Belirsizliği saklamayız. Yalnızca önemli olduğunda sana sorarız.`
- CTA after interaction: `Anladım, devam et`
- skip: `Geç`

Acceptance criteria:

- screen reader announces item status and selected portion
- selected state is not communicated by color alone
- scripted demo takes at most 1.2 seconds before it becomes interactive
- no generated photograph is represented as a calibrated gram reference

### OB-03 — Minimal personalization

Purpose: configure presentation without pretending to prescribe nutrition.

Fields:

- primary intention, single select:
  - `Ne yediğimi daha iyi anlamak`
  - `Proteinimi takip etmek`
  - `Kalori hedefimi takip etmek`
- energy target:
  - optional numeric kcal field, shown only for calorie tracking
  - default is visually marked as a demo suggestion, not medical advice
- units: metric fixed for MVP (`g`, `ml`, `kcal`)

Copy:

- headline: `Sana uygun bir başlangıç yapalım.`
- disclosure: `Meal Clarity tahmin sunar; tıbbi tavsiye vermez.`
- CTA: `Hesabımı oluştur`

Data behavior:

- store draft onboarding choices locally before auth
- write them to `profiles` only after a session exists
- retain choices if OTP entry is dismissed

Acceptance criteria:

- no age, sex, weight, or health-data request in the MVP
- optional target can be skipped
- invalid target has an inline, actionable error

### Onboarding completion

- `onboarding_version` stored locally and remotely
- completion occurs after authentication and profile write succeed
- users who update from an older version are not forced through the full flow;
  new concepts use contextual coachmarks
- a `Restart introduction` action exists under Profile → Help

## 7. Authentication specification

### Decision

Primary MVP authentication is email OTP. Sign in with Apple is a Sprint 5
stretch item gated on Apple Developer configuration. Google sign-in is deferred.

Why email OTP:

- one unified sign-in/sign-up flow
- no password rules or reset flow
- works on iOS and Android
- avoids Apple provider configuration blocking the critical path

Supabase supports passwordless email OTP and the Flutter client verifies codes
with `verifyOTP`. Built-in email sending is heavily rate-limited, so custom SMTP
is required before external beta distribution. Sources:
[Passwordless email](https://supabase.com/docs/guides/auth/auth-email-passwordless?language=dart&queryGroups=language),
[Auth rate limits](https://supabase.com/docs/guides/auth/rate-limits).

### AUTH-01 — Email entry

- headline: `İlerlemeni cihazların arasında koru.`
- field: email with autofill and correct keyboard
- CTA: `Kod gönder`
- alternative: `Apple ile devam et` only when configured
- legal footer: Terms and Privacy links
- returning and new users use the same form

Behavior:

- normalize whitespace, but do not silently alter the email address
- disable duplicate submission while pending
- map provider errors to stable product messages
- rate-limit UI includes a visible resend countdown

### AUTH-02 — OTP verification

- six-digit input with paste/autofill support
- masked email shown with `E-postayı değiştir`
- resend becomes available after the server-configured cooldown
- successful verification continues onboarding profile commit
- expired/invalid code preserves the email and explains the next action

### Session behavior

- app listens to auth-state changes through one `AuthRepository`
- route guards derive only from auth and onboarding state
- token refresh failures do not delete local user data immediately
- sign-out stops sync, cancels subscriptions, then removes that user's local
  cache according to the selected privacy policy
- account deletion is a server-side privileged operation, never a direct client
  deletion of `auth.users`

### Auth privacy and abuse controls

- publishable key may ship in the app; secret/service-role keys never do
- custom SMTP before external testers
- CAPTCHA/Turnstile assessment before enabling anonymous sign-in
- no anonymous sign-in in MVP because cleanup and account linking add scope and
  abuse surface; Supabase recommends CAPTCHA for anonymous accounts and does not
  currently clean them up automatically
- auth errors are logged by code/category, never OTP or email contents

## 8. Meal logging UX states

### Composer

- multiline natural-language input
- primary CTA disabled for empty/whitespace-only input
- max input length: 1,000 visible characters; backend hard limit remains 4,000
- voice button uses OS dictation / speech adapter only after contextual
  microphone permission
- offline state explains that AI analysis needs a connection
- cached recent meals remain available offline as manual repeat actions

### Analyzing

- statuses: `Yiyecekleri ayırıyoruz` → `Katalogla eşleştiriyoruz` →
  `Belirsizlikleri kontrol ediyoruz`
- no fake percentage
- cancel after 1 second
- timeout has `Tekrar dene` and `Elle ekle` actions

### Draft review

Each item shows:

- canonical name
- source span → canonical mapping
- portion and grams
- calories plus compact macros
- status: matched / check identity / check amount / not found
- edit and remove actions accessible without swipe

CTA:

- unresolved material ambiguity: `1 noktayı kontrol et`
- ready: `Öğünü kaydet`

### Clarification

Priority:

1. food identity
2. preparation/state
3. portion

Use a bottom sheet when one decision is required. Use a full screen only for
search/manual selection. Portion options must be food-specific and offer exact
entry.

### Commit success

- return to Today immediately
- insert row animation and light haptic
- snackbar: `Kahvaltı kaydedildi · Geri al`
- no full-screen success page
- queued offline manual edits use `Cihazda kaydedildi · Senkronize edilecek`

## 9. Offline and sync UX

The UI has four explicit sync states:

| State | User-facing behavior |
|---|---|
| `synced` | no badge |
| `pending` | subtle clock and `Senkronize ediliyor` |
| `offline` | persistent compact banner; cached data remains usable |
| `failed` | warning icon with `Tekrar dene` and error details |

Rules:

- connectivity type is only a hint; a successful request determines online
  health
- AI analysis is online-only in MVP
- already-created meals can be edited/deleted offline through the outbox
- manual meal creation offline is allowed if all nutrition fields are local;
  AI meal creation waits for connectivity
- never show a remote success state before the server acknowledges the
  idempotent mutation
- conflicts are rare because user-owned meals have one writer; when they occur,
  server `updated_at` wins unless the local operation is still pending
- failed validation never retries automatically

## 10. Permissions

Do not request microphone, camera, photo library, notifications, or health data
at app launch. Apple and Android both recommend contextual permission requests.
Sources: [Apple Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy),
[Android onboarding](https://developer.android.com/design/ui/mobile/guides/patterns/onboarding).

- Microphone: prime and request when voice input is first tapped.
- Camera/photos: prime and request when photo attachment is first tapped.
- Notifications: not required for MVP.
- HealthKit/Health Connect: excluded.

Denial behavior must leave a usable text-first path and link to system settings
only after a permission is permanently denied.

## 11. Accessibility and internationalization

- minimum 44×44 iOS / 48×48 Android effective hit area
- support 200% text scaling without clipping critical actions
- every macro value includes a text label; color is supplementary
- semantic announcements for analysis completion and sync errors
- focus order follows visual order
- reduced motion removes transforms and number tweens
- Turkish first, but no copy embedded inside images
- domain stores grams and UTC timestamps; locale formats values at presentation
- RTL is not an MVP language, but layout must avoid hardcoded left/right where
  Flutter directional APIs exist

## 12. Product analytics events

No raw meal text, email, photo path, or canonical food name is sent to product
analytics.

Events:

- `onboarding_started`
- `onboarding_demo_completed`
- `onboarding_completed`
- `auth_otp_requested`
- `auth_completed`
- `meal_analysis_started`
- `meal_analysis_completed`
- `clarification_shown` with reason class
- `clarification_resolved`
- `meal_commit_completed`
- `meal_commit_failed` with stable error code
- `sync_queue_depth_changed`
- `meal_correction_submitted` with error taxonomy only

Every event includes app version, platform, locale, anonymous installation ID,
and trace ID where relevant. User IDs are hashed/pseudonymous outside Supabase.

## 13. Definition of done — product slice

- all screen states have loading, empty, error, offline, and retry behavior
- onboarding can be resumed after process death
- OTP flow works on physical iOS and Android devices with production redirect
  configuration
- no service key or model key appears in the mobile bundle
- first meal flow passes unit, widget, golden, accessibility, and device
  integration tests
- queued edit survives app restart and syncs exactly once
- account switch cannot expose the previous account's cached data
- README and Loom show one happy path and at least three failure modes

