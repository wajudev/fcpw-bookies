import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';

class TopScorersWidget extends StatelessWidget {
  final Player? topMenScorer;
  final Player? topWomenScorer;

  const TopScorersWidget({
    super.key,
    this.topMenScorer,
    this.topWomenScorer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.sports_soccer,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Top Scorers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Empty state or scorers
            if (topMenScorer == null && topWomenScorer == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.sports_soccer_outlined,
                        size: 48,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No goals yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Season scorers will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Show scorers
              if (topMenScorer != null) ...[
                _buildScorerCard(
                  player: topMenScorer!,
                  label: "Men",
                  icon: Icons.male,
                ),
                const SizedBox(height: 12),
              ],
              if (topWomenScorer != null)
                _buildScorerCard(
                  player: topWomenScorer!,
                  label: "Women",
                  icon: Icons.female,
                ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScorerCard({
    required Player player,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gender label
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Player info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: Text(
                  player.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (player.matchesPlayed != null && player.matchesPlayed! > 0)
                      Text(
                        '${player.matchesPlayed} matches',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              // Stats
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatBadge('${player.goals} ⚽', Colors.white),
                  const SizedBox(width: 6),
                  if (player.redCards > 0)
                    _buildStatBadge('${player.redCards} 🟥', Colors.red.shade100),
                  const SizedBox(width: 6),
                  if (player.yellowCards > 0)
                    _buildStatBadge('${player.yellowCards} 🟨', Colors.yellow.shade100),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: bgColor == Colors.white ? AppTheme.primaryGreen : Colors.black87,
        ),
      ),
    );
  }
}
