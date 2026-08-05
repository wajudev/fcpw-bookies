import 'dart:async';
import 'package:flutter/material.dart';

class TripleCarouselWidget extends StatefulWidget {
  final List<Widget> children;
  final Duration interval;
  final Duration animationDuration;

  const TripleCarouselWidget({
    super.key,
    required this.children,
    this.interval = const Duration(seconds: 6),
    this.animationDuration = const Duration(milliseconds: 800),
  }) : assert(children.length == 3, 'Must have exactly 3 children');

  @override
  State<TripleCarouselWidget> createState() => _TripleCarouselWidgetState();
}

class _TripleCarouselWidgetState extends State<TripleCarouselWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  int _centerIndex = 1; // Start with middle widget in center

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _startAutoRotate();
  }

  void _startAutoRotate() {
    _timer = Timer.periodic(widget.interval, (_) {
      _rotateLeft();
    });
  }

  void _rotateLeft() {
    _controller.forward(from: 0.0).then((_) {
      setState(() {
        // Rotate indices: left → center, center → right, right → left
        _centerIndex = (_centerIndex + 1) % 3;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Get widget at position relative to center
  Widget _getWidgetAtPosition(int offset) {
    final index = (_centerIndex + offset) % 3;
    return widget.children[index];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left widget
            Expanded(
              child: Transform.translate(
                offset: Offset(-100 * progress, 0),
                child: Opacity(
                  opacity: 1.0 - (progress * 0.5),
                  child: Transform.scale(
                    scale: 0.95 - (progress * 0.05),
                    child: _getWidgetAtPosition(-1),
                  ),
                ),
              ),
            ),

            // Center widget (emphasized)
            Expanded(
              child: Transform.translate(
                offset: Offset(-100 * progress, 0),
                child: Transform.scale(
                  scale: 1.0,
                  child: _getWidgetAtPosition(0),
                ),
              ),
            ),

            // Right widget
            Expanded(
              child: Transform.translate(
                offset: Offset(-100 * progress, 0),
                child: Opacity(
                  opacity: 1.0 - (progress * 0.5),
                  child: Transform.scale(
                    scale: 0.95 - (progress * 0.05),
                    child: _getWidgetAtPosition(1),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
