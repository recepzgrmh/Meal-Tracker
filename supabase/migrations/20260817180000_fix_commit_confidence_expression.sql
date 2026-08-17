do $migration$
declare
  v_function_oid regprocedure :=
    'public.commit_analyzed_meal(uuid,uuid,uuid,text,timestamptz,jsonb)'::regprocedure;
  v_definition text;
  v_qualified_expression text :=
    'pg_catalog.greatest(0::numeric, pg_catalog.least(1::numeric, coalesce(v_candidate.retrieval_score, 0.5::numeric)))';
  v_fixed_expression text :=
    'greatest(0::numeric, least(1::numeric, coalesce(v_candidate.retrieval_score, 0.5::numeric)))';
begin
  select pg_catalog.pg_get_functiondef(v_function_oid)
    into v_definition;
  if pg_catalog.strpos(v_definition, v_qualified_expression) = 0 then
    raise exception 'expected qualified confidence expression was not found';
  end if;
  execute pg_catalog.replace(v_definition, v_qualified_expression, v_fixed_expression);
end;
$migration$;
