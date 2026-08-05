package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/chromedp/chromedp"
)

type Player struct {
	Name          string
	MatchesPlayed int
	Goals         int
	RedCards      int
	DoubleYellow  int
	YellowCards   int
	Gender        string // "M" or "F"
}

type TeamStanding struct {
	TeamName       string
	Position       int
	Played         int
	Won            int
	Drawn          int
	Lost           int
	GoalsFor       int
	GoalsAgainst   int
	GoalDifference int
	Points         int
}

func main() {
	squads := []struct {
		Name        string
		KaderURL    string
		TabellenURL string
		Gender      string
		SquadKey    string
	}{
		{
			"Men (Reserve)",
			"https://vereine.oefb.at/1FussballclubPaulanerWieden/Mannschaften/Saison-2026-27/Res/Kader/",
			"https://vereine.oefb.at/1FussballclubPaulanerWieden/Mannschaften/Saison-2026-27/Res/Tabellen/",
			"M",
			"reserve",
		},
		{
			"Men (KM)",
			"https://vereine.oefb.at/1FussballclubPaulanerWieden/Mannschaften/Saison-2026-27/KM/Kader/",
			"https://vereine.oefb.at/1FussballclubPaulanerWieden/Mannschaften/Saison-2026-27/KM/Tabellen/",
			"M",
			"km",
		},
		{
			"Women",
			"https://vereine.oefb.at/1FussballclubPaulanerWieden/Mannschaften/Saison-2026-27/KM-FR/Kader/",
			"https://vereine.oefb.at/1FussballclubPaulanerWieden/Mannschaften/Saison-2026-27/KM-FR/Tabellen/",
			"F",
			"women",
		},
	}

	allPlayers := make(map[string]Player)
	allStandings := make(map[string][]TeamStanding) // squad -> standings

	for _, squad := range squads {
		log.Printf("Scraping %s players...", squad.Name)
		players, err := scrapePage(squad.KaderURL)
		if err != nil {
			log.Printf("  ERROR: %v", err)
			continue
		}

		log.Printf("  Found %d players", len(players))
		for _, p := range players {
			p.Gender = squad.Gender // Tag with gender
			allPlayers[p.Name] = p
			log.Printf("    %s: %d matches, %d⚽ %d🟥 %d🟨🟨 %d🟨", p.Name, p.MatchesPlayed, p.Goals, p.RedCards, p.DoubleYellow, p.YellowCards)
		}

		// Scrape standings
		log.Printf("Scraping %s standings...", squad.Name)
		standings, err := scrapeStandings(squad.TabellenURL)
		if err != nil {
			log.Printf("  ERROR: %v", err)
		} else {
			log.Printf("  Found %d teams in table", len(standings))
			allStandings[squad.SquadKey] = standings
			for i, team := range standings {
				log.Printf("    %d. %s (%d pts)", i+1, team.TeamName, team.Points)
			}
		}
	}

	// Generate SQL
	fmt.Println("\n-- OEFB Player Stats SQL")
	fmt.Println("-- Upserts players (updates existing, inserts new)")
	fmt.Println("DO $$")
	fmt.Println("DECLARE sid UUID := (SELECT id FROM seasons WHERE is_current = true);")
	fmt.Println("BEGIN")
	fmt.Println("  -- No DELETE: preserve foreign key references to user picks")
	fmt.Println("  INSERT INTO players (season_id, external_id, name, team, matches_played, goals, red_cards, double_yellow, yellow_cards, gender) VALUES")

	i := 0
	total := len(allPlayers)
	for _, p := range allPlayers {
		i++
		cleanName := strings.ReplaceAll(p.Name, "'", "''")
		comma := ","
		if i == total {
			comma = ""
		}
		fmt.Printf("  (sid, 'oefb_%03d', '%s', '1. FC Paulaner Wieden', %d, %d, %d, %d, %d, '%s')%s\n",
			i, cleanName, p.MatchesPlayed, p.Goals, p.RedCards, p.DoubleYellow, p.YellowCards, p.Gender, comma)
	}

	fmt.Println("  ON CONFLICT (external_id, season_id) DO UPDATE SET")
	fmt.Println("    name = EXCLUDED.name, matches_played = EXCLUDED.matches_played,")
	fmt.Println("    goals = EXCLUDED.goals, red_cards = EXCLUDED.red_cards,")
	fmt.Println("    double_yellow = EXCLUDED.double_yellow, yellow_cards = EXCLUDED.yellow_cards,")
	fmt.Println("    gender = EXCLUDED.gender;")
	fmt.Println("END $$;")

	// Generate Standings SQL
	totalStandings := 0
	for _, standings := range allStandings {
		totalStandings += len(standings)
	}

	if totalStandings > 0 {
		fmt.Println("\n-- OEFB League Standings SQL")
		fmt.Println("DO $$")
		fmt.Println("DECLARE sid UUID := (SELECT id FROM seasons WHERE is_current = true);")
		fmt.Println("BEGIN")
		fmt.Println("  -- Clear old standings")
		fmt.Println("  DELETE FROM team_standings WHERE season_id = sid;")
		fmt.Println()
		fmt.Println("  -- Insert new standings")
		fmt.Println("  INSERT INTO team_standings (season_id, squad, team_name, position, played, won, drawn, lost, goals_for, goals_against, goal_difference, points) VALUES")

		standingsCount := 0
		for squad, standings := range allStandings {
			for _, team := range standings {
				standingsCount++
				cleanName := strings.ReplaceAll(team.TeamName, "'", "''")
				comma := ","
				if standingsCount == totalStandings {
					comma = ""
				}
				fmt.Printf("    (sid, '%s', '%s', %d, %d, %d, %d, %d, %d, %d, %d, %d)%s\n",
					squad, cleanName, team.Position, team.Played, team.Won, team.Drawn,
					team.Lost, team.GoalsFor, team.GoalsAgainst, team.GoalDifference, team.Points, comma)
			}
		}

		fmt.Println("  ON CONFLICT (season_id, squad, team_name) DO UPDATE SET")
		fmt.Println("    position = EXCLUDED.position, played = EXCLUDED.played,")
		fmt.Println("    won = EXCLUDED.won, drawn = EXCLUDED.drawn, lost = EXCLUDED.lost,")
		fmt.Println("    goals_for = EXCLUDED.goals_for, goals_against = EXCLUDED.goals_against,")
		fmt.Println("    goal_difference = EXCLUDED.goal_difference, points = EXCLUDED.points,")
		fmt.Println("    updated_at = NOW();")
		fmt.Println("END $$;")

		log.Printf("\n✅ Done! %d unique players, %d team standings", total, totalStandings)
	} else {
		log.Printf("\n✅ Done! %d unique players, 0 team standings", total)
	}
}

func scrapePage(url string) ([]Player, error) {
	opts := append(chromedp.DefaultExecAllocatorOptions[:], chromedp.Flag("headless", true))
	allocCtx, cancel := chromedp.NewExecAllocator(context.Background(), opts...)
	defer cancel()

	ctx, cancel := chromedp.NewContext(allocCtx)
	defer cancel()

	ctx, cancel = context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	var bodyText string
	err := chromedp.Run(ctx,
		chromedp.Navigate(url),
		chromedp.Sleep(5*time.Second),
		chromedp.Evaluate(`document.body.innerText`, &bodyText),
	)

	if err != nil {
		return nil, err
	}

	return parsePlayers(bodyText), nil
}

func parsePlayers(text string) []Player {
	lines := strings.Split(text, "\n")
	var players []Player
	namePattern := regexp.MustCompile(`^[A-Za-zÄÖÜäöüß\s\-\.]+$`)

	for i := 0; i < len(lines); i++ {
		line := strings.TrimSpace(lines[i])

		// Skip if not a potential name
		if len(line) < 5 || len(line) > 50 {
			continue
		}
		if !strings.Contains(line, " ") {
			continue
		}
		if !namePattern.MatchString(line) {
			continue
		}

		// Skip exact non-player strings first
		lower := strings.ToLower(line)

		// Exact blacklist
		blacklist := []string{
			"unsere mannschaften",
			"kampfmannschaft fr.",
			"kampfmannschaft",
			"reserve",
			"eine seite des öfb dachangebotes",
			"alle rechte vorbehalten",
		}

		isBlacklisted := false
		for _, blocked := range blacklist {
			if lower == blocked {
				isBlacklisted = true
				break
			}
		}
		if isBlacklisted {
			continue
		}

		// Contains checks
		if strings.Contains(lower, "kader") || strings.Contains(lower, "trainer") ||
			strings.Contains(lower, "spiele") || strings.Contains(lower, "tabellen") ||
			strings.Contains(lower, "betreuer") || strings.Contains(lower, "öfb") {
			continue
		}

		// Look for 5 numbers after the name
		stats := []int{}
		for j := 1; j <= 5 && i+j < len(lines); j++ {
			num, err := strconv.Atoi(strings.TrimSpace(lines[i+j]))
			if err == nil {
				stats = append(stats, num)
			}
		}

		// Need all 5 stats
		if len(stats) >= 5 {
			players = append(players, Player{
				Name:          line,
				MatchesPlayed: stats[0], // [0]=matches played
				Goals:         stats[1], // [1]=goals
				RedCards:      stats[2], // [2]=reds
				DoubleYellow:  stats[3], // [3]=double yellow
				YellowCards:   stats[4], // [4]=single yellow
			})
		}
	}

	return players
}

func scrapeStandings(url string) ([]TeamStanding, error) {
	opts := append(chromedp.DefaultExecAllocatorOptions[:], chromedp.Flag("headless", true))
	allocCtx, cancel := chromedp.NewExecAllocator(context.Background(), opts...)
	defer cancel()

	ctx, cancel := chromedp.NewContext(allocCtx)
	defer cancel()

	ctx, cancel = context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	var bodyText string
	err := chromedp.Run(ctx,
		chromedp.Navigate(url),
		chromedp.Sleep(5*time.Second),
		chromedp.Evaluate(`document.body.innerText`, &bodyText),
	)

	if err != nil {
		return nil, err
	}

	return parseStandings(bodyText), nil
}

func parseStandings(text string) []TeamStanding {
	lines := strings.Split(text, "\n")
	var standings []TeamStanding

	for _, line := range lines {
		line = strings.TrimSpace(line)
		lower := strings.ToLower(line)

		// Skip obvious non-teams
		if strings.Contains(lower, "paulaner wieden 1. fußballclub") ||
			strings.Contains(lower, "eine seite") ||
			strings.Contains(lower, "alle rechte") ||
			len(line) < 3 {
			continue
		}

		// Must contain tab (tables have tabs separating columns)
		if !strings.Contains(line, "\t") {
			continue
		}

		// Split by tabs to get team name and stats
		parts := strings.Split(line, "\t")
		if len(parts) < 2 {
			continue
		}

		teamName := strings.TrimSpace(parts[0])
		if len(teamName) < 3 {
			continue
		}

		// Extract all numbers from remaining parts
		var stats []int
		for _, part := range parts[1:] {
			// Handle "0:0" goal format
			if strings.Contains(part, ":") {
				goalParts := strings.Split(part, ":")
				if len(goalParts) == 2 {
					if gf, err := strconv.Atoi(strings.TrimSpace(goalParts[0])); err == nil {
						stats = append(stats, gf) // Goals for
					}
					if ga, err := strconv.Atoi(strings.TrimSpace(goalParts[1])); err == nil {
						stats = append(stats, ga) // Goals against
					}
				}
				continue
			}

			// Regular numbers
			cleaned := strings.TrimSpace(part)
			if cleaned == "" {
				continue
			}
			if num, err := strconv.Atoi(cleaned); err == nil {
				stats = append(stats, num)
			}
		}

		// Pattern: Played, Won, Drawn, Lost, GoalsFor, GoalsAgainst, GoalDiff, Points
		// We should have at least 8 numbers
		if len(stats) >= 8 {
			standings = append(standings, TeamStanding{
				TeamName:       teamName,
				Position:       len(standings) + 1,
				Played:         stats[0],
				Won:            stats[1],
				Drawn:          stats[2],
				Lost:           stats[3],
				GoalsFor:       stats[4],
				GoalsAgainst:   stats[5],
				GoalDifference: stats[6],
				Points:         stats[7],
			})
		}
	}

	return standings
}

func isAllDigits(s string) bool {
	for _, ch := range s {
		if ch < '0' || ch > '9' {
			return false
		}
	}
	return true
}

func init() {
	log.SetOutput(os.Stderr)
}
