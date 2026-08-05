-- Add card predictions (most yellow/red cards)

ALTER TABLE public.user_season_stats
ADD COLUMN IF NOT EXISTS yellow_card_pick UUID REFERENCES public.players(id),
ADD COLUMN IF NOT EXISTS red_card_pick UUID REFERENCES public.players(id),
ADD COLUMN IF NOT EXISTS yellow_card_hit BOOLEAN,
ADD COLUMN IF NOT EXISTS red_card_hit BOOLEAN;

COMMENT ON COLUMN public.user_season_stats.yellow_card_pick IS 'User''s prediction for most yellow cards';
COMMENT ON COLUMN public.user_season_stats.red_card_pick IS 'User''s prediction for most red cards';
COMMENT ON COLUMN public.user_season_stats.yellow_card_hit IS 'Did user correctly predict yellow card leader';
COMMENT ON COLUMN public.user_season_stats.red_card_hit IS 'Did user correctly predict red card leader';
