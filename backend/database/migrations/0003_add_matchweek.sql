-- Add matchweek columns to matches table
ALTER TABLE matches
ADD COLUMN IF NOT EXISTS matchweek INTEGER,
ADD COLUMN IF NOT EXISTS matchweek_name TEXT;

-- Create index for efficient matchweek queries
CREATE INDEX IF NOT EXISTS idx_matches_matchweek ON matches(season_id, squad, matchweek);

-- Add comment explaining source
COMMENT ON COLUMN matches.matchweek IS 'Round number from fan.at API (round.nr)';
COMMENT ON COLUMN matches.matchweek_name IS 'Round display name from fan.at API (round.ui_name, e.g. "Runde 3")';
