-- The project is configured not to expose new public tables automatically.
-- Grant only the operations the authenticated mobile client needs. All AI
-- orchestration and catalog writes are reserved for the service role.

grant usage on schema public to authenticated, service_role;

grant select on table public.profiles to authenticated;
grant update (
  display_name,
  locale,
  timezone,
  daily_calorie_target
) on table public.profiles to authenticated;

grant select on table public.foods to authenticated;
grant select on table public.food_aliases to authenticated;
grant select on table public.food_portions to authenticated;

grant select on table public.analysis_runs to authenticated;
grant select on table public.analysis_candidates to authenticated;

grant select, insert, delete on table public.meals to authenticated;
grant select, insert, update, delete on table public.meal_items to authenticated;
grant select, insert on table public.meal_item_corrections to authenticated;

grant all privileges on all tables in schema public to service_role;
grant all privileges on all sequences in schema public to service_role;

alter default privileges for role postgres in schema public
  revoke all on tables from anon, authenticated;
alter default privileges for role postgres in schema public
  grant all privileges on tables to service_role;
alter default privileges for role postgres in schema public
  grant all privileges on sequences to service_role;
