-- Separate Golden Boot for Men and Women + Add Matches Played

-- 1. Add gender and matches played to players table
ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT 'M' CHECK (gender IN ('M', 'F')),
ADD COLUMN IF NOT EXISTS matches_played INTEGER DEFAULT 0;

-- 2. Add index for quick gender filtering
CREATE INDEX IF NOT EXISTS idx_players_gender_goals
ON public.players(season_id, gender, goals DESC);

-- 3. Add separate women's golden boot pick to user_season_stats
ALTER TABLE public.user_season_stats
ADD COLUMN IF NOT EXISTS golden_boot_pick_women UUID REFERENCES public.players(id);

-- 4. Keep golden_boot_pick as alias for men (backwards compatible)
-- Add new column for women only
-- NOTE: If you want to rename golden_boot_pick → golden_boot_pick_men,
-- uncomment below and update all queries:
-- ALTER TABLE public.user_season_stats
-- RENAME COLUMN golden_boot_pick TO golden_boot_pick_men;

-- 5. Comments
COMMENT ON COLUMN public.players.gender IS 'Player gender: M = Men, F = Women';
COMMENT ON COLUMN public.players.matches_played IS 'Number of matches played by this player';
COMMENT ON COLUMN public.user_season_stats.golden_boot_pick_men IS 'User''s prediction for top goal scorer (Men) - kept for backwards compatibility';
COMMENT ON COLUMN public.user_season_stats.golden_boot_pick_women IS 'User''s prediction for top goal scorer (Women)';
