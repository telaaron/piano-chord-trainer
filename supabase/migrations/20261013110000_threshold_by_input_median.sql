-- v_coach_threshold_by_input: report the median, not just the mean.
--
-- The mean read 362 s to first chord for MIDI vs 34 s without an input,
-- which looked like a MIDI connection problem. It is one event: a session
-- started and left open for 48 h (172,418 s) makes up 94 % of the MIDI sum.
-- Median for block 0 is 6.3 s (MIDI) vs 6.0 s (none); p90 is 29.7 s vs
-- 84.8 s. A tab left open is a normal outlier for this metric, so the
-- median and p90 are the numbers to read; avg stays for comparison.

create or replace view public.v_coach_threshold_by_input
with (security_invoker = on) as
select
  coalesce(payload ->> 'input', 'unknown') as input,
  count(*) as first_chords,
  round(avg((payload ->> 'msSinceSessionStart')::numeric) / 1000.0, 1) as avg_seconds_to_first_chord,
  round((percentile_cont(0.5) within group (order by (payload ->> 'msSinceSessionStart')::numeric) / 1000.0)::numeric, 1)
    as median_seconds_to_first_chord,
  round((percentile_cont(0.9) within group (order by (payload ->> 'msSinceSessionStart')::numeric) / 1000.0)::numeric, 1)
    as p90_seconds_to_first_chord
from public.coach_events
where event_type = 'first_chord_played'
  and coalesce((payload ->> 'blockIdx')::int, 0) = 0
group by 1
order by first_chords desc;

revoke all on public.v_coach_threshold_by_input from anon, authenticated;

comment on view public.v_coach_threshold_by_input is
  'Block-0 first chords by input and time to get there. Read median/p90: a session left open for hours skews the mean.';
