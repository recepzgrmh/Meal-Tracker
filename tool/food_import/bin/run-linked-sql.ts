#!/usr/bin/env node
import { promises as fs } from "node:fs";
import { homedir } from "node:os";
import { resolve } from "node:path";

const ROOT = resolve(import.meta.dirname, "../../..");
const args = process.argv.slice(2);
const rollback = args.includes("--rollback");
const readOnly = args.includes("--read-only");
const file = args.find((arg) => !arg.startsWith("--"));
if (!file) throw new Error("Usage: run-linked-sql.ts [--rollback] [--read-only] <sql-file>");

const projectRef = (await fs.readFile(resolve(ROOT, "supabase/.temp/project-ref"), "utf8")).trim();
let token = process.env.SUPABASE_ACCESS_TOKEN?.trim();
if (!token) {
  try { token = (await fs.readFile(resolve(homedir(), ".supabase/access-token"), "utf8")).trim(); }
  catch { throw new Error("SUPABASE_ACCESS_TOKEN is required; the CLI Keychain credential is intentionally not inspected"); }
}
const source = await fs.readFile(resolve(ROOT, file), "utf8");
const query = rollback ? `begin;\n${source}\nrollback;` : source;
const response = await fetch(`https://api.supabase.com/v1/projects/${encodeURIComponent(projectRef)}/database/query`, {
  method: "POST",
  headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
  body: JSON.stringify({ query, read_only: readOnly }),
});
if (!response.ok) throw new Error(`Supabase SQL query failed: HTTP ${response.status}: ${(await response.text()).slice(0, 2000)}`);
const result: any = await response.json();
console.log(JSON.stringify({ ok: true, project_ref: projectRef, rolled_back: rollback, read_only: readOnly,
  result_sets: Array.isArray(result) ? result.length : 1 }, null, 2));
