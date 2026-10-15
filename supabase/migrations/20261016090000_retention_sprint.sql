-- Retention sprint (until 30.11.2026): measure returning devices per week,
-- and let people opt into the weekly practice mail without an account.
--
-- 1. internal_devices: devices that belong to the team (Aaron's browsers,
--    simulators, TestFlight phones). Excluded from every retention number.
-- 2. v_weekly_returning: the sprint metric. A device "returns" in a week when
--    it is active that week and was already active in an earlier week.
--    Goal: two consecutive weeks with 10+ returning devices.
-- 3. email_consents for anonymous devices: most people who finish a block
--    have no account (28 of 46 devices in the last 60 days), so the opt-in
--    must work with just an address. Such rows have no user_id; the address
--    is the key. Deliberately no device_id: the privacy policy promises the
--    telemetry device id is never linked to an email address. Brevo's double
--    opt-in stays the confirmation step.

-- ══════════════════════════════════════════════════════════════
-- 1. INTERNAL DEVICES
-- ══════════════════════════════════════════════════════════════

create table public.internal_devices (
  device_id uuid primary key,
  note text not null,
  added_at timestamptz not null default now()
);

-- service_role only: no policies, so anon/authenticated can neither read nor write.
alter table public.internal_devices enable row level security;

comment on table public.internal_devices is
  'Team devices (Aaron, simulators, TestFlight) excluded from retention metrics. Add one with: insert into internal_devices values (''<uuid>'', ''<what it is>'');';

-- Found 15.10.2026 from coach_events: every device that ever sent events
-- logged in as Aaron, and every iOS device before the public App Store
-- release (dev builds and TestFlight). Confirmed with Aaron before applying.
insert into public.internal_devices (device_id, note) values
  ('6b772f2b-4114-4999-91e6-e5bae457e7c0', 'web, logged in as Aaron'),
  ('01dfb964-1e4e-4b3f-8317-1b6f535ee8ac', 'web, logged in as Aaron'),
  ('e75e1d6c-0f22-4182-9e69-e9119be18b64', 'web, logged in as Aaron'),
  ('e928881f-3d8a-4409-9280-4098e4c81b75', 'ios-dev build'),
  ('424940ba-57e0-42a0-9540-e5eed147390e', 'ios-dev build'),
  ('f6c79330-ceeb-450f-8f41-fdac14947c99', 'ios-dev build'),
  ('abb877d4-e33c-4789-8362-c58ee6a1a9ea', 'ios TestFlight 1.0.0')
on conflict do nothing;

-- ══════════════════════════════════════════════════════════════
-- 2. WEEKLY RETURNING DEVICES (sprint metric)
-- ══════════════════════════════════════════════════════════════

create or replace view public.v_weekly_returning
with (security_invoker = on) as
with active as (
  select e.device_id, date_trunc('week', e.ts)::date as week
  from public.coach_events e
  where not exists (select 1 from public.internal_devices i where i.device_id = e.device_id)
  group by 1, 2
),
first_week as (
  select device_id, min(week) as first_week from active group by 1
)
select
  a.week,
  count(*) as active_devices,
  count(*) filter (where f.first_week < a.week) as returning_devices,
  count(*) filter (where f.first_week = a.week) as new_devices
from active a
join first_week f using (device_id)
group by a.week
order by a.week desc;

revoke all on public.v_weekly_returning from anon, authenticated;

comment on view public.v_weekly_returning is
  'Retention sprint metric (Aaron, 15.10.2026): devices active this ISO week that were already active in an earlier week, team devices excluded. Goal: 2 consecutive weeks >= 10 by 30.11.2026.';

-- ══════════════════════════════════════════════════════════════
-- 3. EMAIL CONSENT WITHOUT AN ACCOUNT
-- ══════════════════════════════════════════════════════════════

alter table public.email_consents alter column user_id drop not null;

create index idx_email_consents_email_created on public.email_consents(lower(email), created_at desc);

-- Current state per address: an anonymous opt-in has no user_id to group by,
-- and the address is what Brevo mails anyway.
drop view public.v_email_consent_current;
create view public.v_email_consent_current
with (security_invoker = on) as
select distinct on (lower(email), purpose)
  user_id, email, purpose, status, source, text_version, created_at as since
from public.email_consents
order by lower(email), purpose, created_at desc;

revoke all on public.v_email_consent_current from anon, authenticated;
