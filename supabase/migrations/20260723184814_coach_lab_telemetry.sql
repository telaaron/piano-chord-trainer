-- Coach-Lab: Telemetry + Remote-Config foundation for the Auto-Modus ("Coach") feature
-- Tables: coach_events (insert-only anonymous telemetry), coach_config (public read-only remote config)
-- See docs/auto-mode-roadmap.md — "Telemetrie-Schema" and "Coach-Parameter" for the spec.

-- ══════════════════════════════════════════════════════════════
-- 1. COACH_EVENTS — anonymous, insert-only telemetry
-- ══════════════════════════════════════════════════════════════

create table public.coach_events (
  id uuid primary key default gen_random_uuid(),
  device_id uuid not null,
  user_id uuid references auth.users(id) on delete set null,
  ts timestamptz not null default now(),
  app text check (app in ('web', 'ios')),
  version text,
  cohort text,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb
);

-- RLS: anon + authenticated may ONLY insert. No select/update/delete from the client.
-- (service_role bypasses RLS by default and is used for analytics/dashboards.)
alter table public.coach_events enable row level security;

create policy "Anyone can insert coach events"
  on public.coach_events for insert
  to anon, authenticated
  with check (true);

-- ══════════════════════════════════════════════════════════════
-- 2. COACH_CONFIG — remote-tunable coach parameters, per cohort
-- ══════════════════════════════════════════════════════════════

create table public.coach_config (
  id uuid primary key default gen_random_uuid(),
  key text not null,
  value jsonb not null,
  cohort text not null default 'default',
  active boolean default true,
  unique (key, cohort)
);

-- RLS: anon + authenticated may ONLY select active rows. No insert/update/delete from the client.
alter table public.coach_config enable row level security;

create policy "Anyone can read active coach config"
  on public.coach_config for select
  to anon, authenticated
  using (active = true);

-- ══════════════════════════════════════════════════════════════
-- 3. INDEXES
-- ══════════════════════════════════════════════════════════════

create index idx_coach_events_event_type_ts on public.coach_events(event_type, ts);
create index idx_coach_events_device_ts on public.coach_events(device_id, ts);
