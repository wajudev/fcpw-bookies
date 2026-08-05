package fanat

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"fcpw-bookies-backend/models"
)

const (
	BaseURL    = "https://api.fan.at"
	UserAgent  = "FCPW-Tippspiel/1.0 (fcpw-bookies; +https://github.com/fcpw/bookies)"
	MaxRetries = 3
)

type Client struct {
	httpClient *http.Client
}

func NewClient() *Client {
	return &Client{
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// FetchTeamEvents fetches future or past events for a specific team
func (c *Client) FetchTeamEvents(teamID string, isPast bool, offset, limit int) ([]models.FanatEvent, error) {
	direction := "future"
	if isPast {
		direction = "past"
	}

	url := fmt.Sprintf("%s/v2/events/team/%s/%s/%d/%d", BaseURL, teamID, direction, offset, limit)

	var resp models.FanatEventsResponse
	if err := c.doRequest(url, &resp); err != nil {
		return nil, err
	}

	if !resp.Success {
		return nil, fmt.Errorf("API returned success=false for %s", url)
	}

	return resp.Data, nil
}

// FetchAllTeamEvents fetches all events (future + past) for a team
func (c *Client) FetchAllTeamEvents(teamID string) ([]models.FanatEvent, error) {
	const batchSize = 50
	var allEvents []models.FanatEvent

	// Fetch future
	future, err := c.FetchTeamEvents(teamID, false, 0, batchSize)
	if err != nil {
		return nil, fmt.Errorf("fetch future events: %w", err)
	}
	allEvents = append(allEvents, future...)

	// Fetch past
	past, err := c.FetchTeamEvents(teamID, true, 0, batchSize)
	if err != nil {
		return nil, fmt.Errorf("fetch past events: %w", err)
	}
	allEvents = append(allEvents, past...)

	return allEvents, nil
}

func (c *Client) doRequest(url string, target interface{}) error {
	var lastErr error

	for i := 0; i < MaxRetries; i++ {
		if i > 0 {
			backoff := time.Duration(i*i) * time.Second
			time.Sleep(backoff)
		}

		req, err := http.NewRequest("GET", url, nil)
		if err != nil {
			return fmt.Errorf("create request: %w", err)
		}

		req.Header.Set("User-Agent", UserAgent)
		req.Header.Set("Accept", "application/json")

		resp, err := c.httpClient.Do(req)
		if err != nil {
			lastErr = fmt.Errorf("HTTP request failed: %w", err)
			continue
		}

		defer resp.Body.Close()

		if resp.StatusCode == 429 {
			// Rate limited, back off exponentially
			lastErr = fmt.Errorf("rate limited (429)")
			continue
		}

		if resp.StatusCode != 200 {
			body, _ := io.ReadAll(resp.Body)
			lastErr = fmt.Errorf("HTTP %d: %s", resp.StatusCode, string(body))
			continue
		}

		if err := json.NewDecoder(resp.Body).Decode(target); err != nil {
			return fmt.Errorf("decode JSON: %w", err)
		}

		return nil
	}

	return fmt.Errorf("request failed after %d retries: %w", MaxRetries, lastErr)
}
