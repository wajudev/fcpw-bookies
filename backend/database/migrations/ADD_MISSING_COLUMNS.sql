-- Add missing columns to players table

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS red_cards INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS yellow_cards INTEGER NOT NULL DEFAULT 0;

-- Add index for quick lookups
CREATE INDEX IF NOT EXISTS idx_players_name_season
ON public.players(season_id, name);

-- Add comments
COMMENT ON COLUMN public.players.goals IS 'Total goals scored this season';
COMMENT ON COLUMN public.players.red_cards IS 'Total straight red cards (not double yellow)';
COMMENT ON COLUMN public.players.double_yellow IS 'Total double yellows (2 yellows in one match = red card)';
COMMENT ON COLUMN public.players.yellow_cards IS 'Total single yellow cards (not leading to red)';

-- Verify
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'players'
ORDER BY ordinal_position;
