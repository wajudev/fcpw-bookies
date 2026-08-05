import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../widgets/league_table_widget.dart';

class StandingsService {
  final _supabase = SupabaseConfig.client;

  Future<List<TeamStanding>> getStandings(String seasonId, String squad) async {
    try {
      debugPrint('Fetching standings: seasonId=$seasonId, squad=$squad');

      final response = await _supabase
          .from('team_standings')
          .select()
          .eq('season_id', seasonId)
          .eq('squad', squad)
          .order('position', ascending: true);

      debugPrint('Standings response for $squad: ${(response as List).length} teams');

      return (response as List)
          .map((json) => TeamStanding.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching standings for $squad: $e');
      return [];
    }
  }
}
