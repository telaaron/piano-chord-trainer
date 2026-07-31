-- Feedback — the /feedback page's destination.
--
-- Shaped after coach_events (20260723184814): insert-only from the client,
-- never readable by it. A stranger who writes here must not be able to read
-- back what anyone else wrote, so there is no select policy for anon at all —
-- the owner reads this table through the service role (SQL editor / dashboard).

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  -- The message itself. Length is capped in the database as well as the form:
  -- the endpoint is public, so the column is the boundary that actually holds.
  message text not null check (char_length(message) between 1 and 4000),
  -- Optional: only so the owner can reply. Blank when the sender stayed anonymous.
  email text check (email is null or char_length(email) <= 320),
  -- Set server-side when the sender happened to be signed in; never trusted
  -- from the request body.
  user_id uuid references auth.users(id) on delete set null,
  -- Which locale the page was in, so a German note gets a German reply.
  locale text check (locale is null or char_length(locale) <= 10)
);

-- RLS: nothing may reach this table from the client directly. The insert runs
-- through /api/feedback under the service role, which bypasses RLS. Enabling
-- RLS with no policies is the point — it denies anon and authenticated both.
alter table public.feedback enable row level security;

create index idx_feedback_created_at on public.feedback(created_at desc);
