package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/chromedp/chromedp"
)

func main() {
	url := "https://vereine.oefb.at/1FussballclubPaulanerWieden/Mannschaften/Saison-2026-27/Res/Kader/"

	if len(os.Args) > 1 {
		url = os.Args[1]
	}

	log.Printf("Debugging: %s\n", url)

	opts := append(chromedp.DefaultExecAllocatorOptions[:],
		chromedp.Flag("headless", true),
	)

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
		log.Fatal(err)
	}

	fmt.Println("=== RAW PAGE TEXT ===")
	fmt.Println(bodyText)
	fmt.Println("\n=== ANALYSIS ===")
	fmt.Println("Looking for player patterns...")

	// Show what we're finding
	lines := []string{}
	for _, line := range splitLines(bodyText) {
		line = trim(line)
		if len(line) > 5 && len(line) < 50 && hasSpace(line) {
			lines = append(lines, line)
		}
	}

	fmt.Printf("Found %d potential name lines:\n", len(lines))
	for i, line := range lines[:min(20, len(lines))] {
		fmt.Printf("%d: %s\n", i+1, line)
	}
}

func splitLines(s string) []string {
	result := []string{}
	current := ""
	for _, ch := range s {
		if ch == '\n' {
			result = append(result, current)
			current = ""
		} else {
			current += string(ch)
		}
	}
	if current != "" {
		result = append(result, current)
	}
	return result
}

func trim(s string) string {
	start := 0
	end := len(s)
	for start < end && (s[start] == ' ' || s[start] == '\t') {
		start++
	}
	for start < end && (s[end-1] == ' ' || s[end-1] == '\t') {
		end--
	}
	return s[start:end]
}

func hasSpace(s string) bool {
	for _, ch := range s {
		if ch == ' ' {
			return true
		}
	}
	return false
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
