-- Canonical catalog v2: additive, versioned and reversible.
--
-- This schema intentionally does not alter public.foods, public.food_aliases,
-- public.food_portions or any meal/analysis table. A release can be fully
-- loaded and validated here before a later, explicit application cutover.

create table public.catalog_v2_releases (
  id uuid primary key default extensions.gen_random_uuid(),
  catalog_version text not null unique check (catalog_version ~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$'),
  normalization_version text not null,
  cleaning_version text not null,
  canonicalization_version text not null,
  generic_identity_ontology_version text not null,
  status text not null default 'staged'
    check (status in ('staged', 'loading', 'validating', 'validated', 'publishing', 'published', 'failed', 'retired')),
  quality_threshold numeric(5, 2) check (quality_threshold is null or quality_threshold between 0 and 100),
  source_manifest jsonb not null default '{}'::jsonb check (jsonb_typeof(source_manifest) = 'object'),
  metrics jsonb not null default '{}'::jsonb check (jsonb_typeof(metrics) = 'object'),
  record_count bigint not null default 0 check (record_count >= 0),
  canonical_food_count bigint not null default 0 check (canonical_food_count >= 0),
  review_case_count bigint not null default 0 check (review_case_count >= 0),
  blocked_match_count bigint not null default 0 check (blocked_match_count >= 0),
  input_checksum_sha256 text check (input_checksum_sha256 is null or input_checksum_sha256 ~ '^[0-9a-f]{64}$'),
  output_checksum_sha256 text check (output_checksum_sha256 is null or output_checksum_sha256 ~ '^[0-9a-f]{64}$'),
  failure_detail text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  validated_at timestamptz,
  published_at timestamptz,
  retired_at timestamptz,
  check (published_at is null or validated_at is not null),
  check (retired_at is null or published_at is not null),
  check (status not in ('validated', 'publishing', 'published', 'retired') or validated_at is not null),
  check (status not in ('published', 'retired') or published_at is not null),
  check (status <> 'retired' or retired_at is not null),
  check (status <> 'failed' or nullif(btrim(failure_detail), '') is not null)
);

create table public.catalog_v2_source_records (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references public.catalog_v2_releases (id) on delete cascade,
  source text not null check (source in ('usda_foundation', 'usda_fndds', 'usda_sr_legacy', 'usda_branded', 'turkomp', 'open_food_facts')),
  source_id text not null check (nullif(btrim(source_id), '') is not null),
  dataset_version text not null check (nullif(btrim(dataset_version), '') is not null),
  source_record_ordinal bigint not null check (source_record_ordinal > 0),
  record_hash_sha256 text not null check (record_hash_sha256 ~ '^[0-9a-f]{64}$'),
  original_name text not null check (nullif(btrim(original_name), '') is not null),
  display_name text not null check (nullif(btrim(display_name), '') is not null),
  normalized_name text not null check (nullif(btrim(normalized_name), '') is not null),
  category text,
  locale text,
  food_type text not null check (food_type in ('generic_food', 'branded_product')),
  validation_status text not null default 'valid' check (validation_status in ('valid', 'warning', 'invalid', 'excluded')),
  data_quality_score numeric(5, 2) check (data_quality_score is null or data_quality_score between 0 and 100),
  cleaning_flags text[] not null default '{}',
  provenance jsonb not null default '{}'::jsonb check (jsonb_typeof(provenance) = 'object'),
  normalized_payload jsonb check (normalized_payload is null or jsonb_typeof(normalized_payload) = 'object'),
  created_at timestamptz not null default now(),
  unique (release_id, source, source_id, source_record_ordinal),
  unique (release_id, source, source_record_ordinal),
  unique (release_id, id)
);

create table public.catalog_v2_canonical_foods (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references public.catalog_v2_releases (id) on delete cascade,
  canonical_id text not null check (canonical_id ~ '^cf2_[0-9a-f]{24}$'),
  canonical_key text not null check (nullif(btrim(canonical_key), '') is not null),
  food_type text not null check (food_type in ('generic_food', 'branded_product')),
  canonical_name text not null check (nullif(btrim(canonical_name), '') is not null),
  canonical_name_tr text,
  canonical_name_en text,
  category text,
  preparation text,
  qualifier_identity jsonb not null default '{}'::jsonb check (jsonb_typeof(qualifier_identity) = 'object'),
  status text not null default 'candidate' check (status in ('candidate', 'active', 'review', 'blocked', 'superseded')),
  confidence text not null check (confidence in ('VERY_HIGH', 'HIGH', 'MEDIUM', 'AMBIGUOUS')),
  representative_source_record_id uuid,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (release_id, canonical_id),
  unique (release_id, id),
  foreign key (release_id, representative_source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade
);

create table public.catalog_v2_source_mappings (
  id bigint generated always as identity primary key,
  release_id uuid not null references public.catalog_v2_releases (id) on delete cascade,
  canonical_food_id uuid not null,
  source_record_id uuid not null,
  match_method text not null check (nullif(btrim(match_method), '') is not null),
  confidence text not null check (confidence in ('VERY_HIGH', 'HIGH', 'MEDIUM', 'AMBIGUOUS')),
  mapping_status text not null default 'accepted' check (mapping_status in ('accepted', 'review', 'blocked', 'rejected')),
  identity_ontology_version text not null,
  match_reasons text[] not null default '{}',
  contradiction_flags text[] not null default '{}',
  nutrition_similarity numeric(6, 5) check (nutrition_similarity is null or nutrition_similarity between 0 and 1),
  category_compatibility text check (category_compatibility is null or category_compatibility in ('compatible', 'incompatible', 'unknown')),
  is_automatic boolean not null default false,
  created_at timestamptz not null default now(),
  unique (release_id, source_record_id),
  unique (release_id, canonical_food_id, source_record_id),
  foreign key (release_id, canonical_food_id)
    references public.catalog_v2_canonical_foods (release_id, id) on delete cascade,
  foreign key (release_id, source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade,
  check (not is_automatic or (mapping_status = 'accepted' and confidence in ('VERY_HIGH', 'HIGH') and cardinality(contradiction_flags) = 0))
);

-- Source nutrition is immutable provenance. Canonical nutrition below is an
-- explicit representative snapshot; values are never averaged during import.
create table public.catalog_v2_source_nutrition (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references public.catalog_v2_releases (id) on delete cascade,
  source_record_id uuid not null,
  kcal_100g numeric(14, 5) check (kcal_100g is null or kcal_100g >= 0),
  protein_100g numeric(14, 5) check (protein_100g is null or protein_100g >= 0),
  carbs_100g numeric(14, 5) check (carbs_100g is null or carbs_100g >= 0),
  fat_100g numeric(14, 5) check (fat_100g is null or fat_100g >= 0),
  fiber_100g numeric(14, 5) check (fiber_100g is null or fiber_100g >= 0),
  sugars_100g numeric(14, 5) check (sugars_100g is null or sugars_100g >= 0),
  sodium_mg_100g numeric(16, 5) check (sodium_mg_100g is null or sodium_mg_100g >= 0),
  nutrient_count integer not null default 0 check (nutrient_count >= 0),
  derivation_code text,
  measurement_type text,
  data_points integer check (data_points is null or data_points >= 0),
  min_values jsonb not null default '{}'::jsonb check (jsonb_typeof(min_values) = 'object'),
  max_values jsonb not null default '{}'::jsonb check (jsonb_typeof(max_values) = 'object'),
  median_values jsonb not null default '{}'::jsonb check (jsonb_typeof(median_values) = 'object'),
  extra_nutrients jsonb not null default '{}'::jsonb check (jsonb_typeof(extra_nutrients) = 'object'),
  provenance jsonb not null default '{}'::jsonb check (jsonb_typeof(provenance) = 'object'),
  created_at timestamptz not null default now(),
  unique (release_id, source_record_id),
  unique (release_id, id),
  foreign key (release_id, source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade,
  check (num_nonnulls(kcal_100g, protein_100g, carbs_100g, fat_100g, fiber_100g, sugars_100g, sodium_mg_100g) > 0)
);

create table public.catalog_v2_food_nutrition (
  canonical_food_id uuid primary key,
  release_id uuid not null references public.catalog_v2_releases (id) on delete cascade,
  source_record_id uuid not null,
  source_nutrition_id uuid not null,
  kcal_100g numeric(14, 5) check (kcal_100g is null or kcal_100g >= 0),
  protein_100g numeric(14, 5) check (protein_100g is null or protein_100g >= 0),
  carbs_100g numeric(14, 5) check (carbs_100g is null or carbs_100g >= 0),
  fat_100g numeric(14, 5) check (fat_100g is null or fat_100g >= 0),
  fiber_100g numeric(14, 5) check (fiber_100g is null or fiber_100g >= 0),
  sugars_100g numeric(14, 5) check (sugars_100g is null or sugars_100g >= 0),
  sodium_mg_100g numeric(16, 5) check (sodium_mg_100g is null or sodium_mg_100g >= 0),
  selection_method text not null default 'representative_source_record'
    check (selection_method in ('representative_source_record', 'reviewed_source_record')),
  selection_score numeric,
  selection_reasons text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (release_id, canonical_food_id),
  foreign key (release_id, canonical_food_id)
    references public.catalog_v2_canonical_foods (release_id, id) on delete cascade,
  foreign key (release_id, source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade,
  foreign key (release_id, source_nutrition_id)
    references public.catalog_v2_source_nutrition (release_id, id) on delete cascade,
  check (num_nonnulls(kcal_100g, protein_100g, carbs_100g, fat_100g, fiber_100g, sugars_100g, sodium_mg_100g) > 0)
);

create table public.catalog_v2_portions (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references public.catalog_v2_releases (id) on delete cascade,
  canonical_food_id uuid not null,
  source_record_id uuid,
  description text not null check (nullif(btrim(description), '') is not null),
  normalized_label text not null check (nullif(btrim(normalized_label), '') is not null),
  amount numeric(12, 5) check (amount is null or amount > 0),
  unit text,
  gram_weight numeric(12, 5) not null check (gram_weight > 0 and gram_weight <= 10000),
  household_serving_description text,
  locale text,
  resolution_method text,
  confidence numeric(6, 5) check (confidence is null or confidence between 0 and 1),
  is_default boolean not null default false,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  foreign key (release_id, canonical_food_id)
    references public.catalog_v2_canonical_foods (release_id, id) on delete cascade,
  foreign key (release_id, source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade
);

create table public.catalog_v2_aliases (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references public.catalog_v2_releases (id) on delete cascade,
  canonical_food_id uuid not null,
  source_record_id uuid,
  alias extensions.citext not null,
  normalized_alias text not null check (nullif(btrim(normalized_alias), '') is not null),
  locale text,
  alias_type text not null default 'source_name'
    check (alias_type in ('canonical_name', 'source_name', 'translation', 'additional_description', 'search_alias', 'brand_name')),
  priority smallint not null default 0 check (priority between -100 and 100),
  is_preferred boolean not null default false,
  created_at timestamptz not null default now(),
  foreign key (release_id, canonical_food_id)
    references public.catalog_v2_canonical_foods (release_id, id) on delete cascade,
  foreign key (release_id, source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade
);

-- One row per branded source record: source brand/ingredients are preserved and
-- are not overwritten by another record sharing a canonical product.
create table public.catalog_v2_branded_metadata (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references public.catalog_v2_releases (id) on delete cascade,
  canonical_food_id uuid not null,
  source_record_id uuid not null,
  brand text,
  normalized_brand text,
  barcode text,
  barcode_valid boolean not null default false,
  barcode_kind text check (barcode_kind is null or barcode_kind in ('gtin_8', 'upc_a', 'ean_13', 'gtin_14', 'retailer_internal', 'invalid')),
  ingredients text,
  detected_languages text[] not null default '{}',
  market_country_tags text[] not null default '{}',
  category_tags text[] not null default '{}',
  data_quality_score numeric(5, 2) check (data_quality_score is null or data_quality_score between 0 and 100),
  turkey_relevance_score numeric(5, 2) check (turkey_relevance_score is null or turkey_relevance_score between 0 and 100),
  english_relevance_score numeric(5, 2) check (english_relevance_score is null or english_relevance_score between 0 and 100),
  inclusion_reasons text[] not null default '{}',
  source_quality_flags text[] not null default '{}',
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  unique (release_id, source_record_id),
  foreign key (release_id, canonical_food_id)
    references public.catalog_v2_canonical_foods (release_id, id) on delete cascade,
  foreign key (release_id, source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade,
  check (barcode_valid = false or (barcode ~ '^[0-9]{8,14}$' and barcode_kind in ('gtin_8', 'upc_a', 'ean_13', 'gtin_14')))
);

create table public.catalog_v2_review_cases (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references public.catalog_v2_releases (id) on delete cascade,
  case_type text not null check (case_type in ('generic_pair', 'barcode_group', 'source_record', 'canonical_food', 'mapping')),
  severity text not null default 'medium' check (severity in ('low', 'medium', 'high', 'critical')),
  status text not null default 'pending'
    check (status in ('pending', 'in_review', 'resolved_merge', 'resolved_separate', 'dismissed')),
  canonical_food_id uuid,
  left_source_record_id uuid,
  right_source_record_id uuid,
  identity_key text,
  reason_codes text[] not null default '{}',
  evidence jsonb not null default '{}'::jsonb check (jsonb_typeof(evidence) = 'object'),
  resolution jsonb check (resolution is null or jsonb_typeof(resolution) = 'object'),
  assigned_to uuid references auth.users (id) on delete set null,
  resolved_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz,
  foreign key (release_id, canonical_food_id)
    references public.catalog_v2_canonical_foods (release_id, id) on delete cascade,
  foreign key (release_id, left_source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade,
  foreign key (release_id, right_source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade,
  check (canonical_food_id is not null or left_source_record_id is not null),
  check (left_source_record_id is null or right_source_record_id is null or left_source_record_id <> right_source_record_id),
  check ((status in ('resolved_merge', 'resolved_separate', 'dismissed')) = (resolved_at is not null)),
  check (resolved_at is null or resolved_by is not null)
);

create table public.catalog_v2_blocked_matches (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references public.catalog_v2_releases (id) on delete cascade,
  left_source_record_id uuid not null,
  right_source_record_id uuid not null,
  review_case_id uuid,
  block_type text not null check (block_type in ('barcode_contradiction', 'qualifier_conflict', 'category_conflict', 'nutrition_conflict', 'same_source', 'invalid_identity', 'manual', 'other')),
  status text not null default 'active' check (status in ('active', 'overridden', 'expired')),
  identity_key text,
  reason_codes text[] not null default '{}',
  evidence jsonb not null default '{}'::jsonb check (jsonb_typeof(evidence) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  overridden_at timestamptz,
  overridden_by uuid references auth.users (id) on delete set null,
  override_reason text,
  foreign key (release_id, left_source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade,
  foreign key (release_id, right_source_record_id)
    references public.catalog_v2_source_records (release_id, id) on delete cascade,
  foreign key (review_case_id) references public.catalog_v2_review_cases (id) on delete set null,
  check (left_source_record_id <> right_source_record_id),
  check ((status = 'overridden') = (overridden_at is not null)),
  check (overridden_at is null or (overridden_by is not null and nullif(btrim(override_reason), '') is not null))
);

-- Release lifecycle and deterministic/idempotent import indexes.
create unique index catalog_v2_one_published_release_idx
  on public.catalog_v2_releases ((status)) where status = 'published';
create index catalog_v2_releases_status_idx
  on public.catalog_v2_releases (status, created_at desc);
create index catalog_v2_source_records_name_idx
  on public.catalog_v2_source_records (release_id, source, normalized_name);
create index catalog_v2_source_records_hash_idx
  on public.catalog_v2_source_records (release_id, record_hash_sha256);
create index catalog_v2_source_records_quality_idx
  on public.catalog_v2_source_records (release_id, validation_status, data_quality_score desc);
create index catalog_v2_canonical_foods_catalog_idx
  on public.catalog_v2_canonical_foods (release_id, status, food_type, category);
create index catalog_v2_canonical_foods_name_idx
  on public.catalog_v2_canonical_foods (release_id, canonical_name);
create index catalog_v2_canonical_foods_key_idx
  on public.catalog_v2_canonical_foods (release_id, canonical_key);
create index catalog_v2_source_mappings_food_idx
  on public.catalog_v2_source_mappings (release_id, canonical_food_id, mapping_status);
create index catalog_v2_source_mappings_method_idx
  on public.catalog_v2_source_mappings (release_id, match_method, confidence);
create index catalog_v2_portions_food_idx
  on public.catalog_v2_portions (release_id, canonical_food_id, locale, gram_weight);
create unique index catalog_v2_portions_identity_idx
  on public.catalog_v2_portions (release_id, canonical_food_id, coalesce(source_record_id, '00000000-0000-0000-0000-000000000000'::uuid), normalized_label, gram_weight);
create unique index catalog_v2_portions_one_default_idx
  on public.catalog_v2_portions (release_id, canonical_food_id, coalesce(locale, '')) where is_default;
create index catalog_v2_aliases_lookup_idx
  on public.catalog_v2_aliases (release_id, locale, normalized_alias, priority desc);
create index catalog_v2_aliases_trgm_idx
  on public.catalog_v2_aliases using gin (normalized_alias extensions.gin_trgm_ops);
create index catalog_v2_canonical_name_trgm_idx
  on public.catalog_v2_canonical_foods using gin ((canonical_name::text) extensions.gin_trgm_ops);
create unique index catalog_v2_aliases_identity_idx
  on public.catalog_v2_aliases (release_id, canonical_food_id, coalesce(source_record_id, '00000000-0000-0000-0000-000000000000'::uuid), coalesce(locale, ''), normalized_alias, alias_type);
create index catalog_v2_branded_barcode_idx
  on public.catalog_v2_branded_metadata (release_id, barcode) where barcode_valid;
create index catalog_v2_branded_brand_idx
  on public.catalog_v2_branded_metadata (release_id, normalized_brand) where normalized_brand is not null;
create index catalog_v2_review_queue_idx
  on public.catalog_v2_review_cases (release_id, status, severity, created_at);
create unique index catalog_v2_blocked_pair_idx
  on public.catalog_v2_blocked_matches (
    release_id,
    least(left_source_record_id, right_source_record_id),
    greatest(left_source_record_id, right_source_record_id),
    block_type
  ) where status = 'active';
create index catalog_v2_blocked_status_idx
  on public.catalog_v2_blocked_matches (release_id, status, block_type);

create trigger catalog_v2_releases_set_updated_at
before update on public.catalog_v2_releases
for each row execute function public.set_updated_at();
create trigger catalog_v2_canonical_foods_set_updated_at
before update on public.catalog_v2_canonical_foods
for each row execute function public.set_updated_at();
create trigger catalog_v2_food_nutrition_set_updated_at
before update on public.catalog_v2_food_nutrition
for each row execute function public.set_updated_at();
create trigger catalog_v2_review_cases_set_updated_at
before update on public.catalog_v2_review_cases
for each row execute function public.set_updated_at();
create trigger catalog_v2_blocked_matches_set_updated_at
before update on public.catalog_v2_blocked_matches
for each row execute function public.set_updated_at();

alter table public.catalog_v2_releases enable row level security;
alter table public.catalog_v2_source_records enable row level security;
alter table public.catalog_v2_canonical_foods enable row level security;
alter table public.catalog_v2_source_mappings enable row level security;
alter table public.catalog_v2_source_nutrition enable row level security;
alter table public.catalog_v2_food_nutrition enable row level security;
alter table public.catalog_v2_portions enable row level security;
alter table public.catalog_v2_aliases enable row level security;
alter table public.catalog_v2_branded_metadata enable row level security;
alter table public.catalog_v2_review_cases enable row level security;
alter table public.catalog_v2_blocked_matches enable row level security;

-- Authenticated clients may only read the active surface of the published v2
-- release. Source payloads, mappings, validation/review and block evidence stay
-- service-role-only.
create policy "catalog v2 read published release"
  on public.catalog_v2_releases for select to authenticated
  using (status = 'published');
create policy "catalog v2 read active foods"
  on public.catalog_v2_canonical_foods for select to authenticated
  using (
    status = 'active' and exists (
      select 1 from public.catalog_v2_releases r
      where r.id = catalog_v2_canonical_foods.release_id and r.status = 'published'
    )
  );
create policy "catalog v2 read active nutrition"
  on public.catalog_v2_food_nutrition for select to authenticated
  using (exists (
    select 1
    from public.catalog_v2_canonical_foods food
    join public.catalog_v2_releases r on r.id = food.release_id
    where food.id = canonical_food_id and food.status = 'active' and r.status = 'published'
  ));
create policy "catalog v2 read active portions"
  on public.catalog_v2_portions for select to authenticated
  using (exists (
    select 1
    from public.catalog_v2_canonical_foods food
    join public.catalog_v2_releases r on r.id = food.release_id
    where food.id = canonical_food_id and food.status = 'active' and r.status = 'published'
  ));
create policy "catalog v2 read active aliases"
  on public.catalog_v2_aliases for select to authenticated
  using (exists (
    select 1
    from public.catalog_v2_canonical_foods food
    join public.catalog_v2_releases r on r.id = food.release_id
    where food.id = canonical_food_id and food.status = 'active' and r.status = 'published'
  ));
create policy "catalog v2 read active branded metadata"
  on public.catalog_v2_branded_metadata for select to authenticated
  using (exists (
    select 1
    from public.catalog_v2_canonical_foods food
    join public.catalog_v2_releases r on r.id = food.release_id
    where food.id = canonical_food_id and food.status = 'active' and r.status = 'published'
  ));

revoke all on table
  public.catalog_v2_releases,
  public.catalog_v2_source_records,
  public.catalog_v2_canonical_foods,
  public.catalog_v2_source_mappings,
  public.catalog_v2_source_nutrition,
  public.catalog_v2_food_nutrition,
  public.catalog_v2_portions,
  public.catalog_v2_aliases,
  public.catalog_v2_branded_metadata,
  public.catalog_v2_review_cases,
  public.catalog_v2_blocked_matches
from public, anon, authenticated;

grant select on table
  public.catalog_v2_releases,
  public.catalog_v2_canonical_foods,
  public.catalog_v2_food_nutrition,
  public.catalog_v2_portions,
  public.catalog_v2_aliases,
  public.catalog_v2_branded_metadata
to authenticated;

create or replace function public.normalize_catalog_v2_search_text(value text)
returns text
language sql
immutable
strict
set search_path = ''
as $$
  select pg_catalog.btrim(pg_catalog.regexp_replace(
    pg_catalog.lower(pg_catalog.translate(value, 'ÇĞİÖŞÜIçğıöşü', 'CGIOSUIcgiosu')),
    '[^a-z0-9]+', ' ', 'g'
  ));
$$;

-- Compatibility/query layer for a later resolver cutover. The current
-- public.foods hot path is intentionally untouched. Only published, active,
-- nutrition-complete foods with a real positive-gram portion are exposed.
create view public.catalog_v2_resolver_foods
with (security_invoker = true)
as
select
  food.id,
  food.canonical_id,
  food.canonical_name,
  food.canonical_name_tr,
  food.canonical_name_en,
  food.food_type,
  food.category,
  nutrition.kcal_100g as calories_per_100g,
  nutrition.protein_100g as protein_per_100g,
  nutrition.carbs_100g as carbs_per_100g,
  nutrition.fat_100g as fat_per_100g,
  nutrition.source_record_id as nutrition_source_record_id,
  food.release_id
from public.catalog_v2_canonical_foods food
join public.catalog_v2_releases release on release.id = food.release_id
join public.catalog_v2_food_nutrition nutrition
  on nutrition.release_id = food.release_id and nutrition.canonical_food_id = food.id
where release.status = 'published'
  and food.status = 'active'
  and num_nonnulls(nutrition.kcal_100g, nutrition.protein_100g, nutrition.carbs_100g, nutrition.fat_100g) = 4
  and exists (
    select 1 from public.catalog_v2_aliases alias
    where alias.release_id = food.release_id and alias.canonical_food_id = food.id
  )
  and exists (
    select 1 from public.catalog_v2_portions portion
    where portion.release_id = food.release_id and portion.canonical_food_id = food.id and portion.gram_weight > 0
  );

create or replace function public.search_catalog_v2_lexical(
  p_query text,
  p_locale text default 'tr-TR',
  p_limit integer default 20
)
returns table (
  canonical_food_id uuid,
  canonical_id text,
  display_name text,
  matched_alias text,
  match_method text,
  score numeric,
  default_grams numeric,
  default_portion_label text,
  calories_per_100g numeric,
  protein_per_100g numeric,
  carbs_per_100g numeric,
  fat_per_100g numeric,
  nutrition_source_record_id uuid
)
language sql
stable
set search_path = ''
as $$
  with ranked as (
    select
      food.*,
      alias.alias::text as matched_alias,
      case when alias.normalized_alias = public.normalize_catalog_v2_search_text(p_query)
        then 'exact_alias' else 'trigram' end as method,
      case when alias.normalized_alias = public.normalize_catalog_v2_search_text(p_query)
        then 1::numeric
        else extensions.similarity(alias.normalized_alias, public.normalize_catalog_v2_search_text(p_query))::numeric
      end as lexical_score
    from public.catalog_v2_resolver_foods food
    join public.catalog_v2_aliases alias
      on alias.release_id = food.release_id and alias.canonical_food_id = food.id
    where (alias.locale = p_locale or alias.locale is null)
      and (
        alias.normalized_alias = public.normalize_catalog_v2_search_text(p_query)
        or alias.normalized_alias operator(extensions.%) public.normalize_catalog_v2_search_text(p_query)
      )
  )
  select
    ranked.id,
    ranked.canonical_id,
    ranked.canonical_name,
    ranked.matched_alias,
    ranked.method,
    ranked.lexical_score,
    portion.gram_weight,
    portion.description,
    ranked.calories_per_100g,
    ranked.protein_per_100g,
    ranked.carbs_per_100g,
    ranked.fat_per_100g,
    ranked.nutrition_source_record_id
  from ranked
  join lateral (
    select p.gram_weight, p.description
    from public.catalog_v2_portions p
    where p.release_id = ranked.release_id and p.canonical_food_id = ranked.id
    order by (p.locale = p_locale) desc, p.is_default desc, p.gram_weight, p.id
    limit 1
  ) portion on true
  order by ranked.lexical_score desc, ranked.canonical_name, ranked.id
  limit least(50, greatest(1, p_limit));
$$;

grant select on public.catalog_v2_resolver_foods to authenticated;
revoke all on function public.normalize_catalog_v2_search_text(text) from public, anon;
grant execute on function public.normalize_catalog_v2_search_text(text) to authenticated;
revoke all on function public.search_catalog_v2_lexical(text, text, integer) from public, anon;
grant execute on function public.search_catalog_v2_lexical(text, text, integer) to authenticated;

comment on table public.catalog_v2_releases is
  'Immutable catalog release boundary. At most one release is published; old releases remain retired and reproducible.';
comment on table public.catalog_v2_source_records is
  'Lossless normalized source identities and provenance. Rows are never overwritten by canonical values.';
comment on table public.catalog_v2_source_mappings is
  'Reversible source-to-canonical decisions with version, confidence, reasons and contradiction evidence.';
comment on table public.catalog_v2_source_nutrition is
  'Per-source nutrition and derivation metadata, retained without cross-source averaging.';
comment on table public.catalog_v2_food_nutrition is
  'Hot-path canonical nutrition snapshot selected from one explicit source record.';
comment on table public.catalog_v2_review_cases is
  'Human-review lifecycle for unresolved generic, barcode, mapping or record-quality decisions.';
comment on table public.catalog_v2_blocked_matches is
  'Deterministic must-not-merge evidence, including barcode contradictions and explicit qualifier conflicts.';
