import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';

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

  static Color _hsl(double h, double s, double l) =>
      HSLColor.fromAHSL(1, h, s / 100, l / 100).toColor();

  factory _VcareToastColors.forVariant(VcareToastVariant variant) {
    return switch (variant) {
      VcareToastVariant.success => _VcareToastColors(
        background: _hsl(140, 55, 94),
        border: _hsl(145, 45, 75),
        foreground: _hsl(150, 55, 22),
        icon: LucideIcons.checkCircle2,
      ),
      VcareToastVariant.info => _VcareToastColors(
        background: _hsl(215, 85, 95),
        border: _hsl(215, 75, 82),
        foreground: _hsl(220, 70, 35),
        icon: LucideIcons.info,
      ),
      VcareToastVariant.destructive => _VcareToastColors(
        background: _hsl(0, 75, 96),
        border: _hsl(0, 70, 85),
        foreground: _hsl(0, 60, 38),
        icon: LucideIcons.xCircle,
      ),
      VcareToastVariant.warning => _VcareToastColors(
        background: _hsl(48, 95, 92),
        border: _hsl(45, 80, 75),
        foreground: _hsl(35, 70, 30),
        icon: LucideIcons.alertTriangle,
      ),
      VcareToastVariant.defaultVariant => _VcareToastColors(
        background: VCareColors.muted,
        border: VCareColors.border,
        foreground: VCareColors.foreground,
        icon: LucideIcons.info,
      ),
    };
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
    final colors = _VcareToastColors.forVariant(variant);

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
  void showVcareToast({
    required String title,
    String? description,
    VcareToastVariant variant = VcareToastVariant.defaultVariant,
    Duration duration = const Duration(seconds: 1),
  }) {
    final messenger = ScaffoldMessenger.of(this);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          behavior: SnackBarBehavior.floating,
          duration: duration,
          dismissDirection: DismissDirection.down,
          content: VcareToastContent(
            title: title,
            description: description,
            variant: variant,
          ),
        ),
      );
  }
}
