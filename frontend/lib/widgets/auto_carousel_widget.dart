import 'dart:async';
import 'package:flutter/material.dart';

class AutoCarouselWidget extends StatefulWidget {
  final List<Widget> slides;
  final Duration interval;
  final Duration animationDuration;
  final bool showIndicators;

  const AutoCarouselWidget({
    super.key,
    required this.slides,
    this.interval = const Duration(seconds: 6),
    this.animationDuration = const Duration(milliseconds: 600),
    this.showIndicators = true,
  });

  @override
  State<AutoCarouselWidget> createState() => _AutoCarouselWidgetState();
}

class _AutoCarouselWidgetState extends State<AutoCarouselWidget> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoRotate();
  }

  void _startAutoRotate() {
    _timer = Timer.periodic(widget.interval, (_) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: widget.animationDuration,
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.slides.length,
            itemBuilder: (context, index) {
              return widget.slides[index];
            },
          ),
        ),

        // Page indicators (clickable)
        if (widget.showIndicators && widget.slides.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.slides.length,
              (index) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
