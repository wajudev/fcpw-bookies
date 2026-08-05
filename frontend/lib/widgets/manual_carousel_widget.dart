import 'package:flutter/material.dart';

class ManualCarouselWidget extends StatefulWidget {
  final List<Widget> children;
  final Duration animationDuration;
  final bool useClick; // true = click to rotate, false = hover to rotate

  const ManualCarouselWidget({
    super.key,
    required this.children,
    this.animationDuration = const Duration(milliseconds: 400),
    this.useClick = false,
  }) : assert(children.length == 3, 'Must have exactly 3 children');

  @override
  State<ManualCarouselWidget> createState() => _ManualCarouselWidgetState();
}

class _ManualCarouselWidgetState extends State<ManualCarouselWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _centerIndex = 1; // Start with middle widget in center
  int _targetIndex = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rotateToIndex(int targetIndex) {
    if (targetIndex == _centerIndex) return;

    setState(() {
      _targetIndex = targetIndex;
    });

    _controller.forward(from: 0.0).then((_) {
      setState(() {
        _centerIndex = targetIndex;
      });
    });
  }

  // Get widget at position relative to center
  Widget _getWidgetAtPosition(int offset) {
    final index = (_centerIndex + offset) % 3;
    return widget.children[index];
  }

  Widget _buildWidgetWithInteraction(Widget child, int position) {
    // Position: -1 = left, 0 = center, 1 = right
    final actualIndex = (_centerIndex + position) % 3;

    Widget wrappedChild = child;

    if (widget.useClick) {
      // Click to rotate
      wrappedChild = GestureDetector(
        onTap: () => _rotateToIndex(actualIndex),
        child: MouseRegion(
          cursor: position != 0 ? SystemMouseCursors.click : MouseCursor.defer,
          child: child,
        ),
      );
    } else {
      // Hover to rotate
      wrappedChild = MouseRegion(
        onEnter: (_) => _rotateToIndex(actualIndex),
        cursor: position != 0 ? SystemMouseCursors.click : MouseCursor.defer,
        child: child,
      );
    }

    return wrappedChild;
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
              child: Transform.scale(
                scale: 0.90 + (progress * 0.10), // Scale up if becoming center
                child: Opacity(
                  opacity: 0.5 + (progress * 0.5),
                  child: _buildWidgetWithInteraction(
                    _getWidgetAtPosition(-1),
                    -1,
                  ),
                ),
              ),
            ),

            // Center widget (emphasized)
            Expanded(
              child: Transform.scale(
                scale: 1.0,
                child: _buildWidgetWithInteraction(
                  _getWidgetAtPosition(0),
                  0,
                ),
              ),
            ),

            // Right widget
            Expanded(
              child: Transform.scale(
                scale: 0.90 + (progress * 0.10),
                child: Opacity(
                  opacity: 0.5 + (progress * 0.5),
                  child: _buildWidgetWithInteraction(
                    _getWidgetAtPosition(1),
                    1,
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
