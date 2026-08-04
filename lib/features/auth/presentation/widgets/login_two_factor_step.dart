import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';

/// parity: vcare-agent-app-2.0/src/features/auth/components/TwoFactorStep.tsx
class LoginTwoFactorStep extends StatelessWidget {
  const LoginTwoFactorStep({
    super.key,
    required this.destination,
    required this.otpController,
    required this.error,
    required this.loading,
    required this.resendIn,
    required this.resendLoading,
    required this.rememberMe,
    required this.onRememberMeChanged,
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
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
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
          icon: LucideIcons.shieldCheck,
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
          padding: const EdgeInsets.only(bottom: 8),
          child: LoginOtpInput(
            controller: otpController,
            onChanged: onChanged,
            onCompleted: onCompleted,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'The code is valid for 10 minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
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
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: vcare.muted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => onRememberMeChanged(!rememberMe),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: rememberMe,
                        onChanged: (value) =>
                            onRememberMeChanged(value == true),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Remember this code for 7 days',
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                const TextSpan(text: "Didn't receive the code? "),
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
                      resendIn > 0
                          ? 'Resend in ${_formatTwoFactorResendLabel(resendIn)}'
                          : 'Resend code',
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

/// parity: TwoFactorStep.tsx resendLabel (`M:SS` when minutes > 0, else `Xs`)
String _formatTwoFactorResendLabel(int resendIn) {
  final minutes = resendIn ~/ 60;
  final seconds = resendIn % 60;
  if (minutes > 0) {
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  return '${seconds}s';
}
