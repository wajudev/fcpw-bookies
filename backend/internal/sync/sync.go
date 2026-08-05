package sync

import (
	"context"
	"fmt"
	"log"
	"time"

	"fcpw-bookies-backend/internal/db"
	"fcpw-bookies-backend/internal/fanat"
	"fcpw-bookies-backend/internal/scoring"
	"fcpw-bookies-backend/models"
)

type Service struct {
	db     *db.DB
	fanat  *fanat.Client
	scorer *scoring.Scorer
	logger *log.Logger
}

func NewService(database *db.DB, logger *log.Logger) *Service {
	return &Service{
		db:     database,
		fanat:  fanat.NewClient(),
		scorer: scoring.NewScorer(database.GetPool(), logger),
		logger: logger,
	}
}

// SyncAll fetches and syncs all squads for the current season
func (s *Service) SyncAll(ctx context.Context) error {
	season, err := s.db.GetCurrentSeason(ctx)
	if err != nil {
		return fmt.Errorf("get current season: %w", err)
	}
	if season == nil {
		return fmt.Errorf("no current season found")
	}

	s.logger.Printf("Syncing season %s (%s)", season.Name, season.ID)

	squads, err := s.db.GetSeasonSquads(ctx, season.ID)
	if err != nil {
		return fmt.Errorf("get squads: %w", err)
	}

	for _, squad := range squads {
		if err := s.syncSquad(ctx, season, &squad); err != nil {
			s.logger.Printf("ERROR syncing %s: %v", squad.Squad, err)
			continue
		}
	}

	s.logger.Println("Sync complete")
	return nil
}

func (s *Service) syncSquad(ctx context.Context, season *models.Season, squad *models.SeasonSquad) error {
	s.logger.Printf("  [%s] Fetching events from fan.at (team %s)", squad.Squad, squad.FanatLeagueID)

	events, err := s.fanat.FetchAllTeamEvents(squad.FanatLeagueID)
	if err != nil {
		return fmt.Errorf("fetch events: %w", err)
	}

	s.logger.Printf("  [%s] Got %d events", squad.Squad, len(events))

	synced := 0
	skipped := 0
	scored := 0
	for _, event := range events {
		kickoff := time.UnixMilli(event.Timestamps.Start)

		// Skip matches outside this season's date range
		if kickoff.Before(season.StartsAt) || kickoff.After(season.EndsAt) {
			skipped++
			continue
		}

		oldMatch := s.getExistingMatch(ctx, event.ID)
		match := s.eventToMatch(&event, season.ID, squad.Squad)
		if err := s.db.UpsertMatch(ctx, match); err != nil {
			s.logger.Printf("  [%s] WARN: upsert match %s failed: %v", squad.Squad, event.ID, err)
			continue
		}
		synced++

		// AUTO-SCORE: If match just became finished, score it
		if s.shouldAutoScore(oldMatch, match) {
			s.logger.Printf("  [%s] 🎯 Auto-scoring match: %s vs %s", squad.Squad, match.HomeTeam, match.AwayTeam)

			// Fetch liveticker to get goal scorers and cards
			s.updatePlayerStatsFromLiveticker(ctx, &event, season.ID, squad.Squad)

			// Score predictions
			if err := s.scorer.ScoreMatch(ctx, match.ExternalID); err != nil {
				s.logger.Printf("  [%s] ERROR auto-scoring %s: %v", squad.Squad, match.ExternalID, err)
			} else {
				scored++
			}
		}
	}

	s.logger.Printf("  [%s] Synced %d matches (skipped %d outside season %s - %s, auto-scored %d)",
		squad.Squad, synced, skipped, season.StartsAt.Format("2006-01-02"), season.EndsAt.Format("2006-01-02"), scored)
	return nil
}

// getExistingMatch retrieves the current state of a match before update
func (s *Service) getExistingMatch(ctx context.Context, externalID string) *models.Match {
	// Simple query to get match status before update
	var status string
	var homeScore, awayScore *int

	err := s.db.GetPool().QueryRow(ctx, `
		SELECT status, home_score_actual, away_score_actual
		FROM matches
		WHERE external_id = $1
	`, externalID).Scan(&status, &homeScore, &awayScore)

	if err != nil {
		return nil // Match doesn't exist yet
	}

	return &models.Match{
		Status:          status,
		HomeScoreActual: homeScore,
		AwayScoreActual: awayScore,
	}
}

// shouldAutoScore determines if a match should be auto-scored
func (s *Service) shouldAutoScore(old, new *models.Match) bool {
	// No old match = brand new, don't score
	if old == nil {
		return false
	}

	// New match not finished = don't score
	if new.Status != "finished" {
		return false
	}

	// Old match already finished = already scored
	if old.Status == "finished" {
		return false
	}

	// New match must have scores
	if new.HomeScoreActual == nil || new.AwayScoreActual == nil {
		return false
	}

	// Match just transitioned to finished!
	s.logger.Printf("    ✅ Match status changed: %s → finished", old.Status)
	return true
}

// updatePlayerStatsFromLiveticker fetches liveticker and updates player goals/cards
func (s *Service) updatePlayerStatsFromLiveticker(ctx context.Context, event *models.FanatEvent, seasonID, squad string) {
	// Fetch liveticker events
	livetickerEvents, err := s.fanat.FetchLiveticker(event.ID, event.Teams.Home.TeamID)
	if err != nil {
		s.logger.Printf("    WARN: Failed to fetch liveticker: %v", err)
		return
	}

	if len(livetickerEvents) == 0 {
		s.logger.Printf("    No liveticker events found (match might not have detailed stats)")
		return
	}

	s.logger.Printf("    📊 Processing %d liveticker events", len(livetickerEvents))

	// Process each event
	for _, evt := range livetickerEvents {
		switch evt.Type {
		case "goal":
			s.updatePlayerGoals(ctx, evt.PlayerName, seasonID, 1)
		case "yellow_card":
			s.updatePlayerCards(ctx, evt.PlayerName, seasonID, "yellow")
		case "red_card":
			s.updatePlayerCards(ctx, evt.PlayerName, seasonID, "red")
		}
	}
}

// updatePlayerGoals increments a player's goal count
func (s *Service) updatePlayerGoals(ctx context.Context, playerName, seasonID string, goals int) {
	result, err := s.db.GetPool().Exec(ctx, `
		UPDATE players
		SET goals = goals + $1
		WHERE season_id = $2
		AND (
			name = $3
			OR name ILIKE $3  -- Case-insensitive
			OR LOWER(name) = LOWER($3)
		)
	`, goals, seasonID, playerName)

	if err != nil {
		s.logger.Printf("    ERROR updating goals for %s: %v", playerName, err)
		return
	}

	if result.RowsAffected() == 0 {
		s.logger.Printf("    ⚠️  Player not found: %s (might need to add to database)", playerName)
	} else {
		s.logger.Printf("    ⚽ %s +%d goal(s)", playerName, goals)
	}
}

// updatePlayerCards increments a player's card count
func (s *Service) updatePlayerCards(ctx context.Context, playerName, seasonID, cardType string) {
	column := "yellow_cards"
	emoji := "🟨"
	if cardType == "red" {
		column = "red_cards"
		emoji = "🟥"
	}

	result, err := s.db.GetPool().Exec(ctx, fmt.Sprintf(`
		UPDATE players
		SET %s = %s + 1
		WHERE season_id = $1
		AND (
			name = $2
			OR name ILIKE $2
			OR LOWER(name) = LOWER($2)
		)
	`, column, column), seasonID, playerName)

	if err != nil {
		s.logger.Printf("    ERROR updating cards for %s: %v", playerName, err)
		return
	}

	if result.RowsAffected() == 0 {
		s.logger.Printf("    ⚠️  Player not found: %s", playerName)
	} else {
		s.logger.Printf("    %s %s card for %s", emoji, cardType, playerName)
	}
}

func (s *Service) eventToMatch(event *models.FanatEvent, seasonID, squad string) *models.Match {
	m := &models.Match{
		ExternalID:  event.ID,
		SeasonID:    seasonID,
		Squad:       squad,
		HomeTeam:    event.Teams.Home.Name,
		AwayTeam:    event.Teams.Away.Name,
		KickoffTime: time.UnixMilli(event.Timestamps.Start),
		Status:      mapStatus(event.Status),
	}

	// fan.at returns score=-1 for unplayed matches; map to NULL
	if event.Teams.Home.Score >= 0 {
		m.HomeScoreActual = &event.Teams.Home.Score
	}
	if event.Teams.Away.Score >= 0 {
		m.AwayScoreActual = &event.Teams.Away.Score
	}

	// Extract round info (e.g. "Runde 3", nr=3)
	if event.Round.Nr > 0 {
		m.Matchweek = &event.Round.Nr
	}
	if event.Round.UIName != "" {
		m.MatchweekName = &event.Round.UIName
	}

	return m
}

// mapStatus translates fan.at status values to our DB enum
func mapStatus(fanatStatus string) string {
	switch fanatStatus {
	case "upcoming", "pregame":
		return "upcoming"
	case "live", "running":
		return "live"
	case "ended", "finished", "cancelled":
		return "finished"
	default:
		// Unknown status, default to upcoming to avoid DB errors
		return "upcoming"
	}
}

// SyncLive performs a tight poll of matches near kickoff
func (s *Service) SyncLive(ctx context.Context, windowMinutes int) error {
	season, err := s.db.GetCurrentSeason(ctx)
	if err != nil {
		return fmt.Errorf("get current season: %w", err)
	}
	if season == nil {
		return nil // No active season, nothing to poll
	}

	now := time.Now()
	windowStart := now.Add(-time.Duration(windowMinutes) * time.Minute)
	windowEnd := now.Add(3 * time.Hour) // Match still live up to ~3h after kickoff

	matches, err := s.db.GetUpcomingMatches(ctx, season.ID, windowStart, windowEnd)
	if err != nil {
		return fmt.Errorf("get upcoming: %w", err)
	}

	if len(matches) == 0 {
		return nil
	}

	s.logger.Printf("Live poll: %d match(es) in window", len(matches))

	// Re-sync all three squads (simpler than per-match fetches; fan.at API is team-scoped)
	return s.SyncAll(ctx)
}
