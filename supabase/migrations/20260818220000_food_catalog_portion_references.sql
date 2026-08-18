-- Accuracy-first food catalog expansion.
-- One food can have many household portions and each portion can carry a
-- reviewed visual reference. Nutrition remains normalized per 100 g.

alter table public.food_portions
  add column if not exists size_class text,
  add column if not exists household_measure text,
  add column if not exists reference_image_path text,
  add column if not exists visual_status text not null default 'missing',
  add column if not exists visual_source text,
  add column if not exists visual_license text,
  add column if not exists visual_attribution text,
  add column if not exists reviewed_at timestamptz;

alter table public.food_portions
  drop constraint if exists food_portions_size_class_check;
alter table public.food_portions
  add constraint food_portions_size_class_check
  check (size_class is null or size_class in ('small', 'regular', 'large', 'custom'));

alter table public.food_portions
  drop constraint if exists food_portions_visual_status_check;
alter table public.food_portions
  add constraint food_portions_visual_status_check
  check (visual_status in ('missing', 'draft', 'reviewed', 'published'));

update public.food_portions
set size_class = case
  when is_default then 'regular'
  when lower(label::text) in ('az', 'small', 'yarım', 'half') then 'small'
  when lower(label::text) in ('fazla', 'large') then 'large'
  else 'custom'
end
where size_class is null;

create table if not exists public.food_nutrients (
  id bigint generated always as identity primary key,
  food_id uuid not null references public.foods (id) on delete cascade,
  nutrient_code text not null,
  nutrient_name text not null,
  amount_per_100g numeric(14, 5) not null check (amount_per_100g >= 0),
  unit text not null,
  source_ref text,
  created_at timestamptz not null default now(),
  unique (food_id, nutrient_code)
);

create table if not exists public.catalog_import_batches (
  id uuid primary key default extensions.gen_random_uuid(),
  source text not null,
  source_release text not null,
  status text not null default 'staged'
    check (status in ('staged', 'validated', 'published', 'rejected')),
  record_count integer not null default 0 check (record_count >= 0),
  checksum text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  validated_at timestamptz,
  published_at timestamptz,
  unique (source, source_release, checksum)
);

create table if not exists public.catalog_source_records (
  id bigint generated always as identity primary key,
  batch_id uuid not null references public.catalog_import_batches (id) on delete cascade,
  source_food_id text not null,
  payload jsonb not null,
  validation_errors jsonb not null default '[]'::jsonb,
  imported_food_id uuid references public.foods (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (batch_id, source_food_id)
);

create index if not exists food_portions_food_size_idx
  on public.food_portions (food_id, locale, size_class, grams);
create index if not exists food_nutrients_food_idx
  on public.food_nutrients (food_id);
create index if not exists catalog_source_records_batch_idx
  on public.catalog_source_records (batch_id);

alter table public.food_nutrients enable row level security;
alter table public.catalog_import_batches enable row level security;
alter table public.catalog_source_records enable row level security;

drop policy if exists "food_nutrients_read_catalog" on public.food_nutrients;
create policy "food_nutrients_read_catalog"
on public.food_nutrients for select to authenticated
using (exists (
  select 1 from public.foods f
  where f.id = food_id and f.is_active
));

revoke all on table public.catalog_import_batches from public, anon, authenticated;
revoke all on table public.catalog_source_records from public, anon, authenticated;
grant select on table public.food_nutrients to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'food-portion-references',
  'food-portion-references',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "public_read_food_portion_references" on storage.objects;
create policy "public_read_food_portion_references"
on storage.objects for select to public
using (bucket_id = 'food-portion-references');

comment on table public.food_nutrients is
  'Detailed, source-traceable nutrients normalized per 100 g; macro columns on foods remain the hot path.';
comment on table public.catalog_import_batches is
  'Staging and provenance boundary for repeatable USDA/FNDDS or curated catalog imports.';
comment on column public.food_portions.reference_image_path is
  'Public storage path for the reviewed visual reference of this exact portion.';
