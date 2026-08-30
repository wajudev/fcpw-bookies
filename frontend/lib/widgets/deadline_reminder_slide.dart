import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/date_helper.dart';

class DeadlineReminderSlide extends StatefulWidget {
  final DateTime? bootLockTime;
  final List<({DateTime kickoff, String homeTeam, String awayTeam})> upcomingMatches;
  final VoidCallback? onTapSeasonPicks;
  final VoidCallback? onTapMatches;

  const DeadlineReminderSlide({
    super.key,
    this.bootLockTime,
    this.upcomingMatches = const [],
    this.onTapSeasonPicks,
    this.onTapMatches,
  });

  @override
  State<DeadlineReminderSlide> createState() => _DeadlineReminderSlideState();
}

class _DeadlineReminderSlideState extends State<DeadlineReminderSlide> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Determine update frequency based on nearest deadline
    final allDeadlines = [
      if (widget.bootLockTime != null) widget.bootLockTime!,
      ...widget.upcomingMatches.map((m) => DateHelper.getMatchDeadline(m.kickoff)),
    ];

    if (allDeadlines.isEmpty) return;

    final now = DateTime.now();
    final nearestDeadline = allDeadlines
        .where((d) => d.isAfter(now))
        .fold<DateTime?>(null, (nearest, current) {
      if (nearest == null) return current;
      return current.isBefore(nearest) ? current : nearest;
    });

    if (nearestDeadline == null) return;

    final timeUntilDeadline = nearestDeadline.difference(now);
    final updateInterval = timeUntilDeadline.inHours < 1
        ? const Duration(seconds: 1) // Update every second when < 1 hour
        : const Duration(minutes: 1); // Update every minute otherwise

    _timer = Timer.periodic(updateInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasBootDeadline = widget.bootLockTime != null &&
        !DateHelper.isDeadlinePassed(widget.bootLockTime!);

    // Filter to only upcoming matches (deadline not passed)
    final validMatches = widget.upcomingMatches.where((match) {
      final deadline = DateHelper.getMatchDeadline(match.kickoff);
      return !DateHelper.isDeadlinePassed(deadline);
    }).toList();

    if (!hasBootDeadline && validMatches.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.primaryGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.alarm,
                  color: AppTheme.primaryPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deadlines',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Verpasse keine Frist!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Season picks deadline (one-time, before first game of season)
          if (hasBootDeadline) ...[
            _buildDeadlineItem(
              icon: Icons.emoji_events,
              title: 'Saison-Tipps',
              subtitle: 'Torschützenkönig & Karten',
              deadline: widget.bootLockTime!,
              color: AppTheme.kmGold,
              onTap: widget.onTapSeasonPicks,
            ),
            if (validMatches.isNotEmpty) const SizedBox(height: 12),
          ],

          // All upcoming match deadlines
          ...validMatches.map((match) {
            final deadline = DateHelper.getMatchDeadline(match.kickoff);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDeadlineItem(
                icon: Icons.sports_soccer,
                title: '${match.homeTeam} - ${match.awayTeam}',
                subtitle: DateHelper.formatDateTime(match.kickoff),
                deadline: deadline,
                color: AppTheme.primaryGreen,
                onTap: widget.onTapMatches,
              ),
            );
          }),

          if (validMatches.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tippe bis 2 Stunden vor Anpfiff',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildDeadlineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required DateTime deadline,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateHelper.getCountdownWithIndicator(deadline),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'noch',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
