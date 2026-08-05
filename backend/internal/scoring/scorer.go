package scoring

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// PredictionResult represents a user's prediction with actual result
type PredictionResult struct {
	PredictionID    string
	UserID          string
	MatchID         string
	SeasonID        string
	HomeScorePred   int
	AwayScorePred   int
	HomeScoreActual int
	AwayScoreActual int
}

// ScoringResult holds points awarded for a prediction
type ScoringResult struct {
	PredictionID string
	Points       int
	IsExactHit   bool
}

// Scorer handles all scoring logic
type Scorer struct {
	pool   *pgxpool.Pool
	logger *log.Logger
}

func NewScorer(pool *pgxpool.Pool, logger *log.Logger) *Scorer {
	return &Scorer{
		pool:   pool,
		logger: logger,
	}
}

// CalculatePoints calculates points for a single prediction
// TODO: Update this function when scoring document arrives
func (s *Scorer) CalculatePoints(pred PredictionResult) ScoringResult {
	result := ScoringResult{
		PredictionID: pred.PredictionID,
		Points:       0,
		IsExactHit:   false,
	}

	// PLACEHOLDER LOGIC - Replace with actual rules from document

	// Exact score match
	if pred.HomeScorePred == pred.HomeScoreActual && pred.AwayScorePred == pred.AwayScoreActual {
		result.Points = 3
		result.IsExactHit = true
		return result
	}

	// Correct outcome (win/draw/loss)
	predOutcome := getOutcome(pred.HomeScorePred, pred.AwayScorePred)
	actualOutcome := getOutcome(pred.HomeScoreActual, pred.AwayScoreActual)

	if predOutcome == actualOutcome {
		result.Points = 1
		return result
	}

	// Wrong prediction
	return result
}

// ScoreMatch scores all predictions for a finished match by UUID or external_id
func (s *Scorer) ScoreMatch(ctx context.Context, matchID string) error {
	s.logger.Printf("Scoring match: %s", matchID)

	// 1. Get match details (works with both UUID id or external_id)
	var homeActual, awayActual *int
	var seasonID, actualMatchID string
	err := s.pool.QueryRow(ctx, `
		SELECT id, season_id, home_score_actual, away_score_actual
		FROM matches
		WHERE (id::text = $1 OR external_id = $1) AND status = 'finished'
	`, matchID).Scan(&actualMatchID, &seasonID, &homeActual, &awayActual)

	if err == pgx.ErrNoRows {
		return fmt.Errorf("match not found or not finished: %s", matchID)
	}
	if err != nil {
		return fmt.Errorf("failed to get match: %w", err)
	}

	if homeActual == nil || awayActual == nil {
		return fmt.Errorf("match %s has no actual scores", matchID)
	}

	// 2. Get all predictions for this match (use actual UUID)
	predictions, err := s.getPredictions(ctx, actualMatchID)
	if err != nil {
		return fmt.Errorf("failed to get predictions: %w", err)
	}

	s.logger.Printf("Found %d predictions to score", len(predictions))

	// 3. Calculate points for each prediction
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	for _, pred := range predictions {
		result := s.CalculatePoints(pred)

		// Update prediction with points
		_, err := tx.Exec(ctx, `
			UPDATE predictions
			SET points = $1, scored_at = $2
			WHERE id = $3
		`, result.Points, time.Now(), result.PredictionID)

		if err != nil {
			return fmt.Errorf("failed to update prediction %s: %w", result.PredictionID, err)
		}

		// Update user season stats
		_, err = tx.Exec(ctx, `
			UPDATE user_season_stats
			SET
				total_points = total_points + $1,
				exact_hits = exact_hits + $2
			WHERE user_id = $3 AND season_id = $4
		`, result.Points, boolToInt(result.IsExactHit), pred.UserID, pred.SeasonID)

		if err != nil {
			return fmt.Errorf("failed to update user stats for %s: %w", pred.UserID, err)
		}

		s.logger.Printf("User %s: %d points (exact: %v)", pred.UserID, result.Points, result.IsExactHit)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit scores: %w", err)
	}

	s.logger.Printf("Successfully scored match %s", matchID)
	return nil
}

// ScoreMatchweek scores all finished matches in a matchweek
func (s *Scorer) ScoreMatchweek(ctx context.Context, seasonID string, matchweek int) error {
	s.logger.Printf("Scoring matchweek %d for season %s", matchweek, seasonID)

	rows, err := s.pool.Query(ctx, `
		SELECT id FROM matches
		WHERE season_id = $1
		AND matchweek = $2
		AND status = 'finished'
		AND (home_score_actual IS NOT NULL AND away_score_actual IS NOT NULL)
	`, seasonID, matchweek)

	if err != nil {
		return fmt.Errorf("failed to get matches: %w", err)
	}
	defer rows.Close()

	matchCount := 0
	for rows.Next() {
		var matchID string
		if err := rows.Scan(&matchID); err != nil {
			return fmt.Errorf("failed to scan match: %w", err)
		}

		if err := s.ScoreMatch(ctx, matchID); err != nil {
			s.logger.Printf("ERROR scoring match %s: %v", matchID, err)
			// Continue with other matches
		} else {
			matchCount++
		}
	}

	s.logger.Printf("Scored %d matches in matchweek %d", matchCount, matchweek)
	return nil
}

// getPredictions retrieves all predictions for a match
func (s *Scorer) getPredictions(ctx context.Context, matchID string) ([]PredictionResult, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT
			p.id,
			p.user_id,
			p.match_id,
			p.season_id,
			p.home_score,
			p.away_score,
			m.home_score_actual,
			m.away_score_actual
		FROM predictions p
		JOIN matches m ON p.match_id = m.id
		WHERE p.match_id = $1
	`, matchID)

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var predictions []PredictionResult
	for rows.Next() {
		var pred PredictionResult
		err := rows.Scan(
			&pred.PredictionID,
			&pred.UserID,
			&pred.MatchID,
			&pred.SeasonID,
			&pred.HomeScorePred,
			&pred.AwayScorePred,
			&pred.HomeScoreActual,
			&pred.AwayScoreActual,
		)
		if err != nil {
			return nil, err
		}
		predictions = append(predictions, pred)
	}

	return predictions, nil
}

// Helper functions

func getOutcome(homeScore, awayScore int) string {
	if homeScore > awayScore {
		return "home_win"
	}
	if awayScore > homeScore {
		return "away_win"
	}
	return "draw"
}

func boolToInt(b bool) int {
	if b {
		return 1
	}
	return 0
}
