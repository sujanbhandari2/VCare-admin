import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Horizontal carousel with dot indicators — parity with vcareapp [Carousel].
class ClientDetailCarousel extends StatefulWidget {
  const ClientDetailCarousel({
    super.key,
    required this.height,
    required this.itemWidth,
    required this.itemCount,
    required this.itemBuilder,
    this.gap = 12,
  });

  final double height;
  final double itemWidth;
  final int itemCount;
  final double gap;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<ClientDetailCarousel> createState() => _ClientDetailCarouselState();
}

class _ClientDetailCarouselState extends State<ClientDetailCarousel> {
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
    final stride = widget.itemWidth + widget.gap;
    final idx = (_controller.offset / stride).round().clamp(
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

    // Card content grows with the user's font scale, so the fixed track height
    // has to grow with it too.
    final height = MediaQuery.textScalerOf(context).scale(widget.height);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.itemCount,
            separatorBuilder: (_, _) => SizedBox(width: widget.gap),
            itemBuilder: (context, index) => SizedBox(
              width: widget.itemWidth,
              child: widget.itemBuilder(context, index),
            ),
          ),
        ),
        if (widget.itemCount > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.itemCount, (i) {
              final active = i == _activeIndex;
              return GestureDetector(
                onTap: () => _goToIndex(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? context.vcare.primary
                        : context.vcare.mutedForeground.withValues(alpha: 0.3),
                    borderRadius: VCareRadius.fullAll,
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
