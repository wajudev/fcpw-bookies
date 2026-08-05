-- Add league standings table

CREATE TABLE IF NOT EXISTS public.team_standings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    season_id UUID NOT NULL REFERENCES public.seasons(id) ON DELETE CASCADE,
    squad TEXT NOT NULL, -- 'km', 'reserve', 'women'
    team_name TEXT NOT NULL,
    position INTEGER NOT NULL,
    played INTEGER NOT NULL DEFAULT 0,
    won INTEGER NOT NULL DEFAULT 0,
    drawn INTEGER NOT NULL DEFAULT 0,
    lost INTEGER NOT NULL DEFAULT 0,
    goals_for INTEGER NOT NULL DEFAULT 0,
    goals_against INTEGER NOT NULL DEFAULT 0,
    goal_difference INTEGER NOT NULL DEFAULT 0,
    points INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(season_id, squad, team_name)
);

CREATE INDEX IF NOT EXISTS idx_standings_season_squad
ON public.team_standings(season_id, squad, position);

COMMENT ON TABLE public.team_standings IS 'League standings for each squad';
COMMENT ON COLUMN public.team_standings.squad IS 'Squad identifier: km, reserve, or women';
COMMENT ON COLUMN public.team_standings.position IS 'League position (1 = first place)';
