#!/usr/bin/env node
/**
 * Gives the English-named half of the catalog a Turkish name.
 *
 * Roughly 13,300 of the 60,000 imported rows are USDA generic foods whose only
 * name is English ("Home recipe pasta with cream sauce and meat"). The importer
 * already prefers `canonical_name_tr` when the canonical data has one, but that
 * field is populated for 11,276 of 1.2M canonical records — the TürKomp slice —
 * so USDA rows fall back to English. Two things break as a result:
 *
 *   - A Turkish user is shown English food names, including in the "which one
 *     was it?" sheet where they have to *choose* between them.
 *   - Turkish lexical retrieval cannot reach those rows at all, because the
 *     only alias they carry is the English name. They are reachable in theory
 *     by embedding and poorly in practice, which is why "kremalı tavuklu
 *     makarna" surfaced ready-meal brands instead of the pasta rows that were
 *     sitting in the catalog the whole time.
 *
 * This writes `metadata.canonical_name_tr` and adds a `tr-TR` alias, so the
 * name is fixed once in the data rather than translated per request.
 *
 * Nutrition is never touched. The model only ever renames.
 *
 *   DATABASE_URL=postgres://... OPENAI_API_KEY=sk-... \
 *     node --experimental-strip-types tool/food_import/bin/translate-catalog-names-postgres.ts
 *
 * Resumable: rows that already have a Turkish name are skipped, so an
 * interrupted run continues where it stopped. `TRANSLATE_LIMIT` bounds a run.
 */
import pg from "pg";

const { Pool } = pg;

const BATCH_SIZE = Math.max(1, Math.min(60, Number(process.env.TRANSLATE_BATCH_SIZE ?? 40)));
const CONCURRENCY = Math.max(1, Math.min(8, Number(process.env.TRANSLATE_CONCURRENCY ?? 4)));
const LIMIT = Math.max(0, Number(process.env.TRANSLATE_LIMIT ?? 0));
const MODEL = process.env.OPENAI_TRANSLATION_MODEL ?? "gpt-5.4-nano";
const ALIAS_PRIORITY = 85;
const MAX_ATTEMPTS = 3;
// Catalog names reach 535 characters and the 99th percentile is 141, so a cap
// of 90 made the longest entries impossible to translate and they failed on
// every run.
const MAX_NAME_LENGTH = 150;

type Row = { id: string; canonical_name: string };

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} is required`);
  return value;
}

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function buildRequest(names: string[]): Record<string, unknown> {
  return {
    model: MODEL,
    store: false,
    max_output_tokens: 4000,
    reasoning: { effort: "none" },
    input: [
      {
        role: "system",
        content: [{
          type: "input_text",
          text: [
            "You translate food composition database entries from English into Turkish.",
            "Return the name a Turkish food composition database would use, not a literal word-for-word translation: 'Home recipe pasta with cream sauce and meat' is 'ev yapımı kremalı etli makarna'.",
            "Keep every qualifier that changes what the food is or how it was prepared — raw/cooked, home recipe/restaurant/ready-to-heat, whole grain, fat level, with or without skin. These distinguish rows that otherwise collapse together.",
            "Keep it under 150 characters. Use lowercase except for proper nouns and brand names.",
            "Leave brand names, and Turkish words that are already Turkish, as they are.",
            "Translate every entry you are given, in the same order, and return exactly as many as you received.",
          ].join(" "),
        }],
      },
      {
        role: "user",
        content: [{ type: "input_text", text: JSON.stringify({ names }) }],
      },
    ],
    text: {
      format: {
        type: "json_schema",
        name: "catalog_name_translation",
        strict: true,
        schema: {
          type: "object",
          additionalProperties: false,
          properties: {
            translations: {
              type: "array",
              minItems: names.length,
              maxItems: names.length,
              items: { type: "string", minLength: 1, maxLength: MAX_NAME_LENGTH },
            },
          },
          required: ["translations"],
        },
      },
    },
  };
}

function outputText(payload: Record<string, unknown>): string {
  const output = payload.output;
  if (!Array.isArray(output)) throw new Error("translator returned no output");
  for (const item of output) {
    if (typeof item !== "object" || item === null) continue;
    const content = (item as Record<string, unknown>).content;
    if (!Array.isArray(content)) continue;
    for (const part of content) {
      if (typeof part !== "object" || part === null) continue;
      const typed = part as Record<string, unknown>;
      if (typed.type === "refusal") throw new Error("translator refused the batch");
      if (typed.type === "output_text" && typeof typed.text === "string") return typed.text;
    }
  }
  throw new Error("translator returned no output text");
}

async function translateBatch(apiKey: string, names: string[]): Promise<string[]> {
  let lastError = new Error("translator failed");
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
    try {
      const response = await fetch("https://api.openai.com/v1/responses", {
        method: "POST",
        headers: { authorization: `Bearer ${apiKey}`, "content-type": "application/json" },
        body: JSON.stringify(buildRequest(names)),
      });
      if (response.ok) {
        const payload = await response.json() as Record<string, unknown>;
        const parsed = JSON.parse(outputText(payload)) as { translations?: unknown };
        const translations = Array.isArray(parsed.translations) ? parsed.translations : [];
        // A short or ragged batch would silently pair a name with someone
        // else's translation, so the whole batch is rejected instead.
        if (translations.length !== names.length) {
          throw new Error(`translator returned ${translations.length} of ${names.length}`);
        }
        return translations.map((value) => String(value).trim());
      }
      lastError = new Error(`translator failed with ${response.status}`);
      const retryable = response.status === 408 || response.status === 409 ||
        response.status === 429 || response.status >= 500;
      if (!retryable) throw lastError;
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      if (attempt === MAX_ATTEMPTS) throw lastError;
    }
    await delay(400 * 2 ** (attempt - 1));
  }
  throw lastError;
}

async function persist(pool: pg.Pool, rows: Row[], translations: string[]): Promise<number> {
  // Every row that came back with a name is recorded, including one whose
  // Turkish name is identical to its English one — a brand, or a word Turkish
  // borrowed unchanged. Dropping those left them without a translation, so the
  // next run selected them again and they failed forever. The duplicate alias
  // that results is absorbed by the insert's conflict clause.
  const pairs = rows
    .map((row, index) => ({ id: row.id, tr: (translations[index] ?? "").trim() }))
    .filter(({ tr }) => tr.length > 0);
  if (pairs.length === 0) return 0;

  const client = await pool.connect();
  try {
    await client.query("begin");
    await client.query(
      `update public.foods f
         set metadata = f.metadata || jsonb_build_object('canonical_name_tr', v.tr),
             updated_at = now()
        from (select unnest($1::uuid[]) as id, unnest($2::text[]) as tr) v
       where f.id = v.id`,
      [pairs.map((pair) => pair.id), pairs.map((pair) => pair.tr)],
    );
    // The alias is what makes the row reachable by Turkish text at all. Priority
    // sits below the analyzer's identity-ambiguity threshold (80) on purpose: a
    // translated name is good evidence, not proof, so a hit asks the user to
    // confirm rather than silently committing to one row.
    await client.query(
      `insert into public.food_aliases (food_id, alias, locale, priority)
       select v.id, v.tr, 'tr-TR', $3
         from (select unnest($1::uuid[]) as id, unnest($2::text[]) as tr) v
       on conflict (alias, locale, food_id) do nothing`,
      [pairs.map((pair) => pair.id), pairs.map((pair) => pair.tr), ALIAS_PRIORITY],
    );
    await client.query("commit");
    return pairs.length;
  } catch (error) {
    await client.query("rollback");
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Translates a batch, and on failure halves it and tries each half.
 *
 * A whole batch used to be abandoned when any part of it failed — usually one
 * name the model would not return in the shape the schema demands — so 39 good
 * rows were deferred along with the bad one, run after run. Splitting isolates
 * the row that cannot be translated and lets the rest through.
 */
async function translateWithSplit(
  pool: pg.Pool,
  apiKey: string,
  batch: Row[],
): Promise<[number, number]> {
  try {
    const names = batch.map((row) => row.canonical_name);
    return [await persist(pool, batch, await translateBatch(apiKey, names)), 0];
  } catch (error) {
    if (batch.length === 1) {
      process.stderr.write(
        `untranslatable: ${batch[0].canonical_name.slice(0, 60)} — ${
          error instanceof Error ? error.message : String(error)
        }\n`,
      );
      return [0, 1];
    }
    const middle = Math.floor(batch.length / 2);
    const [left, right] = await Promise.all([
      translateWithSplit(pool, apiKey, batch.slice(0, middle)),
      translateWithSplit(pool, apiKey, batch.slice(middle)),
    ]);
    return [left[0] + right[0], left[1] + right[1]];
  }
}

async function main(): Promise<void> {
  const connectionString = requiredEnv("DATABASE_URL");
  const apiKey = requiredEnv("OPENAI_API_KEY");
  const pool = new Pool({
    connectionString,
    max: CONCURRENCY + 1,
    ssl: { rejectUnauthorized: false },
    options: "-c default_transaction_read_only=off",
  });

  try {
    const { rows: pending } = await pool.query<Row>(
      `select id, canonical_name::text as canonical_name
         from public.foods
        where source = 'canonical_v2_lean'
          and locale = 'en-US'
          and is_active
          and (metadata ->> 'canonical_name_tr') is null
        order by id
        ${LIMIT > 0 ? "limit " + LIMIT : ""}`,
    );
    process.stderr.write(`pending English-named rows: ${pending.length.toLocaleString()}\n`);
    if (pending.length === 0) return;

    const batches: Row[][] = [];
    for (let index = 0; index < pending.length; index += BATCH_SIZE) {
      batches.push(pending.slice(index, index + BATCH_SIZE));
    }

    let translated = 0;
    let failed = 0;
    let cursor = 0;
    const workers = Array.from({ length: Math.min(CONCURRENCY, batches.length) }, async () => {
      while (cursor < batches.length) {
        const batch = batches[cursor++];
        const [done, lost] = await translateWithSplit(pool, apiKey, batch);
        // Incremented after the awaits, not across them: `x += await f()` reads
        // the counter before suspending, so four workers were overwriting each
        // other's totals and the printed number went backwards.
        translated += done;
        failed += lost;
        process.stderr.write(
          `translated ${translated.toLocaleString()} / ${pending.length.toLocaleString()}` +
            (failed > 0 ? ` (${failed.toLocaleString()} deferred)` : "") + "\n",
        );
      }
    });
    await Promise.all(workers);

    const { rows: [summary] } = await pool.query<{ named: string; total: string }>(
      `select count(*) filter (where (metadata ->> 'canonical_name_tr') is not null)::text as named,
              count(*)::text as total
         from public.foods
        where source = 'canonical_v2_lean' and locale = 'en-US' and is_active`,
    );
    process.stderr.write(
      `done: ${summary.named} of ${summary.total} English-named rows now have a Turkish name\n`,
    );
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  process.stderr.write(`${error instanceof Error ? error.stack ?? error.message : error}\n`);
  process.exit(1);
});
