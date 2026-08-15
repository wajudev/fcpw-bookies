package scoring

import (
	"testing"
)

func TestCalculatePoints(t *testing.T) {
	scorer := &Scorer{}

	tests := []struct {
		name           string
		predHome       int
		predAway       int
		actualHome     int
		actualAway     int
		expectedPoints int
		expectedExact  bool
	}{
		{
			name:           "Exact score match",
			predHome:       2,
			predAway:       1,
			actualHome:     2,
			actualAway:     1,
			expectedPoints: 2,
			expectedExact:  true,
		},
		{
			name:           "Correct outcome - home win",
			predHome:       3,
			predAway:       1,
			actualHome:     2,
			actualAway:     0,
			expectedPoints: 1,
			expectedExact:  false,
		},
		{
			name:           "Correct outcome - away win",
			predHome:       0,
			predAway:       2,
			actualHome:     1,
			actualAway:     3,
			expectedPoints: 1,
			expectedExact:  false,
		},
		{
			name:           "Correct outcome - draw",
			predHome:       1,
			predAway:       1,
			actualHome:     2,
			actualAway:     2,
			expectedPoints: 1,
			expectedExact:  false,
		},
		{
			name:           "Wrong outcome",
			predHome:       2,
			predAway:       1,
			actualHome:     1,
			actualAway:     2,
			expectedPoints: 0,
			expectedExact:  false,
		},
		{
			name:           "High scoring exact",
			predHome:       5,
			predAway:       4,
			actualHome:     5,
			actualAway:     4,
			expectedPoints: 2,
			expectedExact:  true,
		},
		{
			name:           "0-0 draw exact",
			predHome:       0,
			predAway:       0,
			actualHome:     0,
			actualAway:     0,
			expectedPoints: 2,
			expectedExact:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			pred := PredictionResult{
				PredictionID:    "test-pred",
				HomeScorePred:   tt.predHome,
				AwayScorePred:   tt.predAway,
				HomeScoreActual: tt.actualHome,
				AwayScoreActual: tt.actualAway,
			}

			result := scorer.CalculatePoints(pred)

			if result.Points != tt.expectedPoints {
				t.Errorf("Expected %d points, got %d", tt.expectedPoints, result.Points)
			}

			if result.IsExactHit != tt.expectedExact {
				t.Errorf("Expected exact=%v, got %v", tt.expectedExact, result.IsExactHit)
			}
		})
	}
}

func TestGetOutcome(t *testing.T) {
	tests := []struct {
		home     int
		away     int
		expected string
	}{
		{2, 1, "home_win"},
		{1, 2, "away_win"},
		{1, 1, "draw"},
		{0, 0, "draw"},
		{5, 0, "home_win"},
		{0, 5, "away_win"},
	}

	for _, tt := range tests {
		result := getOutcome(tt.home, tt.away)
		if result != tt.expected {
			t.Errorf("getOutcome(%d, %d) = %s, want %s", tt.home, tt.away, result, tt.expected)
		}
	}
}

// TODO: Add integration tests with real database when scoring rules finalized
// These will test:
// - ScoreMatch() with real predictions
// - ScoreMatchweek() with multiple matches
// - Transaction rollback on errors
// - User stats updates
