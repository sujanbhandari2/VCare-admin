import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Compact role pill shown next to a messenger display name.
class VcareMessengerRoleBadge extends StatelessWidget {
  const VcareMessengerRoleBadge({
    super.key,
    required this.roleLabel,
    this.compact = false,
  });

  final String roleLabel;
  final bool compact;

  static bool shouldShow(String roleLabel) =>
      _displayLabel(roleLabel).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final label = _displayLabel(roleLabel);
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = _colorsFor(label, context.vcare);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 9.5 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          height: 1.1,
          color: colors.foreground,
        ),
      ),
    );
  }

  static String _displayLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final label = trimmed
        .toUpperCase()
        .split(RegExp(r'[\s_]+'))
        .where((part) => part.isNotEmpty)
        .join(' ');
    // Hide the mapper fallback used when the API role is missing.
    if (label == 'USER') {
      return '';
    }
    return label;
  }

  static _RoleBadgeColors _colorsFor(String label, VCareThemeExtension vcare) {
    switch (label) {
      case 'CLIENT':
        return const _RoleBadgeColors(
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF1B5E20),
          border: Color(0xFFA5D6A7),
        );
      case 'ADMIN':
        return const _RoleBadgeColors(
          background: Color(0xFFFFF3E0),
          foreground: Color(0xFFBF360C),
          border: Color(0xFFFFCC80),
        );
      case 'AGENT':
        return const _RoleBadgeColors(
          background: Color(0xFFE3F2FD),
          foreground: Color(0xFF1565C0),
          border: Color(0xFF90CAF9),
        );
      default:
        return _RoleBadgeColors(
          background: vcare.muted.withValues(alpha: 0.55),
          foreground: vcare.mutedForeground,
          border: vcare.border,
        );
    }
  }
}

class _RoleBadgeColors {
  const _RoleBadgeColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
