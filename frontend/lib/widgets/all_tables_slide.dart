import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'league_table_widget.dart';

class AllTablesSlide extends StatelessWidget {
  final List<TeamStanding> kmStandings;
  final List<TeamStanding> reserveStandings;
  final List<TeamStanding> womenStandings;
  final VoidCallback? onTap;

  const AllTablesSlide({
    super.key,
    required this.kmStandings,
    required this.reserveStandings,
    required this.womenStandings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Limit to top 6 teams to fit in carousel height
    final kmTop6 = kmStandings.take(6).toList();
    final reserveTop6 = reserveStandings.take(6).toList();
    final womenTop6 = womenStandings.take(6).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
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
            // Header
            Row(
              children: [
                const Icon(Icons.table_chart, color: AppTheme.primaryPurple, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'League Standings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  const Icon(Icons.arrow_forward, color: AppTheme.textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 16),

            // Tables (top 6 only)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        Expanded(
                          child: LeagueTableWidget(
                            squadName: 'KM',
                            standings: kmTop6,
                            highlightTeam: 'DSG Paulaner Wieden',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LeagueTableWidget(
                            squadName: 'Women',
                            standings: womenTop6,
                            highlightTeam: 'Paulaner Wieden',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LeagueTableWidget(
                            squadName: 'Reserve',
                            standings: reserveTop6,
                            highlightTeam: 'DSG Paulaner Wieden',
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LeagueTableWidget(
                          squadName: 'KM',
                          standings: kmTop6,
                          highlightTeam: 'DSG Paulaner Wieden',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LeagueTableWidget(
                          squadName: 'Women',
                          standings: womenTop6,
                          highlightTeam: 'Paulaner Wieden',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LeagueTableWidget(
                          squadName: 'Reserve',
                          standings: reserveTop6,
                          highlightTeam: 'DSG Paulaner Wieden',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
