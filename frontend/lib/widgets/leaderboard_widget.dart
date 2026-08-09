import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LeaderboardWidget extends StatelessWidget {
  final List<({String username, int points, int rank})> topUsers;
  final VoidCallback? onViewAll;

  const LeaderboardWidget({
    super.key,
    required this.topUsers,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.kmGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View all'),
                  ),
              ],
            ),
          ),
          if (topUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No rankings yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Make predictions to earn points!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...topUsers.take(5).map((user) => _buildUserRow(user)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUserRow(({String username, int points, int rank}) user) {
    final isTopThree = user.rank <= 3;
    final medalColor = user.rank == 1
        ? AppTheme.kmGold
        : user.rank == 2
            ? Colors.grey.shade400
            : const Color(0xFFCD7F32); // Bronze

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        color: isTopThree ? medalColor.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: isTopThree
                ? Icon(
                    Icons.emoji_events,
                    color: medalColor,
                    size: 24,
                  )
                : Text(
                    '${user.rank}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Username
          Expanded(
            child: Text(
              user.username,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isTopThree ? FontWeight.w600 : FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${user.points} pts',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
