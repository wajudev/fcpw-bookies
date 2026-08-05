import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/match_model.dart';
import '../../services/auth_service.dart';
import '../../services/matches_service.dart';
import '../../theme/app_theme.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final _authService = AuthService();
  final _matchesService = MatchesService();

  List<Match> _recentResults = [];
  List<Match> _upcomingMatches = [];
  Map<String, Prediction> _predictions = {};
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

    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));

    // Last week's finished matches
    final recentResults = allMatches
        .where((m) =>
            m.status == MatchStatus.finished &&
            m.kickoffTime.isAfter(lastWeek) &&
            m.kickoffTime.isBefore(now))
        .toList();

    // Next 6 upcoming matches
    final upcoming = allMatches
        .where((m) =>
            m.status == MatchStatus.upcoming && m.kickoffTime.isAfter(now))
        .take(6)
        .toList();

    final predictions =
        await _matchesService.getUserPredictions(userId, seasonId);

    if (!mounted) return;

    setState(() {
      _recentResults = recentResults;
      _upcomingMatches = upcoming;
      _predictions = predictions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Last week's results
          if (_recentResults.isNotEmpty) ...[
            _buildSectionTitle('Letzte Ergebnisse'),
            const SizedBox(height: 12),
            ..._recentResults.map((match) => _buildResultCard(match)),
            const SizedBox(height: 24),
          ],

          // Upcoming matches
          _buildSectionTitle('Nächste Spiele'),
          const SizedBox(height: 12),
          if (_upcomingMatches.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Keine bevorstehenden Spiele',
                  style: TextStyle(color: AppTheme.slateLight),
                ),
              ),
            )
          else
            ..._upcomingMatches.map((match) => _buildUpcomingCard(match)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = _authService.currentUser;
    final username = user?.userMetadata?['username'] ?? 'Spieler';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servus, $username! 👋',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.gold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '1. FCPW Predictor',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.slateLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildResultCard(Match match) {
    final prediction = _predictions[match.id];
    final dateFormat = DateFormat('EEE, dd.MM', 'de_DE');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Squad badge + date
            Row(
              children: [
                _buildSquadBadge(match.squad),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(match.kickoffTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.slateLight,
                  ),
                ),
                const Spacer(),
                if (prediction?.pointsAwarded != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPointsColor(prediction!.pointsAwarded!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${prediction.pointsAwarded} Pkt.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Match result
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.homeTeam,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (prediction != null)
                        Text(
                          'Tipp: ${prediction.homeScoreGuess}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.slateLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${match.homeScoreActual ?? '-'} : ${match.awayScoreActual ?? '-'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gold,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        match.awayTeam,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (prediction != null)
                        Text(
                          'Tipp: ${prediction.awayScoreGuess}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.slateLight,
                          ),
                          textAlign: TextAlign.right,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(Match match) {
    final prediction = _predictions[match.id];
    final dateFormat = DateFormat('EEE, dd.MM · HH:mm', 'de_DE');
    final isLocked = match.isLocked;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Squad badge + date + lock status
            Row(
              children: [
                _buildSquadBadge(match.squad),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateFormat.format(match.kickoffTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.slateLight,
                    ),
                  ),
                ),
                if (isLocked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          'Gesperrt',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Teams
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.homeTeam,
                    style: const TextStyle(fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'vs',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.slateLight,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.awayTeam,
                    style: const TextStyle(fontSize: 15),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Prediction status
            if (prediction != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.navyBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: AppTheme.gold),
                    const SizedBox(width: 8),
                    Text(
                      'Dein Tipp: ${prediction.homeScoreGuess} : ${prediction.awayScoreGuess}',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (!isLocked)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Noch kein Tipp abgegeben',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Center(
                child: Text(
                  'Kein Tipp abgegeben',
                  style: TextStyle(
                    color: AppTheme.slateLight,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadBadge(String squad) {
    final label = squad == 'km'
        ? 'KM'
        : squad == 'reserve'
            ? 'Res'
            : 'Frauen';
    final color = squad == 'km'
        ? AppTheme.gold
        : squad == 'reserve'
            ? Colors.blue
            : Colors.pink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getPointsColor(int points) {
    if (points == 3) return Colors.green;
    if (points == 1) return AppTheme.gold;
    return Colors.red.shade300;
  }
}
