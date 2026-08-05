import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';

class MatchCalendarDialog extends StatefulWidget {
  final List<Match> allMatches;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const MatchCalendarDialog({
    super.key,
    required this.allMatches,
    this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<MatchCalendarDialog> createState() => _MatchCalendarDialogState();
}

class _MatchCalendarDialogState extends State<MatchCalendarDialog> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate ?? DateTime.now();
    _selectedDay = widget.selectedDate;
  }

  // Get all matches for a specific day
  List<Match> _getMatchesForDay(DateTime day) {
    return widget.allMatches.where((match) {
      final matchDate = DateTime(
        match.kickoffTime.year,
        match.kickoffTime.month,
        match.kickoffTime.day,
      );
      final targetDate = DateTime(day.year, day.month, day.day);
      return matchDate == targetDate;
    }).toList();
  }

  // Get squad color for a match
  Color _getSquadColor(String squad) {
    switch (squad) {
      case 'km':
        return AppTheme.kmGold;
      case 'reserve':
        return AppTheme.reserveBlue;
      case 'women':
        return AppTheme.womenPink;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.calendar_month, color: AppTheme.primaryPurple),
                const SizedBox(width: 12),
                const Text(
                  'Match Calendar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('KM', AppTheme.kmGold),
                const SizedBox(width: 16),
                _buildLegendItem('Women', AppTheme.womenPink),
                const SizedBox(width: 16),
                _buildLegendItem('Reserve', AppTheme.reserveBlue),
              ],
            ),
            const SizedBox(height: 16),

            // Calendar
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                widget.onDateSelected(selectedDay);
                Navigator.of(context).pop();
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primaryPurple,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final matches = _getMatchesForDay(date);
                  if (matches.isEmpty) return null;

                  // Show colored dots for each squad that has a match
                  final squads = matches.map((m) => m.squad).toSet().toList();

                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: squads.take(3).map((squad) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _getSquadColor(squad),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
