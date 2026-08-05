package main

import (
	"encoding/json"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
)

// ScoreMatchRequest is the request body for scoring a match
type ScoreMatchRequest struct {
	MatchID string `json:"match_id"`
}

// ScoreMatchweekRequest is the request body for scoring a matchweek
type ScoreMatchweekRequest struct {
	SeasonID  string `json:"season_id"`
	Matchweek int    `json:"matchweek"`
}

// handleScoreMatch triggers scoring for a specific match (admin only)
func (s *Server) handleScoreMatch(w http.ResponseWriter, r *http.Request) {
	var req ScoreMatchRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.MatchID == "" {
		http.Error(w, "match_id is required", http.StatusBadRequest)
		return
	}

	err := s.scorer.ScoreMatch(r.Context(), req.MatchID)
	if err != nil {
		s.logger.Printf("Error scoring match %s: %v", req.MatchID, err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Match scored successfully",
		"match_id": req.MatchID,
	})
}

// handleScoreMatchweek triggers scoring for all matches in a matchweek (admin only)
func (s *Server) handleScoreMatchweek(w http.ResponseWriter, r *http.Request) {
	var req ScoreMatchweekRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.SeasonID == "" || req.Matchweek == 0 {
		http.Error(w, "season_id and matchweek are required", http.StatusBadRequest)
		return
	}

	err := s.scorer.ScoreMatchweek(r.Context(), req.SeasonID, req.Matchweek)
	if err != nil {
		s.logger.Printf("Error scoring matchweek %d: %v", req.Matchweek, err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Matchweek scored successfully",
		"season_id": req.SeasonID,
		"matchweek": req.Matchweek,
	})
}

// handleMatchStats returns statistics for a match (admin)
func (s *Server) handleMatchStats(w http.ResponseWriter, r *http.Request) {
	matchID := chi.URLParam(r, "matchID")
	if matchID == "" {
		http.Error(w, "match_id is required", http.StatusBadRequest)
		return
	}

	type Stats struct {
		TotalPredictions int     `json:"total_predictions"`
		AvgHomeScore     float64 `json:"avg_home_score"`
		AvgAwayScore     float64 `json:"avg_away_score"`
		ExactHits        int     `json:"exact_hits"`
	}

	var stats Stats
	err := s.db.GetPool().QueryRow(r.Context(), `
		SELECT
			COUNT(*) as total_predictions,
			COALESCE(AVG(home_score), 0) as avg_home_score,
			COALESCE(AVG(away_score), 0) as avg_away_score,
			COUNT(*) FILTER (WHERE points = 3) as exact_hits
		FROM predictions
		WHERE match_id = $1
	`, matchID).Scan(&stats.TotalPredictions, &stats.AvgHomeScore, &stats.AvgAwayScore, &stats.ExactHits)

	if err != nil {
		s.logger.Printf("Error getting match stats: %v", err)
		http.Error(w, "Failed to get stats", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(stats)
}

// adminAuthMiddleware checks for admin authentication
func (s *Server) adminAuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		apiKey := r.Header.Get("X-Admin-Key")

		// Get expected admin key from environment
		expectedKey := os.Getenv("ADMIN_API_KEY")
		if expectedKey == "" {
			s.logger.Println("WARNING: ADMIN_API_KEY not set in environment")
			expectedKey = "dev-admin-key-change-in-production"
		}

		if apiKey != expectedKey {
			http.Error(w, "Unauthorized: Invalid admin key", http.StatusUnauthorized)
			return
		}

		next.ServeHTTP(w, r)
	})
}
