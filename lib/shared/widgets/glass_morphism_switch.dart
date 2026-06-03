import 'package:flutter/material.dart';

class GlassMorphismSwitch extends StatefulWidget {
  const GlassMorphismSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 60.0,
    this.duration = const Duration(milliseconds: 200),
    this.blurIntensity = 5.0,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final Duration duration;
  final double blurIntensity;

  @override
  State<GlassMorphismSwitch> createState() => _GlassMorphismSwitchState();
}

class _GlassMorphismSwitchState extends State<GlassMorphismSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (widget.value) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(GlassMorphismSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width / 2;

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: .circular(height),
              border: .all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: .circular(height),
              child: BackdropFilter(
                filter: .blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: .topLeft,
                      end: .bottomRight,
                      colors: widget.value
                          ? [
                              Colors.green.withValues(alpha: 0.3),
                              Colors.green.withValues(alpha: 0.1),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: widget.duration,
                        curve: Curves.easeInOut,
                        left: widget.value ? widget.width - height + 2 : 2,
                        top: 1,
                        child: Container(
                          width: height - 4,
                          height: height - 4,
                          decoration: BoxDecoration(
                            shape: .circle,
                            border: .all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: .blur(
                                sigmaX: widget.blurIntensity,
                                sigmaY: widget.blurIntensity,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: .topLeft,
                                    end: .bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.4),
                                      Colors.white.withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                                child: widget.value
                                    ? Icon(
                                        Icons.check,
                                        size: (height - 4) * 0.6,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
