-- ============================================================================
-- 1. FCPW Predictor — Phase 1: initial schema, RLS, triggers, scoring
-- Apply in the Supabase SQL editor or via `supabase db push`.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Types
-- ----------------------------------------------------------------------------
create type public.squad_type as enum ('km', 'reserve', 'women');
create type public.match_status as enum ('upcoming', 'live', 'finished');

-- ----------------------------------------------------------------------------
-- Tables
-- ----------------------------------------------------------------------------

-- Identity only. All per-season data lives in user_season_stats.
create table public.users (
  id         uuid primary key references auth.users (id) on delete cascade,
  username   text not null
             check (char_length(username) between 3 and 20
                    and username ~ '^[A-Za-z0-9_]+$'),
  created_at timestamptz not null default now()
);
create unique index users_username_lower_key on public.users (lower(username));

create table public.seasons (
  id             uuid primary key default gen_random_uuid(),
  name           text not null unique,           -- e.g. "2026/27"
  starts_at      timestamptz not null,
  ends_at        timestamptz not null,
  boot_lock_time timestamptz not null,           -- global golden-boot lock
  is_current     boolean not null default false,
  check (starts_at < ends_at)
);
create unique index seasons_one_current_key on public.seasons (is_current)
  where is_current;

-- Maps each squad to its fan.at league for one of our seasons.
create table public.season_squads (
  season_id        uuid not null references public.seasons (id) on delete cascade,
  squad            public.squad_type not null,
  fanat_league_slug text not null,               -- e.g. "dsg-oberliga-a-w"
  fanat_league_id  text,                         -- resolved & cached by the worker
  fanat_season_id  text,
  primary key (season_id, squad)
);

create table public.matches (
  id                uuid primary key default gen_random_uuid(),
  external_id       text not null unique,        -- fan.at event _id; stable across reschedules
  season_id         uuid not null references public.seasons (id) on delete cascade,
  squad             public.squad_type not null,
  home_team         text not null,
  away_team         text not null,
  kickoff_time      timestamptz not null,
  home_score_actual integer check (home_score_actual >= 0),
  away_score_actual integer check (away_score_actual >= 0),
  status            public.match_status not null default 'upcoming'
);
create index matches_season_squad_kickoff_idx
  on public.matches (season_id, squad, kickoff_time);

-- One row per player per season (roster snapshot); feeds the golden-boot dropdown.
create table public.players (
  id          uuid primary key default gen_random_uuid(),
  external_id text not null,                     -- fan.at player id where available
  season_id   uuid not null references public.seasons (id) on delete cascade,
  name        text not null,
  team        text not null,
  goals       integer not null default 0 check (goals >= 0),
  unique (external_id, season_id)
);
create index players_season_goals_idx on public.players (season_id, goals desc);

create table public.predictions (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.users (id) on delete cascade,
  match_id         uuid not null references public.matches (id) on delete cascade,
  home_score_guess integer not null check (home_score_guess >= 0),
  away_score_guess integer not null check (away_score_guess >= 0),
  points_awarded   integer,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (user_id, match_id)
);
create index predictions_match_idx on public.predictions (match_id);

-- Per-season scoreboard. Points columns are written only by the scoring
-- function / worker; users may only touch golden_boot_pick (column grants below).
create table public.user_season_stats (
  user_id          uuid not null references public.users (id) on delete cascade,
  season_id        uuid not null references public.seasons (id) on delete cascade,
  total_points     integer not null default 0,
  exact_hits       integer not null default 0,
  golden_boot_pick uuid references public.players (id),
  golden_boot_hit  boolean,                      -- resolved by close_season()
  final_rank       integer,                      -- frozen by close_season(); NULL while running
  primary key (user_id, season_id)
);
create index user_season_stats_season_rank_idx
  on public.user_season_stats (season_id, total_points desc, exact_hits desc);

-- ----------------------------------------------------------------------------
-- Signup trigger: create public.users row, username from signup metadata
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username',
             'user_' || left(new.id::text, 8))
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- Helper: is the prediction window for a match still open? (2-hour rule)
-- SECURITY DEFINER so RLS policies can consult matches without recursion.
-- ----------------------------------------------------------------------------
create or replace function public.prediction_window_open(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from matches m
    where m.id = p_match_id
      and m.kickoff_time - interval '2 hours' > now()
  );
$$;

-- ----------------------------------------------------------------------------
-- Scoring: idempotent recalculation (3 exact / 1 trend / 0 otherwise)
-- ----------------------------------------------------------------------------
create or replace function public.recalculate_match_points(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  m matches%rowtype;
begin
  select * into m from matches where id = p_match_id;
  if not found then
    return;
  end if;

  if m.status = 'finished'
     and m.home_score_actual is not null
     and m.away_score_actual is not null then
    update predictions p
    set points_awarded = case
          when p.home_score_guess = m.home_score_actual
           and p.away_score_guess = m.away_score_actual then 3
          when sign(p.home_score_guess - p.away_score_guess)
             = sign(m.home_score_actual - m.away_score_actual) then 1
          else 0
        end,
        updated_at = now()
    where p.match_id = p_match_id;
  else
    -- Result missing or annulled (e.g. reverted to live/upcoming): clear points.
    update predictions
    set points_awarded = null, updated_at = now()
    where match_id = p_match_id;
  end if;

  -- Recompute season totals from scratch for everyone who predicted this season.
  insert into user_season_stats (user_id, season_id, total_points, exact_hits)
  select p.user_id,
         m.season_id,
         coalesce(sum(p.points_awarded), 0),
         count(*) filter (where p.points_awarded = 3)
  from predictions p
  join matches ma on ma.id = p.match_id
  where ma.season_id = m.season_id
  group by p.user_id, m.season_id
  on conflict (user_id, season_id) do update
    set total_points = excluded.total_points,
        exact_hits   = excluded.exact_hits;
end;
$$;

create or replace function public.handle_match_result_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.recalculate_match_points(new.id);
  return new;
end;
$$;

create trigger on_match_result_change
  after update of home_score_actual, away_score_actual, status on public.matches
  for each row
  when (old.home_score_actual is distinct from new.home_score_actual
     or old.away_score_actual is distinct from new.away_score_actual
     or old.status is distinct from new.status)
  execute function public.handle_match_result_change();

-- ----------------------------------------------------------------------------
-- Season close: freeze final ranks and resolve the golden boot
-- ----------------------------------------------------------------------------
create or replace function public.close_season(p_season_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (select 1 from matches
             where season_id = p_season_id and status <> 'finished') then
    raise exception 'season % still has unfinished matches', p_season_id;
  end if;

  -- Golden boot: pick counts if it matches any player tied for most goals (> 0).
  update user_season_stats uss
  set golden_boot_hit = (uss.golden_boot_pick is not null and exists (
        select 1 from players p
        where p.id = uss.golden_boot_pick
          and p.goals > 0
          and p.goals = (select max(goals) from players
                         where season_id = p_season_id)
      ))
  where uss.season_id = p_season_id;

  update user_season_stats uss
  set final_rank = r.rnk
  from (
    select user_id,
           rank() over (order by total_points desc, exact_hits desc) as rnk
    from user_season_stats
    where season_id = p_season_id
  ) r
  where uss.season_id = p_season_id and uss.user_id = r.user_id;

  update seasons set is_current = false where id = p_season_id;
end;
$$;

-- Admin/worker only — not callable by app users.
revoke execute on function public.recalculate_match_points(uuid) from public, anon, authenticated;
revoke execute on function public.close_season(uuid) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Hall of Fame view (closed seasons only)
-- ----------------------------------------------------------------------------
create view public.hall_of_fame
with (security_invoker = on) as
select s.id   as season_id,
       s.name as season_name,
       uss.final_rank,
       u.username,
       uss.total_points,
       uss.exact_hits,
       uss.golden_boot_hit,
       ts.name  as top_scorer_name,
       ts.team  as top_scorer_team,
       ts.goals as top_scorer_goals
from public.seasons s
join public.user_season_stats uss on uss.season_id = s.id
join public.users u on u.id = uss.user_id
left join lateral (
  select p.name, p.team, p.goals
  from public.players p
  where p.season_id = s.id and p.goals > 0
  order by p.goals desc
  limit 1
) ts on true
where uss.final_rank is not null and uss.final_rank <= 3
order by s.starts_at desc, uss.final_rank;

-- ----------------------------------------------------------------------------
-- Row Level Security
-- ----------------------------------------------------------------------------
alter table public.users             enable row level security;
alter table public.seasons           enable row level security;
alter table public.season_squads     enable row level security;
alter table public.matches           enable row level security;
alter table public.players           enable row level security;
alter table public.predictions       enable row level security;
alter table public.user_season_stats enable row level security;

-- Everyone logged in can read shared data (leaderboards need all usernames/stats).
create policy "read users"        on public.users             for select to authenticated using (true);
create policy "read seasons"      on public.seasons           for select to authenticated using (true);
create policy "read squads"       on public.season_squads     for select to authenticated using (true);
create policy "read matches"      on public.matches           for select to authenticated using (true);
create policy "read players"      on public.players           for select to authenticated using (true);
create policy "read season stats" on public.user_season_stats for select to authenticated using (true);

-- Users may rename themselves (unique index still applies).
create policy "update own profile" on public.users
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- Predictions: your own are always visible; other people's only once the
-- match is locked (no copying tips before the deadline).
create policy "read predictions" on public.predictions
  for select to authenticated
  using (user_id = auth.uid()
         or not public.prediction_window_open(match_id));

-- The 2-hour rule, enforced server-side.
create policy "insert own prediction while open" on public.predictions
  for insert to authenticated
  with check (user_id = auth.uid()
              and public.prediction_window_open(match_id));

create policy "update own prediction while open" on public.predictions
  for update to authenticated
  using (user_id = auth.uid() and public.prediction_window_open(match_id))
  with check (user_id = auth.uid() and public.prediction_window_open(match_id));

-- Golden boot: users may create/update their stats row only for their own
-- user_id, only before the season's boot lock, and (via column grants below)
-- may only ever touch golden_boot_pick.
create policy "insert own boot pick before lock" on public.user_season_stats
  for insert to authenticated
  with check (user_id = auth.uid()
              and exists (select 1 from public.seasons s
                          where s.id = season_id and s.boot_lock_time > now()));

create policy "update own boot pick before lock" on public.user_season_stats
  for update to authenticated
  using (user_id = auth.uid()
         and exists (select 1 from public.seasons s
                     where s.id = season_id and s.boot_lock_time > now()))
  with check (user_id = auth.uid());

-- No insert/update/delete policies on seasons, season_squads, matches, players:
-- only the worker (service role, bypasses RLS) writes them.

-- ----------------------------------------------------------------------------
-- Column grants: stop users from writing points/ranks even on their own rows
-- ----------------------------------------------------------------------------
revoke insert, update, delete on public.users             from anon, authenticated;
revoke insert, update, delete on public.seasons           from anon, authenticated;
revoke insert, update, delete on public.season_squads     from anon, authenticated;
revoke insert, update, delete on public.matches           from anon, authenticated;
revoke insert, update, delete on public.players           from anon, authenticated;
revoke insert, update, delete on public.predictions       from anon, authenticated;
revoke insert, update, delete on public.user_season_stats from anon, authenticated;
revoke select on public.users, public.seasons, public.season_squads,
                 public.matches, public.players, public.predictions,
                 public.user_season_stats, public.hall_of_fame from anon;

-- Explicit grants (don't rely on Supabase's default privileges)
grant usage on schema public to authenticated, service_role;
grant select on public.users, public.seasons, public.season_squads,
                public.matches, public.players, public.predictions,
                public.user_season_stats, public.hall_of_fame to authenticated;
grant all on all tables in schema public to service_role;

grant update (username) on public.users to authenticated;

grant insert (user_id, match_id, home_score_guess, away_score_guess),
      update (home_score_guess, away_score_guess)
  on public.predictions to authenticated;

grant insert (user_id, season_id, golden_boot_pick),
      update (golden_boot_pick)
  on public.user_season_stats to authenticated;
