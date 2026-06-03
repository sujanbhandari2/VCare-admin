import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Configuration for the draggable sticky widget
///
class DraggableStickyConfig {
  const DraggableStickyConfig({
    required this.margin,
    required this.snapDuration,
    required this.snapCurve,
    required this.velocityThreshold,
    required this.enableHaptics,
  });

  final double margin;
  final Duration snapDuration;
  final Curve snapCurve;
  final double velocityThreshold;
  final bool enableHaptics;

  static const defaultConfig = DraggableStickyConfig(
    margin: 12,
    snapDuration: Duration(milliseconds: 300),
    snapCurve: Curves.easeInOutCubic,
    velocityThreshold: 500,
    enableHaptics: true,
  );

  DraggableStickyConfig copyWith({
    double? margin,
    Duration? snapDuration,
    Curve? snapCurve,
    double? velocityThreshold,
    bool? enableHaptics,
  }) {
    return DraggableStickyConfig(
      margin: margin ?? this.margin,
      snapDuration: snapDuration ?? this.snapDuration,
      snapCurve: snapCurve ?? this.snapCurve,
      velocityThreshold: velocityThreshold ?? this.velocityThreshold,
      enableHaptics: enableHaptics ?? this.enableHaptics,
    );
  }
}

/// Optimized draggable sticky widget that adapts to any child size
///
/// Features:
/// - Measures child widget naturally (no forced sizing)
/// - Smooth snapping to edges with customizable duration
/// - Boundary constraints respecting safe areas (notches, status bars)
/// - Velocity-based throw animation
/// - Customizable margins
/// - Haptic feedback on snap
/// - Prevents accidental drags with threshold
class DraggableSticky extends StatefulWidget {
  const DraggableSticky({
    required this.child,
    this.config = DraggableStickyConfig.defaultConfig,
    this.onPositionChanged,
    super.key,
  });

  /// Widget to display (can be any size, shape, or complexity)
  final Widget child;

  /// Configuration for the draggable sticky icon
  final DraggableStickyConfig config;

  /// Callback when position changes (useful for persistence)
  final ValueChanged<Offset>? onPositionChanged;

  @override
  State<DraggableSticky> createState() => _DraggableStickyState();
}

class _DraggableStickyState extends State<DraggableSticky> {
  late final ValueNotifier<Offset?> _position = ValueNotifier<Offset?>(null);
  late final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  late final ValueNotifier<Size?> _childSize = ValueNotifier<Size?>(null);
  late final Listenable _stateListenable = Listenable.merge([
    _position,
    _isDragging,
    _childSize,
  ]);

  @override
  void dispose() {
    _position.dispose();
    _isDragging.dispose();
    _childSize.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _stateListenable,
      builder: (context, _) {
        final mediaQuery = MediaQuery.of(context);
        final screenSize = mediaQuery.size;
        final padding = mediaQuery.padding;
        final viewInsets = mediaQuery.viewInsets;

        // Get child size for boundary calculations
        final widgetWidth = _childSize.value?.width ?? 0;
        final widgetHeight = _childSize.value?.height ?? 0;

        // Calculate safe area bounds
        final minY = padding.top + widget.config.margin;
        final maxY =
            (screenSize.height -
                    viewInsets.bottom -
                    widgetHeight -
                    widget.config.margin)
                .clamp(minY, double.infinity);
        final minX = widget.config.margin;
        final maxX = (screenSize.width - widgetWidth - widget.config.margin)
            .clamp(minX, double.infinity);

        // Initial position: right side, vertically centered
        final currentPosition =
            _position.value ??
            Offset(
              maxX,
              ((screenSize.height - widgetHeight) / 2).clamp(minY, maxY),
            );

        // Clamp position to bounds
        final clampedPosition = Offset(
          currentPosition.dx.clamp(minX, maxX),
          currentPosition.dy.clamp(minY, maxY),
        );

        // Calculate whether to snap to left or right
        final shouldSnapLeft =
            (clampedPosition.dx + widgetWidth / 2) < screenSize.width / 2;

        return AnimatedPositioned(
          duration: _isDragging.value
              ? Duration.zero
              : widget.config.snapDuration,
          curve: widget.config.snapCurve,
          left: clampedPosition.dx,
          top: clampedPosition.dy,
          child: GestureDetector(
            onPanStart: (details) {
              _isDragging.value = true;
            },
            onPanUpdate: (details) {
              final newPosition = Offset(
                clampedPosition.dx + details.delta.dx,
                clampedPosition.dy + details.delta.dy,
              );

              _position.value = Offset(
                newPosition.dx.clamp(minX, maxX),
                newPosition.dy.clamp(minY, maxY),
              );
            },
            onPanEnd: (details) {
              // Calculate final snap position with velocity consideration
              var finalX = shouldSnapLeft ? minX : maxX;
              var finalY = clampedPosition.dy;

              // Apply velocity-based throw if threshold is exceeded
              if (details.velocity.pixelsPerSecond.dx.abs() >
                  widget.config.velocityThreshold) {
                final direction = details.velocity.pixelsPerSecond.dx > 0
                    ? 1
                    : -1;
                finalX = direction > 0 ? maxX : minX;
              }

              final finalPosition = Offset(finalX, finalY);
              _isDragging.value = false;
              _position.value = finalPosition;

              // Callback for position changes (e.g., save to preferences)
              widget.onPositionChanged?.call(finalPosition);

              // Haptic feedback on snap
              if (widget.config.enableHaptics) {
                HapticFeedback.selectionClick();
              }
            },
            child: _ChildSizeMeasurer(
              onSizeChanged: (size) {
                if (!mounted || _childSize.value == size) return;
                _childSize.value = size;
              },
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Helper widget to measure child size
class _ChildSizeMeasurer extends StatelessWidget {
  const _ChildSizeMeasurer({required this.child, required this.onSizeChanged});

  final Widget child;
  final ValueChanged<Size> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return MeasureSize(onChange: onSizeChanged, child: child);
  }
}

/// Widget that measures its child size
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, required Widget child})
    : super(child: child);

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class MeasureSizeRenderObject extends RenderProxyBox {
  MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? oldSize;

  @override
  void performLayout() {
    super.performLayout();

    final size = child?.size;
    if (size != null && size != oldSize) {
      oldSize = size;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(size);
      });
    }
  }
}
