-- Migration: Add missing card count columns and CHECK constraints
-- Ensures users cannot submit negative or zero predictions

-- Add missing card count columns (0006 may not have been run)
ALTER TABLE public.user_season_stats
  ADD COLUMN IF NOT EXISTS yellow_card_pick_count INTEGER,
  ADD COLUMN IF NOT EXISTS red_card_pick_count INTEGER;

COMMENT ON COLUMN public.user_season_stats.yellow_card_pick_count IS 'User''s predicted count for most yellow cards';
COMMENT ON COLUMN public.user_season_stats.red_card_pick_count IS 'User''s predicted count for most red cards';

-- Add CHECK constraints for positive values
-- Use existing column name: golden_boot_goals_prediction (not golden_boot_pick_count)

-- Drop constraints if they exist, then recreate (idempotent)
DO $$
BEGIN
  ALTER TABLE public.user_season_stats DROP CONSTRAINT IF EXISTS golden_boot_goals_prediction_positive;
  ALTER TABLE public.user_season_stats DROP CONSTRAINT IF EXISTS yellow_card_pick_count_positive;
  ALTER TABLE public.user_season_stats DROP CONSTRAINT IF EXISTS red_card_pick_count_positive;
END $$;

ALTER TABLE public.user_season_stats
  ADD CONSTRAINT golden_boot_goals_prediction_positive
  CHECK (golden_boot_goals_prediction IS NULL OR golden_boot_goals_prediction > 0);

ALTER TABLE public.user_season_stats
  ADD CONSTRAINT yellow_card_pick_count_positive
  CHECK (yellow_card_pick_count IS NULL OR yellow_card_pick_count > 0);

ALTER TABLE public.user_season_stats
  ADD CONSTRAINT red_card_pick_count_positive
  CHECK (red_card_pick_count IS NULL OR red_card_pick_count > 0);
