package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"fcpw-bookies-backend/internal/db"
	"fcpw-bookies-backend/internal/retry"
	"fcpw-bookies-backend/internal/sync"

	"github.com/joho/godotenv"
)

func main() {
	logger := log.New(os.Stdout, "[sync] ", log.LstdFlags)

	// Load .env if present
	_ = godotenv.Load()

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		logger.Fatal("DATABASE_URL not set")
	}

	syncInterval := getEnvInt("SYNC_INTERVAL_SECONDS", 3600)
	livePollInterval := getEnvInt("LIVE_POLL_INTERVAL_SECONDS", 120)
	livePollStartMin := getEnvInt("LIVE_POLL_START_MINUTES", 30)

	logger.Printf("Starting sync worker (interval: %ds, live: %ds starting %dm before kickoff)", syncInterval, livePollInterval, livePollStartMin)

	database, err := db.New(databaseURL)
	if err != nil {
		logger.Fatalf("Database connect failed: %v", err)
	}
	defer database.Close()

	svc := sync.NewService(database, logger)

	// Initial sync on startup
	ctx := context.Background()
	if err := svc.SyncAll(ctx); err != nil {
		logger.Printf("Initial sync failed: %v", err)
	}

	// Background ticker for regular syncs
	syncTicker := time.NewTicker(time.Duration(syncInterval) * time.Second)
	defer syncTicker.Stop()

	// Background ticker for live polling (tight window around kickoffs)
	liveTicker := time.NewTicker(time.Duration(livePollInterval) * time.Second)
	defer liveTicker.Stop()

	// Graceful shutdown
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	logger.Println("Worker running. Press Ctrl+C to stop.")

	for {
		select {
		case <-syncTicker.C:
			logger.Println("Regular sync triggered")
			err := retry.DoWithCallback(ctx, 3, func() error {
				return svc.SyncAll(ctx)
			}, func(attempt int, err error) {
				logger.Printf("Sync attempt %d failed: %v (retrying...)", attempt+1, err)
			})
			if err != nil {
				logger.Printf("Sync failed after retries: %v", err)
			}

		case <-liveTicker.C:
			err := retry.DoWithCallback(ctx, 2, func() error {
				return svc.SyncLive(ctx, livePollStartMin)
			}, func(attempt int, err error) {
				logger.Printf("Live poll attempt %d failed: %v (retrying...)", attempt+1, err)
			})
			if err != nil {
				logger.Printf("Live poll failed after retries: %v", err)
			}

		case <-stop:
			logger.Println("Shutdown signal received, exiting...")
			return
		}
	}
}

func getEnvInt(key string, defaultVal int) int {
	val := os.Getenv(key)
	if val == "" {
		return defaultVal
	}
	i, err := strconv.Atoi(val)
	if err != nil {
		return defaultVal
	}
	return i
}
