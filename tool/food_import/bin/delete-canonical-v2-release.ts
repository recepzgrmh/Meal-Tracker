#!/usr/bin/env node
import pg from "pg";

const { Client } = pg;
const connectionString = process.env.DATABASE_URL;
const catalogVersion = process.env.CATALOG_VERSION;
if (!connectionString) throw new Error("DATABASE_URL is required");
if (!catalogVersion) throw new Error("CATALOG_VERSION is required");
if (process.env.ALLOW_DELETE_CATALOG_RELEASE !== "1") throw new Error("ALLOW_DELETE_CATALOG_RELEASE=1 is required");

const client = new Client({ connectionString, ssl: { rejectUnauthorized: false }, options: "-c default_transaction_read_only=off" });
try {
  await client.connect();
  await client.query("begin");
  await client.query("set transaction read write");
  const result = await client.query(
    "delete from public.catalog_v2_releases where catalog_version=$1 and status <> 'published' returning id,catalog_version,status,canonical_food_count",
    [catalogVersion],
  );
  await client.query("commit");
  console.log(JSON.stringify({ deleted: result.rowCount, releases: result.rows }, null, 2));
} catch (error) {
  await client.query("rollback");
  throw error;
} finally {
  await client.end();
}
