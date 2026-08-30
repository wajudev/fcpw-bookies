import 'dart:async';
import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../utils/date_helper.dart';

class CardPredictorWidget extends StatefulWidget {
  final Player? yellowCardPick;
  final Player? redCardPick;
  final bool isLocked;
  final DateTime? bootLockTime;
  final VoidCallback onTapYellow;
  final VoidCallback onTapRed;

  const CardPredictorWidget({
    super.key,
    this.yellowCardPick,
    this.redCardPick,
    required this.isLocked,
    this.bootLockTime,
    required this.onTapYellow,
    required this.onTapRed,
  });

  @override
  State<CardPredictorWidget> createState() => _CardPredictorWidgetState();
}

class _CardPredictorWidgetState extends State<CardPredictorWidget> {
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
            Colors.orange.shade600,
            Colors.orange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cards',
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

            // Yellow Card Pick
            _buildPickCard(
              context: context,
              title: "Most Yellows",
              currentPick: widget.yellowCardPick,
              onTap: widget.onTapYellow,
              color: Colors.yellow,
              icon: '🟨',
            ),

            const SizedBox(height: 12),

            // Red Card Pick
            _buildPickCard(
              context: context,
              title: "Most Reds",
              currentPick: widget.redCardPick,
              onTap: widget.onTapRed,
              color: Colors.red,
              icon: '🟥',
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
                    'Locked (season started)',
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
    );
  }

  Widget _buildPickCard({
    required BuildContext context,
    required String title,
    required Player? currentPick,
    required VoidCallback onTap,
    required Color color,
    required String icon,
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
                Text(
                  icon,
                  style: const TextStyle(fontSize: 16),
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
                    radius: 18,
                    child: Text(
                      currentPick.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentPick.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      icon == '🟨'
                          ? '${currentPick.yellowCards} 🟨'
                          : '${currentPick.redCards} 🟥',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
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
                      isLocked ? 'No selection' : 'Tap to select',
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
