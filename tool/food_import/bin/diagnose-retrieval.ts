#!/usr/bin/env node
/**
 * Shows what retrieval actually does with one query, instead of inferring it
 * from a screenshot.
 *
 * Prints, in order: whether the ranking helpers exist at all, what the overlap
 * score is for the rows in question, and the top rows the lexical arm produces
 * with every ranking term broken out. That is enough to tell "the migration did
 * not apply", "the helper returns null", and "the ranking is working and the
 * candidate set is the problem" apart from each other.
 *
 *   PGPASSWORD='...' DATABASE_URL='postgresql://user@host:5432/postgres' \
 *     node --experimental-strip-types tool/food_import/bin/diagnose-retrieval.ts "kremalı tavuklu makarna"
 */
import pg from "pg";

const { Pool } = pg;
const QUERY = (process.argv[2] ?? "kremalı tavuklu makarna").toLocaleLowerCase("tr-TR");
const LOCALE = process.env.DIAGNOSE_LOCALE ?? "tr-TR";

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} is required`);
  return value;
}

async function main(): Promise<void> {
  const pool = new Pool({
    connectionString: requiredEnv("DATABASE_URL"),
    max: 1,
    ssl: { rejectUnauthorized: false },
  });

  try {
    console.log(`sorgu: "${QUERY}"  locale: ${LOCALE}\n`);

    const { rows: helpers } = await pool.query<{ proname: string; args: string }>(
      `select p.proname, pg_catalog.pg_get_function_identity_arguments(p.oid) as args
         from pg_catalog.pg_proc p
         join pg_catalog.pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname in ('query_name_overlap', 'localized_name', 'hybrid_search_food_catalog')
        order by p.proname`,
    );
    console.log("veritabanındaki fonksiyonlar:");
    for (const row of helpers) console.log(`  ${row.proname}(${row.args})`);
    if (!helpers.some((row) => row.proname === "query_name_overlap")) {
      console.log("\n  !! query_name_overlap YOK — sıralama migration'ı uygulanmamış.\n");
    }

    const { rows: named } = await pool.query<{ named: string; total: string }>(
      `select count(*) filter (where (metadata ->> 'canonical_name_tr') is not null)::text named,
              count(*)::text total
         from public.foods where source = 'canonical_v2_lean' and locale = 'en-US' and is_active`,
    );
    console.log(`\nTürkçe adı olan İngilizce satır: ${named[0].named} / ${named[0].total}`);

    // The lexical arm alone, with every ranking term shown separately. The
    // vector arm needs an embedding this script has no key to build, so this
    // isolates exactly the half that ordering changes affect.
    const { rows } = await pool.query(
      `with scored as (
         select
           f.id,
           public.localized_name(f.canonical_name::text, f.metadata, $2) as name,
           a.alias::text as alias,
           a.priority,
           greatest(
             extensions.similarity(a.alias::text, $1),
             extensions.word_similarity($1, a.alias::text)
           )::numeric as similarity,
           public.query_name_overlap(
             $1, public.localized_name(f.canonical_name::text, f.metadata, $2)
           ) as overlap,
           (f.metadata ->> 'tier') as tier,
           (f.metadata ->> 'turkey_relevance_score') as relevance
         from public.food_aliases a
         join public.foods f on f.id = a.food_id
        where a.locale = $2
          and f.is_active
          and (
            pg_catalog.lower(a.alias::text) = $1
            or a.alias::text operator(extensions.%) $1
          )
       )
       select distinct on (id) * from scored
       order by id, similarity desc`,
      [QUERY, LOCALE],
    );

    rows.sort((left, right) =>
      Number(right.overlap ?? -1) - Number(left.overlap ?? -1) ||
      Number(right.similarity) - Number(left.similarity)
    );

    console.log(`\nlexical adaylar: ${rows.length} (örtüşmeye göre sıralı, ilk 15)\n`);
    console.log(
      "  örtüşme  benzerlik  tier                 alaka  ad",
    );
    for (const row of rows.slice(0, 15)) {
      const overlap = row.overlap === null ? " NULL " : Number(row.overlap).toFixed(3);
      console.log(
        `  ${overlap.padStart(7)}  ${Number(row.similarity).toFixed(3).padStart(9)}  ` +
          `${String(row.tier ?? "-").padEnd(20)} ${String(row.relevance ?? "-").padStart(5)}  ` +
          String(row.name).slice(0, 60),
      );
    }
    if (rows.length === 0) {
      console.log("  (hiç lexical aday yok — bu sorgu sadece embedding ile bulunabiliyor)");
    }
    if (rows.some((row) => row.overlap === null)) {
      console.log("\n  !! bazı satırlarda örtüşme NULL — DESC sıralamada bunlar en başa gider.");
    }

    // Everything above is a proxy. This is the function the app actually calls,
    // with the floor the analyze path passes, so its output is what the user
    // sees rather than an approximation of it.
    const client = await pool.connect();
    try {
      await client.query("begin");
      // The RPC refuses an unauthenticated caller, and a direct Postgres
      // connection has no auth.uid(); the claim makes it answer.
      await client.query(
        `select pg_catalog.set_config('request.jwt.claims',
           '{"sub":"00000000-0000-0000-0000-000000000001"}', true)`,
      );
      for (const floor of [null, 40]) {
        const { rows: hits } = await client.query(
          `select canonical_name, match_method, score, lexical_rank, vector_rank
             from public.hybrid_search_food_catalog($1, null, $2, 10, $3)`,
          [QUERY, LOCALE, floor],
        );
        console.log(
          `\nRPC (lexical, alaka eşiği ${floor ?? "yok"}) → ${hits.length} satır:\n`,
        );
        for (const hit of hits) {
          console.log(
            `  ${Number(hit.score).toFixed(4).padStart(7)}  ${
              String(hit.match_method).padEnd(12)
            } ${String(hit.canonical_name).slice(0, 60)}`,
          );
        }
        if (hits.length === 0) console.log("  (boş)");
      }
      await client.query("rollback");
    } finally {
      client.release();
    }
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  process.stderr.write(`${error instanceof Error ? error.stack ?? error.message : error}\n`);
  process.exit(1);
});
