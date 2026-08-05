package models

import (
	"time"
)

// DB models matching the Supabase schema
type Season struct {
	ID           string    `db:"id"`
	Name         string    `db:"name"`
	StartsAt     time.Time `db:"starts_at"`
	EndsAt       time.Time `db:"ends_at"`
	BootLockTime time.Time `db:"boot_lock_time"`
	IsCurrent    bool      `db:"is_current"`
}

type SeasonSquad struct {
	SeasonID        string  `db:"season_id"`
	Squad           string  `db:"squad"`
	FanatLeagueSlug string  `db:"fanat_league_slug"`
	FanatLeagueID   string  `db:"fanat_league_id"`
	FanatSeasonID   *string `db:"fanat_season_id"`
}

type Match struct {
	ID              string     `db:"id"`
	ExternalID      string     `db:"external_id"`
	SeasonID        string     `db:"season_id"`
	Squad           string     `db:"squad"`
	HomeTeam        string     `db:"home_team"`
	AwayTeam        string     `db:"away_team"`
	KickoffTime     time.Time  `db:"kickoff_time"`
	HomeScoreActual *int       `db:"home_score_actual"`
	AwayScoreActual *int       `db:"away_score_actual"`
	Status          string     `db:"status"`
	Matchweek       *int       `db:"matchweek"`
	MatchweekName   *string    `db:"matchweek_name"`
}

type Player struct {
	ID         string `db:"id"`
	ExternalID string `db:"external_id"`
	SeasonID   string `db:"season_id"`
	Name       string `db:"name"`
	Team       string `db:"team"`
	Goals      int    `db:"goals"`
}

type CurrentMatchweek struct {
	Matchweek int       `json:"matchweek"`
	FirstDate time.Time `json:"first_date"`
	LastDate  time.Time `json:"last_date"`
}

// fan.at API response models
type FanatAPIResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data"`
}

type FanatEvent struct {
	ID         string               `json:"_id"`
	Status     string               `json:"status"`
	Round      FanatRound           `json:"round"`
	Teams      FanatTeams           `json:"teams"`
	Timestamps FanatTimestamps      `json:"timestamps"`
	// Scores field exists but is complex nested object; we use teams.home/away.score instead
}

type FanatRound struct {
	Nr     int    `json:"nr"`
	UIName string `json:"ui_name"`
}

type FanatTeams struct {
	Home FanatTeam `json:"home"`
	Away FanatTeam `json:"away"`
}

type FanatTeam struct {
	TeamID string `json:"teamid"`
	Name   string `json:"name"`
	Score  int    `json:"score"`
}

type FanatTimestamps struct {
	Start int64 `json:"start"`
}

type FanatEventsResponse struct {
	Success bool         `json:"success"`
	Data    []FanatEvent `json:"data"`
}
