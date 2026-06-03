import 'package:flutter/material.dart';

class GradientMask extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientMask({
    super.key,
    required this.child,
    this.colors,
    this.begin = .topLeft,
    this.end = .bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShaderMask(
      blendMode: .srcATop,
      shaderCallback: (bounds) => LinearGradient(
        begin: begin,
        end: end,
        colors:
            colors ?? [theme.colorScheme.primary, theme.colorScheme.secondary],
        tileMode: .mirror,
      ).createShader(bounds),
      child: child,
    );
  }
}
