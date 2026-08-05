import 'package:flutter/material.dart';
import '../../widgets/league_table_widget.dart';
import '../../widgets/leaderboard_widget.dart';
import '../../services/leaderboard_service.dart';
import '../../services/matches_service.dart';
import '../../services/standings_service.dart';
import '../../theme/app_theme.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  bool _isLoading = true;
  final _leaderboardService = LeaderboardService();
  final _matchesService = MatchesService();
  final _standingsService = StandingsService();

  List<TeamStanding> _kmStandings = [];
  List<TeamStanding> _reserveStandings = [];
  List<TeamStanding> _womenStandings = [];
  List<({String username, int points, int rank})> _topUsers = [];

  @override
  void initState() {
    super.initState();
    _loadStandings();
  }

  Future<void> _loadStandings() async {
    setState(() => _isLoading = true);

    // Get current season
    final seasonId = await _matchesService.getCurrentSeasonId();

    if (seasonId != null) {
      // Fetch leaderboard
      final leaderboard = await _leaderboardService.getLeaderboard(seasonId, limit: 10);
      final topUsers = leaderboard
          .map((entry) => (
                username: entry.username,
                points: entry.totalPoints,
                rank: entry.rank,
              ))
          .toList();

      // Fetch standings
      final kmStandings = await _standingsService.getStandings(seasonId, 'km');
      final reserveStandings = await _standingsService.getStandings(seasonId, 'reserve');
      final womenStandings = await _standingsService.getStandings(seasonId, 'women');

      print('DEBUG: KM standings: ${kmStandings.length}');
      print('DEBUG: Reserve standings: ${reserveStandings.length}');
      print('DEBUG: Women standings: ${womenStandings.length}');

      if (mounted) {
        setState(() {
          _topUsers = topUsers;
          _kmStandings = kmStandings;
          _reserveStandings = reserveStandings;
          _womenStandings = womenStandings;
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
                            'League Tables',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Season standings for all squads',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Leaderboard (full list on this page)
                    LeaderboardWidget(topUsers: _topUsers), // Shows top 10
                    const SizedBox(height: 32),

                    // Section Header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'League Standings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tables Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KM Table
                        Expanded(
                          child: LeagueTableWidget(
                            squadName: 'KM',
                            standings: _kmStandings,
                            highlightTeam: '1. FC Paulaner Wieden',
                          ),
                        ),

                        // Reserve Table
                        Expanded(
                          child: LeagueTableWidget(
                            squadName: 'Reserve',
                            standings: _reserveStandings,
                            highlightTeam: '1. SC Paulaner Wieden',
                          ),
                        ),

                        // Women Table
                        Expanded(
                          child: LeagueTableWidget(
                            squadName: 'Women',
                            standings: _womenStandings,
                            highlightTeam: '1. FC Paulaner Wieden',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Info message if no data
                    if (_kmStandings.isEmpty &&
                        _reserveStandings.isEmpty &&
                        _womenStandings.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.table_chart,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'League standings not available yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tables will be updated as matches are played',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
