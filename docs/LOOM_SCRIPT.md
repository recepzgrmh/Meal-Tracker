# Loom walkthrough script

> Record AFTER all fixes land. Target length: ~8 minutes. Keep the tone plain;
> state limits proactively rather than waiting to be asked.

## 0:00 — Thesis over the architecture diagram

- "This is Meal Clarity, an accuracy-first meal logger. The rule the whole
  system is built around: the model interprets, the catalog decides."
- Point at the diagram: text or photo goes through vision extraction and
  hybrid retrieval, but the LLM only ever picks from a server-created
  allow-list of catalog IDs — it never emits nutrition numbers.
- "Every calorie in the database comes from a catalog row re-read inside
  Postgres at commit time. Neither the model nor the client can forge it."

## 0:40 — Live demo: ambiguous input, NO_MATCH, photo

- Type "biraz beyaz peynir" — "a bit of white cheese" — and show the
  clarification sheet: the server flagged the amount as uncertain instead of
  silently guessing, I pick a portion, commit, and it lands on the dashboard.
- Now a food the catalog doesn't have: the app shows an explicit NO_MATCH,
  I use manual catalog search, and when nothing fits, the server produces a
  clearly-labeled, bounds-checked AI estimate — persisted server-side, never
  supplied by the client.
- Finish with a photo meal: camera to private per-user storage, vision
  extraction, and the same grounded matching path — photos get no special
  trust.

## 3:00 — Hallucination gates in code

- Open the candidate selector: the LLM response schema is an enum of allowed
  food IDs, so choosing a food that wasn't retrieved is a schema violation,
  not a subtle bug.
- Open the commit RPC: it re-reads nutrition from the catalog inside the
  database — whatever the client sends for nutrition is ignored.
- Show the forged-nutrition test: a client submitting fake macros is rejected;
  this invariant is enforced by a test, not by convention.

## 4:30 — Measurement story

- "Before showing numbers, what they don't mean: the CI regression gate scores
  60/60 against a 3-food fixture catalog with no retrieval and no LLM. That
  perfection means no Turkish-parsing regressions — it is not product
  accuracy."
- Product accuracy comes from the live eval: 24 bilingual text and photo cases
  against the deployed function, reporting latency, tokens, and cost per case.
- Open the admin dashboard's AI Evals page: runs persist to eval tables, so
  every eval is inspectable after the fact, not a one-off terminal log.

## 5:45 — Reliability demo

- Replay the same commit request ID twice: the second commit is a no-op —
  idempotency keys mean a flaky network can't double-log a meal.
- Turn on airplane mode, log a meal, turn it off: the outbox syncs it. This
  path is covered by integration tests, not just demoed.

## 6:45 — Admin observability

- Show the cost and error breakdown: per-request tokens, estimated spend,
  error codes, and vision fallback reasons — raw meal text stays out of logs.
- "When accuracy or spend drifts, this is where you see it first."

## 7:30 — EatBetter comparison, limitations, next steps

- "Against EatBetter, most of my claimed advantages are hypotheses with a
  measurement plan — correction-rate telemetry is how I'd prove or disprove
  them. The one verifiable property is that hallucinated nutrition is
  structurally impossible here."
- Honest limits: uncalibrated confidence thresholds, a small eval set, a known
  analyze-path duplicate race, and synchronous embedding backfill.
- Next steps: calibrate thresholds from correction rates, expand the eval set
  with dietitian review, and move backfill to a scheduled worker.
