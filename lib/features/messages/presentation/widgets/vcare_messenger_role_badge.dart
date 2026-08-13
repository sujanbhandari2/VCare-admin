import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_spacing.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';

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

    final colors = VCareStatusColors.of(context, _toneFor(label));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : VCareSpacing.s2,
        vertical: compact ? VCareSpacing.s0_5 : 3,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: VCareRadius.fullAll,
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

  static VCareStatusTone _toneFor(String label) {
    return switch (label) {
      'CLIENT' => VCareStatusTone.success,
      'ADMIN' => VCareStatusTone.warning,
      'AGENT' => VCareStatusTone.info,
      _ => VCareStatusTone.neutral,
    };
  }
}
