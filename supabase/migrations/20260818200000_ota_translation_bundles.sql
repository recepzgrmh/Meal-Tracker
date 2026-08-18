create table public.translation_bundles (
  locale text not null check (locale in ('tr', 'en')),
  version integer not null check (version > 0),
  status text not null default 'draft'
    check (status in ('draft', 'staging', 'production', 'archived')),
  values jsonb not null default '{}'::jsonb check (pg_catalog.jsonb_typeof(values) = 'object'),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  check (pg_catalog.octet_length(values::text) <= 65536),
  primary key (locale, version)
);

create unique index translation_bundles_single_active_status
on public.translation_bundles (locale, status)
where status in ('staging', 'production');

alter table public.translation_bundles enable row level security;

create policy "translation_bundles_read" on public.translation_bundles
for select to anon, authenticated using (status = 'production');

revoke all on table public.translation_bundles from public;
grant select on table public.translation_bundles to anon, authenticated;
grant all on table public.translation_bundles to service_role;

insert into public.translation_bundles (locale, version, status, values, published_at)
values
  ('tr', 1, 'production', '{}'::jsonb, now()),
  ('en', 1, 'production', '{}'::jsonb, now())
on conflict (locale, version) do nothing;

comment on table public.translation_bundles is
  'Versioned OTA copy overrides. Mobile clients cache values and always retain bundled ARB fallbacks.';
