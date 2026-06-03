import 'package:flutter/material.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';

class HomeHorizontalCarousel extends StatefulWidget {
  const HomeHorizontalCarousel({
    super.key,
    required this.itemCount,
    required this.itemWidth,
    required this.itemBuilder,
    this.gap = 12,
  });

  final int itemCount;
  final double itemWidth;
  final double gap;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<HomeHorizontalCarousel> createState() => _HomeHorizontalCarouselState();
}

class _HomeHorizontalCarouselState extends State<HomeHorizontalCarousel> {
  final _controller = ScrollController();
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients || widget.itemCount == 0) return;
    final itemWidth = widget.itemWidth + widget.gap;
    final idx = (_controller.offset / itemWidth).round().clamp(
      0,
      widget.itemCount - 1,
    );
    if (idx != _activeIndex) {
      setState(() => _activeIndex = idx);
    }
  }

  void _goToIndex(int index) {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      index * (widget.itemWidth + widget.gap),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: _carouselHeight(context),
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: widget.itemCount,
            separatorBuilder: (context, index) => SizedBox(width: widget.gap),
            itemBuilder: (context, index) {
              return SizedBox(
                width: widget.itemWidth,
                child: widget.itemBuilder(context, index),
              );
            },
          ),
        ),
        if (widget.itemCount > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.itemCount, (i) {
              final active = i == _activeIndex;
              return GestureDetector(
                onTap: () => _goToIndex(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? VCareColors.primary
                        : VCareColors.mutedForeground.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  double _carouselHeight(BuildContext context) {
    // Let parent constrain; default heights per card type are set by children.
    return 120;
  }
}

/// Wraps [HomeHorizontalCarousel] with intrinsic height from child.
class HomeHorizontalCarouselSized extends StatelessWidget {
  const HomeHorizontalCarouselSized({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemWidth,
    required this.itemBuilder,
    this.gap = 12,
  });

  final double height;
  final int itemCount;
  final double itemWidth;
  final double gap;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return _HomeHorizontalCarouselWithHeight(
      height: height,
      itemCount: itemCount,
      itemWidth: itemWidth,
      gap: gap,
      itemBuilder: itemBuilder,
    );
  }
}

class _HomeHorizontalCarouselWithHeight extends StatefulWidget {
  const _HomeHorizontalCarouselWithHeight({
    required this.height,
    required this.itemCount,
    required this.itemWidth,
    required this.gap,
    required this.itemBuilder,
  });

  final double height;
  final int itemCount;
  final double itemWidth;
  final double gap;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<_HomeHorizontalCarouselWithHeight> createState() =>
      _HomeHorizontalCarouselWithHeightState();
}

class _HomeHorizontalCarouselWithHeightState
    extends State<_HomeHorizontalCarouselWithHeight> {
  final _controller = ScrollController();
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients || widget.itemCount == 0) return;
    final itemWidth = widget.itemWidth + widget.gap;
    final idx = (_controller.offset / itemWidth).round().clamp(
      0,
      widget.itemCount - 1,
    );
    if (idx != _activeIndex) {
      setState(() => _activeIndex = idx);
    }
  }

  void _goToIndex(int index) {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      index * (widget.itemWidth + widget.gap),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayCount = widget.itemCount > 6 ? 6 : widget.itemCount;

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: displayCount,
            separatorBuilder: (context, index) => SizedBox(width: widget.gap),
            itemBuilder: (context, index) => SizedBox(
              width: widget.itemWidth,
              child: widget.itemBuilder(context, index),
            ),
          ),
        ),
        if (displayCount > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(displayCount, (i) {
              final active = i == _activeIndex;
              return GestureDetector(
                onTap: () => _goToIndex(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? VCareColors.primary
                        : VCareColors.mutedForeground.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
