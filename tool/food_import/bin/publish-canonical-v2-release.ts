#!/usr/bin/env node
import pg from "pg";

const { Client } = pg;
const connectionString = process.env.DATABASE_URL;
const catalogVersion = process.env.CATALOG_VERSION;
if (!connectionString || !catalogVersion) throw new Error("DATABASE_URL and CATALOG_VERSION are required");
if (process.env.ALLOW_PUBLISH_CATALOG_RELEASE !== "1") throw new Error("ALLOW_PUBLISH_CATALOG_RELEASE=1 is required");
const client = new Client({ connectionString });
try {
  await client.connect();
  await client.query("begin");
  const result = await client.query(`update public.catalog_v2_releases
    set status='published',published_at=now(),updated_at=now()
    where catalog_version=$1 and status='validated'
    returning id,catalog_version,status,record_count,canonical_food_count`, [catalogVersion]);
  if (result.rowCount !== 1) throw new Error("exactly one validated release must be published");
  await client.query("commit");
  console.log(JSON.stringify(result.rows[0], null, 2));
} catch (error) {
  await client.query("rollback"); throw error;
} finally { await client.end(); }
