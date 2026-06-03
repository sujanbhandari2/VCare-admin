import 'package:flutter/material.dart';

/// Type Def for Custom Expansion Widget Builder
typedef ExpansionWidgetBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  bool expanded,
  VoidCallback onToggle,
);

/// Custom Expansion Builder
class CustomExpansionBuilder extends StatefulWidget {
  final ExpansionWidgetBuilder builder;
  final bool initiallyExpanded;

  const CustomExpansionBuilder({
    super.key,
    required this.builder,
    this.initiallyExpanded = false,
  });

  @override
  State<CustomExpansionBuilder> createState() => _CustomExpansionBuilderState();
}

class _CustomExpansionBuilderState extends State<CustomExpansionBuilder>
    with SingleTickerProviderStateMixin {
  /// Animation controller for smooth expansion and collapsed animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  /// variable to track the expansion status
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initializing animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // initializing animation
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // If Initially Expanded
    _handleInitialExpansion();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Method to handle initial expansion
  void _handleInitialExpansion() {
    if (widget.initiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {
          _isExpanded = widget.initiallyExpanded;
          if (_isExpanded) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        });
      });
    }
  }

  /// Method to toggle expansion
  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder.call(
      context,
      _animation,
      _isExpanded,
      _toggleExpansion,
    );
  }
}
