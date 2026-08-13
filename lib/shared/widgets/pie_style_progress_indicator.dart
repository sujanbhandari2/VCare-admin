import 'package:flutter/material.dart';
import 'dart:math';

import 'package:vcare_admin/shared/utils/extension_functions.dart';

class PieStyleProgressIndicator extends StatelessWidget {
  final double progress; // Value between 0 and 1
  final double secondaryProgress; // Value between 0 and 1
  final Color? progressColor;
  final Color? secondaryProgressColor;
  final double size;
  final bool outline;
  final bool secondaryProgressAbovePrimary;
  final Color? background;

  const PieStyleProgressIndicator({
    super.key,
    required this.progress,
    this.secondaryProgress = 0.0,
    this.progressColor,
    this.secondaryProgressColor,
    this.size = 24.0,
    this.outline = false,
    this.secondaryProgressAbovePrimary = false,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size), // Adjust the size as needed
      painter: PieProgressPainter(
        progress: progress,
        secondaryProgress: secondaryProgress,
        progressColor: progressColor ?? context.theme.primaryColor,
        secondaryProgressColor:
            secondaryProgressColor ?? context.theme.colorScheme.outline,
        outline: outline,
        secondaryProgressAbovePrimary: secondaryProgressAbovePrimary,
        background: background,
      ),
    );
  }
}

class PieProgressPainter extends CustomPainter {
  final double progress;
  final double secondaryProgress;
  final Color progressColor;
  final Color secondaryProgressColor;
  final bool outline;
  final bool secondaryProgressAbovePrimary;
  final Color? background;

  PieProgressPainter({
    required this.progress,
    this.secondaryProgress = 0.0,
    this.progressColor = Colors.green,
    this.secondaryProgressColor = Colors.yellow,
    this.outline = false,
    this.secondaryProgressAbovePrimary = false,
    this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double radius = size.width / 2;

    // Background painter
    Paint bgPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Progress Painter
    Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.fill;

    // Progress Painter
    Paint secondaryProgressPaint = Paint()
      ..color = secondaryProgressAbovePrimary
          ? secondaryProgressColor.withValues(alpha: 0.15)
          : secondaryProgressColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    if (background != null) {
      Paint bgPaint = Paint()
        ..color = background!
        ..style = .fill;

      // Draw outline circle
      canvas.drawCircle(Offset(centerX, centerY), radius, bgPaint);
    }

    if (outline) {
      Paint outlinePaint = Paint()
        ..color = progressColor
        ..style = .stroke
        ..strokeWidth = 0.75;

      // Draw outline circle
      canvas.drawCircle(Offset(centerX, centerY), radius, outlinePaint);
    }

    // Draw background
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -pi / 2,
      2 * pi,
      true,
      bgPaint,
    );

    // Calculating angle for secondary progress
    double secondaryAngle = 2 * pi * secondaryProgress;

    if (!secondaryProgressAbovePrimary) {
      // Draw progress
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        -pi / 2,
        secondaryAngle,
        true,
        secondaryProgressPaint,
      );
    }

    // Calculating angle for progress
    double angle = 2 * pi * progress;

    // Draw progress
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -pi / 2,
      angle,
      true,
      progressPaint,
    );

    // If Secondary Progress Above the Primary is true
    if (secondaryProgressAbovePrimary) {
      // Draw progress
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        -pi / 2,
        secondaryAngle,
        true,
        secondaryProgressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(PieProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        secondaryProgress != oldDelegate.secondaryProgress;
  }
}
