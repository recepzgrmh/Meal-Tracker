-- Regression guard for 20260824130000. COALESCE/GREATEST/LEAST/NULLIF are
-- parser constructs, so qualifying them with pg_catalog turns them into missing
-- function lookups (42883) at execution time. That is invisible to `db lint`
-- and to any test that never reaches the statement, which is how it previously
-- reached production in both the budget check and the commit RPC.
begin;

select plan(2);

select is_empty(
  $$
    select p.oid::pg_catalog.regprocedure::text
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and pg_catalog.pg_get_functiondef(p.oid) ~*
        'pg_catalog\.(coalesce|greatest|least|nullif)\s*\('
  $$,
  'no public function schema-qualifies a SQL construct'
);

-- Exercise the ceiling check itself: it is the statement that failed in
-- production, and it is cheap to call because no rows are required.
select lives_ok(
  $$
    select public.analysis_cost_budget_check(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid, 100000, 2000000, 20000
    )
  $$,
  'the daily cost ceiling check executes'
);

select * from finish();

rollback;
