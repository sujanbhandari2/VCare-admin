import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_button_styles.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';

/// Approve CTA fill — the same fixed brand teal as the failed-payment recovery
/// buttons, so both review actions read as the one primary action colour.
ButtonStyle pendingMembershipApproveButtonStyle({
  VCareButtonSize size = VCareButtonSize.lg,
  TextStyle? labelStyle,
  EdgeInsetsGeometry? padding,
  bool dimWhenDisabled = true,
}) {
  return VCareButtonStyles.filled(
    background: VCareColors.paymentRecoveryCta,
    foreground: Colors.white,
    hoverBackground: VCareColors.paymentRecoveryCtaHover,
    pressedBackground: VCareColors.paymentRecoveryCtaActive,
    size: size,
    labelStyle: labelStyle,
    padding: padding,
    dimWhenDisabled: dimWhenDisabled,
  );
}
