package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"fcpw-bookies-backend/internal/db"
	"fcpw-bookies-backend/internal/scoring"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/joho/godotenv"
)

type Server struct {
	db     *db.DB
	scorer *scoring.Scorer
	router *chi.Mux
	logger *log.Logger
}

func main() {
	logger := log.New(os.Stdout, "[api] ", log.LstdFlags)

	if err := godotenv.Load(); err != nil {
		logger.Println("No .env file found, using environment variables")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		logger.Fatal("DATABASE_URL not set")
	}

	database, err := db.New(dbURL)
	if err != nil {
		logger.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.Close()

	srv := &Server{
		db:     database,
		scorer: scoring.NewScorer(database.GetPool(), logger),
		router: chi.NewRouter(),
		logger: logger,
	}

	srv.setupRoutes()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	logger.Printf("Starting API server on :%s", port)
	if err := http.ListenAndServe(":"+port, srv.router); err != nil {
		logger.Fatalf("Server failed: %v", err)
	}
}

func (s *Server) setupRoutes() {
	s.router.Use(middleware.Logger)
	s.router.Use(middleware.Recoverer)
	s.router.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:*", "https://*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-Admin-Key"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// Public routes
	s.router.Get("/health", s.handleHealth)
	s.router.Get("/api/seasons/{seasonID}/current-matchweek", s.handleCurrentMatchweek)
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func (s *Server) handleCurrentMatchweek(w http.ResponseWriter, r *http.Request) {
	seasonID := chi.URLParam(r, "seasonID")
	if seasonID == "" {
		http.Error(w, "season_id required", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	mw, err := s.db.GetCurrentMatchweek(ctx, seasonID)
	if err != nil {
		log.Printf("Error getting current matchweek: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if mw == nil {
		http.Error(w, "No upcoming matches found", http.StatusNotFound)
		return
	}

	// Format date range for display
	dateRange := formatDateRange(mw.FirstDate, mw.LastDate)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"matchweek":  mw.Matchweek,
		"first_date": mw.FirstDate,
		"last_date":  mw.LastDate,
		"date_range": dateRange,
	})
}

func formatDateRange(first, last time.Time) string {
	// German date format
	if first.Day() == last.Day() && first.Month() == last.Month() {
		return fmt.Sprintf("%d. %s", first.Day(), monthNameDE(first.Month()))
	}

	return fmt.Sprintf("%d. %s - %d. %s",
		first.Day(), monthNameDE(first.Month()),
		last.Day(), monthNameDE(last.Month()))
}

func monthNameDE(m time.Month) string {
	months := map[time.Month]string{
		time.January:   "Jan",
		time.February:  "Feb",
		time.March:     "März",
		time.April:     "Apr",
		time.May:       "Mai",
		time.June:      "Juni",
		time.July:      "Juli",
		time.August:    "Aug",
		time.September: "Sept",
		time.October:   "Okt",
		time.November:  "Nov",
		time.December:  "Dez",
	}
	return months[m]
}
