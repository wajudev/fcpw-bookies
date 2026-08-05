import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/offline_banner.dart';
import '../leaderboard/leaderboard_screen_full.dart';
import '../matches/matches_by_week_screen.dart';
import '../profile/profile_screen.dart';
import 'home_feed_screen_modern.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _authService = AuthService();

  void _navigateToMatches() {
    setState(() => _selectedIndex = 1);
  }

  List<Widget> get _screens => [
        HomeFeedScreenModern(onNavigateToMatches: _navigateToMatches),
        const MatchesByWeekScreen(),
        const LeaderboardScreenFull(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OfflineBanner(
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
