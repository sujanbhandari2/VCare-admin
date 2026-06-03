import 'package:flutter/material.dart';

/// Dashed rounded border — parity with vcareapp dashed attachment tiles.
class RequestNewDashedBorder extends StatelessWidget {
  const RequestNewDashedBorder({
    super.key,
    required this.color,
    required this.radius,
    required this.child,
  });

  final Color color;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RequestNewDashedBorderPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class RequestNewDashedBorderPainter extends CustomPainter {
  const RequestNewDashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant RequestNewDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
