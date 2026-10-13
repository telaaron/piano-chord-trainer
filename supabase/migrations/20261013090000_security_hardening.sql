-- Applied to production 13.10.2026.
-- Security + performance hardening, driven by the Supabase advisors (13.10.2026).
--
-- 1. The v_coach_* metric views ran as SECURITY DEFINER (the Postgres default
--    for views), so they bypassed RLS on coach_events. The comment in
--    20260731090000 assumed selects would fail for anon — they did not: the
--    anon key could read every view, including per-device rows in
--    v_coach_time_to_mastery. Views now run as the caller, and only
--    service_role may read them.
-- 2. handle_new_user / set_updated_at had a mutable search_path; the two
--    SECURITY DEFINER functions were callable through /rest/v1/rpc by anon.
-- 3. RLS policies re-evaluated auth.uid() per row, and the "Service role full
--    access" policies applied to every role, doubling the policy work for each
--    anon/authenticated query.
-- 4. Two foreign keys had no covering index.
-- 5. v_coach_threshold_by_input counted every block's first chord, so a
--    3-block session counted three times. It now counts one per session.

-- ── 1. Metric views: caller's rights, service_role only ─────────────────────
alter view public.v_coach_time_to_mastery set (security_invoker = on);
alter view public.v_coach_retention set (security_invoker = on);
alter view public.v_coach_completion set (security_invoker = on);
alter view public.v_coach_feedback set (security_invoker = on);
alter view public.v_coach_threshold set (security_invoker = on);
alter view public.v_coach_threshold_by_input set (security_invoker = on);

revoke all on public.v_coach_time_to_mastery, public.v_coach_retention,
  public.v_coach_completion, public.v_coach_feedback, public.v_coach_threshold,
  public.v_coach_threshold_by_input
  from anon, authenticated;

-- ── 2. Functions ─────────────────────────────────────────────────────────────
-- handle_new_user already qualifies public.profiles, so an empty path is safe.
alter function public.handle_new_user() set search_path = '';
alter function public.set_updated_at() set search_path = '';

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;

-- ── 3. RLS policies ──────────────────────────────────────────────────────────
-- Altered in place rather than dropped and recreated, so there is never a
-- moment without a policy. The service-role policies are scoped to
-- service_role, which takes them out of every anon/authenticated query.
alter policy "Users can read own profile" on public.profiles
  to authenticated using ((select auth.uid()) = id);
alter policy "Users can update own profile" on public.profiles
  to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
alter policy "Service role full access on profiles" on public.profiles
  to service_role using (true);

alter policy "Users can read own data" on public.user_data
  to authenticated using ((select auth.uid()) = user_id);
alter policy "Users can insert own data" on public.user_data
  to authenticated with check ((select auth.uid()) = user_id);
alter policy "Users can update own data" on public.user_data
  to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
alter policy "Users can delete own data" on public.user_data
  to authenticated using ((select auth.uid()) = user_id);
alter policy "Service role full access on user_data" on public.user_data
  to service_role using (true);

alter policy "Users can read own subscription" on public.subscriptions
  to authenticated using ((select auth.uid()) = user_id);
alter policy "Service role full access on subscriptions" on public.subscriptions
  to service_role using (true);

-- feedback keeps RLS on with no policy on purpose: only /api/feedback writes
-- it, with the service role.
comment on table public.feedback is
  'Written only by /api/feedback via service_role. RLS on, no policies: anon/authenticated have no access by design.';

-- ── 4. Indexes ───────────────────────────────────────────────────────────────
create index if not exists idx_coach_events_user_id on public.coach_events(user_id);
create index if not exists idx_feedback_user_id on public.feedback(user_id);

-- ── 5. One first chord per session ───────────────────────────────────────────
-- first_chord_played fires per block (by design: it marks each block's start).
-- Block 0 is the session's crossing. Events from before blockIdx existed
-- count as block 0.
create or replace view public.v_coach_threshold_by_input
with (security_invoker = on) as
select
  coalesce(payload ->> 'input', 'unknown') as input,
  count(*) as first_chords,
  round(avg((payload ->> 'msSinceSessionStart')::numeric) / 1000.0, 1) as avg_seconds_to_first_chord
from public.coach_events
where event_type = 'first_chord_played'
  and coalesce((payload ->> 'blockIdx')::int, 0) = 0
group by 1
order by first_chords desc;

revoke all on public.v_coach_threshold_by_input from anon, authenticated;
