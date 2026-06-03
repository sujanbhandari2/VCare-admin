import 'dart:math';
import 'package:flutter/material.dart';

/// Represents an item in the overlay floating button.
///
class OverlayFloatingItem {
  const OverlayFloatingItem({
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });

  /// The icon to display for this item.
  ///
  final IconData icon;

  /// Callback function when the item is tapped.
  ///
  final VoidCallback? onTap;

  /// Background color of the item button.
  /// If null, uses the theme's primary color.
  ///
  final Color? backgroundColor;

  /// Color of the icon.
  /// If null, uses the theme's on-primary color.
  ///
  final Color? iconColor;

  /// Optional tooltip text to show when hovering over the item.
  ///
  final String? tooltip;
}

/// Enum to check if styling is circular or arc or vertical
///
enum OverlayStyling { circular, arc, vertical, horizontal }

/// A customizable floating action button that displays an overlay of items in different layouts.
///
/// This widget supports three different layouts:
/// - Circular: Items are arranged in a circular pattern around the main button
/// - Arc: Items are arranged in an arc pattern with configurable start and end angles
/// - Vertical: Items are stacked vertically above the main button
///
class OverlayFloatingButton extends StatefulWidget {
  /// Creates a private base constructor for the overlay floating button.
  const OverlayFloatingButton._({
    super.key,
    required this.items,
    required this.mainButtonIcon,
    required this.mainButtonColor,
    required this.animationDuration,
    required this.curve,
    this.reverseCurve,
    this.spreadRadius = 100.0,
    this.startAngle = 180.0,
    this.endAngle = 270.0,
    this.itemSpacing = 16.0,
    this.itemSize = 48.0,
    this.itemRotateAngleBase = 2.0,
    this.hideOverlayOnItemClick = true,
    this.toLeft = true,
    required this.styling,
  }) : assert(items.length > 0, 'Items list cannot be empty'),
       assert(spreadRadius > 0, 'Spread radius must be positive'),
       assert(itemSize > 0, 'Item size must be positive'),
       assert(itemSpacing >= 0, 'Item spacing must be non-negative'),
       assert(
         startAngle >= 0 && startAngle <= 360,
         'Start angle must be between 0 and 360',
       ),
       assert(
         endAngle >= 0 && endAngle <= 360,
         'End angle must be between 0 and 360',
       ),
       assert(
         itemRotateAngleBase >= 0,
         'Item rotation angle base must be non-negative',
       );

  /// The list of items to display in the overlay.
  ///
  final List<OverlayFloatingItem> items;

  /// The icon to display on the main floating action button.
  ///
  final IconData mainButtonIcon;

  /// The color of the main floating action button.
  /// If null, defaults to the theme's accent color.
  ///
  final Color? mainButtonColor;

  /// The duration of the animation when showing/hiding the overlay.
  ///
  final Duration animationDuration;

  /// The curve to use for the showing animation.
  ///
  final Curve curve;

  /// The curve to use for the hiding animation.
  /// If null, uses the reverse of [curve].
  ///
  final Curve? reverseCurve;

  /// The size of each overlay item button.
  ///
  final double itemSize;

  /// The base angle for item rotation animation.
  ///
  final double itemRotateAngleBase;

  /// Whether to hide the overlay when an item is clicked.
  ///
  final bool hideOverlayOnItemClick;

  /// The radius of the circle/arc in which items are placed.
  ///
  final double spreadRadius;

  /// The starting angle for arc layout (in degrees).
  ///
  final double startAngle;

  /// The ending angle for arc layout (in degrees).
  ///
  final double endAngle;

  /// The spacing between items in vertical layout.
  ///
  final double itemSpacing;

  /// Is horizontal direction is left
  ///
  final bool toLeft;

  /// Styling to be rendered
  ///
  final OverlayStyling styling;

  /// Creates an overlay floating button with items arranged in a circular pattern.
  ///
  factory OverlayFloatingButton.circular({
    Key? key,
    required List<OverlayFloatingItem> items,
    IconData mainButtonIcon = Icons.add,
    Color? mainButtonColor,
    Duration animationDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOutCubic,
    Curve? reverseCurve,
    double spreadRadius = 100.0,
    double itemSize = 48.0,
    double itemRotateAngleBase = 2.0,
    bool hideOverlayOnItemClick = true,
  }) {
    return OverlayFloatingButton._(
      key: key,
      items: items,
      mainButtonIcon: mainButtonIcon,
      mainButtonColor: mainButtonColor,
      animationDuration: animationDuration,
      curve: curve,
      reverseCurve: reverseCurve,
      spreadRadius: spreadRadius,
      itemSize: itemSize,
      itemRotateAngleBase: itemRotateAngleBase,
      hideOverlayOnItemClick: hideOverlayOnItemClick,
      styling: OverlayStyling.circular,
    );
  }

  /// Creates an overlay floating button with items arranged in an arc pattern.
  ///
  factory OverlayFloatingButton.arc({
    Key? key,
    required List<OverlayFloatingItem> items,
    IconData mainButtonIcon = Icons.add,
    Color? mainButtonColor,
    Duration animationDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutBack,
    Curve? reverseCurve = Curves.easeInBack,
    double spreadRadius = 100.0,
    double startAngle = 180.0,
    double endAngle = 270.0,
    double itemSize = 48.0,
    double itemRotateAngleBase = 2.0,
    bool hideOverlayOnItemClick = true,
  }) {
    return OverlayFloatingButton._(
      key: key,
      items: items,
      mainButtonIcon: mainButtonIcon,
      mainButtonColor: mainButtonColor,
      animationDuration: animationDuration,
      curve: curve,
      reverseCurve: reverseCurve,
      spreadRadius: spreadRadius,
      startAngle: startAngle,
      endAngle: endAngle,
      itemSize: itemSize,
      itemRotateAngleBase: itemRotateAngleBase,
      hideOverlayOnItemClick: hideOverlayOnItemClick,
      styling: OverlayStyling.arc,
    );
  }

  /// Creates an overlay floating button with items arranged vertically.
  ///
  factory OverlayFloatingButton.vertical({
    Key? key,
    required List<OverlayFloatingItem> items,
    IconData mainButtonIcon = Icons.add,
    Color? mainButtonColor,
    Duration animationDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutBack,
    Curve? reverseCurve = Curves.easeInBack,
    double itemSize = 48.0,
    double itemSpacing = 16.0,
    double itemRotateAngleBase = 2.0,
    bool hideOverlayOnItemClick = true,
  }) {
    return OverlayFloatingButton._(
      key: key,
      items: items,
      mainButtonIcon: mainButtonIcon,
      mainButtonColor: mainButtonColor,
      animationDuration: animationDuration,
      curve: curve,
      reverseCurve: reverseCurve,
      itemSpacing: itemSpacing,
      itemSize: itemSize,
      itemRotateAngleBase: itemRotateAngleBase,
      hideOverlayOnItemClick: hideOverlayOnItemClick,
      styling: OverlayStyling.vertical,
    );
  }

  /// Creates an overlay floating button with items arranged vertically.
  ///
  factory OverlayFloatingButton.horizontal({
    Key? key,
    required List<OverlayFloatingItem> items,
    IconData mainButtonIcon = Icons.add,
    Color? mainButtonColor,
    Duration animationDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutBack,
    Curve? reverseCurve = Curves.easeInBack,
    double itemSize = 48.0,
    double itemSpacing = 16.0,
    double itemRotateAngleBase = 2.0,
    bool hideOverlayOnItemClick = true,
    bool toLeft = true,
  }) {
    return OverlayFloatingButton._(
      key: key,
      items: items,
      mainButtonIcon: mainButtonIcon,
      mainButtonColor: mainButtonColor,
      animationDuration: animationDuration,
      curve: curve,
      reverseCurve: reverseCurve,
      itemSpacing: itemSpacing,
      itemSize: itemSize,
      itemRotateAngleBase: itemRotateAngleBase,
      hideOverlayOnItemClick: hideOverlayOnItemClick,
      toLeft: toLeft,
      styling: OverlayStyling.horizontal,
    );
  }

  @override
  State<OverlayFloatingButton> createState() => _OverlayFloatingButtonState();
}

class _OverlayFloatingButtonState extends State<OverlayFloatingButton>
    with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  final List<OverlayEntry> _overlayEntries = [];
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedRotation(
        duration: widget.animationDuration,
        turns: _isOpen ? 0.125 : 0,
        child: FloatingActionButton(
          key: _key,
          backgroundColor: widget.mainButtonColor,
          elevation: 4,
          onPressed: _toggleOverlay,
          child: Icon(widget.mainButtonIcon),
        ),
      ),
    );
  }

  void _toggleOverlay() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        if (widget.styling == .circular) {
          _showCircularOverlay();
        } else if (widget.styling == .arc) {
          _showArcOverlay();
        } else if (widget.styling == .vertical) {
          _showVerticalOverlay();
        } else if (widget.styling == .horizontal) {
          _showHorizontalOverlay(toLeft: widget.toLeft);
        } else {
          // Unspecified Styling
        }
      } else {
        _hideOverlay();
      }
    });
  }

  /// Method to show circular overlay
  ///
  void _showCircularOverlay() {
    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    _overlayEntries.clear();
    final overlay = Overlay.of(context);

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final angle = (2 * pi / widget.items.length) * i - (pi / 2);

      final entry = OverlayEntry(
        builder: (context) => AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final progress = _expandAnimation.value;
            final currentRadius = widget.spreadRadius * progress;

            final x =
                center.dx + currentRadius * cos(angle) - widget.itemSize / 2;
            final y =
                center.dy + currentRadius * sin(angle) - widget.itemSize / 2;

            return Positioned(
              left: x,
              top: y,
              child: _buildOverlayItemUi(item, progress),
            );
          },
        ),
      );

      _overlayEntries.add(entry);
      overlay.insert(entry);
    }

    _controller.forward();
  }

  /// Method to show arc overlay
  ///
  void _showArcOverlay() {
    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    _overlayEntries.clear();
    final overlay = Overlay.of(context);

    // Convert start and end angles to radians
    final startAngleRad = widget.startAngle * (pi / 180);
    final endAngleRad = widget.endAngle * (pi / 180);
    final angleSpan = endAngleRad - startAngleRad;

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      // Calculate angle for even distribution along the arc
      final itemAngle =
          startAngleRad + (i * angleSpan / (widget.items.length - 1));

      final entry = OverlayEntry(
        builder: (context) => AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final progress = _expandAnimation.value;
            final currentRadius = widget.spreadRadius * progress;

            // Calculate position using angle
            final x =
                center.dx +
                currentRadius * cos(itemAngle) -
                widget.itemSize / 2;
            final y =
                center.dy +
                currentRadius * sin(itemAngle) -
                widget.itemSize / 2;

            return Positioned(
              left: x,
              top: y,
              child: _buildOverlayItemUi(item, progress),
            );
          },
        ),
      );

      _overlayEntries.add(entry);
      overlay.insert(entry);
    }

    _controller.forward();
  }

  /// Method to show vertical overlay
  ///
  void _showVerticalOverlay() {
    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    _overlayEntries.clear();
    final overlay = Overlay.of(context);

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final itemIndex = i + 1; // Add 1 to create space from main button

      final entry = OverlayEntry(
        builder: (context) => AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final progress = _expandAnimation.value;

            final yOffset =
                (widget.itemSize + widget.itemSpacing) * itemIndex * progress;

            return Positioned(
              left: center.dx - widget.itemSize / 2,
              top:
                  center.dy -
                  yOffset -
                  (widget.itemSize + widget.itemSpacing) / 2,
              child: _buildOverlayItemUi(item, progress),
            );
          },
        ),
      );

      _overlayEntries.add(entry);
      overlay.insert(entry);
    }

    _controller.forward();
  }

  /// Method to show horizontal overlay
  ///
  void _showHorizontalOverlay({bool toLeft = true}) {
    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    _overlayEntries.clear();
    final overlay = Overlay.of(context);

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final itemIndex = i + 1; // Add 1 to create space from main button

      final entry = OverlayEntry(
        builder: (context) => AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final progress = _expandAnimation.value;

            final xOffset =
                (widget.itemSize + widget.itemSpacing) * itemIndex * progress;

            final left = toLeft
                ? center.dx -
                      xOffset -
                      (widget.itemSize + widget.itemSpacing) / 2
                : center.dx +
                      xOffset -
                      (widget.itemSize - widget.itemSpacing) / 2;

            return Positioned(
              left: left,
              top: center.dy - widget.itemSize / 2,
              child: _buildOverlayItemUi(item, progress),
            );
          },
        ),
      );

      _overlayEntries.add(entry);
      overlay.insert(entry);
    }

    _controller.forward();
  }

  /// Method to build overlay item ui
  ///
  Widget _buildOverlayItemUi(OverlayFloatingItem item, double progress) {
    final elevation = 4 * progress;

    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: progress,
        child: Opacity(
          opacity: progress >= 0.0 && progress <= 1.0 ? progress : 1.0,
          child: Transform.rotate(
            angle: widget.itemRotateAngleBase * pi * progress,
            child: SizedBox(
              width: widget.itemSize,
              height: widget.itemSize,
              child: Tooltip(
                message: item.tooltip ?? '',
                child: FloatingActionButton(
                  backgroundColor: item.backgroundColor,
                  elevation: elevation > 0.0 ? elevation : null,
                  onPressed: () {
                    item.onTap?.call();
                    if (widget.hideOverlayOnItemClick) {
                      _toggleOverlay();
                    }
                  },
                  child: Icon(item.icon, color: item.iconColor ?? Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _hideOverlay() {
    _controller.reverse().whenComplete(() {
      for (final entry in _overlayEntries) {
        entry.remove();
      }
      _overlayEntries.clear();
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    super.dispose();
  }
}
