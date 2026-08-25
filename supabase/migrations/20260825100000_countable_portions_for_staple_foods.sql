-- The imported catalog knows what 100 g of a food contains and nothing about
-- what one of it weighs. Of 120,013 portion rows the commonest labels are
-- "100 g", "1 ONZ (28 g)" and "3 undetermined oz" — a nutrition basis and some
-- untranslated US measures. Nothing says "1 adet".
--
-- So "2 yumurta" resolved to 2 × 100 g = 200 g and 286 kcal, against a true
-- ~155 kcal. The code side of that is fixed separately: a count is no longer
-- treated as confident when the only portion is a mass basis, so the user is
-- asked instead of told. This is the other half — giving the staples a unit so
-- there is nothing to ask about.
--
-- Scope is deliberately tiny. These are foods Turkish speakers count rather
-- than weigh, and each weight is a published reference, not a guess:
--
--   yumurta   50 g  — USDA medium/large shelled reference weight (large is
--                     ~57 g in shell, ~50 g of egg); TürKomp's 143 kcal/100 g
--                     then gives ~72 kcal per egg, matching the 70-75 kcal
--                     figure nutrition tables quote.
--   ekmek     25 g  — one slice of standard loaf bread.
--   simit     100 g — a whole simit; the existing basis happens to be right,
--                     recorded as a unit so a count multiplies something that
--                     means one simit.
--
-- Everything else keeps asking, which is the honest state until someone
-- reviews weights properly. Portions are inserted as non-default so the
-- existing 100 g basis stays the nutrition reference; the resolver reads any
-- portion whose label matches the user's counting word.

insert into public.food_portions (food_id, label, grams, is_default, locale)
select f.id, v.label, v.grams, false, v.locale
from public.foods f
cross join (values
  ('yumurta', '1 adet', 50.0, 'tr-TR'),
  ('yumurta', '1 piece', 50.0, 'en-US'),
  ('ekmek', '1 dilim', 25.0, 'tr-TR'),
  ('ekmek', '1 slice', 25.0, 'en-US'),
  ('simit', '1 adet', 100.0, 'tr-TR'),
  ('simit', '1 piece', 100.0, 'en-US')
) as v(alias, label, grams, locale)
where f.is_active
  and f.metadata ->> 'tier' = 'generic_core'
  and exists (
    select 1 from public.food_aliases a
    where a.food_id = f.id and a.alias = v.alias and a.locale = 'tr-TR'
  )
on conflict (food_id, label, locale) do nothing;
