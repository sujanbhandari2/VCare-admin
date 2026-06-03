import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef PathBuilder = Path Function(Size);

/// Dash painter class
class DashPainter extends CustomPainter {
  final double strokeWidth;
  final List<double> dashPattern;
  final Color color;
  final Radius radius;
  final StrokeCap strokeCap;

  DashPainter({
    this.strokeWidth = 1.0,
    this.dashPattern = const <double>[8.0],
    this.color = const Color(0xffE2E2E2),
    this.radius = Radius.zero,
    this.strokeCap = StrokeCap.round,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = strokeCap
      ..style = PaintingStyle.stroke;

    Path path = dashPath(_getRRectPath(size, radius),
        dashArray: CircularIntervalList(dashPattern));

    canvas.drawPath(path, paint);
  }

  /// Method to return the rounded rectangular path
  Path _getRRectPath(Size size, Radius radius) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            0,
            0,
            size.width,
            size.height,
          ),
          radius,
        ),
      );
  }

  /// Method to return the dashed path
  Path dashPath(
    Path source, {
    required CircularIntervalList<double> dashArray,
    DashOffset? dashOffset,
  }) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = (dashOffset ?? const DashOffset.absolute(0.0))
          ._calculate(metric.length);
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray.next;
        if (draw) {
          dest.addPath(
              metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }

    return dest;
  }

  @override
  bool shouldRepaint(DashPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.dashPattern != dashPattern;
  }
}

/// Dash offset class
class DashOffset {
  DashOffset.percentage(double percentage)
      : _rawVal = percentage.clamp(0.0, 1.0),
        _dashOffsetType = _DashOffsetType.percentage;

  const DashOffset.absolute(double start)
      : _rawVal = start,
        _dashOffsetType = _DashOffsetType.absolute;

  final double _rawVal;
  final _DashOffsetType _dashOffsetType;

  double _calculate(double length) {
    return _dashOffsetType == _DashOffsetType.absolute
        ? _rawVal
        : length * _rawVal;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashOffset &&
          runtimeType == other.runtimeType &&
          _rawVal == other._rawVal &&
          _dashOffsetType == other._dashOffsetType;

  @override
  int get hashCode => _rawVal.hashCode ^ _dashOffsetType.hashCode;
}

// Enum for Dash offset type
enum _DashOffsetType { absolute, percentage }

/// Class to handle the circular interval
class CircularIntervalList<T> {
  CircularIntervalList(this._values);

  final List<T> _values;
  int _idx = 0;

  T get next {
    if (_idx >= _values.length) {
      _idx = 0;
    }
    return _values[_idx++];
  }
}
