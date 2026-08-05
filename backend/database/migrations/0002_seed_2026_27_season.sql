-- ============================================================================
-- 1. FCPW Predictor — Seed: 2026/27 season with three squads
-- Run this AFTER 0001_initial_schema.sql has been applied.
-- ============================================================================

-- Adjust these dates to match the actual 2026/27 season calendar:
insert into public.seasons (id, name, starts_at, ends_at, boot_lock_time, is_current)
values (
  'bbbbbbbb-2026-2027-0000-000000000000',
  '2026/27',
  '2026-09-01 00:00:00+02',                -- season starts (approx first matchday)
  '2027-06-30 23:59:59+02',                -- season ends (approx last matchday)
  '2026-09-05 15:00:00+02',                -- golden boot locks (adjust to ~1 week before first match)
  true                                     -- this is the current season
);

-- Map each squad to its fan.at team. The worker will resolve league/season IDs on first run.
insert into public.season_squads (season_id, squad, fanat_league_slug, fanat_league_id, fanat_season_id)
values
  -- KM (men's first team): https://1-fc-paulaner-wieden.fan.at
  ('bbbbbbbb-2026-2027-0000-000000000000', 'km',
   '1-fc-paulaner-wieden',                 -- readable_id (slug)
   '5f26d8076457523192976cef',             -- team ID (not league ID; worker fetches team events)
   null),                                  -- season ID resolved by worker

  -- Reserve (men's second team, same player pool): https://1-sc-paulaner-wieden-res.fan.at
  ('bbbbbbbb-2026-2027-0000-000000000000', 'reserve',
   '1-sc-paulaner-wieden-res',
   '5f41648510304553cada7b29',
   null),

  -- Women: https://1-fc-paulaner-wieden-damen.fan.at
  ('bbbbbbbb-2026-2027-0000-000000000000', 'women',
   '1-fc-paulaner-wieden-damen',
   '5f26d73964575231929767e8',
   null);

-- NOTE: The worker (Phase 2) will call:
--   GET https://api.fan.at/v2/events/team/{fanat_league_id}/future/0/50
--   GET https://api.fan.at/v2/events/team/{fanat_league_id}/past/0/50
-- to fetch FCPW-only matches (not the entire league). The `fanat_league_id` column here
-- is actually the **team ID** — naming kept for schema consistency, but semantics differ
-- from the league-wide approach. Worker upserts to `matches` keyed on event._id.
