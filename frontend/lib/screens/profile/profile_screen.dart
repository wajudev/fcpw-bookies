import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../services/auth_service.dart';
import '../../services/matches_service.dart';
import '../../services/players_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _matchesService = MatchesService();
  final _profileService = ProfileService();
  final _playersService = PlayersService();

  UserProfile? _profile;
  Player? _goldenBootPlayerMen;
  Player? _goldenBootPlayerWomen;
  Player? _yellowCardPlayer;
  Player? _redCardPlayer;
  List<SeasonHistory> _history = [];
  String? _seasonId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final seasonId = await _matchesService.getCurrentSeasonId();
    if (seasonId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await _profileService.getUserProfile(userId, seasonId);
    final history = await _profileService.getSeasonHistory(userId);

    // Fetch all picks
    Player? goldenBootPlayerMen;
    if (profile?.goldenBootPickMenId != null) {
      goldenBootPlayerMen = await _playersService.getGoldenBootPlayer(profile!.goldenBootPickMenId!);
    }

    Player? goldenBootPlayerWomen;
    if (profile?.goldenBootPickWomenId != null) {
      goldenBootPlayerWomen = await _playersService.getGoldenBootPlayer(profile!.goldenBootPickWomenId!);
    }

    Player? yellowCardPlayer;
    if (profile?.yellowCardPickId != null) {
      yellowCardPlayer = await _playersService.getGoldenBootPlayer(profile!.yellowCardPickId!);
    }

    Player? redCardPlayer;
    if (profile?.redCardPickId != null) {
      redCardPlayer = await _playersService.getGoldenBootPlayer(profile!.redCardPickId!);
    }

    if (!mounted) return;

    setState(() {
      _seasonId = seasonId;
      _profile = profile;
      _goldenBootPlayerMen = goldenBootPlayerMen;
      _goldenBootPlayerWomen = goldenBootPlayerWomen;
      _yellowCardPlayer = yellowCardPlayer;
      _redCardPlayer = redCardPlayer;
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                // Header shimmer
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                // Stats shimmer
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Golden boot shimmer
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
              ),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header Card
                    _buildHeaderCard(),
                    const SizedBox(height: 20),

                    // Stats Grid
                    _buildStatsGrid(),
                    const SizedBox(height: 20),

                    // Section: Season Picks
                    const Text(
                      'My Season Picks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Golden Boot Picks
                    if (_goldenBootPlayerMen != null || _goldenBootPlayerWomen != null) ...[
                      _buildGoldenBootCard(),
                      const SizedBox(height: 12),
                    ],

                    // Card Picks
                    if (_yellowCardPlayer != null || _redCardPlayer != null) ...[
                      _buildCardPicksCard(),
                      const SizedBox(height: 20),
                    ],

                    // Season History
                    if (_history.isNotEmpty) ...[
                    const Text(
                      'Season History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                      const SizedBox(height: 12),
                      ..._history.map((season) => _buildHistoryCard(season)),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple,
            AppTheme.primaryPurple.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              (_profile?.username ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profile?.username ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Rank #${_profile?.currentRank ?? 0}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return Column(
            children: [
              _buildStatCard(
                icon: Icons.star,
                label: 'Total Points',
                value: '${_profile?.totalPoints ?? 0}',
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.check_circle,
                label: 'Exact Hits',
                value: '${_profile?.exactHits ?? 0}',
                color: AppTheme.kmGold,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                label: 'Total Points',
                value: '${_profile?.totalPoints ?? 0}',
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle,
                label: 'Exact Hits',
                value: '${_profile?.exactHits ?? 0}',
                color: AppTheme.kmGold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoldenBootCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppTheme.kmGold, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Golden Boot Picks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Men's Pick
          if (_goldenBootPlayerMen != null) ...[
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MEN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: AppTheme.kmGold.withOpacity(0.1),
                  radius: 20,
                  child: Text(
                    _goldenBootPlayerMen!.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.kmGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _goldenBootPlayerMen!.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_goldenBootPlayerMen!.goals} goals',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_profile?.goldenBootHitMen == true)
                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Women's Pick
          if (_goldenBootPlayerWomen != null) ...[
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.womenPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'WOMEN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.womenPink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: AppTheme.kmGold.withOpacity(0.1),
                  radius: 20,
                  child: Text(
                    _goldenBootPlayerWomen!.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.kmGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _goldenBootPlayerWomen!.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_goldenBootPlayerWomen!.goals} goals',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_profile?.goldenBootHitWomen == true)
                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardPicksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Card Predictions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Yellow Card Pick
          if (_yellowCardPlayer != null) ...[
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'YELLOW',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  radius: 20,
                  child: Text(
                    _yellowCardPlayer!.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _yellowCardPlayer!.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_yellowCardPlayer!.yellowCards} 🟨',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_profile?.yellowCardHit == true)
                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Red Card Pick
          if (_redCardPlayer != null) ...[
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'RED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.liveRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: AppTheme.liveRed.withOpacity(0.1),
                  radius: 20,
                  child: Text(
                    _redCardPlayer!.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.liveRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _redCardPlayer!.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_redCardPlayer!.redCards} 🟥',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_profile?.redCardHit == true)
                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard(SeasonHistory season) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      season.seasonName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (season.goldenBootHit) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.emoji_events, color: AppTheme.kmGold, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${season.totalPoints} pts · ${season.exactHits} exact hits${season.finalRank != null ? ' · Rank #${season.finalRank}' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
