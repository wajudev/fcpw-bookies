# FCPW Bookies Backend

Go-based sync worker that fetches FCPW match fixtures and live results from fan.at and syncs them to Supabase.

## Structure

```
backend/
├── cmd/sync/          # Main sync worker entry point
├── internal/
│   ├── db/           # Supabase/Postgres database layer
│   ├── fanat/        # fan.at API client
│   └── sync/         # Sync orchestration logic
├── models/           # Shared data models
└── database/
    └── migrations/   # SQL schema migrations
```

## Setup

1. **Apply database migrations** (in Supabase SQL Editor):
   ```sql
   -- Copy and run backend/database/migrations/0001_initial_schema.sql
   -- Copy and run backend/database/migrations/0002_seed_2026_27_season.sql
   ```

2. **Configure environment** (create `.env` from `.env.example`):
   ```bash
   cp .env.example .env
   ```

   Fill in your Supabase credentials:
   - `DATABASE_URL`: Postgres connection string (Transaction mode, port 5432, NOT pooler)
   - `SUPABASE_URL`: Your project URL (https://xxx.supabase.co)
   - `SUPABASE_SERVICE_ROLE_KEY`: Service role key (Settings → API)

3. **Install dependencies**:
   ```bash
   go mod download
   ```

4. **Build**:
   ```bash
   go build -o bin/sync ./cmd/sync
   ```

## Running

### One-shot sync (test):
```bash
./bin/sync
# Runs one full sync, then exits on first ticker (Ctrl+C after ~1 second)
```

### Continuous (production):
```bash
./bin/sync
# Runs forever:
#  - Full sync every SYNC_INTERVAL_SECONDS (default 3600 = 1h)
#  - Live poll every LIVE_POLL_INTERVAL_SECONDS (default 120 = 2min) for matches within LIVE_POLL_START_MINUTES (default 30min) of kickoff
```

### Environment variables:
- `SYNC_INTERVAL_SECONDS`: Baseline sync frequency (default 3600)
- `LIVE_POLL_INTERVAL_SECONDS`: Tight poll frequency for live matches (default 120)
- `LIVE_POLL_START_MINUTES`: Start live polling this many minutes before kickoff (default 30)

## What it does

1. **Fetches fixtures from fan.at** for all three FCPW squads:
   - KM (team ID `5f26d8076457523192976cef`)
   - Reserve (team ID `5f41648510304553cada7b29`)
   - Women (team ID `5f26d73964575231929767e8`)

2. **Upserts to Supabase `matches` table**:
   - Keyed on `external_id` (fan.at event `_id`)
   - Inserts new fixtures, updates kickoff times on reschedules
   - Writes scores + status for live/finished matches

3. **Triggers automatic scoring**:
   - When a final score is written, the Postgres trigger from Phase 1 fires
   - Recalculates all predictions for that match (3 exact / 1 trend / 0 wrong)
   - Updates `user_season_stats` totals

4. **Adaptive polling**:
   - Slow baseline (hourly) when no matches are imminent
   - Fast (2min) when matches are within 30min of kickoff or currently live
   - Auto-detects the live window from `matches.kickoff_time` in the DB

## Deployment

**Option 1: Long-running process** (VPS, Railway, Fly.io, Render)
- Deploy `./bin/sync` as a background worker
- Set environment variables via the platform's config

**Option 2: Cron job** (if you have a server with cron)
- Run `./bin/sync` once per hour via cron
- Live polling won't work (no daemon), but regular syncs will

**Option 3: Serverless cron** (Supabase Edge Functions + pg_cron, or external cron service)
- Trigger a lightweight edge function on a schedule
- Edge function calls the sync logic (would need refactor to library)

## Testing the fan.at API

```bash
# Verify KM team events are accessible:
curl -s "https://api.fan.at/v2/events/team/5f26d8076457523192976cef/future/0/5" | jq '.data[] | {home: .teams.home.name, away: .teams.away.name, kickoff: .timestamps.kickoff_time}'
```

## Phase completion checklist

- [x] Models (DB + fan.at API structs)
- [x] fan.at client (with retries, backoff, rate-limit handling)
- [x] Database layer (Supabase via pgx)
- [x] Sync service (fetch + upsert logic)
- [x] Main worker (tickers, graceful shutdown)
- [x] Build + test compilation
- [ ] **TODO: Apply Phase 1 migrations to Supabase** (user must do this)
- [ ] **TODO: Configure `.env` with real credentials** (user must do this)
- [ ] **TODO: First live sync test** (user runs `./bin/sync` and verifies matches appear in Supabase)
- [ ] **TODO: Deploy to production** (user picks deployment method)

## Next: Phase 3 (Flutter Auth + UI)
Once the sync worker is running and matches appear in Supabase, Phase 3 will build the Flutter app (auth, games view, leaderboard, profile).
