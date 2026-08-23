-- Every imported food carries exactly one alias: the raw source display name
-- ("Yumurta, tavuk, tam", "Eggs, Grade A, Large"). Users type the head noun
-- ("yumurta"), which matched nothing, so both the deterministic matcher and the
-- lexical half of hybrid retrieval missed the most common inputs.
--
-- This derives the head segment as an additional, lower-priority alias. The
-- priority is deliberately below the identity-ambiguity threshold (80) the
-- analyzer uses, so a head-noun hit asks the user to confirm which food was
-- meant instead of silently picking one of several.
--
-- Normalization mirrors normalizeTurkishInput in
-- supabase/functions/analyze-meal/deterministic.ts: Turkish-aware lowercasing
-- (I->ı and İ->i before lower()), non-alphanumeric runs collapsed to single
-- spaces, trimmed.

insert into public.food_aliases (food_id, alias, locale, priority)
select distinct derived.food_id, derived.alias, derived.locale, 60
from (
  select
    a.food_id,
    a.locale,
    btrim(
      regexp_replace(
        regexp_replace(
          lower(translate(split_part(a.alias, ',', 1), 'Iİ', 'ıi')),
          '[^[:alnum:]]+', ' ', 'g'
        ),
        '\s+', ' ', 'g'
      )
    ) as alias
  from public.food_aliases a
  join public.foods f on f.id = a.food_id
  where f.is_active
    and position(',' in a.alias) > 0
) as derived
where char_length(derived.alias) between 2 and 120
on conflict (alias, locale, food_id) do nothing;

comment on table public.food_aliases is
  'Search surface for the catalog. Priority >= 100 is an exact colloquial name, 90 the raw source display name, 60 a derived head noun that requires user confirmation.';
