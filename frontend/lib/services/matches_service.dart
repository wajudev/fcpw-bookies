import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/match_model.dart';

class MatchesService {
  final _supabase = SupabaseConfig.client;

  Future<String?> getCurrentSeasonId() async {
    try {
      final response = await _supabase
          .from('seasons')
          .select('id')
          .eq('is_current', true)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      debugPrint('Error fetching current season: $e');
      return null;
    }
  }

  Future<DateTime?> getBootLockTime(String seasonId) async {
    try {
      final response = await _supabase
          .from('seasons')
          .select('boot_lock_time')
          .eq('id', seasonId)
          .maybeSingle();

      if (response?['boot_lock_time'] != null) {
        return DateTime.parse(response!['boot_lock_time'] as String);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching boot lock time: $e');
      return null;
    }
  }

  Future<List<Match>> getMatchesForSquad(String seasonId, String squad) async {
    try {
      final response = await _supabase
          .from('matches')
          .select()
          .eq('season_id', seasonId)
          .eq('squad', squad)
          .order('kickoff_time', ascending: true);

      return (response as List)
          .map((json) => Match.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching matches: $e');
      return [];
    }
  }

  Future<Map<String, Prediction>> getUserPredictions(
      String userId, String seasonId) async {
    try {
      final response = await _supabase
          .from('predictions')
          .select('*, matches!inner(season_id)')
          .eq('user_id', userId)
          .eq('matches.season_id', seasonId);

      final predictions = <String, Prediction>{};
      for (final json in response as List) {
        final prediction = Prediction.fromJson(json as Map<String, dynamic>);
        predictions[prediction.matchId] = prediction;
      }
      return predictions;
    } catch (e) {
      debugPrint('Error fetching predictions: $e');
      return {};
    }
  }

  Future<void> submitPrediction({
    required String userId,
    required String matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    try {
      // Check current auth state
      final currentUser = _supabase.auth.currentUser;
      debugPrint('Current auth user: ${currentUser?.id}');
      debugPrint('Attempting prediction: user=$userId, match=$matchId, score=$homeScore:$awayScore');

      // First, try to check if prediction exists
      final existing = await _supabase
          .from('predictions')
          .select('id')
          .eq('user_id', userId)
          .eq('match_id', matchId)
          .maybeSingle();

      if (existing != null) {
        // Update existing prediction
        debugPrint('Updating existing prediction: ${existing['id']}');
        await _supabase
            .from('predictions')
            .update({
              'home_score_guess': homeScore,
              'away_score_guess': awayScore,
            })
            .eq('user_id', userId)
            .eq('match_id', matchId);
      } else {
        // Insert new prediction
        debugPrint('Inserting new prediction');
        await _supabase.from('predictions').insert({
          'user_id': userId,
          'match_id': matchId,
          'home_score_guess': homeScore,
          'away_score_guess': awayScore,
        });
      }
      debugPrint('Prediction saved successfully');
    } catch (e) {
      debugPrint('Error submitting prediction: $e');
      rethrow;
    }
  }
}
