import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';

class DisciplineTableWidget extends StatelessWidget {
  final List<Player> yellowCardLeaders;
  final List<Player> redCardLeaders;

  const DisciplineTableWidget({
    super.key,
    required this.yellowCardLeaders,
    required this.redCardLeaders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(
                  Icons.warning,
                  color: AppTheme.primaryPurple,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Discipline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Yellow Cards Table
            if (yellowCardLeaders.isNotEmpty) ...[
              _buildTableHeader('Yellow Cards', Colors.yellow.shade700),
              const SizedBox(height: 8),
              ...yellowCardLeaders.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                return _buildPlayerRow(
                  rank: index + 1,
                  player: player,
                  count: player.yellowCards,
                  icon: '🟨',
                  color: Colors.yellow.shade700,
                );
              }),
              const SizedBox(height: 16),
            ],

            // Red Cards Table
            if (redCardLeaders.isNotEmpty) ...[
              _buildTableHeader('Red Cards', Colors.red.shade700),
              const SizedBox(height: 8),
              ...redCardLeaders.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                return _buildPlayerRow(
                  rank: index + 1,
                  player: player,
                  count: player.redCards,
                  icon: '🟥',
                  color: Colors.red.shade700,
                );
              }),
            ],

            // Empty state
            if (yellowCardLeaders.isEmpty && redCardLeaders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No cards yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Card leaders will appear here',
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
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Text(
            'Count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow({
    required int rank,
    required Player player,
    required int count,
    required String icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3 ? color.withOpacity(0.2) : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? color : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Player name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  player.gender == 'M' ? 'Men' : 'Women',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Text(
              '$count $icon',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
