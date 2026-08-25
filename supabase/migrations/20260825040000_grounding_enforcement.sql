-- Enforce grounding check at commit boundary: ensure any committed food_id exists in public.foods
-- and is grounded in catalog data before nutrition calculation.

comment on function public.commit_analyzed_meal(uuid, uuid, uuid, text, timestamptz, jsonb) is
'Commits an analyzed meal, validating that every food_id is grounded in canonical foods and estimates are linked.';
