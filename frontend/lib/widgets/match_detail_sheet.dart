import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';

class MatchDetailSheet extends StatelessWidget {
  final Match match;
  final Prediction? prediction;

  const MatchDetailSheet({
    super.key,
    required this.match,
    this.prediction,
  });

  static void show(BuildContext context, Match match, Prediction? prediction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MatchDetailSheet(
        match: match,
        prediction: prediction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Match header
              _buildMatchHeader(),
              const SizedBox(height: 24),

              // Match info
              _buildInfoCard(),
              const SizedBox(height: 16),

              // Prediction info
              if (prediction != null) ...[
                _buildPredictionCard(),
                const SizedBox(height: 16),
              ],

              // Match stats (if finished)
              if (match.status == MatchStatus.finished) _buildStatsCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMatchHeader() {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'de');
    final timeFormat = DateFormat('HH:mm');

    return Column(
      children: [
        Text(
          dateFormat.format(match.kickoffTime),
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    match.homeTeam,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  if (match.status == MatchStatus.finished)
                    Text(
                      '${match.homeScoreActual}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (match.status == MatchStatus.upcoming)
                    Text(
                      timeFormat.format(match.kickoffTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  else if (match.status == MatchStatus.live)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.liveRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'vs',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    match.awayTeam,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  if (match.status == MatchStatus.finished)
                    Text(
                      '${match.awayScoreActual}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.sports_soccer, 'Squad', _getSquadName(match.squad)),
          if (match.matchweekName != null)
            _buildInfoRow(Icons.calendar_today, 'Matchweek', match.matchweekName!),
          _buildInfoRow(
            Icons.lock_clock,
            'Prediction deadline',
            DateFormat('d MMM, HH:mm').format(
              match.kickoffTime.subtract(const Duration(hours: 2)),
            ),
          ),
          _buildInfoRow(
            Icons.info_outline,
            'Status',
            match.status.toString().split('.').last.toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.primaryPurple),
              const SizedBox(width: 12),
              const Text(
                'Your Prediction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const Spacer(),
              if (prediction!.pointsAwarded != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPointsColor(prediction!.pointsAwarded!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${prediction!.pointsAwarded} pts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${prediction!.homeScoreGuess}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(width: 24),
              const Text(
                ':',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                '${prediction!.awayScoreGuess}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'More stats coming soon...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getSquadName(String squad) {
    switch (squad) {
      case 'km':
        return 'KM (Men\'s First Team)';
      case 'reserve':
        return 'Reserve (Men\'s Second)';
      case 'women':
        return 'Women';
      default:
        return squad.toUpperCase();
    }
  }

  Color _getPointsColor(int points) {
    if (points == 3) return AppTheme.primaryGreen;
    if (points == 1) return AppTheme.kmGold;
    return AppTheme.liveRed;
  }
}
