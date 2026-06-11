import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/app_colors.dart';

class TapHereAnimation extends StatefulWidget {
  const TapHereAnimation({
    super.key,
    this.rippleColor = AppColors.lightGreen,
    this.handColor = AppColors.green,
    this.handSize = 24.0,
    this.size = 48.0,
    this.background,
    this.onTap,
  });

  final Color rippleColor;
  final Color handColor;
  final double handSize;
  final double size;
  final Color? background;
  final VoidCallback? onTap;

  @override
  State<TapHereAnimation> createState() => _TapHereAnimationState();
}

class _TapHereAnimationState extends State<TapHereAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  // Ripple should show during hand compression phase i.e. on scale down
  bool get isRippleVisible => _controller.value < 1;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: false);

    // For Hand Scale Animation
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // For Ripple Effect Animation
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: .circle,
          color: widget.background ?? Colors.transparent,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: .center,
                children: [
                  if (isRippleVisible) _buildRipple(),
                  Align(alignment: .bottomCenter, child: _buildHand()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Helper function to build ripple effect ui
  ///
  Widget _buildRipple() {
    return Container(
      width: widget.size * _rippleAnimation.value,
      height: widget.size * _rippleAnimation.value,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.handColor.withValues(alpha: 1 - _rippleAnimation.value),
      ),
    );
  }

  /// Helper function to build hand ui
  ///
  Widget _buildHand() {
    return Transform.scale(
      scale: _scaleAnimation.value,
      child: Icon(
        Icons.pan_tool_alt_outlined,
        size: widget.handSize,
        color: widget.handColor,
      ),
    );
  }

  /// Dispose Animation Controller
  ///
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
