do $migration$
declare
  v_function_oid regprocedure :=
    'public.search_food_catalog(text,text,integer)'::regprocedure;
  v_definition text;
  v_old_expression text := 'pg_catalog.round(ranked.score, 6)';
  v_new_expression text := 'pg_catalog.round(ranked.score::numeric, 6)';
begin
  select pg_catalog.pg_get_functiondef(v_function_oid)
    into v_definition;
  if pg_catalog.strpos(v_definition, v_old_expression) = 0 then
    raise exception 'expected catalog score expression was not found';
  end if;
  execute pg_catalog.replace(v_definition, v_old_expression, v_new_expression);
end;
$migration$;
