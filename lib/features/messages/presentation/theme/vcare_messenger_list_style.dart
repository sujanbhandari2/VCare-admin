import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// VCare conversation list styling tokens for [MessengerChatShell].
class VcareMessengerListStyle {
  VcareMessengerListStyle._();

  static MessengerUserListItemStyle fromVcareTheme(BuildContext context) {
    final vcare = context.vcare;
    return MessengerUserListItemStyle(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      borderRadius: 24,
      backgroundColor: vcare.card,
      selectedBackgroundColor: vcare.card,
      border: BorderSide(color: vcare.border),
      selectedBorder: BorderSide(color: vcare.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      titleStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      subtitleStyle: TextStyle(
        fontSize: 13,
        color: vcare.mutedForeground.withValues(alpha: 0.8),
        height: 1.2,
      ),
      trailingIconColor: vcare.mutedForeground,
      unreadDotColor: VCareColors.primary,
    );
  }
}
