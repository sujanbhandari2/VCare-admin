import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/data/vcare_mock_lookup.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';

/// parity: vcare-agent-app-2.0/src/features/auth/components/ForgotIdentifyStep.tsx
class LoginForgotIdentifyStep extends StatelessWidget {
  const LoginForgotIdentifyStep({
    super.key,
    required this.controller,
    required this.error,
    required this.loading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginStepHeader(
          icon: LucideIcons.keyRound,
          title: 'Reset your password',
          subtitle: Text(
            "Enter the email linked to your VCare account(s) and we'll help you choose which one to reset.",
          ),
        ),
        LoginTextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          hint: 'you@example.com',
          autofocus: true,
          prefix: const Padding(
            padding: EdgeInsets.only(left: 16, right: 12),
            child: Icon(LucideIcons.mail, size: 16),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(fontSize: 12, color: VCareColors.destructive),
          ),
        ],
        const SizedBox(height: 12),
        LoginPrimaryButton(
          label: 'Find my accounts',
          loading: loading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

/// parity: vcare-agent-app-2.0/src/features/auth/components/ForgotSelectStep.tsx
class LoginForgotSelectStep extends StatelessWidget {
  const LoginForgotSelectStep({
    super.key,
    required this.forgotEmail,
    required this.accounts,
    required this.loadingKey,
    required this.pendingClientId,
    required this.onSelect,
  });

  final String forgotEmail;
  final List<LoginClientRecord> accounts;
  final String? loadingKey;
  final String? pendingClientId;
  final ValueChanged<LoginClientRecord> onSelect;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginStepHeader(
          icon: LucideIcons.users,
          title: 'Choose an account',
          subtitle: Text.rich(
            TextSpan(
              style: TextStyle(color: vcare.mutedForeground),
              children: [
                TextSpan(
                  text: 'We found ${accounts.length} accounts linked to ',
                ),
                TextSpan(
                  text: forgotEmail,
                  style: TextStyle(
                    color: VCareColors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(
                  text: '. Pick the one whose password you want to reset.',
                ),
              ],
            ),
          ),
        ),
        ...accounts.map((account) {
          final pending =
              loadingKey == 'forgot-send' &&
              pendingClientId == account.clientId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: vcare.muted.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: vcare.border),
              ),
              child: InkWell(
                onTap: loadingKey != null ? null : () => onSelect(account),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.fullName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${account.memberId} · DOB ${account.dobMasked} · ZIP ${account.zipMasked}',
                              style: TextStyle(
                                fontSize: 12,
                                color: vcare.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pending)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: vcare.mutedForeground,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// parity: vcare-agent-app-2.0/src/features/auth/components/ForgotVerifyStep.tsx
class LoginForgotVerifyStep extends StatelessWidget {
  const LoginForgotVerifyStep({
    super.key,
    required this.forgotEmail,
    required this.forgotSelected,
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

  final String forgotEmail;
  final LoginClientRecord? forgotSelected;
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
          title: "Verify it's you",
          subtitle: Text.rich(
            TextSpan(
              style: TextStyle(color: vcare.mutedForeground),
              children: [
                const TextSpan(text: 'We sent a 6-digit code to '),
                TextSpan(
                  text: forgotEmail,
                  style: TextStyle(
                    color: VCareColors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (forgotSelected != null) ...[
                  const TextSpan(text: ' for '),
                  TextSpan(
                    text: forgotSelected!.fullName,
                    style: TextStyle(
                      color: VCareColors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const TextSpan(text: '.'),
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
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
                children: [
                  const TextSpan(text: 'Demo code: '),
                  TextSpan(
                    text: VcareMockLookup.demoOtp,
                    style: TextStyle(
                      color: VCareColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: LoginPrimaryButton(
            label: 'Verify',
            loading: loading,
            onPressed: otpController.text.length >= 6 ? onVerify : null,
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

/// parity: vcare-agent-app-2.0/src/features/auth/components/ForgotResetStep.tsx
class LoginForgotResetStep extends StatelessWidget {
  const LoginForgotResetStep({
    super.key,
    required this.forgotSelected,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.error,
    required this.loading,
    required this.onSubmit,
  });

  final LoginClientRecord? forgotSelected;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final selected = forgotSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginStepHeader(
          icon: LucideIcons.shieldCheck,
          title: 'Create a new password',
          subtitle: Text(
            selected != null
                ? "You're resetting the password for ${selected.fullName} (${selected.memberId})."
                : "Choose a strong password you haven't used before.",
          ),
        ),
        LoginTextField(
          controller: newPasswordController,
          obscureText: true,
          hint: 'New password (min 8 chars)',
          autofocus: true,
        ),
        const SizedBox(height: 12),
        LoginTextField(
          controller: confirmPasswordController,
          obscureText: true,
          hint: 'Confirm new password',
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(fontSize: 12, color: VCareColors.destructive),
          ),
        ],
        const SizedBox(height: 12),
        LoginPrimaryButton(
          label: 'Reset password',
          loading: loading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
