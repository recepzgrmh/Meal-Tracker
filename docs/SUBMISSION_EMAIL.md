# Submission email draft

Subject: Case study submission — Meal Clarity

Hi [name],

Here is my case-study submission: an accuracy-first meal logger built with
Flutter, a Node.js/TypeScript backend, Supabase (Postgres + pgvector, auth and
storage), and a React admin console for AI quality and cost.

**What I built.** An end-to-end flow: messy Turkish or English text (or a
photo) goes through a hybrid pipeline — deterministic Turkish parsing, then a
language model that only ever picks from a server-built allow-list of catalog
ids — and lands as a reviewed meal whose nutrition is re-read from a 60k-food
catalog inside Postgres at commit time. Uncertain items are flagged, one
question is asked up front, and anything still unchecked is named again before
the meal is logged.

**The one invariant to remember.** The model interprets, the catalog decides.
Nutrition can never be invented by the model or forged by the client: the
commit payload carries no macros at all, and `meal_items.calories` is a
generated column. AI estimates for foods the catalog does not contain are
bounds-checked, visibly labelled, and stored as unreviewed.

**Compared to EatBetter.** Three concrete differences, with how I would prove
each. (1) Uncertainty is visible — every item carries a confidence and an
explicit "check the type / check the amount" state, where the current app shows
none; measurable as correction rate per logged meal. (2) Fabricated nutrition
is structurally impossible rather than merely unlikely, because numbers come
from catalog rows re-read server-side. (3) Corrections are a feedback loop:
every edit is written as a diff, which is what would let portion priors improve
instead of staying static. Public reviews of the current app describe portion
estimates missing in both directions ("2 minutes logging, 20 minutes fixing")
— portion is exactly what this system asks about rather than guesses silently.
Most of these are hypotheses with a measurement plan, and the README says so.

**What I didn't build.** No fine-tuning, no barcode scanning, no deployed
backend (it runs locally, which the brief allows). The full 1.2M-food corpus
stays offline in favour of a reproducible 60k catalog.

**Key trade-offs.** Grounding over coverage: refusing to let the model emit
numbers means anything outside the catalog cannot be logged as a catalog fact,
so recall is bounded by catalog size. I took that because a wrong number the
user trusts is worse than a visible gap they can correct. Second, the service
began on Supabase Edge Functions (Deno) for the integrated auth and RLS, then
had to be ported to Node.js/TypeScript — speed early, a rewrite later; the port
was kept mechanical so behaviour could be shown not to have drifted.

**How accuracy is measured, honestly.** A deterministic parser regression gate
in CI (60/60 — that means no Turkish-parsing regressions, not product
accuracy), a live eval of bilingual text and photo cases against the running
backend reporting latency, tokens and cost, and commit-time correction diffs as
ongoing telemetry. The gold set is small and the confidence thresholds are
hand-picked, uncalibrated constants. Measurement did earn its keep: it exposed
a systematic wrong-match bug in my own catalog where 68,535 machine-generated
aliases outranked curated Turkish foods — "badem" could resolve to popcorn
seasoning salt at 0 kcal. The README documents the before/after.

**Next steps, in order.** Calibrate the clarification thresholds against the
correction telemetry instead of hand-picking them; batch the per-component
catalog lookups that make a composite dish take ~20 s; expand the gold set with
dietitian-reviewed labels and run blinded live evals against pinned model
snapshots.

Repo: [repo link]
Walkthrough: [Loom link]

Thanks for reading,
[author]
