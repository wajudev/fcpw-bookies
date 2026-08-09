import 'package:flutter/material.dart';
import '../../widgets/leaderboard_widget.dart';
import '../../services/leaderboard_service.dart';
import '../../services/matches_service.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreenFull extends StatefulWidget {
  const LeaderboardScreenFull({super.key});

  @override
  State<LeaderboardScreenFull> createState() => _LeaderboardScreenFullState();
}

class _LeaderboardScreenFullState extends State<LeaderboardScreenFull> {
  bool _isLoading = true;
  final _leaderboardService = LeaderboardService();
  final _matchesService = MatchesService();

  List<({String username, int points, int rank})> _topUsers = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    final seasonId = await _matchesService.getCurrentSeasonId();

    if (seasonId != null) {
      final leaderboard = await _leaderboardService.getLeaderboard(seasonId, limit: 100);
      final topUsers = leaderboard
          .map((entry) => (
                username: entry.username,
                points: entry.totalPoints,
                rank: entry.rank,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _topUsers = topUsers;
        });
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leaderboard',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Season rankings',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full Leaderboard
                    LeaderboardWidget(topUsers: _topUsers),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
