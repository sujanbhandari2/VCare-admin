import 'package:flutter/material.dart';

class GlassMorphismCard extends StatelessWidget {
  const GlassMorphismCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.sigmaX = 12.0,
    this.sigmaY = 12.0,
    this.margin = .zero,
    this.padding = const .all(16.0),
    this.borderRadius,
    this.border,
    this.gradient,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double sigmaX;
  final double sigmaY;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? .circular(20),
        border:
            border ??
            Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: .blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          decoration: BoxDecoration(
            gradient:
                gradient ??
                LinearGradient(
                  begin: .topLeft,
                  end: .bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
