package retry

import (
	"context"
	"fmt"
	"time"
)

// Do executes fn with exponential backoff retry logic
func Do(ctx context.Context, maxRetries int, fn func() error) error {
	var lastErr error

	for attempt := 0; attempt <= maxRetries; attempt++ {
		err := fn()
		if err == nil {
			return nil // Success!
		}

		lastErr = err

		// Last attempt failed
		if attempt == maxRetries {
			break
		}

		// Exponential backoff: 1s, 2s, 4s, 8s, 16s
		backoff := time.Duration(1<<uint(attempt)) * time.Second

		select {
		case <-time.After(backoff):
			// Wait and retry
		case <-ctx.Done():
			return ctx.Err()
		}
	}

	return fmt.Errorf("failed after %d attempts: %w", maxRetries+1, lastErr)
}

// DoWithCallback is like Do but calls onRetry before each retry
func DoWithCallback(ctx context.Context, maxRetries int, fn func() error, onRetry func(attempt int, err error)) error {
	var lastErr error

	for attempt := 0; attempt <= maxRetries; attempt++ {
		err := fn()
		if err == nil {
			return nil
		}

		lastErr = err

		if attempt == maxRetries {
			break
		}

		// Callback for logging
		if onRetry != nil {
			onRetry(attempt, err)
		}

		backoff := time.Duration(1<<uint(attempt)) * time.Second

		select {
		case <-time.After(backoff):
		case <-ctx.Done():
			return ctx.Err()
		}
	}

	return fmt.Errorf("failed after %d attempts: %w", maxRetries+1, lastErr)
}
