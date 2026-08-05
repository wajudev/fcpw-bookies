import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/match_model.dart';
import '../../services/auth_service.dart';
import '../../services/matches_service.dart';
import '../../services/standings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/error_handler.dart';
import '../../widgets/prediction_dialog.dart';
import '../../widgets/match_detail_sheet.dart';
import '../../widgets/league_table_widget.dart';
import '../../widgets/match_calendar_dialog.dart';
import '../../widgets/hover_scale_widget.dart';
import '../../widgets/manual_carousel_widget.dart';

class MatchesByWeekScreen extends StatefulWidget {
  const MatchesByWeekScreen({super.key});

  @override
  State<MatchesByWeekScreen> createState() => _MatchesByWeekScreenState();
}

class _MatchesByWeekScreenState extends State<MatchesByWeekScreen> {
  final _authService = AuthService();
  final _matchesService = MatchesService();
  final _standingsService = StandingsService();

  String? _seasonId;
  int _currentMatchweek = 1;
  int _maxMatchweek = 1;
  List<Match> _matchweekMatches = [];
  List<Match> _allMatches = [];
  Map<String, Prediction> _predictions = {};
  List<TeamStanding> _kmStandings = [];
  List<TeamStanding> _reserveStandings = [];
  List<TeamStanding> _womenStandings = [];
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

    // Get all matches
    final kmMatches = await _matchesService.getMatchesForSquad(seasonId, 'km');
    final reserveMatches =
        await _matchesService.getMatchesForSquad(seasonId, 'reserve');
    final womenMatches =
        await _matchesService.getMatchesForSquad(seasonId, 'women');

    final allMatches = [...kmMatches, ...reserveMatches, ...womenMatches];

    // Find max matchweek
    final maxMatchweek = allMatches
        .where((m) => m.matchweek != null)
        .map((m) => m.matchweek!)
        .fold(1, (max, mw) => mw > max ? mw : max);

    // Get current matchweek (next upcoming)
    final now = DateTime.now();
    final upcoming = allMatches
        .where((m) =>
            m.status == MatchStatus.upcoming &&
            m.kickoffTime.isAfter(now) &&
            m.matchweek != null)
        .toList()
      ..sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));

    final currentMatchweek = upcoming.isNotEmpty
        ? upcoming.first.matchweek!
        : allMatches
                .where((m) => m.matchweek != null)
                .map((m) => m.matchweek!)
                .fold(1, (max, mw) => mw > max ? mw : max);

    final predictions =
        await _matchesService.getUserPredictions(userId, seasonId);

    // Fetch standings
    final kmStandings = await _standingsService.getStandings(seasonId, 'km');
    final reserveStandings = await _standingsService.getStandings(seasonId, 'reserve');
    final womenStandings = await _standingsService.getStandings(seasonId, 'women');

    if (!mounted) return;

    setState(() {
      _seasonId = seasonId;
      _currentMatchweek = currentMatchweek;
      _maxMatchweek = maxMatchweek;
      _predictions = predictions;
      _allMatches = allMatches;
      _kmStandings = kmStandings;
      _reserveStandings = reserveStandings;
      _womenStandings = womenStandings;
      _isLoading = false;
    });

    _loadMatchweek(currentMatchweek, allMatches);
  }

  void _loadMatchweek(int matchweek, List<Match>? allMatches) async {
    if (allMatches == null) {
      // Reload all matches
      final kmMatches =
          await _matchesService.getMatchesForSquad(_seasonId!, 'km');
      final reserveMatches =
          await _matchesService.getMatchesForSquad(_seasonId!, 'reserve');
      final womenMatches =
          await _matchesService.getMatchesForSquad(_seasonId!, 'women');
      allMatches = [...kmMatches, ...reserveMatches, ...womenMatches];
    }

    final matchweekMatches = allMatches
        .where((m) => m.matchweek == matchweek)
        .toList()
      ..sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));

    setState(() {
      _currentMatchweek = matchweek;
      _matchweekMatches = matchweekMatches;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final dateFormat = DateFormat('EEE, d MMM');

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          '1. FCPW Matches 2026/27',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        actions: [
          // Calendar view
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => MatchCalendarDialog(
                  allMatches: _allMatches,
                  selectedDate: _matchweekMatches.isNotEmpty
                      ? _matchweekMatches.first.kickoffTime
                      : null,
                  onDateSelected: (date) {
                    // Find matchweek for selected date
                    final matchOnDate = _allMatches.firstWhere(
                      (m) {
                        final matchDate = DateTime(
                          m.kickoffTime.year,
                          m.kickoffTime.month,
                          m.kickoffTime.day,
                        );
                        final targetDate = DateTime(date.year, date.month, date.day);
                        return matchDate == targetDate;
                      },
                      orElse: () => _allMatches.first,
                    );
                    if (matchOnDate.matchweek != null) {
                      _loadMatchweek(matchOnDate.matchweek!, null);
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Matchweek navigation
            Container(
              color: AppTheme.cardWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentMatchweek > 1
                      ? () => _loadMatchweek(_currentMatchweek - 1, null)
                      : null,
                  color: AppTheme.primaryPurple,
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      'Matchweek $_currentMatchweek',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (_matchweekMatches.isNotEmpty)
                      Text(
                        '${dateFormat.format(_matchweekMatches.first.kickoffTime)} - ${dateFormat.format(_matchweekMatches.last.kickoffTime)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentMatchweek < _maxMatchweek
                      ? () => _loadMatchweek(_currentMatchweek + 1, null)
                      : null,
                  color: AppTheme.primaryPurple,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Matches list + League Tables
          Expanded(
            child: _matchweekMatches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matches in this matchweek',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Matches
                        ..._matchweekMatches.map((match) => _buildMatchCard(match)),

                        const SizedBox(height: 32),

                        // League Tables Section
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
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

                        // Tables Row (responsive)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Stack vertically on narrow screens (< 900px)
                            if (constraints.maxWidth < 900) {
                              return Column(
                                children: [
                                  HoverScaleWidget(
                                    child: LeagueTableWidget(
                                      squadName: 'KM',
                                      standings: _kmStandings,
                                      highlightTeam: 'DSG Paulaner Wieden',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  HoverScaleWidget(
                                    child: LeagueTableWidget(
                                      squadName: 'Women',
                                      standings: _womenStandings,
                                      highlightTeam: 'Paulaner Wieden',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  HoverScaleWidget(
                                    child: LeagueTableWidget(
                                      squadName: 'Reserve',
                                      standings: _reserveStandings,
                                      highlightTeam: 'DSG Paulaner Wieden',
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Horizontal on wider screens - Manual Carousel
                            return ManualCarouselWidget(
                              useClick: true, // Click to rotate
                              children: [
                                LeagueTableWidget(
                                  squadName: 'KM',
                                  standings: _kmStandings,
                                  highlightTeam: 'DSG Paulaner Wieden',
                                ),
                                LeagueTableWidget(
                                  squadName: 'Women',
                                  standings: _womenStandings,
                                  highlightTeam: 'Paulaner Wieden',
                                ),
                                LeagueTableWidget(
                                  squadName: 'Reserve',
                                  standings: _reserveStandings,
                                  highlightTeam: 'DSG Paulaner Wieden',
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _showPredictionDialog(Match match) async {
    final prediction = _predictions[match.id];
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => PredictionDialog(
        match: match,
        existingPrediction: prediction,
      ),
    );

    if (result != null && mounted) {
      try {
        final userId = _authService.currentUser!.id;
        debugPrint('Submitting prediction for user: $userId, match: ${match.id}');
        await _matchesService.submitPrediction(
          userId: userId,
          matchId: match.id,
          homeScore: result['homeScore']!,
          awayScore: result['awayScore']!,
        );

        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Prediction saved!');
          _loadData(); // Refresh
        }
      } catch (e) {
        ErrorHandler.logError('Submitting prediction', e);
        if (mounted) {
          final errorMessage = ErrorHandler.getUserMessage(e);
          SnackbarHelper.showError(context, errorMessage);
        }
      }
    }
  }

  Widget _buildMatchCard(Match match) {
    final prediction = _predictions[match.id];
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('EEE, d MMM');
    final isFinished = match.status == MatchStatus.finished;
    final isLive = match.status == MatchStatus.live;

    return GestureDetector(
      onTap: () => _showPredictionDialog(match),
      onLongPress: () => MatchDetailSheet.show(context, match, prediction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
            // Date + Squad badge
            Row(
              children: [
                Text(
                  dateFormat.format(match.kickoffTime),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                _buildSquadBadge(match.squad),
                const SizedBox(width: 8),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.liveRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    timeFormat.format(match.kickoffTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Teams and score
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.homeTeam,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (isFinished || isLive)
                  Row(
                    children: [
                      Text(
                        '${match.homeScoreActual ?? 0}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      Text(
                        '${match.awayScoreActual ?? 0}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'vs',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    match.awayTeam,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            // Prediction status
            if (prediction != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your prediction: ${prediction.homeScoreGuess}:${prediction.awayScoreGuess}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    if (prediction.pointsAwarded != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPointsColor(prediction.pointsAwarded!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${prediction.pointsAwarded}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    // Show edit button if not locked
                    if (!match.isLocked && !isFinished) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit,
                        size: 14,
                        color: AppTheme.primaryGreen.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (!match.isLocked && !isFinished)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Tap to predict',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSquadBadge(String squad) {
    final config = _getSquadConfig(squad);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: config.color,
        ),
      ),
    );
  }

  ({String label, Color color}) _getSquadConfig(String squad) {
    switch (squad) {
      case 'km':
        return (label: 'KM', color: AppTheme.kmGold);
      case 'reserve':
        return (label: 'RESERVE', color: AppTheme.reserveBlue);
      case 'women':
        return (label: 'FRAUEN', color: AppTheme.womenPink);
      default:
        return (label: squad.toUpperCase(), color: AppTheme.textSecondary);
    }
  }

  Color _getPointsColor(int points) {
    if (points == 3) return AppTheme.primaryGreen;
    if (points == 1) return AppTheme.kmGold;
    return AppTheme.liveRed;
  }
}
