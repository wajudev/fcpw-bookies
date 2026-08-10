import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FunStatsSlide extends StatelessWidget {
  final String? hotStreak;
  final String? coldStreak;
  final String? recentLeader;
  final int? biggestLead;

  const FunStatsSlide({
    super.key,
    this.hotStreak,
    this.coldStreak,
    this.recentLeader,
    this.biggestLead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Text(
                '🔥',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Stats & Streaks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats in rows - 2 stats side by side, non-scrollable
          Expanded(
            child: Column(
              children: [
                // Top row: Hot & Cold Streak
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          emoji: '🔥',
                          label: 'Hot Streak',
                          value: hotStreak ?? 'Coming soon',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          emoji: '🧊',
                          label: 'Cold Streak',
                          value: coldStreak ?? 'Coming soon',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Bottom row: Current Leader & Biggest Lead
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          emoji: '👑',
                          label: 'Current Leader',
                          value: recentLeader ?? 'Coming soon',
                          color: AppTheme.kmGold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          emoji: '📊',
                          label: 'Biggest Lead',
                          value: biggestLead != null ? '$biggestLead pts' : 'Coming soon',
                          color: AppTheme.primaryGreen,
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
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
