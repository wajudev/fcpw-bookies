import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/player_model.dart';

class PlayersService {
  final _supabase = SupabaseConfig.client;

  Future<List<Player>> getPlayersForSeason(String seasonId, {String? gender}) async {
    try {
      var query = _supabase
          .from('players')
          .select()
          .eq('season_id', seasonId);

      if (gender != null) {
        query = query.eq('gender', gender);
      }

      final response = await query.order('goals', ascending: false);

      return (response as List)
          .map((json) => Player.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching players: $e');
      return [];
    }
  }

  Future<String?> getGoldenBootPick(String userId, String seasonId, {required String gender}) async {
    try {
      final column = gender == 'M' ? 'golden_boot_pick_men' : 'golden_boot_pick_women';
      final response = await _supabase
          .from('user_season_stats')
          .select(column)
          .eq('user_id', userId)
          .eq('season_id', seasonId)
          .maybeSingle();

      return response?[column] as String?;
    } catch (e) {
      debugPrint('Error fetching golden boot pick: $e');
      return null;
    }
  }

  Future<void> submitGoldenBootPick({
    required String userId,
    required String seasonId,
    required String playerId,
    required String gender, // 'M' or 'F'
    int? predictedGoals,
  }) async {
    try {
      final column = gender == 'M' ? 'golden_boot_pick_men' : 'golden_boot_pick_women';
      debugPrint('Submitting golden boot ($gender): user=$userId, season=$seasonId, player=$playerId, goals=$predictedGoals');

      // Check current auth
      final currentUser = _supabase.auth.currentUser;
      debugPrint('Current auth user: ${currentUser?.id}');

      // Check if stats exist
      final existing = await _supabase
          .from('user_season_stats')
          .select('user_id')
          .eq('user_id', userId)
          .eq('season_id', seasonId)
          .maybeSingle();

      debugPrint('Existing stats: ${existing != null ? "found" : "not found"}');

      if (existing != null) {
        // Update
        print('🔄 Updating existing golden boot stats ($column)');
        await _supabase
            .from('user_season_stats')
            .update({
              column: playerId,
              if (predictedGoals != null) 'golden_boot_goals_prediction': predictedGoals,
            })
            .eq('user_id', userId)
            .eq('season_id', seasonId);
      } else {
        // Insert with explicit defaults
        print('➕ Inserting new golden boot stats');
        await _supabase.from('user_season_stats').insert({
          'user_id': userId,
          'season_id': seasonId,
          column: playerId,
          'total_points': 0,
          'exact_hits': 0,
          if (predictedGoals != null) 'golden_boot_goals_prediction': predictedGoals,
        });
      }

      debugPrint('Golden boot saved successfully');
    } catch (e) {
      debugPrint('Error submitting golden boot pick: $e');
      rethrow;
    }
  }

  Future<Player?> getGoldenBootPlayer(String playerId) async {
    try {
      final response =
          await _supabase.from('players').select().eq('id', playerId).single();

      return Player.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching player: $e');
      return null;
    }
  }

  Future<bool> isGoldenBootLocked(String seasonId) async {
    try {
      final response = await _supabase
          .from('seasons')
          .select('boot_lock_time')
          .eq('id', seasonId)
          .single();

      final lockTime = DateTime.parse(response['boot_lock_time'] as String);
      return DateTime.now().isAfter(lockTime);
    } catch (e) {
      debugPrint('Error checking golden boot lock: $e');
      return true; // Locked by default on error
    }
  }

  Future<Player?> getTopScorer(String seasonId, {required String gender}) async {
    try {
      final response = await _supabase
          .from('players')
          .select()
          .eq('season_id', seasonId)
          .eq('gender', gender)
          .gt('goals', 0) // Only players with goals
          .order('goals', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return Player.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching top scorer ($gender): $e');
      return null;
    }
  }

  Future<List<Player>> getTopYellowCards(String seasonId, {int limit = 5}) async {
    try {
      final response = await _supabase
          .from('players')
          .select()
          .eq('season_id', seasonId)
          .gt('yellow_cards', 0)
          .order('yellow_cards', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Player.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching yellow card leaders: $e');
      return [];
    }
  }

  Future<List<Player>> getTopRedCards(String seasonId, {int limit = 5}) async {
    try {
      final response = await _supabase
          .from('players')
          .select()
          .eq('season_id', seasonId)
          .gt('red_cards', 0)
          .order('red_cards', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Player.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching red card leaders: $e');
      return [];
    }
  }

  Future<String?> getCardPick(String userId, String seasonId, {required String type}) async {
    try {
      final column = type == 'yellow' ? 'yellow_card_pick' : 'red_card_pick';
      final response = await _supabase
          .from('user_season_stats')
          .select(column)
          .eq('user_id', userId)
          .eq('season_id', seasonId)
          .maybeSingle();

      return response?[column] as String?;
    } catch (e) {
      debugPrint('Error fetching card pick ($type): $e');
      return null;
    }
  }

  Future<void> submitCardPick({
    required String userId,
    required String seasonId,
    required String playerId,
    required String type, // 'yellow' or 'red'
    int? predictedCount,
  }) async {
    try {
      final column = type == 'yellow' ? 'yellow_card_pick' : 'red_card_pick';
      debugPrint('Submitting card pick ($type): user=$userId, season=$seasonId, player=$playerId');

      // Check if stats exist
      final existing = await _supabase
          .from('user_season_stats')
          .select('user_id')
          .eq('user_id', userId)
          .eq('season_id', seasonId)
          .maybeSingle();

      if (existing != null) {
        // Update
        final updatePayload = <String, dynamic>{column: playerId};
        if (predictedCount != null) {
          updatePayload[ type == 'yellow' ? 'yellow_card_pick_count' : 'red_card_pick_count' ] = predictedCount;
        }
        await _supabase
            .from('user_season_stats')
            .update(updatePayload)
            .eq('user_id', userId)
            .eq('season_id', seasonId);
      } else {
        // Insert
        final insertPayload = <String, dynamic>{
          'user_id': userId,
          'season_id': seasonId,
          column: playerId,
          'total_points': 0,
          'exact_hits': 0,
        };
        if (predictedCount != null) {
          insertPayload[ type == 'yellow' ? 'yellow_card_pick_count' : 'red_card_pick_count' ] = predictedCount;
        }
        await _supabase.from('user_season_stats').insert(insertPayload);
      }

      debugPrint('Card pick saved successfully');
    } catch (e) {
      debugPrint('Error submitting card pick: $e');
      rethrow;
    }
  }
}
