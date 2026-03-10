# Handoff: Supabase Auth, Stripe Payments & Admin Dashboard

**Date**: 2025-01-XX  
**Agent**: GitHub Copilot (Claude Opus 4.6)  
**Status**: ✅ Build passing (`pnpm check` = 0 errors, `pnpm build` = success)

---

## What Was Built

### 1. Supabase Auth (works, needs database setup)
- **Client**: `src/lib/services/supabase.ts` — browser-side singleton
- **Auth Service**: `src/lib/services/auth.ts` — sign up, sign in, OAuth (Google/GitHub), password reset, delete account
- **Server Hooks**: `src/hooks.server.ts` — session management, admin route protection
- **Auth Callback**: `src/routes/auth/callback/+server.ts` — OAuth code exchange
- **Login Page**: `src/routes/auth/login/+page.svelte` — combined login/signup/reset with merge-local-data option

### 2. Cloud Sync (localStorage → Supabase)
- **Service**: `src/lib/services/cloud-sync.ts` — upload/download/debouncedSync
- **Integration**: `debouncedSync()` added to `progress.ts`, `habits.ts`, `course-progress.ts` (auto-sync on every localStorage write for logged-in users)
- **Sync Banner**: Layout shows a dismissible banner for non-logged-in users with practice data

### 3. Stripe Payments (beta mode, greyed out)
- **Subscription Service**: `src/lib/services/subscription.ts` — `IS_BETA = true`, feature gates, tier checks
- **Checkout API**: `src/routes/api/stripe/checkout/+server.ts`
- **Portal API**: `src/routes/api/stripe/portal/+server.ts`
- **Webhook**: `src/routes/api/stripe/webhook/+server.ts` — handles checkout.completed, sub.updated/deleted, invoice.failed
- **Pricing Page**: `src/routes/pricing/+page.svelte` — 4-tier grid, pro/edu/institution greyed out during beta

### 4. Account Management
- **Account Page**: `src/routes/account/+page.svelte` — profile, subscription, cloud sync, danger zone (delete account)
- **Delete API**: `src/routes/api/account/delete/+server.ts` — cascading delete (data → auth)

### 5. Legal
- **Terms of Service**: `src/routes/terms/+page.svelte` — EU-compliant, Estonian law
- **Privacy Updates**: Added Supabase and Stripe as third-party processors in `src/routes/privacy/+page.svelte`

### 6. Admin Dashboard
- **Stats API**: `src/routes/api/admin/stats/+server.ts` — real Supabase queries (users, sessions, subscriptions, signups by day, tier distribution)
- **Dashboard UI**: `src/routes/admin/+page.svelte` — stats cards, signup chart, tier distribution, recent users table
- **Access Control**: Protected via `hooks.server.ts` — requires `profiles.role = 'admin'`

### 7. i18n
- All new UI strings added to both `src/lib/i18n/en.ts` and `src/lib/i18n/de.ts` (~200 keys: auth, account, pricing, terms, admin, nav_auth sections)

### 8. Database Schema
- **SQL Migration**: `supabase/migration.sql` — tables: `profiles`, `user_data`, `subscriptions` with RLS policies, indexes, auto-create triggers

---

## ⚠️ Things You Must Do Before It Works

### CRITICAL — Database Setup
1. **Run the SQL migration** in Supabase Dashboard → SQL Editor → New Query → paste contents of `supabase/migration.sql` → Run
2. **Set your admin role**: After creating your account, run in SQL Editor:
   ```sql
   UPDATE profiles SET role = 'admin' WHERE id = (
     SELECT id FROM auth.users WHERE email = 'YOUR_EMAIL'
   );
   ```

### CRITICAL — Stripe Setup
3. **Create Stripe products/prices** in Stripe Dashboard (test mode):
   - Pro: €4.99/month recurring
   - Educator: €29/month recurring  
   - Institution: €99/month recurring
4. **Update `.env`** with real Stripe keys:
   - `STRIPE_SECRET_KEY` — from Stripe Dashboard → Developers → API Keys
   - `STRIPE_PUBLISHABLE_KEY` — same place (publishable key)
   - `STRIPE_PRICE_PRO`, `STRIPE_PRICE_EDUCATOR`, `STRIPE_PRICE_INSTITUTION` — the price IDs from step 3
5. **Register webhook endpoint** in Stripe Dashboard → Webhooks:
   - URL: `https://jazzchords.app/api/stripe/webhook`
   - Events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_failed`
   - Copy the webhook signing secret → set as `STRIPE_WEBHOOK_SECRET` in `.env`

### CRITICAL — Supabase Auth Config
6. **Enable Email auth** in Supabase Dashboard → Authentication → Providers → Email
7. **Set redirect URL**: Supabase Dashboard → Authentication → URL Configuration:
   - Site URL: `https://jazzchords.app`
   - Redirect URLs: `https://jazzchords.app/auth/callback`
8. **(Optional) Enable OAuth**: To enable Google/GitHub login:
   - Supabase Dashboard → Authentication → Providers → Google/GitHub
   - Create OAuth apps in Google Cloud Console / GitHub Developer Settings
   - Set the redirect URL from Supabase in the OAuth provider

### Vercel Environment Variables
9. **Add all `.env` variables** to Vercel Dashboard → Project → Settings → Environment Variables

---

## ⚠️ What Couldn't Be Done (Agent Limitations)

| Item | Why | Workaround |
|------|-----|------------|
| Supabase table creation | No Supabase CLI / dashboard access | Run `supabase/migration.sql` manually |
| Stripe product/price creation | No Stripe API access | Create manually in Stripe Dashboard |
| Webhook registration | No Stripe CLI access | Register manually in Stripe Dashboard |
| OAuth provider setup | Requires Google/GitHub developer console | Configure manually per provider |
| Set admin role | Requires database access | Run SQL UPDATE manually |
| Vercel env vars | No Vercel access | Add via Vercel Dashboard |
| Email templates | Supabase Dashboard setting | Customize in Auth → Email Templates |
| `priceIdToTier()` mapping | Price IDs don't exist yet | Update after creating Stripe prices |

---

## Test Checklist

### Auth Flow
- [ ] Visit `/auth/login` — see login form with email/password
- [ ] Sign up with email — receive confirmation email
- [ ] Confirm email → redirected to `/train`
- [ ] Sign in with existing account
- [ ] "Forgot password" → receive reset email → reset works
- [ ] Sign out from account page
- [ ] Check "Merge local data" on login → verify cloud data appears
- [ ] Everything still works without being logged in (core requirement)

### Navigation & Layout
- [ ] "Sign In" button appears in nav when logged out
- [ ] "Account" link appears in nav when logged in
- [ ] Sync banner appears for users with practice data who aren't logged in
- [ ] Dismissing sync banner persists (doesn't reappear)
- [ ] Footer shows Pricing and Terms links

### Pricing Page
- [ ] Visit `/pricing` — see 4-tier grid
- [ ] Beta banner appears at top
- [ ] Pro/Educator/Institution cards are greyed out (opacity-50)
- [ ] Prices show crossed-out styling
- [ ] Buttons say "Coming Soon" (not clickable)
- [ ] Free tier button works (links to train)

### Account Page
- [ ] Visit `/account` when logged in — see profile info
- [ ] Subscription section shows beta banner
- [ ] Cloud sync section has upload/download buttons
- [ ] Upload/download works after SQL migration is run
- [ ] "Delete Account" requires confirmation, then deletes everything

### Admin Dashboard
- [ ] Visit `/admin` when NOT admin → "Access denied" or redirect
- [ ] Visit `/admin` as admin → see real stats
- [ ] Stats cards show real numbers (total users, active today, sessions, subs)
- [ ] Signup chart shows last 30 days
- [ ] Tier distribution shows breakdown
- [ ] Recent users table shows last 20 users with email, role, tier

### Legal
- [ ] `/terms` — full Terms of Service, mentions Aaron Technologies OÜ
- [ ] `/privacy` — updated with Supabase and Stripe in third-party table

### Cloud Sync (after SQL migration)
- [ ] Complete a training session while logged in → data syncs after 3s
- [ ] Log in on another device → download data → see same progress
- [ ] Change settings → settings sync to cloud

---

## Architecture Notes

- **No Svelte stores** — all state uses Svelte 5 runes ($state, $derived, $effect)
- **Auth state** uses callback pattern (`onAuthChange`) to notify components
- **Cloud sync** is fire-and-forget (debouncedSync), never blocks UI
- **Beta mode** controlled by single constant: `IS_BETA = true` in `subscription.ts` — flip to `false` when ready to launch payments
- **Stripe webhook** uses the service role Supabase client for secure database writes
- **Admin access** checked server-side in hooks.server.ts, not client-side

## When Ready to Launch Payments
1. Set `IS_BETA = false` in `src/lib/services/subscription.ts`
2. Update `priceIdToTier()` in webhook to match actual Stripe price IDs
3. Switch Stripe from test mode to live mode
4. Update all `STRIPE_*` env vars with live keys
