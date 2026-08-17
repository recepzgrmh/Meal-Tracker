create table public.translation_bundles (
  locale text primary key check (locale in ('tr', 'en')),
  version integer not null check (version > 0),
  values jsonb not null default '{}'::jsonb check (pg_catalog.jsonb_typeof(values) = 'object'),
  updated_at timestamptz not null default now(),
  check (pg_catalog.octet_length(values::text) <= 65536)
);

alter table public.translation_bundles enable row level security;

create policy "translation_bundles_read" on public.translation_bundles
for select to anon, authenticated using (true);

revoke all on table public.translation_bundles from public;
grant select on table public.translation_bundles to anon, authenticated;
grant all on table public.translation_bundles to service_role;

insert into public.translation_bundles (locale, version, values)
values ('tr', 1, '{}'::jsonb), ('en', 1, '{}'::jsonb)
on conflict (locale) do nothing;

comment on table public.translation_bundles is
  'Versioned OTA copy overrides. Mobile clients cache values and always retain bundled ARB fallbacks.';
