-- Supabase SQL Migration for jazzchords.app
-- Tables: profiles, user_data, subscriptions
-- Run this in Supabase SQL Editor (Dashboard → SQL → New Query)

-- ══════════════════════════════════════════════════════════════
-- 1. PROFILES — extends auth.users with app-specific fields
-- ══════════════════════════════════════════════════════════════

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'user' check (role in ('user', 'admin', 'educator')),
  stripe_customer_id text unique,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id)
  values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- RLS
alter table public.profiles enable row level security;

create policy "Users can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Service role can do everything (API routes use service role)
create policy "Service role full access on profiles"
  on public.profiles for all
  using (auth.role() = 'service_role');

-- ══════════════════════════════════════════════════════════════
-- 2. USER_DATA — stores synced localStorage data as JSONB
-- ══════════════════════════════════════════════════════════════

create table public.user_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- RLS
alter table public.user_data enable row level security;

create policy "Users can read own data"
  on public.user_data for select
  using (auth.uid() = user_id);

create policy "Users can insert own data"
  on public.user_data for insert
  with check (auth.uid() = user_id);

create policy "Users can update own data"
  on public.user_data for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own data"
  on public.user_data for delete
  using (auth.uid() = user_id);

create policy "Service role full access on user_data"
  on public.user_data for all
  using (auth.role() = 'service_role');

-- ══════════════════════════════════════════════════════════════
-- 3. SUBSCRIPTIONS — tracks Stripe subscription status
-- ══════════════════════════════════════════════════════════════

create table public.subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  stripe_subscription_id text unique,
  stripe_customer_id text,
  tier text not null default 'free' check (tier in ('free', 'pro', 'educator', 'institution')),
  status text not null default 'inactive' check (status in ('active', 'trialing', 'past_due', 'canceled', 'inactive')),
  current_period_start timestamptz,
  current_period_end timestamptz,
  price_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS
alter table public.subscriptions enable row level security;

create policy "Users can read own subscription"
  on public.subscriptions for select
  using (auth.uid() = user_id);

create policy "Service role full access on subscriptions"
  on public.subscriptions for all
  using (auth.role() = 'service_role');

-- ══════════════════════════════════════════════════════════════
-- 4. INDEXES
-- ══════════════════════════════════════════════════════════════

create index idx_subscriptions_stripe_customer on public.subscriptions(stripe_customer_id);
create index idx_subscriptions_status on public.subscriptions(status);
create index idx_profiles_stripe_customer on public.profiles(stripe_customer_id);

-- ══════════════════════════════════════════════════════════════
-- 5. UPDATED_AT TRIGGER (auto-set updated_at on UPDATE)
-- ══════════════════════════════════════════════════════════════

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger user_data_updated_at
  before update on public.user_data
  for each row execute function public.set_updated_at();

create trigger subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();
