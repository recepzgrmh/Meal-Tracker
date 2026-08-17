# Live hybrid and vision evaluation

The repository keeps three versioned evaluation layers:

- `turkish_meals_v1.jsonl`: 60 deterministic parser regressions, safe for every PR.
- `bilingual_hybrid_v1.jsonl`: 20 Turkish/English hybrid cases covering typos,
  morphology, regional aliases, mixed inputs, and deliberate `NO_MATCH` cases.
- `photo_meals_v1.json`: four controlled photo fixtures with identity labels and
  portion tolerance bands.

The live runner invokes the deployed authenticated pipeline and joins each result
to its own `analysis_runs` telemetry. It reports exact identity accuracy,
`NO_MATCH` accuracy, portion MAPE, p50/p95 latency, retrieval/response cache hit
rates, token counts, and estimated cost.

## Safe execution

Use a short-lived JWT for a dedicated eval user. Never commit it. The explicit
acknowledgement and case cap prevent accidental unbounded provider spend.

```bash
cd supabase
EVAL_SUPABASE_URL=https://PROJECT.supabase.co \
EVAL_SUPABASE_PUBLISHABLE_KEY=... \
EVAL_USER_JWT=... \
LIVE_EVAL_ACK=I_ACCEPT_PROVIDER_COST \
EVAL_MAX_CASES=20 \
deno task eval:live ../evals/gold/bilingual_hybrid_v1.jsonl
```

For the photo slice, replace the final path with
`../evals/gold/photo_meals_v1.json`. Uploaded fixtures use the same private
`meal-photos` ownership policy as the app.

## Pricing version

`openai-standard-2026-08-18` uses the standard per-million-token prices that
were current when the report contract was authored:

- `gpt-5.4-nano`: $0.20 input, $1.25 output.
- `text-embedding-3-small`: $0.02 input.

Sources: [GPT-5.4 nano model documentation](https://developers.openai.com/api/docs/models/gpt-5.4-nano)
and [text-embedding-3-small model documentation](https://developers.openai.com/api/docs/models/text-embedding-3-small).

Any model or pricing change must update the pricing version and run both live
datasets before release. Generated reports should not contain raw meal text,
JWTs, or image URLs.
