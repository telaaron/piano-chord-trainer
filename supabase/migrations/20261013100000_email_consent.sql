-- Email consent: an append-only record of who agreed to product-update mail,
-- with which wording, from where, and when it was confirmed or withdrawn.
--
-- Consent under the GDPR has to be provable, so every change is a new row and
-- nothing is updated in place. The latest row per user is their current
-- state. Brevo's double opt-in is the confirmation step; `confirmed` is only
-- written once Brevo reports the address on the list.
--
-- Rows are written only by the server (service_role). Users may read their own
-- history; they can never write it, so a client cannot mark itself confirmed.

create table public.email_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  purpose text not null default 'product_updates' check (purpose in ('product_updates')),
  status text not null check (status in ('pending', 'confirmed', 'withdrawn')),
  source text not null check (source in ('signup', 'account', 'prompt', 'brevo')),
  consent_text text,
  text_version text,
  -- clock_timestamp, not now(): two rows in one transaction must still order.
  created_at timestamptz not null default clock_timestamp()
);

alter table public.email_consents enable row level security;

create policy "Users can read own consent history" on public.email_consents
  for select to authenticated using ((select auth.uid()) = user_id);

create index idx_email_consents_user_created on public.email_consents(user_id, created_at desc);

-- Current state per user and purpose. For the server and for mail exports.
create view public.v_email_consent_current
with (security_invoker = on) as
select distinct on (user_id, purpose)
  user_id, email, purpose, status, source, text_version, created_at as since
from public.email_consents
order by user_id, purpose, created_at desc;

revoke all on public.v_email_consent_current from anon, authenticated;

comment on table public.email_consents is
  'Append-only GDPR consent log for product-update email. Written by /api/email-consent with service_role only.';
