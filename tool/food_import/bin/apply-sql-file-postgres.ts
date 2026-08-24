#!/usr/bin/env node
import { promises as fs } from "node:fs";
import { resolve } from "node:path";
import pg from "pg";

const { Client } = pg;
const connectionString = process.env.DATABASE_URL;
const input = process.env.SQL_FILE;
if (!connectionString || !input) throw new Error("DATABASE_URL and SQL_FILE are required");
if (process.env.ALLOW_APPLY_SQL !== "1") throw new Error("ALLOW_APPLY_SQL=1 is required");
const sql = await fs.readFile(resolve(input), "utf8");
const client = new Client({ connectionString, ssl: { rejectUnauthorized: false }, options: "-c default_transaction_read_only=off" });
try {
  await client.connect();
  await client.query("begin");
  await client.query("set transaction read write");
  await client.query(sql);
  await client.query("commit");
  console.log(JSON.stringify({ applied: resolve(input), bytes: Buffer.byteLength(sql) }));
} catch (error) {
  await client.query("rollback"); throw error;
} finally { await client.end(); }
