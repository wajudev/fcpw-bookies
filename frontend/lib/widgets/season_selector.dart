import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SeasonSelector extends StatelessWidget {
  final String currentSeasonName;
  final List<Season> seasons;
  final Function(String seasonId) onSeasonChanged;

  const SeasonSelector({
    super.key,
    required this.currentSeasonName,
    required this.seasons,
    required this.onSeasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (seasons.length <= 1) {
      // Only one season, just show the name
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          currentSeasonName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryPurple,
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => seasons.map((season) {
        final isCurrent = season.name == currentSeasonName;
        return PopupMenuItem<String>(
          value: season.id,
          child: Row(
            children: [
              if (isCurrent)
                const Icon(
                  Icons.check,
                  color: AppTheme.primaryGreen,
                  size: 20,
                )
              else
                const SizedBox(width: 20),
              const SizedBox(width: 12),
              Text(
                season.name,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? AppTheme.primaryPurple : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: onSeasonChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentSeasonName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_drop_down,
              color: AppTheme.primaryPurple,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class Season {
  final String id;
  final String name;
  final bool isCurrent;

  Season({
    required this.id,
    required this.name,
    required this.isCurrent,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as String,
      name: json['name'] as String,
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }
}
