import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';

class MatchHeroCard extends StatelessWidget {
  final Match match;
  final Prediction? prediction;

  const MatchHeroCard({
    super.key,
    required this.match,
    this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == MatchStatus.live;
    final isFinished = match.status == MatchStatus.finished;
    final timeFormat = DateFormat('HH:mm', 'de_DE');
    final dateFormat = DateFormat('EEE, dd MMM', 'de_DE');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.navyBlue,
            AppTheme.navyBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative pattern
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status row
                  Row(
                    children: [
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormat.format(match.kickoffTime),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              timeFormat.format(match.kickoffTime),
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      _buildSquadBadge(match.squad),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Teams and score
                  Row(
                    children: [
                      // Home team
                      Expanded(
                        child: Column(
                          children: [
                            _buildTeamLogo(match.homeTeam),
                            const SizedBox(height: 12),
                            Text(
                              match.homeTeam,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Score
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            if (isFinished || isLive)
                              Row(
                                children: [
                                  Text(
                                    '${match.homeScoreActual ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      ':',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 48,
                                        fontWeight: FontWeight.w300,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${match.awayScoreActual ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'VS',
                                style: TextStyle(
                                  color: AppTheme.gold.withOpacity(0.5),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Away team
                      Expanded(
                        child: Column(
                          children: [
                            _buildTeamLogo(match.awayTeam),
                            const SizedBox(height: 12),
                            Text(
                              match.awayTeam,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Prediction status
                  if (prediction != null && isFinished) ...[
                    Builder(builder: (context) {
                      final pred = prediction!;
                      final points = pred.pointsAwarded ?? 0;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getPointsColor(points).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getPointsColor(points),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              points == 3
                                  ? Icons.star
                                  : points == 1
                                      ? Icons.check_circle
                                      : Icons.close,
                              color: _getPointsColor(points),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dein Tipp: ${pred.homeScoreGuess}:${pred.awayScoreGuess} • $points Punkte',
                              style: TextStyle(
                                color: _getPointsColor(points),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  ] else if (prediction != null) ...[
                    Builder(builder: (context) {
                      final pred = prediction!;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.gold,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dein Tipp: ${pred.homeScoreGuess}:${pred.awayScoreGuess}',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  ]
                  else if (!match.isLocked)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Noch kein Tipp!',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String teamName) {
    // Extract initials (e.g., "FCPW" or "1. FC" -> "FC")
    final words = teamName.split(' ');
    String initials = '';

    for (final word in words) {
      if (word.isNotEmpty && RegExp(r'[A-Z]').hasMatch(word[0])) {
        initials += word[0];
        if (initials.length >= 2) break;
      }
    }

    if (initials.isEmpty) {
      initials = teamName.substring(0, 2).toUpperCase();
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.slateDark,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppTheme.gold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSquadBadge(String squad) {
    final label = squad == 'km'
        ? 'KM'
        : squad == 'reserve'
            ? 'RESERVE'
            : 'FRAUEN';
    final color = squad == 'km'
        ? AppTheme.gold
        : squad == 'reserve'
            ? const Color(0xFF60A5FA)
            : const Color(0xFFF472B6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Color _getPointsColor(int points) {
    if (points == 3) return const Color(0xFF10B981); // Green
    if (points == 1) return AppTheme.gold;
    return const Color(0xFFEF4444); // Red
  }
}
