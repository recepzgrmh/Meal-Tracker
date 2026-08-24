# Text understanding: why simple sentences failed, and what changed

## Symptom

Two inputs that should have been trivial did not work.

```
"2 yumurta yedim kanka"
  → yumurta matched correctly
  → "yedim" and "kanka" also became foods, shown as unmatched items
    with a "add from catalog" affordance

"kaşarlı tavuklu makarna"
  → whole request failed
  → "Öğünü analiz edemedik. Bağlantını kontrol edip tekrar dene."
```

The first is wrong output. The second is wrong output *and* a misleading error:
nothing was wrong with the user's connection.

## Root cause

The pipeline treated "which words in this sentence are foods" as a
deterministic string problem. Free text went straight into an alias matcher,
and **every token the matcher did not consume became a food candidate**
(`analyze-meal/deterministic.ts`, `extractUnmatchedTokens`). The only defence
was `ignoredTokens`, a hand-written set of roughly 45 measurement words and
numerals — `adet`, `tane`, `kase`, `bir`, `iki`, `gram`.

That set is a denylist, and a denylist cannot work here:

- Turkish is agglutinative, so the same verb appears as `yedim`, `yedik`,
  `yemiştim`, `yiyeceğim`.
- The input is conversational, so it carries greetings and slang (`kanka`,
  `abi`, `ya`, `işte`), time references (`sabah`, `kahvaltıda`), and pronouns.
- The set of non-food words in Turkish is open. Every addition to the denylist
  buys one sentence and leaves the next one broken.

So the architecture had the two halves of the problem assigned to the wrong
tools:

| Sub-problem | Nature | Right tool | Was using |
| --- | --- | --- | --- |
| Understanding the sentence (which food, how much) | Language | Language model | Regex + denylist |
| Assigning nutrition (kcal, macros) | Data | Catalog | Catalog |

Three further defects compounded it.

**Leftovers were searched as one blended query.** `analyze-meal/index.ts` joined
every unmatched token into a single string — `"yedim kanka"`, or for a real
two-food sentence, `"ayran pilav"` — and ran one retrieval against it. Neither
retrieval nor the allow-listed selector was designed for a query that describes
two different foods at once.

**The vector floor was too low to reject anything.** `filterGroundedRows`
accepted vector-only candidates at cosine similarity `0.35`. A vector index
always returns its *k* nearest neighbours no matter how far away they are, and
unrelated Turkish words routinely score in the 0.3–0.5 band. `kanka` cleared
that bar, so a non-food token reached a paid selection call with candidates
attached.

**One error class covered three unrelated failures.** `groundUnmatchedText`
wrapped its whole body in a single `catch` and rethrew everything as
`GroundingUnavailableError` → `PROVIDER_UNAVAILABLE` → 503. A Postgres RPC
error, a synchronous embedding backfill timing out over a 60k catalog, and an
actual OpenAI outage were indistinguishable. On the client, `INTERNAL_ERROR`
and `NETWORK_UNAVAILABLE` both mapped to `MealAnalysisFailureKind.unavailable`,
whose message tells the user to check their connection. That is how a
server-side fault on `kaşarlı tavuklu makarna` was reported as a network
problem — and it also meant a single retrieval hiccup skipped the estimate
fallback that would have rescued the request.

## What changed

### 1. A language model reads the sentence; the catalog still owns every number

New `analyze-meal/text-extraction.ts`. It turns one sentence into structured
mentions and nothing else:

```json
{ "foods": [{ "name": "yumurta", "quantity": 2, "unit": "adet", "components": [] }] }
```

The critical property: **the output schema has no nutrition fields at all.**
The model cannot return a calorie or a macro because there is nowhere to put
one. Grams, kcal and macros still come only from catalog rows, re-read inside
Postgres at commit time. The "nutrition is never invented by the model" rule is
now enforced by the schema rather than by convention, so moving understanding
onto the model did not weaken it.

The prompt is explicit that verbs, greetings, slang, pronouns and time
references are never foods, and that an amount is reported only when the user
actually stated one.

### 2. Extracted names are re-rendered and pushed back through the same matcher

`renderExtractedFood` turns `{name: "yumurta", quantity: 2, unit: "adet"}` back
into the clean phrase `"2 adet yumurta"`, which then goes through the existing
`analyzeDeterministically`. Portion resolution, household units, inflection
handling and confidence scoring stay in exactly one place instead of being
reimplemented on the model path.

The deterministic matcher runs *first* and, when it already explains the whole
sentence, no model call happens at all. That keeps the common case free and
fast, and it is why the 60-case deterministic regression suite is unaffected.

### 3. Composite dishes are decomposed into catalog-matchable components

`kaşarlı tavuklu makarna` will never be one catalog row. When the model judges a
dish to be a combination, it also returns components:

```json
{ "name": "kaşarlı tavuklu makarna",
  "components": [
    {"name": "makarna", "grams": 100},
    {"name": "tavuk göğsü", "grams": 80},
    {"name": "kaşar peyniri", "grams": 30}
  ]}
```

Each component is matched against the catalog independently, so an unbounded
space of described dishes resolves to grounded rows without any nutrition being
invented. A second catalog load is scoped to the extracted names, because the
first load was scoped to the raw sentence and would not contain aliases for
`tavuk göğsü`.

The amount travels in the match phrase (`"80 g tavuk göğsü"`) but never in the
retrieval query or the unmatched-item label, where it only adds noise.

### 4. One search per food

`groundUnmatchedItems` replaces the joined query. Each unmatched food gets its
own retrieval and its own selection, and ids already claimed by an earlier food
are excluded from later candidate sets so one row cannot be selected twice.
Token counts, attempts and cache flags are merged for telemetry.

### 5. The vector floor was raised

`MIN_SEMANTIC_SIMILARITY` is now `0.62`, up from `0.35`. Rows with lexical
evidence are still accepted on that evidence; vector-only rows now need a
genuinely close neighbour. A regression case at `0.45` — accepted before,
rejected now — locks the change.

### 6. Retrieval failures and provider failures are separated

`GroundingUnavailableError` carries a `kind`:

- `'provider'` — the model provider failed → `PROVIDER_UNAVAILABLE`, 503.
  The estimate fallback is still skipped here, because the estimator calls the
  same provider and would only add latency before the same 503.
- `'retrieval'` — our Postgres, embedding or RPC side failed →
  `INTERNAL_ERROR`, 500, logged at `error`. The estimate fallback **is** allowed
  to run, because the provider is healthy and a labelled estimate beats failing
  the whole meal.

On the client, `MealAnalysisFailureKind.serverError` is new and separates our
faults from transport faults. `INTERNAL_ERROR` maps to it and gets an honest
message; "check your connection" is now reserved for `NETWORK_UNAVAILABLE`,
`FUNCTION_UNAVAILABLE` and `PROVIDER_UNAVAILABLE`. `PROVIDER_UNAVAILABLE` was
previously unmapped and fell through to `unknown`.

### 7. The text path now answers to the cost budget

Text-only analysis previously bypassed `enforceAnalysisBudget` entirely, which
was already listed as a known issue. It now spends provider tokens, so it is
budgeted like the photo path, and extraction tokens are counted in
`provider_input_tokens`, `provider_output_tokens`, `provider_attempts` and
`estimated_cost_micros`. Without that, every text analysis would have
under-reported its cost.

### 8. The portion question is asked, not offered

Portion size is the dominant error source in dietary self-report, not food
identification. The
[VLM comparison](https://www.sciencedirect.com/science/article/pii/S266592712600105X)
found ingredient information barely moves calorie error while mass-estimation
accuracy predicts it directly, and portion error is long-established as a
leading source in
[dietary assessment](https://www.ncbi.nlm.nih.gov/books/NBK217524/). The bias is
worst exactly where this app is weakest: amorphous foods like pasta and rice
(one controlled-feeding study measured pasta at **+156%**), against single-unit
foods like eggs which are reported reliably.

Two things followed from that.

**Real catalog portions now reach the grounded path.** Retrieval only carries
`default_grams` / `default_portion_label`, so a grounded item arrived with one
portion option and the sheet fell through to synthesising small/regular/large as
×0.5/×1/×1.5 around the model's own gram guess. When the anchor is wrong the
whole range is wrong, and the flat-slope effect means the anchor is low exactly
where portions are large. `loadPortionsForFoods` now fetches every catalog
portion for the selected food ids in one query after selection, so the sheet
offers measured household portions — the FNDDS gram weights the import
deliberately preserved.

**The clarification queue runs before the review screen.** These sheets already
existed but only opened when the user thought to tap a flagged row, so the most
consequential number in the meal sat at a default nobody was prompted to check.
`_runClarificationQueue` walks the open questions one sheet at a time after
analysis. Dismissing a sheet skips that item — it walks the user through the
questions rather than trapping them behind one.

It is already well targeted, and deliberately so: the deterministic path sets
`needsClarification` from `portion.inferred`, so an explicitly stated amount
("2 yumurta") is `matched` and never asked about. Grounded and estimated items
always ask, because their grams are always a model guess.

## Degradation behaviour

Extraction failure is not request failure. If the provider times out, refuses,
or `OPENAI_API_KEY` is unset, `resolveTextAnalysis` returns the deterministic
result and the request continues. A partially understood meal beats an error
screen. A budget rejection is the one exception and still surfaces as 429.

If the model reads the sentence and finds no food in it (`kanka naber`), that is
a successful answer, not a failure: no items, no stray tokens, and the request
lands on `NO_MATCH` rather than inventing candidates.

## Cost

One extra `gpt-5.4-nano` call on the text path, and only when the deterministic
matcher leaves something unexplained. At roughly 200 input tokens and the
versioned $0.20 / 1M input price, that is on the order of $0.00004 per affected
request. It is not free, and it is now measured rather than invisible.

## Verification

Run:

```sh
deno task --config supabase/deno.json check
deno task --config supabase/deno.json test
deno task --config supabase/deno.json eval
flutter analyze
flutter test
```

Observed on this change:

- `deno test` — 65 passed, 0 failed (11 new in
  `functions/tests/analyze-meal/text_extraction_test.ts`, covering filler
  rejection, amount handling, composite decomposition, malformed-row rejection,
  retry, refusal and timeout).
- `deno eval` — 60/60, identity F1 `1.00`, portion MAPE `0`. The deterministic
  gate is unchanged, which is the point: the fast path was not disturbed.
- `flutter analyze` — no issues. `flutter test` — 301 passed.

The clarification-queue change broke four tests, which is the useful part: two
`estimate_review_test` cases and two golden baselines were all reaching review
widgets that a sheet now covers. They were updated to walk past the sheets
(`test/support/clarification.dart`), and the `portion_clarification` baseline
dropped its `review-edit-button` tap because the sheet is what the user now
meets directly. Both goldens then matched their existing images unchanged,
which confirms the sheets and the review screen themselves were not altered —
only when they appear.

Six conversational cases were added to `evals/gold/bilingual_hybrid_v1.jsonl`
(20 → 26), including the two reported failures and a no-food case.

**These live-eval cases have not been run.** The live eval is paid and requires
a deployed function and an API key, so the fix is verified at unit and
regression level, and the end-to-end claim on the two reported sentences is
supported by design and unit coverage but not yet by a live measurement. Run
`deno task --config supabase/deno.json eval:live` against a deployment to close
that gap; that run is also what will show the real latency cost of the extra
call.

The baseline it has to beat is already measured. The first clean hosted run
scored identity exact accuracy `0.55` and portion MAPE `1.46` — the second
number being 146% error against a 10% gate, and an independent confirmation of
the literature: portion, not identification, is where this pipeline loses.
Every change here targets one of those two numbers, and neither can be claimed
as improved until that run is repeated on a deployment carrying this code. See
[`docs/AI_EVAL_REPORT.md`](AI_EVAL_REPORT.md).

## Still open

- The extraction prompt is unversioned beyond `meal-text-extraction-v1` and has
  not been tuned against a held-out set. The six new eval cases are a starting
  point, not a calibration set.
- `MIN_SEMANTIC_SIMILARITY = 0.62` is a hand-picked constant like the confidence
  thresholds around it. It should be calibrated against observed correction
  rates, not chosen.
- Component gram amounts come from the model's idea of a typical dish. They are
  grounded per-ingredient in the catalog, but the *ratio* between ingredients is
  still a model guess and will show up as portion error until measured.
- The concurrent-duplicate race on the analyze path is unchanged, and now costs
  one more provider call when it fires.
