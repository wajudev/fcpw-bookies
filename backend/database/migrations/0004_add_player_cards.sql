-- Add yellow and red card tracking to players table

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS yellow_cards INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS red_cards INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS double_yellow INTEGER NOT NULL DEFAULT 0;

-- Add index for quick lookups
CREATE INDEX IF NOT EXISTS idx_players_name_season
ON public.players(season_id, name);

COMMENT ON COLUMN public.players.yellow_cards IS 'Total single yellow cards (not leading to red)';
COMMENT ON COLUMN public.players.red_cards IS 'Total straight red cards';
COMMENT ON COLUMN public.players.double_yellow IS 'Total double yellows (2 yellows = 1 red)';
