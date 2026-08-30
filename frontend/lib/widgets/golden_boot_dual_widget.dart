import 'dart:async';
import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';
import '../utils/date_helper.dart';

class GoldenBootDualWidget extends StatefulWidget {
  final Player? menPick;
  final Player? womenPick;
  final bool isLocked;
  final DateTime? bootLockTime;
  final VoidCallback onTapMen;
  final VoidCallback onTapWomen;

  const GoldenBootDualWidget({
    super.key,
    this.menPick,
    this.womenPick,
    required this.isLocked,
    this.bootLockTime,
    required this.onTapMen,
    required this.onTapWomen,
  });

  @override
  State<GoldenBootDualWidget> createState() => _GoldenBootDualWidgetState();
}

class _GoldenBootDualWidgetState extends State<GoldenBootDualWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (widget.bootLockTime == null || widget.isLocked) return;

    final now = DateTime.now();
    final timeUntilDeadline = widget.bootLockTime!.difference(now);

    if (timeUntilDeadline.isNegative) return;

    final updateInterval = timeUntilDeadline.inHours < 1
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);

    _timer = Timer.periodic(updateInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.kmGold,
            AppTheme.kmGold.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kmGold.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Golden Boot',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Men's Pick
                _buildPickCard(
                  context: context,
                  title: "Men's Top Scorer",
                  currentPick: widget.menPick,
                  onTap: widget.onTapMen,
                  icon: Icons.male,
                ),

                const SizedBox(height: 12),

                // Women's Pick
                _buildPickCard(
                  context: context,
                  title: "Women's Top Scorer",
                  currentPick: widget.womenPick,
                  onTap: widget.onTapWomen,
                  icon: Icons.female,
                ),

                // Deadline/Lock status
                const SizedBox(height: 12),
                if (widget.isLocked)
                  Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Selections locked (season started)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  )
                else if (widget.bootLockTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Noch ${DateHelper.getTimeRemaining(
                            widget.bootLockTime!,
                            showSeconds: widget.bootLockTime!.difference(DateTime.now()).inHours < 1,
                          )}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickCard({
    required BuildContext context,
    required String title,
    required Player? currentPick,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final isLocked = widget.isLocked;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: currentPick == null
              ? Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const Spacer(),
                if (!isLocked)
                  Icon(
                    Icons.edit,
                    color: Colors.white.withOpacity(0.6),
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Player info or placeholder
            if (currentPick != null)
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Text(
                      currentPick.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kmGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentPick.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (currentPick.matchesPlayed != null &&
                            currentPick.matchesPlayed! > 0)
                          Text(
                            '${currentPick.matchesPlayed} matches',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${currentPick.goals} ⚽',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kmGold,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    isLocked ? Icons.lock : Icons.touch_app,
                    color: Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isLocked ? 'No selection made' : 'Tap to select',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
