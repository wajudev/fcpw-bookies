package fanat

import (
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
)

// LivetickerEvent represents a parsed event from the liveticker
type LivetickerEvent struct {
	Type       string // "goal", "yellow_card", "red_card"
	Minute     string // e.g. "89'"
	PlayerName string
	TeamID     string // Which team the player belongs to
}

// FetchLiveticker fetches and parses the liveticker page for a match
func (c *Client) FetchLiveticker(matchID, teamID string) ([]LivetickerEvent, error) {
	url := fmt.Sprintf("https://1-fc-paulaner-wieden.fan.at/spiele/%s/%s/liveticker", matchID, teamID)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}

	req.Header.Set("User-Agent", UserAgent)
	req.Header.Set("Accept", "text/html")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("HTTP request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("HTTP %d from liveticker", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read body: %w", err)
	}

	return parseLiveticker(string(body), teamID)
}

// parseLiveticker extracts goal and card events from HTML
func parseLiveticker(html, teamID string) ([]LivetickerEvent, error) {
	var events []LivetickerEvent

	// Parse goals: "David Kadlez trifft zum 3:7!"
	goalPattern := regexp.MustCompile(`(?i)([A-Za-zäöüÄÖÜß\s-]+)\s+trifft\s+zum`)
	goalMatches := goalPattern.FindAllStringSubmatch(html, -1)

	for _, match := range goalMatches {
		if len(match) > 1 {
			playerName := strings.TrimSpace(match[1])
			events = append(events, LivetickerEvent{
				Type:       "goal",
				PlayerName: playerName,
				TeamID:     teamID,
			})
		}
	}

	// Parse yellow cards: "Mohammad Kazem Ahmadi sieht die Gelbe Karte"
	yellowPattern := regexp.MustCompile(`(?i)([A-Za-zäöüÄÖÜß\s-]+)\s+sieht\s+die\s+Gelbe\s+Karte`)
	yellowMatches := yellowPattern.FindAllStringSubmatch(html, -1)

	for _, match := range yellowMatches {
		if len(match) > 1 {
			playerName := strings.TrimSpace(match[1])
			events = append(events, LivetickerEvent{
				Type:       "yellow_card",
				PlayerName: playerName,
				TeamID:     teamID,
			})
		}
	}

	// Parse red cards: "Player Name sieht die Rote Karte"
	redPattern := regexp.MustCompile(`(?i)([A-Za-zäöüÄÖÜß\s-]+)\s+sieht\s+die\s+Rote\s+Karte`)
	redMatches := redPattern.FindAllStringSubmatch(html, -1)

	for _, match := range redMatches {
		if len(match) > 1 {
			playerName := strings.TrimSpace(match[1])
			events = append(events, LivetickerEvent{
				Type:       "red_card",
				PlayerName: playerName,
				TeamID:     teamID,
			})
		}
	}

	return events, nil
}

// NormalizePlayerName cleans up player name for database matching
func NormalizePlayerName(name string) string {
	// Remove extra spaces
	name = strings.TrimSpace(name)
	name = regexp.MustCompile(`\s+`).ReplaceAllString(name, " ")

	// Common variations
	// "Firstname Lastname" vs "F. Lastname"
	// Handle as needed

	return name
}
