-- COALESCE, GREATEST, LEAST, and NULLIF are parser constructs rather than
-- catalog functions. The grammar only matches them as bare keywords, so a
-- schema-qualified `pg_catalog.coalesce(...)` is parsed as an ordinary function
-- call, looked up in pg_proc, and rejected with 42883. Qualifying them is also
-- unnecessary under `set search_path = ''`: the parser resolves the keyword
-- before any schema lookup happens, so the empty search path cannot hijack it.
--
-- 20260818170000 already repaired one function this way. The daily cost ceiling
-- (20260823170000) and the commit RPC reintroduced the pattern, which took both
-- hot paths offline in the deployed project: every model-backed analysis failed
-- the budget check and surfaced as PROVIDER_UNAVAILABLE, and every analyzed
-- meal commit would have failed on the confidence clamp.
--
-- Repair whatever is deployed instead of restating each function body, so this
-- stays correct regardless of which definition currently wins, then assert the
-- pattern is gone so a silent reintroduction fails the migration.
do $migration$
declare
  v_signature text;
  v_repaired text;
begin
  for v_signature in
    select p.oid::pg_catalog.regprocedure::text
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and pg_catalog.pg_get_functiondef(p.oid) ~*
        'pg_catalog\.(coalesce|greatest|least|nullif)\s*\('
  loop
    v_repaired := pg_catalog.regexp_replace(
      pg_catalog.pg_get_functiondef(v_signature::pg_catalog.regprocedure),
      'pg_catalog\.(coalesce|greatest|least|nullif)\s*\(',
      '\1(',
      'gi'
    );
    execute v_repaired;
  end loop;
end;
$migration$;

do $guard$
declare
  v_remaining text;
begin
  select pg_catalog.string_agg(p.oid::pg_catalog.regprocedure::text, ', ')
  into v_remaining
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.prokind = 'f'
    and pg_catalog.pg_get_functiondef(p.oid) ~*
      'pg_catalog\.(coalesce|greatest|least|nullif)\s*\(';

  if v_remaining is not null then
    raise exception using
      errcode = '42883',
      message = 'schema-qualified SQL constructs remain in: ' || v_remaining;
  end if;
end;
$guard$;
