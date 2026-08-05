import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/matches_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/empty_state.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _authService = AuthService();
  final _leaderboardService = LeaderboardService();
  final _matchesService = MatchesService();

  List<LeaderboardEntry> _entries = [];
  String? _seasonId;
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = _authService.currentUser?.id;
    final seasonId = await _matchesService.getCurrentSeasonId();

    if (seasonId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final entries = await _leaderboardService.getLeaderboard(seasonId, limit: 100);

    if (!mounted) return;

    setState(() {
      _seasonId = seasonId;
      _currentUserId = userId;
      _entries = entries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                const LoadingShimmer(width: 150, height: 28),
                const SizedBox(height: 8),
                const LoadingShimmer(width: 100, height: 14),
                const SizedBox(height: 24),
                ...List.generate(8, (_) => const LeaderboardRowShimmer()),
              ],
              ),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: _entries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _entries.length + 1, // +1 for header
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildHeader();
                        }
                        return _buildLeaderboardRow(_entries[index - 1]);
                      },
                    ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Season Rankings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_entries.length} players',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        // Top 3 Podium
        if (_entries.length >= 3) _buildPodium(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPodium() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.primaryGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (_entries.length >= 2)
            Expanded(child: _buildPodiumPlace(_entries[1], 2, 100)),
          const SizedBox(width: 8),
          // 1st place (tallest)
          Expanded(child: _buildPodiumPlace(_entries[0], 1, 130)),
          const SizedBox(width: 8),
          // 3rd place
          if (_entries.length >= 3)
            Expanded(child: _buildPodiumPlace(_entries[2], 3, 80)),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(LeaderboardEntry entry, int place, double height) {
    final colors = [
      AppTheme.kmGold, // 1st
      Colors.grey.shade400, // 2nd
      Colors.brown.shade300, // 3rd
    ];
    final color = colors[place - 1];

    return Column(
      children: [
        // Crown for 1st place
        if (place == 1)
          const Icon(Icons.emoji_events, color: AppTheme.kmGold, size: 32),
        if (place == 1) const SizedBox(height: 8),
        // Avatar
        CircleAvatar(
          radius: place == 1 ? 32 : 28,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            entry.username[0].toUpperCase(),
            style: TextStyle(
              fontSize: place == 1 ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Username
        Text(
          entry.username,
          style: TextStyle(
            fontSize: 12,
            fontWeight: place == 1 ? FontWeight.bold : FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Points
        Text(
          '${entry.totalPoints} pts',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        // Podium box
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$place',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry) {
    final isCurrentUser = entry.userId == _currentUserId;
    final isTopThree = entry.rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryPurple.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? AppTheme.primaryPurple
              : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: isTopThree ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: isTopThree ? AppTheme.primaryPurple : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
            child: Text(
              entry.username[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.exactHits} exact hits',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${entry.totalPoints}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const Text(
                  'pts',
                  style: TextStyle(
                    fontSize: 10,
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

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.leaderboard,
      title: 'No rankings yet',
      message: 'Make predictions to start earning points!',
    );
  }
}
