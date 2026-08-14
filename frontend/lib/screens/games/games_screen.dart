import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../../services/auth_service.dart';
import '../../services/matches_service.dart';
import '../../services/players_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/golden_boot_picker.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _matchesService = MatchesService();
  final _playersService = PlayersService();
  final _profileService = ProfileService();

  String? _seasonId;
  UserProfile? _profile;
  Map<String, List<Match>> _matchesBySquad = {};
  Map<String, Prediction> _predictions = {};
  List<Player> _players = [];
  String? _goldenBootPick;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    final kmMatches = await _matchesService.getMatchesForSquad(seasonId, 'km');
    final reserveMatches =
        await _matchesService.getMatchesForSquad(seasonId, 'reserve');
    final womenMatches =
        await _matchesService.getMatchesForSquad(seasonId, 'women');

    final predictions =
        await _matchesService.getUserPredictions(userId, seasonId);
    final players = await _playersService.getPlayersForSeason(seasonId);
    final goldenBootPick =
      await _playersService.getGoldenBootPick(userId, seasonId);
    final profile = await _profileService.getUserProfile(userId, seasonId);

    if (!mounted) return;

    setState(() {
      _seasonId = seasonId;
      _profile = profile;
      _matchesBySquad = {
        'km': kmMatches,
        'reserve': reserveMatches,
        'women': womenMatches,
      };
      _predictions = predictions;
      _players = players;
      _goldenBootPick = goldenBootPick;
      _isLoading = false;
    });
  }

  Future<void> _submitPrediction(
      Match match, int homeScore, int awayScore) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    try {
      await _matchesService.submitPrediction(
        userId: userId,
        matchId: match.id,
        homeScore: homeScore,
        awayScore: awayScore,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tipp gespeichert!'),
          backgroundColor: AppTheme.kmGold,
          duration: Duration(seconds: 2),
        ),
      );

      _loadData(); // Refresh to show updated prediction
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Golden Boot Picker
        _buildGoldenBootSection(),
        // Squad Tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'KM'),
            Tab(text: 'Reserve'),
            Tab(text: 'Frauen'),
          ],
        ),
        // Match Lists
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMatchList('km'),
              _buildMatchList('reserve'),
              _buildMatchList('women'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoldenBootSection() {
    if (_seasonId == null || _players.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedPlayer =
        _players.where((p) => p.id == _goldenBootPick).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saisontipp: Torschützenkönig',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.kmGold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _goldenBootPick,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Spieler wählen'),
            items: _players.map((player) {
              return DropdownMenuItem(
                value: player.id,
                child: Text('${player.name} (${player.team})'),
              );
            }).toList(),
            onChanged: (playerId) async {
              if (playerId == null || _seasonId == null) return;
              final userId = _authService.currentUser?.id;
              if (userId == null) return;
              // Show dialog to optionally enter predicted goals
              final player = players.firstWhere((p) => p.id == playerId);
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => GoldenBootPicker(
                  players: [player],
                  currentPick: player,
                  currentGoalsPrediction: _profile?.goldenBootPickCount,
                ),
              );

              final predictedGoals = result?['predictedGoals'] as int?;

              try {
                await _playersService.submitGoldenBootPick(
                  userId: userId,
                  seasonId: _seasonId!,
                  playerId: playerId,
                  gender: player.gender,
                  predictedGoals: predictedGoals,
                );
                setState(() => _goldenBootPick = playerId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(predictedGoals != null
                        ? 'Torschützenkönig-Tipp gespeichert ($predictedGoals)!'
                        : 'Torschützenkönig-Tipp gespeichert!'),
                    backgroundColor: AppTheme.kmGold,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fehler: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(String squad) {
    final matches = _matchesBySquad[squad] ?? [];

    if (matches.isEmpty) {
      return const Center(
        child: Text('Keine Spiele gefunden'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          final prediction = _predictions[match.id];
          return _buildMatchCard(match, prediction);
        },
      ),
    );
  }

  Widget _buildMatchCard(Match match, Prediction? prediction) {
    final dateFormat = DateFormat('EEE, dd.MM.yyyy HH:mm', 'de_DE');
    final isLocked = match.isLocked;
    final isFinished = match.status == MatchStatus.finished;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and status
            Row(
              children: [
                Text(
                  dateFormat.format(match.kickoffTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                if (isLocked && !isFinished)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'GESPERRT',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (match.status == MatchStatus.live)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade900.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
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
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Text(' - ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    match.awayTeam,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Actual score (if finished or live)
            if (isFinished || match.status == MatchStatus.live)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ergebnis: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${match.homeScoreActual ?? '-'} : ${match.awayScoreActual ?? '-'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kmGold,
                    ),
                  ),
                  if (prediction?.pointsAwarded != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      '(${prediction!.pointsAwarded} Pkt.)',
                      style: TextStyle(
                        color: prediction.pointsAwarded == 3
                            ? Colors.green
                            : prediction.pointsAwarded == 1
                                ? AppTheme.kmGold
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 12),
            // Prediction inputs
            if (!isLocked && !isFinished)
              _PredictionInput(
                match: match,
                prediction: prediction,
                onSubmit: _submitPrediction,
              )
            else if (prediction != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Dein Tipp: '),
                  Text(
                    '${prediction.homeScoreGuess} : ${prediction.awayScoreGuess}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kmGold,
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Kein Tipp abgegeben',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _PredictionInput extends StatefulWidget {
  final Match match;
  final Prediction? prediction;
  final Future<void> Function(Match, int, int) onSubmit;

  const _PredictionInput({
    required this.match,
    required this.prediction,
    required this.onSubmit,
  });

  @override
  State<_PredictionInput> createState() => _PredictionInputState();
}

class _PredictionInputState extends State<_PredictionInput> {
  late TextEditingController _homeController;
  late TextEditingController _awayController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(
      text: widget.prediction?.homeScoreGuess.toString() ?? '',
    );
    _awayController = TextEditingController(
      text: widget.prediction?.awayScoreGuess.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final home = int.tryParse(_homeController.text);
    final away = int.tryParse(_awayController.text);

    if (home == null || away == null || home < 0 || away < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gültige Zahlen eingeben')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await widget.onSubmit(widget.match, home, away);
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _homeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(':', style: TextStyle(fontSize: 20)),
        ),
        Expanded(
          child: TextField(
            controller: _awayController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tippen'),
        ),
      ],
    );
  }
}
