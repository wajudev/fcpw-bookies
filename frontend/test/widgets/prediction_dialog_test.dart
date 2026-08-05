import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/prediction_dialog.dart';
import 'package:frontend/models/match_model.dart';

void main() {
  group('PredictionDialog', () {
    late Match testMatch;

    setUp(() {
      testMatch = Match(
        id: 'test-match-1',
        externalId: 'ext-1',
        seasonId: 'season-1',
        squad: 'km',
        homeTeam: 'Team A',
        awayTeam: 'Team B',
        kickoffTime: DateTime.now().add(Duration(hours: 3)),
        homeScoreActual: null,
        awayScoreActual: null,
        status: MatchStatus.upcoming,
        matchweek: 1,
        matchweekName: 'Round 1',
      );
    });

    testWidgets('shows validation error for invalid scores', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PredictionDialog(match: testMatch),
          ),
        ),
      );

      // Find text fields
      final homeField = find.byType(TextFormField).first;
      final awayField = find.byType(TextFormField).last;

      // Enter invalid score (>99)
      await tester.enterText(homeField, '100');
      await tester.enterText(awayField, '5');

      // Tap submit
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Score cannot exceed 99'), findsOneWidget);
    });

    testWidgets('shows validation error for negative scores', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PredictionDialog(match: testMatch),
          ),
        ),
      );

      final homeField = find.byType(TextFormField).first;

      // Enter negative score
      await tester.enterText(homeField, '-5');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.textContaining('cannot be negative'), findsOneWidget);
    });

    testWidgets('accepts valid scores', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PredictionDialog(match: testMatch),
          ),
        ),
      );

      final homeField = find.byType(TextFormField).first;
      final awayField = find.byType(TextFormField).last;

      // Enter valid scores
      await tester.enterText(homeField, '2');
      await tester.enterText(awayField, '1');

      await tester.tap(find.text('Save'));
      await tester.pump();

      // No validation errors
      expect(find.textContaining('cannot'), findsNothing);
      expect(find.textContaining('exceed'), findsNothing);
    });

    testWidgets('shows locked state when match is locked', (tester) async {
      final lockedMatch = Match(
        id: 'test-match-2',
        externalId: 'ext-2',
        seasonId: 'season-1',
        squad: 'km',
        homeTeam: 'Team C',
        awayTeam: 'Team D',
        kickoffTime: DateTime.now().add(Duration(minutes: 30)), // Less than 2 hours
        homeScoreActual: null,
        awayScoreActual: null,
        status: MatchStatus.upcoming,
        matchweek: 1,
        matchweekName: 'Round 1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PredictionDialog(match: lockedMatch),
          ),
        ),
      );

      // Should show locked message
      expect(find.textContaining('locked'), findsWidgets);
    });
  });
}
