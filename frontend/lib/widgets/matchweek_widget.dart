import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import '../utils/date_helper.dart';

class MatchweekWidget extends StatelessWidget {
  final int matchweekNumber;
  final List<Match> matches;
  final Map<String, Prediction> predictions;
  final VoidCallback? onTap;

  const MatchweekWidget({
    super.key,
    required this.matchweekNumber,
    required this.matches,
    required this.predictions,
    this.onTap,
  });

  String _getDateRange() {
    if (matches.isEmpty) return '';

    final sortedMatches = [...matches]..sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));
    final firstMatch = sortedMatches.first.kickoffTime;
    final lastMatch = sortedMatches.last.kickoffTime;

    final dateFormat = DateFormat('d. MMM', 'de');

    if (firstMatch.day == lastMatch.day &&
        firstMatch.month == lastMatch.month) {
      return dateFormat.format(firstMatch);
    }

    return '${dateFormat.format(firstMatch)} - ${dateFormat.format(lastMatch)}';
  }

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryPurple,
              AppTheme.primaryPurple.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'MATCHWEEK $matchweekNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getDateRange(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Matches
                  ...matches.map((match) => _buildMatchRow(match)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchRow(Match match) {
    final prediction = predictions[match.id];
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('EEE, d MMM');
    final isFinished = match.status == MatchStatus.finished;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Date/Time + Squad
          Row(
            children: [
              _buildSquadBadge(match.squad),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateFormat.format(match.kickoffTime),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    timeFormat.format(match.kickoffTime),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Deadline indicator
                  if (match.status == MatchStatus.upcoming) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateHelper.getTimeRemaining(
                        DateHelper.getMatchDeadline(match.kickoffTime),
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Teams
          Row(
            children: [
              Expanded(
                child: Text(
                  match.homeTeam,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              if (isFinished)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${match.homeScoreActual ?? 0} : ${match.awayScoreActual ?? 0}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Text(
                  'vs',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  match.awayTeam,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Prediction status
          if (prediction != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Your tip: ${prediction.homeScoreGuess}:${prediction.awayScoreGuess}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                if (prediction.pointsAwarded != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getPointsColor(prediction.pointsAwarded!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${prediction.pointsAwarded}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else if (!match.isLocked && !isFinished)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: const Text(
                'No prediction yet',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSquadBadge(String squad) {
    final config = _getSquadConfig(squad);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: config.color, width: 1),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: config.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  ({String label, Color color}) _getSquadConfig(String squad) {
    switch (squad) {
      case 'km':
        return (label: 'KM', color: AppTheme.kmGold);
      case 'reserve':
        return (label: 'RES', color: AppTheme.reserveBlue);
      case 'women':
        return (label: 'W', color: AppTheme.womenPink);
      default:
        return (label: squad.toUpperCase(), color: Colors.white);
    }
  }

  Color _getPointsColor(int points) {
    if (points == 3) return AppTheme.primaryGreen;
    if (points == 1) return AppTheme.kmGold;
    return AppTheme.liveRed;
  }
}
