package db

import (
	"context"
	"fmt"
	"time"

	"fcpw-bookies-backend/models"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type DB struct {
	pool *pgxpool.Pool
}

func New(databaseURL string) (*DB, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("ping: %w", err)
	}

	return &DB{pool: pool}, nil
}

func (db *DB) Close() {
	db.pool.Close()
}

// GetPool returns the underlying connection pool for direct queries
func (db *DB) GetPool() *pgxpool.Pool {
	return db.pool
}

// GetCurrentSeason fetches the active season
func (db *DB) GetCurrentSeason(ctx context.Context) (*models.Season, error) {
	var s models.Season
	err := db.pool.QueryRow(ctx, `
		SELECT id, name, starts_at, ends_at, boot_lock_time, is_current
		FROM seasons
		WHERE is_current = true
		LIMIT 1
	`).Scan(&s.ID, &s.Name, &s.StartsAt, &s.EndsAt, &s.BootLockTime, &s.IsCurrent)

	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("query season: %w", err)
	}

	return &s, nil
}

// GetSeasonSquads fetches all squads for a given season
func (db *DB) GetSeasonSquads(ctx context.Context, seasonID string) ([]models.SeasonSquad, error) {
	rows, err := db.pool.Query(ctx, `
		SELECT season_id, squad, fanat_league_slug, fanat_league_id, fanat_season_id
		FROM season_squads
		WHERE season_id = $1
	`, seasonID)
	if err != nil {
		return nil, fmt.Errorf("query squads: %w", err)
	}
	defer rows.Close()

	var squads []models.SeasonSquad
	for rows.Next() {
		var sq models.SeasonSquad
		if err := rows.Scan(&sq.SeasonID, &sq.Squad, &sq.FanatLeagueSlug, &sq.FanatLeagueID, &sq.FanatSeasonID); err != nil {
			return nil, fmt.Errorf("scan squad: %w", err)
		}
		squads = append(squads, sq)
	}

	return squads, rows.Err()
}

// UpsertMatch inserts or updates a match keyed by external_id
func (db *DB) UpsertMatch(ctx context.Context, m *models.Match) error {
	_, err := db.pool.Exec(ctx, `
		INSERT INTO matches (external_id, season_id, squad, home_team, away_team, kickoff_time, home_score_actual, away_score_actual, status, matchweek, matchweek_name)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		ON CONFLICT (external_id) DO UPDATE SET
			kickoff_time = EXCLUDED.kickoff_time,
			home_score_actual = EXCLUDED.home_score_actual,
			away_score_actual = EXCLUDED.away_score_actual,
			status = EXCLUDED.status,
			matchweek = EXCLUDED.matchweek,
			matchweek_name = EXCLUDED.matchweek_name
	`, m.ExternalID, m.SeasonID, m.Squad, m.HomeTeam, m.AwayTeam, m.KickoffTime, m.HomeScoreActual, m.AwayScoreActual, m.Status, m.Matchweek, m.MatchweekName)

	return err
}

// GetUpcomingMatches returns matches within the time window for live polling
func (db *DB) GetUpcomingMatches(ctx context.Context, seasonID string, windowStart, windowEnd time.Time) ([]models.Match, error) {
	rows, err := db.pool.Query(ctx, `
		SELECT id, external_id, season_id, squad, home_team, away_team, kickoff_time, home_score_actual, away_score_actual, status
		FROM matches
		WHERE season_id = $1
		  AND kickoff_time >= $2
		  AND kickoff_time <= $3
		  AND status IN ('upcoming', 'live')
		ORDER BY kickoff_time
	`, seasonID, windowStart, windowEnd)
	if err != nil {
		return nil, fmt.Errorf("query upcoming: %w", err)
	}
	defer rows.Close()

	var matches []models.Match
	for rows.Next() {
		var m models.Match
		if err := rows.Scan(&m.ID, &m.ExternalID, &m.SeasonID, &m.Squad, &m.HomeTeam, &m.AwayTeam, &m.KickoffTime, &m.HomeScoreActual, &m.AwayScoreActual, &m.Status); err != nil {
			return nil, fmt.Errorf("scan match: %w", err)
		}
		matches = append(matches, m)
	}

	return matches, rows.Err()
}

// UpsertPlayer inserts or updates a player
func (db *DB) UpsertPlayer(ctx context.Context, p *models.Player) error {
	_, err := db.pool.Exec(ctx, `
		INSERT INTO players (external_id, season_id, name, team, goals)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (external_id, season_id) DO UPDATE SET
			name = EXCLUDED.name,
			team = EXCLUDED.team,
			goals = EXCLUDED.goals
	`, p.ExternalID, p.SeasonID, p.Name, p.Team, p.Goals)

	return err
}

// GetCurrentMatchweek returns the current matchweek number and date range for a season
func (db *DB) GetCurrentMatchweek(ctx context.Context, seasonID string) (*models.CurrentMatchweek, error) {
	// Find the next upcoming match to determine current matchweek
	var matchweek *int
	var firstDate, lastDate time.Time

	err := db.pool.QueryRow(ctx, `
		SELECT matchweek
		FROM matches
		WHERE season_id = $1
		  AND status = 'upcoming'
		  AND kickoff_time > NOW()
		  AND matchweek IS NOT NULL
		ORDER BY kickoff_time ASC
		LIMIT 1
	`, seasonID).Scan(&matchweek)

	if err == pgx.ErrNoRows {
		// No upcoming matches, season might be over or not started
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("query current matchweek: %w", err)
	}
	if matchweek == nil {
		return nil, nil
	}

	// Get date range for this matchweek
	err = db.pool.QueryRow(ctx, `
		SELECT MIN(kickoff_time), MAX(kickoff_time)
		FROM matches
		WHERE season_id = $1
		  AND matchweek = $2
	`, seasonID, *matchweek).Scan(&firstDate, &lastDate)

	if err != nil {
		return nil, fmt.Errorf("query matchweek date range: %w", err)
	}

	return &models.CurrentMatchweek{
		Matchweek: *matchweek,
		FirstDate: firstDate,
		LastDate:  lastDate,
	}, nil
}
