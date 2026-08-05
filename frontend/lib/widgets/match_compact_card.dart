import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';

class MatchCompactCard extends StatelessWidget {
  final Match match;
  final Prediction? prediction;
  final VoidCallback? onTap;

  const MatchCompactCard({
    super.key,
    required this.match,
    this.prediction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = match.status == MatchStatus.finished;
    final isLive = match.status == MatchStatus.live;
    final timeFormat = DateFormat('HH:mm', 'de_DE');
    final dateFormat = DateFormat('dd MMM', 'de_DE');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Header row
              Row(
                children: [
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.liveRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isFinished)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FT',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeFormat.format(match.kickoffTime),
                          style: const TextStyle(
                            color: AppTheme.primaryPurple,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dateFormat.format(match.kickoffTime),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  _buildSquadBadge(match.squad),
                ],
              ),
              const SizedBox(height: 16),
              // Teams
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.homeTeam,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (prediction != null)
                          Builder(builder: (context) {
                            final pred = prediction!;
                            return Text(
                              '${pred.homeScoreGuess}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Score
                  if (isFinished || isLive)
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              '${match.homeScoreActual ?? 0}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                ':',
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            Text(
                              '${match.awayScoreActual ?? 0}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (prediction?.pointsAwarded != null)
                          Builder(builder: (context) {
                            final points = prediction!.pointsAwarded!;
                            return Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getPointsColor(points).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+$points',
                                style: TextStyle(
                                  color: _getPointsColor(points),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                      ],
                    )
                  else
                    Text(
                      'vs',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          match.awayTeam,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (prediction != null)
                          Builder(builder: (context) {
                            final pred = prediction!;
                            return Text(
                              '${pred.awayScoreGuess}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (prediction == null && !match.isLocked && !isFinished)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Predict',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquadBadge(String squad) {
    final color = squad == 'km'
        ? AppTheme.kmGold
        : squad == 'reserve'
            ? AppTheme.reserveBlue
            : AppTheme.womenPink;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getPointsColor(int points) {
    if (points == 3) return AppTheme.primaryGreen;
    if (points == 1) return AppTheme.kmGold;
    return AppTheme.liveRed;
  }
}
