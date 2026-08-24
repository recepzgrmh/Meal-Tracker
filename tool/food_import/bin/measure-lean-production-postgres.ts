#!/usr/bin/env node
import pg from "pg";

const { Client } = pg;
if (!process.env.DATABASE_URL) throw new Error("DATABASE_URL is required");
const client = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false }, options: "-c default_transaction_read_only=off" });
try {
  await client.connect();
  const counts = (await client.query(`select
    (select count(*) from public.foods where source='canonical_v2_lean')::bigint foods,
    (select count(*) from public.food_aliases a join public.foods f on f.id=a.food_id where f.source='canonical_v2_lean')::bigint aliases,
    (select count(*) from public.food_portions p join public.foods f on f.id=p.food_id where f.source='canonical_v2_lean')::bigint portions,
    (select count(*) from public.foods where source='canonical_v2_lean'
      and num_nonnulls(calories_per_100g,protein_per_100g,carbs_per_100g,fat_per_100g)=4)::bigint macro_complete,
    (select count(*) from public.food_portions p join public.foods f on f.id=p.food_id
      where f.source='canonical_v2_lean' and (p.grams < 0.01 or p.grams > 10000))::bigint invalid_portions,
    (select count(*) from public.foods where source<>'canonical_v2_lean')::bigint preexisting_foods`)).rows[0];
  const tiers = (await client.query(`select metadata->>'tier' tier,count(*)::bigint records
    from public.foods where source='canonical_v2_lean' group by 1 order by 1`)).rows;
  const sizes: Record<string, number> = {};
  for (const table of ["foods", "food_aliases", "food_portions"]) {
    sizes[table] = Number((await client.query("select pg_total_relation_size($1::regclass)::bigint bytes", [`public.${table}`])).rows[0].bytes);
  }
  const db = (await client.query("select pg_database_size(current_database())::bigint bytes,current_setting('default_transaction_read_only') read_only")).rows[0];
  console.log(JSON.stringify({ database_bytes: Number(db.bytes), read_only: db.read_only,
    counts: Object.fromEntries(Object.entries(counts).map(([key, value]) => [key, Number(value)])),
    tiers: Object.fromEntries(tiers.map((row) => [row.tier, Number(row.records)])),
    relation_sizes_bytes: sizes, hot_catalog_relations_total_bytes: Object.values(sizes).reduce((sum, value) => sum + value, 0) }, null, 2));
} finally { await client.end(); }
