-- Coach-Lab: Metric views for the weekly tuning loop.
-- See docs/auto-mode-roadmap.md ("Erfolgsmetriken") and docs/coach-tuning-playbook.md.
--
-- All views live in schema public but are NOT exposed for anon/authenticated select:
-- the underlying table `coach_events` only grants INSERT to anon/authenticated (RLS),
-- so any select through these views already fails for those roles regardless of the
-- view's own grants. Views are read via service_role (e.g. Supabase SQL editor, a
-- server-side job, or `execute_sql` MCP tooling) — never from client code. No RLS
-- policy is defined on the views themselves; Postgres views have no RLS of their own
-- and simply inherit the permission check on the underlying table at query time.

-- ══════════════════════════════════════════════════════════════
-- 1. v_coach_time_to_mastery
-- Per (device_id, unitId): time from the first block_result touching that unit
-- to the matching coach_decision with decision='promoted' for the same unit.
-- Plus a per-unit aggregate (avg/median) across all devices.
-- ══════════════════════════════════════════════════════════════

create or replace view public.v_coach_time_to_mastery as
with first_touch as (
  -- first time a device worked a block_result that named this unitId
  select
    device_id,
    payload ->> 'unitId' as unit_id,
    min(ts) as first_ts
  from public.coach_events
  where event_type = 'block_result'
    and payload ? 'unitId'
  group by device_id, payload ->> 'unitId'
),
promotions as (
  -- every promoted decision, per device + unit, keep the earliest one
  select
    device_id,
    payload ->> 'unitId' as unit_id,
    min(ts) as promoted_ts
  from public.coach_events
  where event_type = 'coach_decision'
    and payload ->> 'decision' = 'promoted'
    and payload ? 'unitId'
  group by device_id, payload ->> 'unitId'
),
per_device as (
  select
    p.device_id,
    p.unit_id,
    f.first_ts,
    p.promoted_ts,
    p.promoted_ts - f.first_ts as time_to_mastery
  from promotions p
  join first_touch f
    on f.device_id = p.device_id
   and f.unit_id = p.unit_id
  where p.promoted_ts >= f.first_ts
),
per_unit_agg as (
  -- percentile_cont is an ordered-set aggregate and cannot use OVER(), so the
  -- per-unit aggregate is computed separately and joined back onto each row.
  select
    unit_id,
    avg(time_to_mastery) as avg_time_to_mastery_per_unit,
    percentile_cont(0.5) within group (order by time_to_mastery)
      as median_time_to_mastery_per_unit,
    count(*) as mastery_count_per_unit
  from per_device
  group by unit_id
)
select
  d.device_id,
  d.unit_id,
  d.first_ts,
  d.promoted_ts,
  d.time_to_mastery,
  -- per-unit aggregate, repeated on every row so callers can filter to one row
  -- per unit (e.g. `distinct on (unit_id)`) or just read the per-device rows.
  a.avg_time_to_mastery_per_unit,
  a.median_time_to_mastery_per_unit,
  a.mastery_count_per_unit
from per_device d
join per_unit_agg a on a.unit_id = d.unit_id;

comment on view public.v_coach_time_to_mastery is
  'Coach-Lab metric: time-to-mastery per (device_id, unitId), plus avg/median per unitId as window columns. Read via service_role only — underlying coach_events table blocks anon/authenticated select via RLS.';

-- ══════════════════════════════════════════════════════════════
-- 2. v_coach_retention
-- Per cohort-week (a device's first activity week): D1 and D7 return rate.
-- ══════════════════════════════════════════════════════════════

create or replace view public.v_coach_retention as
with device_days as (
  -- every calendar day a device was active, deduped
  select distinct
    device_id,
    date_trunc('day', ts) as active_day
  from public.coach_events
),
first_activity as (
  select
    device_id,
    min(active_day) as first_day
  from device_days
  group by device_id
),
returns as (
  select
    fa.device_id,
    date_trunc('week', fa.first_day) as cohort_week,
    fa.first_day,
    bool_or(dd.active_day = fa.first_day + interval '1 day') as returned_d1,
    bool_or(
      dd.active_day > fa.first_day
      and dd.active_day <= fa.first_day + interval '7 days'
    ) as returned_d7
  from first_activity fa
  left join device_days dd
    on dd.device_id = fa.device_id
  group by fa.device_id, fa.first_day
)
select
  cohort_week,
  count(*) as cohort_size,
  count(*) filter (where returned_d1) as d1_returned,
  count(*) filter (where returned_d7) as d7_returned,
  round(
    count(*) filter (where returned_d1)::numeric / nullif(count(*), 0),
    4
  ) as d1_return_rate,
  round(
    count(*) filter (where returned_d7)::numeric / nullif(count(*), 0),
    4
  ) as d7_return_rate
from returns
group by cohort_week
order by cohort_week;

comment on view public.v_coach_retention is
  'Coach-Lab metric: D1/D7 return rate per cohort week (a devices first activity week). Read via service_role only — underlying coach_events table blocks anon/authenticated select via RLS.';

-- ══════════════════════════════════════════════════════════════
-- 3. v_coach_completion
-- Per week: share of session_end events with completedBlocks = totalBlocks,
-- plus quit_midblock rate per block kind.
-- ══════════════════════════════════════════════════════════════

create or replace view public.v_coach_completion as
with sessions as (
  select
    date_trunc('week', ts) as week,
    (payload ->> 'completedBlocks')::numeric as completed_blocks,
    (payload ->> 'totalBlocks')::numeric as total_blocks
  from public.coach_events
  where event_type = 'session_end'
),
session_completion as (
  select
    week,
    count(*) as total_sessions,
    count(*) filter (
      where completed_blocks = total_blocks
    ) as fully_completed_sessions,
    round(
      count(*) filter (where completed_blocks = total_blocks)::numeric
        / nullif(count(*), 0),
      4
    ) as completion_rate
  from sessions
  group by week
),
quits as (
  select
    date_trunc('week', ts) as week,
    payload ->> 'kind' as block_kind,
    count(*) as quit_count
  from public.coach_events
  where event_type = 'quit_midblock'
  group by date_trunc('week', ts), payload ->> 'kind'
),
block_starts as (
  -- approximate "attempts" of a given block kind by counting block_result rows
  -- (a block that is quit mid-way still emits partial block_results before the quit)
  select
    date_trunc('week', ts) as week,
    payload ->> 'kind' as block_kind,
    count(distinct payload ->> 'unitId') as _unused,
    count(*) as block_result_count
  from public.coach_events
  where event_type = 'block_result'
  group by date_trunc('week', ts), payload ->> 'kind'
),
quit_rates as (
  select
    coalesce(q.week, b.week) as week,
    coalesce(q.block_kind, b.block_kind) as block_kind,
    coalesce(q.quit_count, 0) as quit_count,
    coalesce(b.block_result_count, 0) as block_result_count,
    round(
      coalesce(q.quit_count, 0)::numeric
        / nullif(coalesce(q.quit_count, 0) + coalesce(b.block_result_count, 0), 0),
      4
    ) as quit_rate
  from quits q
  full outer join block_starts b
    on b.week = q.week
   and b.block_kind = q.block_kind
)
select
  sc.week,
  sc.total_sessions,
  sc.fully_completed_sessions,
  sc.completion_rate,
  qr.block_kind as quit_block_kind,
  qr.quit_count,
  qr.block_result_count,
  qr.quit_rate
from session_completion sc
full outer join quit_rates qr
  on qr.week = sc.week
order by coalesce(sc.week, qr.week), qr.block_kind;

comment on view public.v_coach_completion is
  'Coach-Lab metric: weekly session completion rate (completedBlocks=totalBlocks) and quit_midblock rate per block kind. Read via service_role only — underlying coach_events table blocks anon/authenticated select via RLS.';

-- ══════════════════════════════════════════════════════════════
-- 4. v_coach_feedback
-- Distribution of feedback_valve signals per week and overall.
-- ══════════════════════════════════════════════════════════════

create or replace view public.v_coach_feedback as
with weekly as (
  select
    date_trunc('week', ts) as week,
    payload ->> 'signal' as signal,
    count(*) as signal_count
  from public.coach_events
  where event_type = 'feedback_valve'
  group by date_trunc('week', ts), payload ->> 'signal'
),
weekly_totals as (
  select
    week,
    sum(signal_count) as week_total
  from weekly
  group by week
),
overall as (
  select
    null::timestamptz as week,
    signal,
    sum(signal_count) as signal_count
  from weekly
  group by signal
),
overall_total as (
  select sum(signal_count) as total from weekly
)
select
  w.week,
  w.signal,
  w.signal_count,
  wt.week_total,
  round(w.signal_count::numeric / nullif(wt.week_total, 0), 4) as share_of_week
from weekly w
join weekly_totals wt on wt.week = w.week
union all
select
  o.week,
  o.signal,
  o.signal_count,
  ot.total as week_total,
  round(o.signal_count::numeric / nullif(ot.total, 0), 4) as share_of_week
from overall o
cross join overall_total ot
order by week nulls last, signal;

comment on view public.v_coach_feedback is
  'Coach-Lab metric: feedback_valve signal distribution (tooEasy/justRight/tooHard) per week and overall (week IS NULL = overall row). Read via service_role only — underlying coach_events table blocks anon/authenticated select via RLS.';
