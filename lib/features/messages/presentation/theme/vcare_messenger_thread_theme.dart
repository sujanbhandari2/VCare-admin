import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// VCare conversation thread styling tokens for [MessengerChatShell].
class VcareMessengerThreadTheme {
  VcareMessengerThreadTheme._();

  static MessengerThemeData fromContext(BuildContext context) {
    final vcare = context.vcare;
    final scheme = Theme.of(context).colorScheme;
    final scaffoldBackground = Theme.of(context).scaffoldBackgroundColor;

    return MessengerThemeData(
      primary: vcare.primary,
      background: scheme.surface,
      surface: vcare.card,
      border: vcare.border,
      subtleText: vcare.mutedForeground,
      mutedText: vcare.mutedForeground.withValues(alpha: 0.7),
      searchBackground: vcare.muted,
      threadBackgroundMobile: scaffoldBackground,
      bubbleMine: vcare.primary,
      bubbleOther: vcare.muted,
      bubbleMineText: scheme.onPrimary,
      bubbleOtherText: scheme.onSurface,
      bubbleMineTime: scheme.onPrimary.withValues(alpha: 0.7),
      bubbleOtherTime: vcare.mutedForeground.withValues(alpha: 0.8),
      composerFieldBackground: vcare.card,
      onlineIndicator: vcare.success,
      offlineIndicator: vcare.mutedForeground.withValues(alpha: 0.6),
      reactionBackground: vcare.card,
      reactionBorder: vcare.border,
      dateSeparatorBackground: vcare.muted.withValues(alpha: 0.5),
      dateSeparatorText: vcare.mutedForeground.withValues(alpha: 0.8),
      mediaPlaceholderBackground: vcare.muted,
      mediaLoaderColor: vcare.primary,
    );
  }
}
