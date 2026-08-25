-- The same over-broad match in 20260825100000 also gave the non-chicken eggs a
-- chicken egg's weight. "Yumurta, bıldırcın, tam" and "Yumurta, devekuşu, tam"
-- both carry the alias 'yumurta' and both received "1 adet = 50 g".
--
-- A quail egg is about 9 g and an ostrich egg about 1,400 g shelled, so 50 g is
-- wrong by a factor of five in one direction and twenty-eight in the other.
-- Nobody logs an ostrich egg, which is exactly why it would have sat there
-- uncorrected — a plausible-looking number nothing ever checks.
--
-- The lesson this pair records: matching catalog rows by alias to write portion
-- data is too coarse, because an alias is deliberately broad ('yumurta' reaches
-- the yolk, the white, and every species) while a unit weight is specific to
-- one row. Later portion work should match on the food, not on how people can
-- refer to it.

update public.food_portions p
   set grams = 9.0
  from public.foods f
 where f.id = p.food_id
   and f.canonical_name = 'Yumurta, bıldırcın, tam'
   and p.label in ('1 adet', '1 piece')
   and p.grams = 50.0;

update public.food_portions p
   set grams = 1400.0
  from public.foods f
 where f.id = p.food_id
   and f.canonical_name = 'Yumurta, devekuşu, tam'
   and p.label in ('1 adet', '1 piece')
   and p.grams = 50.0;
