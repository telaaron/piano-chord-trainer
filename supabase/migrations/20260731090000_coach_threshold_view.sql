-- Coach-Lab: the threshold metric — did a session ever produce a sound?
--
-- Motivation (docs/MASTERPLAN.md, §1): every started block that was played got
-- finished (225 of 225), yet four of five recorded drop-outs sit at
-- `atChord: 0` — the player left after the session started but before playing
-- anything. That gap was unmeasurable: `session_start` fires on entry and
-- `block_result` only exists once a block completes, so a session that died on
-- the threshold left no positive trace. `first_chord_played` closes it.
--
-- Same access model as the other metric views: `coach_events` grants only
-- INSERT to anon/authenticated via RLS, so selects through this view fail for
-- those roles automatically. Read with service_role only.

-- ══════════════════════════════════════════════════════════════
-- v_coach_threshold
-- Per day and app: sessions started vs. sessions that produced a first chord.
-- `crossed_pct` is the number to watch — target > 90%.
-- ══════════════════════════════════════════════════════════════

create or replace view public.v_coach_threshold as
with starts as (
  select
    date_trunc('day', ts)::date as day,
    app,
    device_id,
    ts,
    -- Pair each start with the next start on the same device, so a "did they
    -- play?" lookup cannot borrow a chord from a later session.
    lead(ts) over (partition by device_id order by ts) as next_start_ts
  from public.coach_events
  where event_type = 'session_start'
),
first_chords as (
  select device_id, ts
  from public.coach_events
  where event_type = 'first_chord_played'
)
select
  s.day,
  s.app,
  count(*) as sessions_started,
  count(*) filter (where fc.device_id is not null) as sessions_crossed,
  round(
    100.0 * count(*) filter (where fc.device_id is not null) / nullif(count(*), 0),
    1
  ) as crossed_pct
from starts s
left join lateral (
  select f.device_id
  from first_chords f
  where f.device_id = s.device_id
    and f.ts >= s.ts
    and (s.next_start_ts is null or f.ts < s.next_start_ts)
  limit 1
) fc on true
group by s.day, s.app
order by s.day desc, s.app;

comment on view public.v_coach_threshold is
  'Share of coach sessions that produced a first chord. The drop-off happens before the first note, so this is the acquisition-side metric for the coach — target crossed_pct > 90.';

-- ══════════════════════════════════════════════════════════════
-- v_coach_threshold_by_input
-- The same crossing, split by the input the player had when they crossed.
-- The leading hypothesis for the drop-off is a MIDI device that never
-- connected; this is how that gets confirmed or ruled out.
-- ══════════════════════════════════════════════════════════════

create or replace view public.v_coach_threshold_by_input as
select
  coalesce(payload ->> 'input', 'unknown') as input,
  count(*) as first_chords,
  round(avg((payload ->> 'msSinceSessionStart')::numeric) / 1000.0, 1) as avg_seconds_to_first_chord
from public.coach_events
where event_type = 'first_chord_played'
group by 1
order by first_chords desc;

comment on view public.v_coach_threshold_by_input is
  'How players who DID start playing were set up, and how long they took to get going. Compare against the input mix of sessions that never crossed.';
