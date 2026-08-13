import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

class VcareEmptyStateCard extends StatelessWidget {
  const VcareEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
    this.iconBackgroundColor,
    this.borderRadius = 16,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: vcare.border,
          style: BorderStyle.solid,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: CustomPaint(
        painter: VcareDashedBorderPainter(
          color: vcare.border,
          radius: borderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: VcareEmptyStateCardContent(
            icon: icon,
            title: title,
            description: description,
            iconColor: iconColor,
            iconBackgroundColor: iconBackgroundColor,
          ),
        ),
      ),
    );
  }
}

class VcareEmptyStateCardContent extends StatelessWidget {
  const VcareEmptyStateCardContent({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final ic = iconColor ?? vcare.primary;
    final icBg = iconBackgroundColor ?? vcare.primary.withValues(alpha: 0.1);

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: icBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 20, color: ic),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: vcare.mutedForeground,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class VcareDashedBorderPainter extends CustomPainter {
  VcareDashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant VcareDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
