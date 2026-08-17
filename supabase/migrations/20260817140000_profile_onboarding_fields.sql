alter table public.profiles
  add column primary_intention text
    check (primary_intention in ('understand', 'protein', 'calories')),
  add column onboarding_version integer not null default 0
    check (onboarding_version >= 0),
  add column onboarding_completed_at timestamptz;

grant update (
  primary_intention,
  onboarding_version,
  onboarding_completed_at
) on table public.profiles to authenticated;

comment on column public.profiles.primary_intention is
  'Presentation preference only; not a medical or nutrition prescription.';
comment on column public.profiles.onboarding_version is
  'Latest onboarding contract completed by the user.';
