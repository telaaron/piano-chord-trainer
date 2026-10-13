# Email consent (product updates)

Opt-in only, double opt-in via Brevo, every change logged.

## Flow

1. **Opt-in:** unticked checkbox at signup (stored in user metadata until the
   account is confirmed) or the toggle on `/account`. Wording + version live in
   `src/lib/consent.ts`; changing the wording means a new `CONSENT_TEXT_VERSION`.
2. **Record:** `/api/email-consent` appends a `pending` row to
   `email_consents` (service role only; users can read, never write).
3. **Confirm:** Brevo sends its double opt-in mail. The click adds the address
   to the list and redirects to `/account?updates=confirmed`; the next read of
   `/api/email-consent` sees the list membership and appends `confirmed`.
4. **Withdraw:** toggle off on `/account` (removes from the Brevo list), or the
   unsubscribe link in any mail (Brevo blacklists; picked up on next read).
   Account deletion deletes the Brevo contact; `email_consents` cascades.

Current state per user: `v_email_consent_current` (service role).

## Who may be mailed

Only addresses on the Brevo list, i.e. confirmed double opt-in. Users who
registered before this existed have **not** consented and must not receive
product announcements by email (GDPR + § 7 UWG). Ask them in the app.

## Setup status (13.10.2026)

- Done: DOI template id **1** ("JazzChords – Double Opt-in (DE/EN)", active,
  sender currently admin@must-seen.com, reply-to info@jazzchords.app);
  Vercel env `BREVO_DOI_TEMPLATE_ID=1` (production + preview).
- Open: list, API key, domain. The Brevo connector cannot create lists, keys
  or sender domains, and jazzchords.app DNS is at Cloudflare.

## Setup (once)

1. Brevo → Senders & Domains: add and authenticate `jazzchords.app` (DNS: DKIM,
   DMARC), sender e.g. `hello@jazzchords.app`.
2. Brevo → Contacts → Lists: create "JazzChords Updates", note its id.
3. Brevo → Templates: create a double opt-in template (must contain the
   `{{ doubleoptin }}` link), note its id.
4. Vercel env (production): `BREVO_API_KEY`, `BREVO_LIST_ID`,
   `BREVO_DOI_TEMPLATE_ID`. Redeploy.
5. Apply `supabase/migrations/20261013100000_email_consent.sql`.
