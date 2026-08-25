-- 20260825100000 matched on the alias 'yumurta', which the catalog also carries
-- on the components: "Yumurta, tavuk, sarı" (yolk), "Yumurta, tavuk, beyaz
-- (ak)" (white) and the pasteurized variants of each. All of them got
-- "1 adet = 50 g", which is the weight of a whole shelled egg and wrong for a
-- part of one: a yolk is about 17 g and a white about 33 g.
--
-- Left alone it would have been worse than the bug it was fixing. "2 yumurta
-- sarısı" would have read 100 g of yolk at 308 kcal/100 g — 308 kcal against a
-- true ~105 — and, because a unit portion now exists, it would have been stated
-- confidently with no clarification question.
--
-- The component weights are the standard split of a 50 g egg (USDA reference:
-- ~17 g yolk, ~33 g white), so they are corrected rather than removed.

update public.food_portions p
   set grams = 17.0
  from public.foods f
 where f.id = p.food_id
   and f.canonical_name in ('Yumurta, tavuk, sarı', 'Yumurta, sarı, pastörize')
   and p.label in ('1 adet', '1 piece')
   and p.grams = 50.0;

update public.food_portions p
   set grams = 33.0
  from public.foods f
 where f.id = p.food_id
   and f.canonical_name in ('Yumurta, tavuk, beyaz (ak)', 'Yumurta, beyaz, pastörize')
   and p.label in ('1 adet', '1 piece')
   and p.grams = 50.0;
