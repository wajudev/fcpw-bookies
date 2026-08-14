import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

class ProfileService {
  final _supabase = SupabaseConfig.client;

  Future<UserProfile?> getUserProfile(String userId, String seasonId) async {
    try {
      // Get user info
      final userResponse = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();

      // If no profile exists, return null
      if (userResponse == null) {
        debugPrint('No profile found for user $userId');
        return null;
      }

      // Get season stats
        final statsResponse = await _supabase
          .from('user_season_stats')
          .select('total_points, exact_hits, final_rank, golden_boot_pick_men, golden_boot_pick_women, golden_boot_pick_count, yellow_card_pick, yellow_card_pick_count, red_card_pick, red_card_pick_count, golden_boot_hit, yellow_card_hit, red_card_hit')
          .eq('user_id', userId)
          .eq('season_id', seasonId)
          .maybeSingle();

      // Get current rank from leaderboard view
      final rankResponse = await _supabase
          .rpc('get_user_rank', params: {
            'p_user_id': userId,
            'p_season_id': seasonId,
          });

      return UserProfile(
        username: userResponse['username'] as String,
        totalPoints: statsResponse?['total_points'] as int? ?? 0,
        exactHits: statsResponse?['exact_hits'] as int? ?? 0,
        currentRank: rankResponse as int? ?? 0,
        finalRank: statsResponse?['final_rank'] as int?,
        goldenBootPickMenId: statsResponse?['golden_boot_pick_men'] as String?,
        goldenBootPickWomenId: statsResponse?['golden_boot_pick_women'] as String?,
        goldenBootPickCount: statsResponse?['golden_boot_pick_count'] as int?,
        yellowCardPickId: statsResponse?['yellow_card_pick'] as String?,
        yellowCardPickCount: statsResponse?['yellow_card_pick_count'] as int?,
        redCardPickId: statsResponse?['red_card_pick'] as String?,
        redCardPickCount: statsResponse?['red_card_pick_count'] as int?,
        goldenBootHit: statsResponse?['golden_boot_hit'] as bool?,
        goldenBootHitMen: statsResponse?['golden_boot_hit'] as bool?, // TODO: separate field in DB
        goldenBootHitWomen: false, // TODO: separate field in DB
        yellowCardHit: statsResponse?['yellow_card_hit'] as bool?,
        redCardHit: statsResponse?['red_card_hit'] as bool?,
      );
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<List<SeasonHistory>> getSeasonHistory(String userId) async {
    try {
      final response = await _supabase
          .from('user_season_stats')
          .select('''
            season_id,
            total_points,
            exact_hits,
            final_rank,
            golden_boot_hit,
            seasons!inner(name, ends_at)
          ''')
          .eq('user_id', userId)
          .order('seasons(ends_at)', ascending: false);

      return (response as List).map((json) {
        final seasonData = json['seasons'] as Map<String, dynamic>;
        return SeasonHistory(
          seasonId: json['season_id'] as String,
          seasonName: seasonData['name'] as String,
          totalPoints: json['total_points'] as int,
          exactHits: json['exact_hits'] as int,
          finalRank: json['final_rank'] as int?,
          goldenBootHit: json['golden_boot_hit'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching season history: $e');
      return [];
    }
  }
}

class UserProfile {
  final String username;
  final int totalPoints;
  final int exactHits;
  final int currentRank;
  final int? finalRank;
  final String? goldenBootPickMenId;
  final String? goldenBootPickWomenId;
  final String? yellowCardPickId;
  final String? redCardPickId;
  final int? goldenBootPickCount;
  final int? yellowCardPickCount;
  final int? redCardPickCount;
  final bool? goldenBootHit;
  final bool? goldenBootHitMen;
  final bool? goldenBootHitWomen;
  final bool? yellowCardHit;
  final bool? redCardHit;

  UserProfile({
    required this.username,
    required this.totalPoints,
    required this.exactHits,
    required this.currentRank,
    this.finalRank,
    this.goldenBootPickMenId,
    this.goldenBootPickWomenId,
    this.yellowCardPickId,
    this.redCardPickId,
    this.goldenBootPickCount,
    this.yellowCardPickCount,
    this.redCardPickCount,
    this.goldenBootHit,
    this.goldenBootHitMen,
    this.goldenBootHitWomen,
    this.yellowCardHit,
    this.redCardHit,
  });
}

class SeasonHistory {
  final String seasonId;
  final String seasonName;
  final int totalPoints;
  final int exactHits;
  final int? finalRank;
  final bool goldenBootHit;

  SeasonHistory({
    required this.seasonId,
    required this.seasonName,
    required this.totalPoints,
    required this.exactHits,
    this.finalRank,
    required this.goldenBootHit,
  });
}
