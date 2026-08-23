#!/usr/bin/env node
import pg from "pg";

const { Client } = pg;
const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error("DATABASE_URL is required");

const catalogVersion = process.env.CATALOG_VERSION ?? null;
const tables = [
  "catalog_v2_releases",
  "catalog_v2_source_records",
  "catalog_v2_canonical_foods",
  "catalog_v2_source_mappings",
  "catalog_v2_source_nutrition",
  "catalog_v2_food_nutrition",
  "catalog_v2_portions",
  "catalog_v2_aliases",
  "catalog_v2_branded_metadata",
  "catalog_v2_review_cases",
  "catalog_v2_blocked_matches",
] as const;

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false },
  options: "-c default_transaction_read_only=off",
});

try {
  await client.connect();
  const release = catalogVersion
    ? (await client.query("select id,catalog_version,status,record_count,canonical_food_count from public.catalog_v2_releases where catalog_version=$1", [catalogVersion])).rows[0]
    : null;
  const relationSizes: Record<string, number> = {};
  for (const table of tables) {
    const result = await client.query("select pg_total_relation_size($1::regclass)::bigint as bytes", [`public.${table}`]);
    relationSizes[table] = Number(result.rows[0].bytes);
  }
  const releaseCounts = release ? (await client.query(`select
    (select count(*) from public.catalog_v2_source_records where release_id=$1)::bigint as source_records,
    (select count(*) from public.catalog_v2_canonical_foods where release_id=$1)::bigint as canonical_foods,
    (select count(*) from public.catalog_v2_source_mappings where release_id=$1)::bigint as source_mappings,
    (select count(*) from public.catalog_v2_source_nutrition where release_id=$1)::bigint as source_nutrition,
    (select count(*) from public.catalog_v2_food_nutrition where release_id=$1)::bigint as food_nutrition,
    (select count(*) from public.catalog_v2_portions where release_id=$1)::bigint as portions,
    (select count(*) from public.catalog_v2_aliases where release_id=$1)::bigint as aliases,
    (select count(*) from public.catalog_v2_branded_metadata where release_id=$1)::bigint as branded_metadata`, [release.id])).rows[0] : null;
  const production = process.env.MEASURE_PRODUCTION === "1" ? (await client.query(`select
      (select count(*) from public.foods)::bigint as foods,
      (select count(*) from public.food_aliases)::bigint as food_aliases,
      (select count(*) from public.food_portions)::bigint as food_portions,
      (select count(*) from public.meals)::bigint as meals,
      (select count(*) from public.meal_items)::bigint as meal_items`)).rows[0] : null;
  const database = (await client.query("select pg_database_size(current_database())::bigint as bytes,current_setting('default_transaction_read_only') as default_read_only")).rows[0];
  console.log(JSON.stringify({
    measured_at: new Date().toISOString(),
    database_bytes: Number(database.bytes),
    default_read_only: database.default_read_only,
    release: release ? { ...release, record_count: Number(release.record_count), canonical_food_count: Number(release.canonical_food_count) } : null,
    release_counts: releaseCounts ? Object.fromEntries(Object.entries(releaseCounts).map(([key, value]) => [key, Number(value)])) : null,
    relation_sizes_bytes: relationSizes,
    catalog_relations_total_bytes: Object.values(relationSizes).reduce((sum, bytes) => sum + bytes, 0),
    production_counts: production ? Object.fromEntries(Object.entries(production).map(([key, value]) => [key, Number(value)])) : null,
  }, null, 2));
} finally {
  await client.end();
}
