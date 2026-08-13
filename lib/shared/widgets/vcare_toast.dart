import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Toast variants — parity with vcare-agent-app-2.0 [toast.tsx].
enum VcareToastVariant {
  success,
  info,
  destructive,
  warning,
  defaultVariant,
}

class _VcareToastColors {
  const _VcareToastColors({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;

  factory _VcareToastColors.forVariant(
    BuildContext context,
    VcareToastVariant variant,
  ) {
    final vcare = context.vcare;
    return switch (variant) {
      VcareToastVariant.success => _fromStatus(
        VCareStatusColors.of(context, VCareStatusTone.success),
        LucideIcons.checkCircle2,
      ),
      VcareToastVariant.info => _fromStatus(
        VCareStatusColors.of(context, VCareStatusTone.info),
        LucideIcons.info,
      ),
      VcareToastVariant.destructive => _fromStatus(
        VCareStatusColors.of(context, VCareStatusTone.danger),
        LucideIcons.xCircle,
      ),
      VcareToastVariant.warning => _fromStatus(
        VCareStatusColors.of(context, VCareStatusTone.warning),
        LucideIcons.alertTriangle,
      ),
      VcareToastVariant.defaultVariant => _VcareToastColors(
        background: vcare.muted,
        border: vcare.border,
        foreground: vcare.foreground,
        icon: LucideIcons.info,
      ),
    };
  }

  static _VcareToastColors _fromStatus(
    VCareStatusColors status,
    IconData icon,
  ) {
    return _VcareToastColors(
      background: status.background,
      border: status.border,
      foreground: status.foreground,
      icon: icon,
    );
  }
}

/// Styled toast content — parity with vcare-agent-app-2.0 [toaster.tsx].
class VcareToastContent extends StatelessWidget {
  const VcareToastContent({
    super.key,
    required this.title,
    this.description,
    this.variant = VcareToastVariant.defaultVariant,
  });

  final String title;
  final String? description;
  final VcareToastVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = _VcareToastColors.forVariant(context, variant);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              colors.icon,
              size: 20,
              color: colors.foreground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                      height: 1.3,
                    ),
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.foreground.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension VcareToastExt on BuildContext {
  /// Shows a VCare-styled toast at the bottom of the screen.
  ///
  /// Rendered in the root overlay so it stays visible above modal routes
  /// such as bottom sheets and dialogs.
  void showVcareToast({
    required String title,
    String? description,
    VcareToastVariant variant = VcareToastVariant.defaultVariant,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    _VcareToastManager.show(
      this,
      title: title,
      description: description,
      variant: variant,
      duration: duration,
      onTap: onTap,
    );
  }
}

/// Manages a single active toast overlay entry at a time.
class _VcareToastManager {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required String title,
    String? description,
    required VcareToastVariant variant,
    required Duration duration,
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismiss();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _VcareToastOverlayWidget(
        title: title,
        description: description,
        variant: variant,
        duration: duration,
        onTap: onTap,
        onDismissed: () {
          if (_entry == entry) {
            _entry = null;
          }
          entry.remove();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void _dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _VcareToastOverlayWidget extends StatefulWidget {
  const _VcareToastOverlayWidget({
    required this.title,
    required this.description,
    required this.variant,
    required this.duration,
    required this.onDismissed,
    this.onTap,
  });

  final String title;
  final String? description;
  final VcareToastVariant variant;
  final Duration duration;
  final VoidCallback onDismissed;
  final VoidCallback? onTap;

  @override
  State<_VcareToastOverlayWidget> createState() =>
      _VcareToastOverlayWidgetState();
}

class _VcareToastOverlayWidgetState extends State<_VcareToastOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _hide);
  }

  Future<void> _hide() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(curved),
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  onTap: () {
                    widget.onTap?.call();
                    _hide();
                  },
                  child: VcareToastContent(
                    title: widget.title,
                    description: widget.description,
                    variant: widget.variant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
