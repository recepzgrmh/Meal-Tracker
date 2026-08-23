\if :{?catalog_version}
\else
\set catalog_version canonical-v2
\endif
\set ON_ERROR_STOP on

-- Canonical-v2 database audit. This script is intentionally read-only.
-- Override the release when needed:
--   psql ... --set=catalog_version=canonical-v2 -f validate-canonical-v2-database.sql
-- Critical invariant failures raise an exception and roll the transaction back.

begin transaction read only;
set local food_import.catalog_version = :'catalog_version';

\echo '== Canonical-v2 release =='
select
  id,
  catalog_version,
  normalization_version,
  cleaning_version,
  canonicalization_version,
  generic_identity_ontology_version,
  status,
  record_count,
  canonical_food_count,
  review_case_count,
  blocked_match_count,
  validated_at,
  published_at
from public.catalog_v2_releases
where catalog_version = current_setting('food_import.catalog_version');

-- Expected canonical-v2 counts are pinned to the validated deterministic files:
-- source mappings 1,242,528; canonical foods 1,228,891; review 2,469; blocked 334.
-- Per-source: Foundation 363, FNDDS 5,432, SR Legacy 7,793, USDA Branded
-- 455,458, TürKomp 645, Open Food Facts production 772,837.
do $audit$
declare
  v_release public.catalog_v2_releases%rowtype;
  v_count bigint;
  v_detail text;
begin
  select * into v_release
  from public.catalog_v2_releases
  where catalog_version = current_setting('food_import.catalog_version');

  if not found then
    raise exception 'canonical-v2 audit: release % does not exist', current_setting('food_import.catalog_version');
  end if;
  if v_release.canonicalization_version <> 'canonical-v2' then
    raise exception 'canonical-v2 audit: unexpected canonicalization_version %', v_release.canonicalization_version;
  end if;
  if v_release.record_count <> 1242528
     or v_release.canonical_food_count <> 1228891
     or v_release.review_case_count <> 2469
     or v_release.blocked_match_count <> 334 then
    raise exception 'canonical-v2 audit: release counters differ from expected: records %, foods %, review %, blocked %',
      v_release.record_count, v_release.canonical_food_count,
      v_release.review_case_count, v_release.blocked_match_count;
  end if;

  select count(*) into v_count from public.catalog_v2_source_records where release_id = v_release.id;
  if v_count <> 1242528 then raise exception 'canonical-v2 audit: source record count %, expected 1242528', v_count; end if;
  select count(*) into v_count from public.catalog_v2_source_mappings where release_id = v_release.id;
  if v_count <> 1242528 then raise exception 'canonical-v2 audit: source mapping count %, expected 1242528', v_count; end if;
  select count(*) into v_count from public.catalog_v2_canonical_foods where release_id = v_release.id;
  if v_count <> 1228891 then raise exception 'canonical-v2 audit: canonical food count %, expected 1228891', v_count; end if;
  select count(*) into v_count from public.catalog_v2_review_cases where release_id = v_release.id;
  if v_count <> 2469 then raise exception 'canonical-v2 audit: review count %, expected 2469', v_count; end if;
  select count(*) into v_count from public.catalog_v2_blocked_matches where release_id = v_release.id;
  if v_count <> 334 then raise exception 'canonical-v2 audit: blocked count %, expected 334', v_count; end if;

  with expected(source, expected_count) as (
    values
      ('usda_foundation'::text, 363::bigint),
      ('usda_fndds', 5432),
      ('usda_sr_legacy', 7793),
      ('usda_branded', 455458),
      ('turkomp', 645),
      ('open_food_facts', 772837)
  ), actual as (
    select source, count(*)::bigint as actual_count
    from public.catalog_v2_source_records
    where release_id = v_release.id
    group by source
  )
  select string_agg(format('%s expected=%s actual=%s', coalesce(e.source, a.source), e.expected_count, coalesce(a.actual_count, 0)), '; ' order by coalesce(e.source, a.source))
    into v_detail
  from expected e full join actual a using (source)
  where e.source is null or a.source is null or e.expected_count <> a.actual_count;
  if v_detail is not null then raise exception 'canonical-v2 audit: per-source counts mismatch: %', v_detail; end if;

  -- Every source record has exactly one reversible mapping.
  select count(*) into v_count
  from public.catalog_v2_source_records sr
  left join public.catalog_v2_source_mappings sm
    on sm.release_id = sr.release_id and sm.source_record_id = sr.id
  where sr.release_id = v_release.id and sm.id is null;
  if v_count <> 0 then raise exception 'canonical-v2 audit: % source records have no mapping', v_count; end if;

  -- The representative must be an accepted member of its canonical identity.
  select count(*) into v_count
  from public.catalog_v2_canonical_foods cf
  left join public.catalog_v2_source_mappings sm
    on sm.release_id = cf.release_id
   and sm.canonical_food_id = cf.id
   and sm.source_record_id = cf.representative_source_record_id
   and sm.mapping_status = 'accepted'
  where cf.release_id = v_release.id and sm.id is null;
  if v_count <> 0 then raise exception 'canonical-v2 audit: % canonical representatives are not accepted mappings', v_count; end if;

  -- Automatic mappings may never carry contradiction evidence.
  select count(*) into v_count
  from public.catalog_v2_source_mappings
  where release_id = v_release.id and is_automatic
    and (mapping_status <> 'accepted' or confidence not in ('VERY_HIGH', 'HIGH') or cardinality(contradiction_flags) <> 0);
  if v_count <> 0 then raise exception 'canonical-v2 audit: % unsafe automatic mappings', v_count; end if;

  -- Preferred nutrition is copied exactly from one explicit mapped source row.
  select count(*) into v_count
  from public.catalog_v2_food_nutrition fn
  join public.catalog_v2_source_nutrition sn
    on sn.release_id = fn.release_id and sn.id = fn.source_nutrition_id
  where fn.release_id = v_release.id
    and (fn.source_record_id <> sn.source_record_id
      or fn.kcal_100g is distinct from sn.kcal_100g
      or fn.protein_100g is distinct from sn.protein_100g
      or fn.carbs_100g is distinct from sn.carbs_100g
      or fn.fat_100g is distinct from sn.fat_100g
      or fn.fiber_100g is distinct from sn.fiber_100g
      or fn.sugars_100g is distinct from sn.sugars_100g
      or fn.sodium_mg_100g is distinct from sn.sodium_mg_100g);
  if v_count <> 0 then raise exception 'canonical-v2 audit: % preferred nutrition rows differ from source nutrition', v_count; end if;

  select count(*) into v_count
  from public.catalog_v2_food_nutrition fn
  left join public.catalog_v2_source_mappings sm
    on sm.release_id = fn.release_id
   and sm.canonical_food_id = fn.canonical_food_id
   and sm.source_record_id = fn.source_record_id
   and sm.mapping_status = 'accepted'
  where fn.release_id = v_release.id and sm.id is null;
  if v_count <> 0 then raise exception 'canonical-v2 audit: % preferred nutrition sources are not accepted members', v_count; end if;

  select count(*) into v_count
  from public.catalog_v2_canonical_foods cf
  where cf.release_id = v_release.id
    and exists (
      select 1 from public.catalog_v2_source_mappings sm
      join public.catalog_v2_source_nutrition sn
        on sn.release_id = sm.release_id and sn.source_record_id = sm.source_record_id
      where sm.release_id = cf.release_id and sm.canonical_food_id = cf.id and sm.mapping_status = 'accepted'
    )
    and not exists (
      select 1 from public.catalog_v2_food_nutrition fn
      where fn.release_id = cf.release_id and fn.canonical_food_id = cf.id
    );
  if v_count <> 0 then raise exception 'canonical-v2 audit: % foods with source nutrition lack preferred nutrition', v_count; end if;

  -- A must-not-merge pair may not be accepted into the same canonical food.
  select count(*) into v_count
  from public.catalog_v2_blocked_matches bm
  join public.catalog_v2_source_mappings lm
    on lm.release_id = bm.release_id and lm.source_record_id = bm.left_source_record_id and lm.mapping_status = 'accepted'
  join public.catalog_v2_source_mappings rm
    on rm.release_id = bm.release_id and rm.source_record_id = bm.right_source_record_id and rm.mapping_status = 'accepted'
  where bm.release_id = v_release.id and bm.status = 'active'
    and lm.canonical_food_id = rm.canonical_food_id;
  if v_count <> 0 then raise exception 'canonical-v2 audit: % active blocked pairs were merged', v_count; end if;

  select count(*) into v_count
  from public.catalog_v2_blocked_matches bm
  join public.catalog_v2_review_cases rc on rc.id = bm.review_case_id
  where bm.release_id = v_release.id and rc.release_id <> bm.release_id;
  if v_count <> 0 then raise exception 'canonical-v2 audit: % blocked matches reference a review case from another release', v_count; end if;

  select count(*) into v_count
  from public.catalog_v2_blocked_matches
  where release_id = v_release.id and status = 'active' and cardinality(reason_codes) = 0;
  if v_count <> 0 then raise exception 'canonical-v2 audit: % active blocked matches have no reason codes', v_count; end if;

  select count(*) into v_count
  from public.catalog_v2_review_cases
  where release_id = v_release.id and status in ('pending', 'in_review') and cardinality(reason_codes) = 0;
  if v_count <> 0 then raise exception 'canonical-v2 audit: % unresolved review cases have no reason codes', v_count; end if;
end
$audit$;

\echo '== Expected and actual counts by source =='
with release as (
  select id from public.catalog_v2_releases where catalog_version = current_setting('food_import.catalog_version')
), expected(source, expected_count) as (
  values
    ('usda_foundation'::text, 363::bigint), ('usda_fndds', 5432),
    ('usda_sr_legacy', 7793), ('usda_branded', 455458),
    ('turkomp', 645), ('open_food_facts', 772837)
), actual as (
  select sr.source, count(*)::bigint actual_count
  from public.catalog_v2_source_records sr join release r on r.id = sr.release_id
  group by sr.source
)
select e.source, e.expected_count, coalesce(a.actual_count, 0) actual_count,
  coalesce(a.actual_count, 0) - e.expected_count as delta
from expected e left join actual a using (source)
order by e.source;

\echo '== Missing, orphan and duplicate reference diagnostics (all hard counts should be zero) =='
with release as (
  select id from public.catalog_v2_releases where catalog_version = current_setting('food_import.catalog_version')
)
select diagnostic, issue_count
from (
  select 'source_records_without_mapping' diagnostic, count(*)::bigint issue_count
  from public.catalog_v2_source_records sr join release r on r.id = sr.release_id
  left join public.catalog_v2_source_mappings sm on sm.release_id = sr.release_id and sm.source_record_id = sr.id
  where sm.id is null
  union all
  select 'mappings_without_source_record', count(*)
  from public.catalog_v2_source_mappings sm join release r on r.id = sm.release_id
  left join public.catalog_v2_source_records sr on sr.release_id = sm.release_id and sr.id = sm.source_record_id
  where sr.id is null
  union all
  select 'mappings_without_canonical_food', count(*)
  from public.catalog_v2_source_mappings sm join release r on r.id = sm.release_id
  left join public.catalog_v2_canonical_foods cf on cf.release_id = sm.release_id and cf.id = sm.canonical_food_id
  where cf.id is null
  union all
  select 'canonical_foods_without_mapping', count(*)
  from public.catalog_v2_canonical_foods cf join release r on r.id = cf.release_id
  left join public.catalog_v2_source_mappings sm on sm.release_id = cf.release_id and sm.canonical_food_id = cf.id
  where sm.id is null
  union all
  select 'duplicate_source_identity_groups', count(*)
  from (
    select sr.source, sr.source_id
    from public.catalog_v2_source_records sr join release r on r.id = sr.release_id
    group by sr.source, sr.source_id having count(*) > 1
  ) duplicates
  union all
  select 'duplicate_mapping_source_groups', count(*)
  from (
    select sm.source_record_id
    from public.catalog_v2_source_mappings sm join release r on r.id = sm.release_id
    group by sm.source_record_id having count(*) > 1
  ) duplicates
  union all
  select 'duplicate_canonical_id_groups', count(*)
  from (
    select cf.canonical_id
    from public.catalog_v2_canonical_foods cf join release r on r.id = cf.release_id
    group by cf.canonical_id having count(*) > 1
  ) duplicates
) checks
order by diagnostic;

\echo '== Preferred nutrition coverage and provenance =='
with release as (
  select id from public.catalog_v2_releases where catalog_version = current_setting('food_import.catalog_version')
), coverage as (
  select
    count(*) as foods,
    count(fn.canonical_food_id) as with_preferred_nutrition,
    count(*) filter (where fn.kcal_100g is not null and fn.protein_100g is not null and fn.carbs_100g is not null and fn.fat_100g is not null) as complete_macros,
    count(*) filter (where fn.canonical_food_id is null) as missing_preferred_nutrition
  from public.catalog_v2_canonical_foods cf
  join release r on r.id = cf.release_id
  left join public.catalog_v2_food_nutrition fn on fn.release_id = cf.release_id and fn.canonical_food_id = cf.id
)
select *, round(100.0 * with_preferred_nutrition / nullif(foods, 0), 2) nutrition_coverage_pct,
  round(100.0 * complete_macros / nullif(foods, 0), 2) complete_macro_coverage_pct
from coverage;

select fn.selection_method, sr.source as selected_source, count(*) as foods
from public.catalog_v2_food_nutrition fn
join public.catalog_v2_releases r on r.id = fn.release_id
join public.catalog_v2_source_records sr on sr.release_id = fn.release_id and sr.id = fn.source_record_id
where r.catalog_version = current_setting('food_import.catalog_version')
group by fn.selection_method, sr.source
order by fn.selection_method, foods desc, sr.source;

\echo '== Alias, portion, barcode, brand, ingredients, TR and EN coverage =='
with release as (
  select id from public.catalog_v2_releases where catalog_version = current_setting('food_import.catalog_version')
), flags as (
  select cf.id,
    exists (select 1 from public.catalog_v2_aliases a where a.release_id = cf.release_id and a.canonical_food_id = cf.id) has_alias,
    exists (select 1 from public.catalog_v2_aliases a where a.release_id = cf.release_id and a.canonical_food_id = cf.id and a.locale in ('tr', 'tr-TR')) has_tr_alias,
    exists (select 1 from public.catalog_v2_aliases a where a.release_id = cf.release_id and a.canonical_food_id = cf.id and a.locale in ('en', 'en-US')) has_en_alias,
    exists (select 1 from public.catalog_v2_portions p where p.release_id = cf.release_id and p.canonical_food_id = cf.id) has_portion,
    exists (select 1 from public.catalog_v2_portions p where p.release_id = cf.release_id and p.canonical_food_id = cf.id and p.is_default) has_default_portion,
    exists (select 1 from public.catalog_v2_branded_metadata b where b.release_id = cf.release_id and b.canonical_food_id = cf.id and b.barcode_valid) has_valid_barcode,
    exists (select 1 from public.catalog_v2_branded_metadata b where b.release_id = cf.release_id and b.canonical_food_id = cf.id and nullif(btrim(b.brand), '') is not null) has_brand,
    exists (select 1 from public.catalog_v2_branded_metadata b where b.release_id = cf.release_id and b.canonical_food_id = cf.id and nullif(btrim(b.ingredients), '') is not null) has_ingredients,
    (cf.canonical_name_tr is not null or exists (select 1 from public.catalog_v2_aliases a where a.release_id = cf.release_id and a.canonical_food_id = cf.id and a.locale in ('tr', 'tr-TR'))
      or exists (select 1 from public.catalog_v2_branded_metadata b where b.release_id = cf.release_id and b.canonical_food_id = cf.id and b.detected_languages && array['tr'])) has_tr,
    (cf.canonical_name_en is not null or exists (select 1 from public.catalog_v2_aliases a where a.release_id = cf.release_id and a.canonical_food_id = cf.id and a.locale in ('en', 'en-US'))
      or exists (select 1 from public.catalog_v2_branded_metadata b where b.release_id = cf.release_id and b.canonical_food_id = cf.id and b.detected_languages && array['en'])) has_en,
    cf.food_type
  from public.catalog_v2_canonical_foods cf join release r on r.id = cf.release_id
)
select food_type, count(*) foods,
  count(*) filter (where has_alias) aliases,
  count(*) filter (where has_portion) portions,
  count(*) filter (where has_default_portion) default_portions,
  count(*) filter (where has_valid_barcode) valid_barcodes,
  count(*) filter (where has_brand) brands,
  count(*) filter (where has_ingredients) ingredients,
  count(*) filter (where has_tr) tr_coverage,
  count(*) filter (where has_en) en_coverage,
  round(100.0 * count(*) filter (where has_alias) / nullif(count(*), 0), 2) alias_pct,
  round(100.0 * count(*) filter (where has_portion) / nullif(count(*), 0), 2) portion_pct,
  round(100.0 * count(*) filter (where has_valid_barcode) / nullif(count(*), 0), 2) barcode_pct
from flags
group by rollup(food_type)
order by food_type nulls last;

\echo '== Diagnostic duplicate aliases and portions after normalization =='
select cf.canonical_id, a.locale, a.normalized_alias, count(*) duplicate_rows
from public.catalog_v2_aliases a
join public.catalog_v2_releases r on r.id = a.release_id
join public.catalog_v2_canonical_foods cf on cf.release_id = a.release_id and cf.id = a.canonical_food_id
where r.catalog_version = current_setting('food_import.catalog_version')
group by cf.canonical_id, a.locale, a.normalized_alias
having count(*) > 1
order by duplicate_rows desc, cf.canonical_id, a.locale, a.normalized_alias
limit 100;

select cf.canonical_id, p.locale, p.normalized_label, p.gram_weight, count(*) duplicate_rows
from public.catalog_v2_portions p
join public.catalog_v2_releases r on r.id = p.release_id
join public.catalog_v2_canonical_foods cf on cf.release_id = p.release_id and cf.id = p.canonical_food_id
where r.catalog_version = current_setting('food_import.catalog_version')
group by cf.canonical_id, p.locale, p.normalized_label, p.gram_weight
having count(*) > 1
order by duplicate_rows desc, cf.canonical_id, p.locale, p.normalized_label
limit 100;

\echo '== Barcode collision diagnostics (separation may be intentional when blocked) =='
select b.barcode,
  count(distinct b.canonical_food_id) canonical_foods,
  count(distinct b.id) source_rows,
  array_agg(distinct cf.canonical_id order by cf.canonical_id) canonical_ids,
  bool_or(bm.id is not null) has_active_block_evidence
from public.catalog_v2_branded_metadata b
join public.catalog_v2_releases r on r.id = b.release_id
join public.catalog_v2_canonical_foods cf on cf.release_id = b.release_id and cf.id = b.canonical_food_id
left join public.catalog_v2_blocked_matches bm on bm.release_id = b.release_id and bm.status = 'active'
  and (bm.left_source_record_id = b.source_record_id or bm.right_source_record_id = b.source_record_id)
where r.catalog_version = current_setting('food_import.catalog_version') and b.barcode_valid
group by b.barcode
having count(distinct b.canonical_food_id) > 1
order by canonical_foods desc, source_rows desc, b.barcode
limit 100;

\echo '== Review and blocked-match integrity summaries =='
select rc.status, rc.severity, rc.case_type, count(*) cases
from public.catalog_v2_review_cases rc join public.catalog_v2_releases r on r.id = rc.release_id
where r.catalog_version = current_setting('food_import.catalog_version')
group by rc.status, rc.severity, rc.case_type
order by rc.status, rc.severity desc, rc.case_type;

select bm.status, bm.block_type, count(*) matches,
  count(*) filter (where bm.review_case_id is not null) linked_review_cases,
  count(*) filter (where cardinality(bm.reason_codes) = 0) missing_reasons
from public.catalog_v2_blocked_matches bm join public.catalog_v2_releases r on r.id = bm.release_id
where r.catalog_version = current_setting('food_import.catalog_version')
group by bm.status, bm.block_type
order by bm.status, matches desc, bm.block_type;

\echo '== Sanity lookups: bilingual generic foods =='
select cf.canonical_id, cf.food_type, cf.canonical_name, cf.canonical_name_tr, cf.canonical_name_en,
  cf.preparation, cf.status, cf.confidence,
  array_agg(distinct sr.source order by sr.source) sources,
  count(distinct sm.source_record_id) source_records
from public.catalog_v2_canonical_foods cf
join public.catalog_v2_releases r on r.id = cf.release_id
join public.catalog_v2_source_mappings sm on sm.release_id = cf.release_id and sm.canonical_food_id = cf.id
join public.catalog_v2_source_records sr on sr.release_id = sm.release_id and sr.id = sm.source_record_id
where r.catalog_version = current_setting('food_import.catalog_version')
  and (cf.canonical_name ilike any (array['%egg%', '%yumurta%', '%yogurt%', '%yoğurt%', '%rice%', '%pirinç%', '%bread%', '%ekmek%', '%banana%', '%muz%', '%olive oil%', '%zeytinyağı%'])
    or cf.canonical_name_tr ilike any (array['%yumurta%', '%yoğurt%', '%pirinç%', '%ekmek%', '%muz%', '%zeytinyağı%'])
    or cf.canonical_name_en ilike any (array['%egg%', '%yogurt%', '%rice%', '%bread%', '%banana%', '%olive oil%']))
group by cf.id
order by count(distinct sm.source_record_id) desc, cf.canonical_name
limit 100;

\echo '== Sanity lookups: high-quality branded products and exact barcode trace =='
select cf.canonical_id, cf.canonical_name, b.brand, b.barcode, b.barcode_kind,
  b.data_quality_score, b.turkey_relevance_score, b.english_relevance_score,
  sr.source, sr.source_id, fn.kcal_100g, fn.protein_100g, fn.carbs_100g, fn.fat_100g
from public.catalog_v2_branded_metadata b
join public.catalog_v2_releases r on r.id = b.release_id
join public.catalog_v2_canonical_foods cf on cf.release_id = b.release_id and cf.id = b.canonical_food_id
join public.catalog_v2_source_records sr on sr.release_id = b.release_id and sr.id = b.source_record_id
left join public.catalog_v2_food_nutrition fn on fn.release_id = cf.release_id and fn.canonical_food_id = cf.id
where r.catalog_version = current_setting('food_import.catalog_version')
  and b.barcode_valid and coalesce(b.data_quality_score, 0) >= 80
order by b.turkey_relevance_score desc nulls last, b.english_relevance_score desc nulls last,
  b.data_quality_score desc, b.barcode, sr.source, sr.source_id
limit 100;

rollback;
