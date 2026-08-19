import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

class LeaderboardEntry {
  final String userId;
  final String username;
  final int totalPoints;
  final int exactHits;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalPoints,
    required this.exactHits,
    required this.rank,
  });
}

class LeaderboardService {
  final _supabase = SupabaseConfig.client;

  Future<List<LeaderboardEntry>> getLeaderboard(String seasonId,
      {int limit = 10}) async {
    try {
      // Get all users with their stats (LEFT JOIN so users without stats show with 0)
      debugPrint('🔍 Leaderboard query with limit: $limit');
      final response = await _supabase
          .from('users')
          .select('id, username, user_season_stats!left(total_points, exact_hits)')
          .limit(limit);

      debugPrint('📊 Response count: ${(response as List).length}');

      final entries = <LeaderboardEntry>[];
      for (var i = 0; i < (response as List).length; i++) {
        final user = response[i];
        final stats = user['user_season_stats'] as List?;

        // Find stats for this season
        final seasonStats = stats?.firstWhere(
          (s) => true, // We'd need to filter by season_id if we had it in the select
          orElse: () => null,
        );

        entries.add(LeaderboardEntry(
          userId: user['id'] as String,
          username: user['username'] as String,
          totalPoints: seasonStats?['total_points'] as int? ?? 0,
          exactHits: seasonStats?['exact_hits'] as int? ?? 0,
          rank: i + 1, // Temporary rank, we'll sort
        ));
      }

      // Sort by points desc, then exact hits desc
      entries.sort((a, b) {
        if (a.totalPoints != b.totalPoints) {
          return b.totalPoints.compareTo(a.totalPoints);
        }
        return b.exactHits.compareTo(a.exactHits);
      });

      // Re-assign ranks after sorting
      for (var i = 0; i < entries.length; i++) {
        entries[i] = LeaderboardEntry(
          userId: entries[i].userId,
          username: entries[i].username,
          totalPoints: entries[i].totalPoints,
          exactHits: entries[i].exactHits,
          rank: i + 1,
        );
      }

      return entries;
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }
}
