import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';

/// parity: vcare-agent-app-2.0/src/features/auth/components/VerifyStep.tsx
class LoginVerifyStep extends StatelessWidget {
  const LoginVerifyStep({
    super.key,
    required this.destination,
    required this.otpController,
    required this.error,
    required this.loading,
    required this.resendIn,
    required this.resendLoading,
    required this.onCompleted,
    required this.onVerify,
    required this.onResend,
    required this.onChanged,
  });

  final String destination;
  final TextEditingController otpController;
  final String? error;
  final bool loading;
  final int resendIn;
  final bool resendLoading;
  final ValueChanged<String> onCompleted;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginStepHeader(
          icon: LucideIcons.lock,
          title: 'Enter verification code',
          subtitle: Text.rich(
            TextSpan(
              text: 'We sent a 6-digit code to\n',
              children: [
                TextSpan(
                  text: destination,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: VCareColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoginOtpInput(
            controller: otpController,
            onChanged: onChanged,
            onCompleted: onCompleted,
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: VCareColors.destructive),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: LoginPrimaryButton(
            label: 'Verify',
            loading: loading,
            onPressed: otpController.text.length >= 6 && !loading
                ? onVerify
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
              children: [
                const TextSpan(text: "Didn't get a code? "),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: TextButton(
                    onPressed: resendIn > 0 || resendLoading ? null : onResend,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      resendIn > 0 ? 'Resend in ${resendIn}s' : 'Resend code',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: resendIn > 0 || resendLoading
                            ? vcare.mutedForeground
                            : VCareColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
