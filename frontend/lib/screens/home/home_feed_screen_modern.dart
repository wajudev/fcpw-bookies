import 'package:flutter/material.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../../services/auth_service.dart';
import '../../services/matches_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/players_service.dart';
import '../../services/profile_service.dart';
import '../../services/standings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/matchweek_widget.dart';
import '../../widgets/leaderboard_widget.dart';
import '../../widgets/golden_boot_widget.dart';
import '../../widgets/golden_boot_picker.dart';
import '../../widgets/golden_boot_dual_widget.dart';
import '../../widgets/card_predictor_widget.dart';
import '../../widgets/top_scorers_widget.dart';
import '../../widgets/discipline_table_widget.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/hover_scale_widget.dart';
import '../../widgets/manual_carousel_widget.dart';
import '../../widgets/auto_carousel_widget.dart';
import '../../widgets/all_tables_slide.dart';
import '../../widgets/fun_stats_slide.dart';
import '../../widgets/league_table_widget.dart';

class HomeFeedScreenModern extends StatefulWidget {
  final VoidCallback? onNavigateToMatches;

  const HomeFeedScreenModern({super.key, this.onNavigateToMatches});

  @override
  State<HomeFeedScreenModern> createState() => _HomeFeedScreenModernState();
}

class _HomeFeedScreenModernState extends State<HomeFeedScreenModern> {
  final _authService = AuthService();
  final _matchesService = MatchesService();
  final _leaderboardService = LeaderboardService();
  final _playersService = PlayersService();
  final _profileService = ProfileService();
  final _standingsService = StandingsService();

  String? _seasonId;
  UserProfile? _profile;
  List<Match> _nextMatchweekGames = [];
  int _currentMatchweek = 1;
  Map<String, Prediction> _predictions = {};
  List<({String username, int points, int rank})> _topUsers = [];
  List<Player> _allPlayers = [];
  Player? _goldenBootPickMen;
  Player? _goldenBootPickWomen;
  Player? _yellowCardPick;
  Player? _redCardPick;
  Player? _topMenScorer;
  Player? _topWomenScorer;
  List<Player> _yellowLeaders = [];
  List<Player> _redLeaders = [];
  List<TeamStanding> _kmStandings = [];
  List<TeamStanding> _reserveStandings = [];
  List<TeamStanding> _womenStandings = [];
  bool _isBootLocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final seasonId = await _matchesService.getCurrentSeasonId();
    if (seasonId == null || !mounted) {
      setState(() => _isLoading = false);
      return;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Get all matches from all squads
    final kmMatches = await _matchesService.getMatchesForSquad(seasonId, 'km');
    final reserveMatches =
        await _matchesService.getMatchesForSquad(seasonId, 'reserve');
    final womenMatches =
        await _matchesService.getMatchesForSquad(seasonId, 'women');

    final allMatches = [...kmMatches, ...reserveMatches, ...womenMatches];
    allMatches.sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));

    // Get current matchweek from next upcoming match
    final now = DateTime.now();
    final upcomingMatches = allMatches
        .where((m) =>
            m.status == MatchStatus.upcoming && m.kickoffTime.isAfter(now))
        .toList();

    print('DEBUG: Total matches: ${allMatches.length}');
    print('DEBUG: Upcoming matches: ${upcomingMatches.length}');

    // Check all matchweek values
    final matchweekValues = allMatches
        .map((m) => m.matchweek)
        .where((mw) => mw != null)
        .toSet()
        .toList()
      ..sort();
    print('DEBUG: All matchweek values (non-null): $matchweekValues');
    print('DEBUG: Matches with null matchweek: ${allMatches.where((m) => m.matchweek == null).length}');

    // Check first 5 matches
    for (var i = 0; i < (allMatches.length > 5 ? 5 : allMatches.length); i++) {
      print('DEBUG: Match ${i + 1}: ${allMatches[i].homeTeam} - matchweek: ${allMatches[i].matchweek}, name: ${allMatches[i].matchweekName}');
    }

    final currentMatchweek = upcomingMatches.isNotEmpty
        ? upcomingMatches.first.matchweek ?? 1
        : 1;

    print('DEBUG: Current matchweek: $currentMatchweek');

    // Get all matches from this matchweek
    final nextMatchweekGames = allMatches
        .where((m) => m.matchweek == currentMatchweek)
        .toList();

    print('DEBUG: Matchweek games for MW $currentMatchweek: ${nextMatchweekGames.length}');

    final predictions =
        await _matchesService.getUserPredictions(userId, seasonId);

    // Fetch user profile to get pick counts and hits
    final profile = await _profileService.getUserProfile(userId, seasonId);

    // Fetch real leaderboard data
    final leaderboard = await _leaderboardService.getLeaderboard(seasonId, limit: 5);
    final topUsers = leaderboard
        .map((entry) => (
              username: entry.username,
              points: entry.totalPoints,
              rank: entry.rank,
            ))
        .toList();

    // Fetch players and predictions
    final players = await _playersService.getPlayersForSeason(seasonId);
    final bootLocked = await _playersService.isGoldenBootLocked(seasonId);

    // Get golden boot picks
    final bootPickMenId = await _playersService.getGoldenBootPick(userId, seasonId, gender: 'M');
    Player? bootPickMen;
    if (bootPickMenId != null) {
      bootPickMen = await _playersService.getGoldenBootPlayer(bootPickMenId);
    }

    final bootPickWomenId = await _playersService.getGoldenBootPick(userId, seasonId, gender: 'F');
    Player? bootPickWomen;
    if (bootPickWomenId != null) {
      bootPickWomen = await _playersService.getGoldenBootPlayer(bootPickWomenId);
    }

    // Get card picks
    final yellowPickId = await _playersService.getCardPick(userId, seasonId, type: 'yellow');
    Player? yellowPick;
    if (yellowPickId != null) {
      yellowPick = await _playersService.getGoldenBootPlayer(yellowPickId);
    }

    final redPickId = await _playersService.getCardPick(userId, seasonId, type: 'red');
    Player? redPick;
    if (redPickId != null) {
      redPick = await _playersService.getGoldenBootPlayer(redPickId);
    }

    // Get top scorers
    final topMen = await _playersService.getTopScorer(seasonId, gender: 'M');
    final topWomen = await _playersService.getTopScorer(seasonId, gender: 'F');

    // Get discipline leaders
    final yellowLeaders = await _playersService.getTopYellowCards(seasonId, limit: 5);
    final redLeaders = await _playersService.getTopRedCards(seasonId, limit: 5);

    // Get standings
    final kmStandings = await _standingsService.getStandings(seasonId, 'km');
    final reserveStandings = await _standingsService.getStandings(seasonId, 'reserve');
    final womenStandings = await _standingsService.getStandings(seasonId, 'women');

    if (!mounted) return;

    setState(() {
      _seasonId = seasonId;
      _profile = profile;
      _nextMatchweekGames = nextMatchweekGames;
      _currentMatchweek = currentMatchweek;
      _predictions = predictions;
      _topUsers = topUsers;
      _allPlayers = players;
      _goldenBootPickMen = bootPickMen;
      _goldenBootPickWomen = bootPickWomen;
      _yellowCardPick = yellowPick;
      _redCardPick = redPick;
      _topMenScorer = topMen;
      _topWomenScorer = topWomen;
      _yellowLeaders = yellowLeaders;
      _redLeaders = redLeaders;
      _kmStandings = kmStandings;
      _reserveStandings = reserveStandings;
      _womenStandings = womenStandings;
      _isBootLocked = bootLocked;
      _isLoading = false;
    });
  }

  Future<void> _showGoldenBootPicker(String gender) async {
    if (_isBootLocked) return;

    final isMen = gender == 'M';
    final players = _allPlayers.where((p) => p.gender == gender).toList();
    final currentPick = isMen ? _goldenBootPickMen : _goldenBootPickWomen;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => GoldenBootPicker(
        players: players,
        currentPick: currentPick,
        isLocked: _isBootLocked,
        currentGoalsPrediction: _profile?.goldenBootPickCount,
      ),
    );

    if (result != null && mounted) {
      try {
        final player = result['player'] as Player;
        final predictedGoals = isMen ? result['predictedGoals'] as int? : null;

        await _playersService.submitGoldenBootPick(
          userId: _authService.currentUser!.id,
          seasonId: _seasonId!,
          playerId: player.id,
          gender: gender,
          predictedGoals: predictedGoals,
        );

        if (mounted) {
          final genderLabel = isMen ? "Men's" : "Women's";
          SnackbarHelper.showSuccess(
            context,
            predictedGoals != null
                ? '$genderLabel Golden Boot selected! ($predictedGoals goals)'
                : '$genderLabel Golden Boot selected!',
          );
          _loadData(); // Refresh
        }
      } catch (e) {
        debugPrint('Error saving golden boot: $e');
        if (mounted) {
          SnackbarHelper.showError(context, 'Error saving');
        }
      }
    }
  }

  Future<void> _showCardPicker(String type) async {
    if (_isBootLocked) return;

    final isYellow = type == 'yellow';
    final currentPick = isYellow ? _yellowCardPick : _redCardPick;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => GoldenBootPicker(
        players: _allPlayers,
        currentPick: currentPick,
        isLocked: _isBootLocked,
        countLabel: isYellow ? 'Predicted yellow cards' : 'Predicted red cards',
        currentGoalsPrediction: isYellow ? _profile?.yellowCardPickCount : _profile?.redCardPickCount,
      ),
    );

    if (result != null && mounted) {
      try {
        final player = result['player'] as Player;
        final predictedCount = result['predictedGoals'] as int?;

        await _playersService.submitCardPick(
          userId: _authService.currentUser!.id,
          seasonId: _seasonId!,
          playerId: player.id,
          type: type,
          predictedCount: predictedCount,
        );

        if (mounted) {
          final label = isYellow ? 'Yellow card' : 'Red card';
          SnackbarHelper.showSuccess(context, '$label pick saved!');
          _loadData(); // Refresh
        }
      } catch (e) {
        debugPrint('Error saving card pick: $e');
        if (mounted) {
          SnackbarHelper.showError(context, 'Error saving');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
        children: [
          // Header shimmer
          const LoadingShimmer(width: 150, height: 20),
          const SizedBox(height: 8),
          const LoadingShimmer(width: 100, height: 32),
          const SizedBox(height: 32),
          // Matchweek shimmer
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          // Golden boot shimmer
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          // Leaderboard shimmer
          ...List.generate(3, (_) => const LeaderboardRowShimmer()),
        ],
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1. FCPW',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Auto-rotating carousel (Matchweek, Tables, Fun Stats)
          SizedBox(
            height: 580,
            child: AutoCarouselWidget(
              interval: const Duration(seconds: 20),
              slides: [
                // Slide 1: Matchweek (full)
                if (_nextMatchweekGames.isNotEmpty)
                  Column(
                    children: [
                      Expanded(
                        child: MatchweekWidget(
                          matchweekNumber: _currentMatchweek,
                          matches: _nextMatchweekGames,
                          predictions: _predictions,
                          onTap: widget.onNavigateToMatches,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextButton.icon(
                          onPressed: widget.onNavigateToMatches,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('View all matches'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  const Center(
                    child: Text('No upcoming matches'),
                  ),

                // Slide 2: All league tables (top 5 only)
                AllTablesSlide(
                  kmStandings: _kmStandings,
                  reserveStandings: _reserveStandings,
                  womenStandings: _womenStandings,
                  onTap: widget.onNavigateToMatches,
                ),

                // Slide 3: Fun stats
                const FunStatsSlide(
                  hotStreak: null,
                  coldStreak: null,
                  recentLeader: null,
                  biggestLead: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Golden Boot & Card Predictor Row (responsive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return Column(
                    children: [
                      HoverScaleWidget(
                        child: GoldenBootDualWidget(
                          menPick: _goldenBootPickMen,
                          womenPick: _goldenBootPickWomen,
                          isLocked: _isBootLocked,
                          onTapMen: () => _showGoldenBootPicker('M'),
                          onTapWomen: () => _showGoldenBootPicker('F'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      HoverScaleWidget(
                        child: CardPredictorWidget(
                          yellowCardPick: _yellowCardPick,
                          redCardPick: _redCardPick,
                          isLocked: _isBootLocked,
                          onTapYellow: () => _showCardPicker('yellow'),
                          onTapRed: () => _showCardPicker('red'),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: HoverScaleWidget(
                        child: GoldenBootDualWidget(
                          menPick: _goldenBootPickMen,
                          womenPick: _goldenBootPickWomen,
                          isLocked: _isBootLocked,
                          onTapMen: () => _showGoldenBootPicker('M'),
                          onTapWomen: () => _showGoldenBootPicker('F'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HoverScaleWidget(
                        child: CardPredictorWidget(
                          yellowCardPick: _yellowCardPick,
                          redCardPick: _redCardPick,
                          isLocked: _isBootLocked,
                          onTapYellow: () => _showCardPicker('yellow'),
                          onTapRed: () => _showCardPicker('red'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row: Leaderboard, Top Scorers, Discipline (responsive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      HoverScaleWidget(
                        child: LeaderboardWidget(
                          topUsers: _topUsers.take(5).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      HoverScaleWidget(
                        child: TopScorersWidget(
                          topMenScorer: _topMenScorer,
                          topWomenScorer: _topWomenScorer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      HoverScaleWidget(
                        child: DisciplineTableWidget(
                          yellowCardLeaders: _yellowLeaders,
                          redCardLeaders: _redLeaders,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: HoverScaleWidget(
                        child: LeaderboardWidget(
                          topUsers: _topUsers.take(5).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HoverScaleWidget(
                        child: TopScorersWidget(
                          topMenScorer: _topMenScorer,
                          topWomenScorer: _topWomenScorer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HoverScaleWidget(
                        child: DisciplineTableWidget(
                          yellowCardLeaders: _yellowLeaders,
                          redCardLeaders: _redLeaders,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Empty state
          if (_nextMatchweekGames.isEmpty && _topUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No matches available',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}
