# Project Master Document: 1. FCPW Tippspiel App

## 1. Project Context & Objectives
* **App Name:** 1. FCPW Predictor (1. FC Paulaner Wieden Tippspiel)
* **Target Audience:** Club players and fans (Sunday League / DSG in Vienna).
* **Primary UI Language:** German.
* **Core Goal:** Build a fully automated application that handles fixtures, live results, locking mechanisms, user predictions, and leaderboard calculations automatically to reduce administrative overhead.
* **Longevity:** The app runs **season after season**. Historical records are kept forever: past leaderboards, past golden-boot outcomes, and a **Hall of Fame** honoring each season's winner.

## 2. Technical Stack
* **Frontend / UI:** Dart (Flutter). Used to build a responsive, mobile-first cross-platform application.
* **Backend Worker / Sync Service:** Go (Golang). A standalone service that fetches fixtures **and live results** from the fan.at JSON API (see §6) and synchronizes them into the database.
* **Database & Authentication:** Supabase. Handles secure user logins (Passwords/Auth), PostgreSQL database management, and Row Level Security (RLS) to ensure users can only edit their own predictions.

## 3. Core Business Logic & Rules
* **Identity: username only.**
  * This is a friends league — no first/last name anywhere. Each user has a unique `username` shown in leaderboards, Hall of Fame, and profile.
  * Under the hood, Supabase Auth still uses **email + password** for login and password reset; the email is never displayed to other users.
* **Seasons as the organizing unit.**
  * Every match, prediction, golden-boot pick, and point total belongs to exactly one season.
  * When a season ends, its standings are frozen (final ranks written) and a new season starts fresh at 0 points. Nothing is deleted — history powers the Hall of Fame.
* **The "2-Hour Rule" (Match Predictions):**
  * Users can predict scores for three squads: DSG KM, Reserves, and Women.
  * Predictions close exactly **2 hours before the scheduled kickoff time**.
  * **Enforced in the database, not only the UI:** the RLS `INSERT`/`UPDATE` policies on `predictions` must check `matches.kickoff_time - interval '2 hours' > now()`. Disabling the Flutter input fields is UX only — the API must reject late writes regardless of client.
  * No prediction = 0 points.
* **The Golden Boot (Saisontipp):**
  * Per season, users predict the top goalscorer, chosen from a **dropdown backed by the `players` table** (no free-text entry — avoids name-matching problems at season's end).
  * The pick locks globally at the season's `boot_lock_time`, enforced server-side (RLS policy / trigger), mirrored as a disabled UI state.
* **Point Calculation System:**
  * **3 Punkte:** Exact correct score (Predicted 2-1, Result 2-1).
  * **1 Punkt:** Correct trend / 1X2 outcome (Predicted 2-0, Result 3-1 → both home wins).
  * **0 Punkte:** Wrong trend or late entry.
  * Scoring must be **idempotent**: when a result is written (or corrected), recalculate all `points_awarded` for that match from scratch, then recompute that season's user totals — never increment blindly.

## 4. Flutter (Dart) UI Requirements
The app must feature a dark mode aesthetic (Navy Blue `#002d72`, Gold/Yellow `#EAB308`, Slate backgrounds) mapped to four main views:
1. **Games View (Spiele):**
   * A `TabBar` to switch between KM, Reserve, and Frauen (current season).
   * UI states mapped to Match Status (e.g., active input fields for "Offen", disabled fields + red warning for "Gesperrt", live score display for "Live").
   * Golden boot section at the top: dropdown of players (from `players`), locked after `boot_lock_time`.
2. **Leaderboard View (Rangliste):**
   * A `ListView` or `DataTable` ranking all users, defaulting to the **current season** with a season switcher to browse past seasons' final tables.
   * Columns: Rang, Name (username), Volltreffer, Punkte.
3. **Hall of Fame View (Ruhmeshalle):**
   * One card per completed season: season name, **champion** (username + points), podium (top 3), and the actual golden-boot winner vs. who picked them correctly.
   * Read-only, derived entirely from frozen `user_season_stats`.
4. **Profile View (Profil):**
   * Username, current-season stats, and career stats (titles won, total career points, best-ever rank) via Supabase.
   * Authentication state management (Login/Register/Logout).

## 5. Database Schema (Supabase / PostgreSQL)
*Ensure Row Level Security (RLS) is enabled so users can only insert/update their own rows, and only inside the allowed time windows. All season-scoped data is kept forever.*

**Table: `users`** — identity only; no per-season data here
* `id` (UUID, Primary Key, references `auth.uid()`)
* `username` (Text, **Unique**, `CHECK` on length/charset) — the only name anyone sees
* `created_at` (Timestamptz)
* *Note:* Auto-create this row via a trigger on `auth.users` at signup (username passed as signup metadata).

**Table: `seasons`**
* `id` (UUID, Primary Key)
* `name` (Text, e.g. "2026/27")
* `starts_at` / `ends_at` (Timestamptz)
* `boot_lock_time` (Timestamptz) — global golden-boot lock
* `is_current` (Boolean) — exactly one true (partial unique index)

**Table: `season_squads`** — maps each squad to its fan.at league/season for one of our seasons
* `season_id` (UUID, FK → seasons.id)
* `squad` (Enum/Text: 'km', 'reserve', 'women')
* `fanat_league_slug` (Text, e.g. "dsg-oberliga-a-w")
* `fanat_league_id` / `fanat_season_id` (Text) — resolved & cached by the worker
* *Constraint:* Unique (`season_id`, `squad`).

**Table: `matches`**
* `id` (UUID, Primary Key)
* `external_id` (Text, Unique) — the fan.at event `_id`; stable upsert key that survives reschedules
* `season_id` (UUID, FK → seasons.id)
* `squad` (Enum/Text: 'km', 'reserve', 'women')
* `home_team` / `away_team` (Text)
* `kickoff_time` (Timestamptz)
* `home_score_actual` / `away_score_actual` (Integer, nullable)
* `status` (Text: 'upcoming', 'live', 'finished') — mirrored from fan.at; the *prediction lock* is always derived from `kickoff_time`, not from this field

**Table: `players`** — one row per player per season (roster snapshot)
* `id` (UUID, Primary Key)
* `external_id` (Text) — fan.at player id where available
* `season_id` (UUID, FK → seasons.id)
* `name` (Text)
* `team` (Text)
* `goals` (Integer, default 0) — synced by the worker; resolves the Golden Boot automatically
* *Constraint:* Unique (`external_id`, `season_id`). Feeds the golden-boot dropdown for that season.

**Table: `predictions`**
* `id` (UUID, Primary Key)
* `user_id` (UUID, FK → users.id)
* `match_id` (UUID, FK → matches.id)
* `home_score_guess` / `away_score_guess` (Integer, `CHECK >= 0`)
* `points_awarded` (Integer, nullable)
* *Constraint:* Unique (`user_id`, `match_id`). Season scope is inherited via the match.

**Table: `user_season_stats`** — the per-season scoreboard; replaces points columns on `users`
* `user_id` (UUID, FK → users.id)
* `season_id` (UUID, FK → seasons.id)
* `total_points` (Integer, default 0) — maintained by the idempotent scoring function
* `exact_hits` (Integer, default 0)
* `golden_boot_pick` (UUID, nullable, FK → players.id) — user-writable only before `boot_lock_time` (RLS)
* `golden_boot_hit` (Boolean, nullable) — resolved at season end
* `final_rank` (Integer, nullable) — written when the season is closed; NULL while running
* *Constraint:* Unique (`user_id`, `season_id`). Row is created on first participation in a season.

**Hall of Fame** — no extra table needed: a view over `user_season_stats` joined to `seasons` where `final_rank IS NOT NULL`, exposing champion/podium per season plus the season's actual top scorer from `players`.

## 6. Fixture & Result Fetcher Service (Go)

### Decision: fan.at JSON API, not wfv.at scraping, not iCal
* **wfv.at is not viable for automation:** the site sits behind **Anubis** (proof-of-work anti-bot protection). Plain HTTP clients receive a JS challenge page, not league data. Getting through would require a headless browser and deliberately defeating a bot wall — fragile and unfriendly.
* **fan.at mirrors the same WFV/DSG data** and exposes an **open, unauthenticated JSON API** (`api.fan.at`) with no bot protection. It carries fixtures, kickoff times, live status, final scores, tables, and rosters. Verified July 2026 for DSG Oberliga A.

### Known API surface (verified)
* League lookup by slug: `GET https://api.fan.at/readable-id/dsg-oberliga-a-w` → league `objectid` (`62c58a64836dc75b348e5e88` for DSG Oberliga A) and its `seasons[]` (e.g. 2026/27 = `6a45b99386c8af017a34ca6a`). **The `seasons[]` list is also how new seasons are detected automatically.**
* Fixtures/results: `GET https://api.fan.at/v2/events/season/{seasonId}/future/{offset}/{limit}` and `.../past/{offset}/{limit}`. Each event includes `_id`, `teams.home/away` (`name`, `teamid`, `score`), `status` (`upcoming`/live/finished), `round`, and `timestamps` (kickoff).
* League table: `GET https://api.fan.at/v2/seasons/{seasonId}/tables`.
* Teams/rosters: `GET https://api.fan.at/leagues/{leagueId}/teams?sorted=true`.
* Top scorers: endpoint is loaded client-side on the Statistiken page — still to be identified (inspect the XHR calls in a browser). Fallback: aggregate goalscorers from per-event detail data.
* Each FCPW squad (KM, Reserve, Frauen) plays in its own league → one `season_squads` row per squad per season.

### Worker logic
1. On each run, for every `season_squads` row of the current season: resolve/cache league & season ids, fetch future + past events.
2. **Upsert** into `matches` keyed on `external_id` (fan.at event `_id`) — inserts new fixtures, updates `kickoff_time` on reschedules, writes scores and `status` on/after match days.
3. Sync `players` (roster + goal tallies, per season) to keep the golden-boot dropdown and standings current.
4. Writing a final score triggers the scoring function (§3) via a Postgres trigger or an explicit RPC call.
5. **Live results:** adaptive polling — a slow baseline (e.g. hourly) that tightens to every 1–2 minutes from kickoff until the event status is `finished`. Kickoff times are known in advance, so the worker can schedule its own tight-poll windows.
6. **Season rollover:** when fan.at publishes a new season for a tracked league, the worker flags it (or auto-creates the `seasons` + `season_squads` rows). Closing the old season — writing `final_rank`, resolving `golden_boot_hit`, flipping `is_current` — runs as an explicit closing routine once all its matches are finished.
7. Connect to Supabase via the Postgres connection string (`database/sql` + pgx) using the service role, bypassing RLS.
8. Be a polite client: identify with a UA string, cache season/league ids, back off on errors.

## 7. Suggested Prompting Roadmap (For LLM Assistant)
1. **Phase 1: Supabase Setup.** "Write the SQL to create the `users`, `seasons`, `season_squads`, `matches`, `players`, `predictions`, and `user_season_stats` tables with RLS policies that (a) restrict writes to the owner, (b) enforce the 2-hour prediction lock and the golden-boot `boot_lock_time` in the policy itself, and (c) keep all historical seasons readable. Include the signup trigger on `auth.users` (username from metadata) and the Hall-of-Fame view."
2. **Phase 2: Go fan.at Sync Worker.** "Write a Go service that resolves fan.at league slugs to season ids, fetches future/past events, and upserts fixtures, live scores, and final results into Supabase Postgres keyed on the fan.at event id, with adaptive polling around kickoff windows and a season-rollover/closing routine."
3. **Phase 3: Dart Auth.** "Write a Flutter auth service using the `supabase_flutter` package with login and registration UI (email + password + unique username as display identity)."
4. **Phase 4: Flutter Games UI.** "Create a Flutter screen that fetches upcoming matches from Supabase, checks the current time against `kickoff_time`, disables the score inputs within 2 hours of kickoff, shows live scores for in-play matches, and renders the golden-boot player dropdown."
5. **Phase 5: Scoring Logic.** "Write an idempotent Supabase Database Function (PL/pgSQL) that recalculates points (3 exact, 1 trend) for all predictions of a match whenever its actual score is written or corrected, then recomputes that season's `user_season_stats`."
6. **Phase 6: Leaderboard, Hall of Fame & Profile.** "Build the Rangliste view with a season switcher, the Ruhmeshalle view over the Hall-of-Fame view (champion, podium, golden-boot outcome per season), and the profile with career stats (titles, career points, best rank)."
