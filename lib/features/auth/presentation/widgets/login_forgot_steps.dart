import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/domain/entities/forgot_password_result.dart';
import 'package:vcare_admin/features/auth/presentation/state/login_flow_state.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// parity: vcare-agent-app-2.0/src/features/auth/components/ForgotRequestStep.tsx
class LoginForgotRequestStep extends StatelessWidget {
  const LoginForgotRequestStep({
    super.key,
    required this.destination,
    required this.method,
    required this.error,
    required this.loading,
    required this.onSubmit,
  });

  final String destination;
  final LoginFlowMethod method;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final viaSms = method == LoginFlowMethod.phone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginStepHeader(
          icon: LucideIcons.mail,
          title: 'Reset your password',
          subtitle: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: context.vcare.mutedForeground,
                height: 1.45,
              ),
              children: [
                const TextSpan(text: "We'll send a reset link to "),
                TextSpan(
                  text: destination,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: context.vcare.foreground,
                  ),
                ),
                TextSpan(text: viaSms ? ' via SMS' : ''),
                const TextSpan(text: ' if an account exists.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (error != null) ...[
          Text(
            error!,
            style: TextStyle(fontSize: 12, color: context.vcare.destructive),
          ),
          const SizedBox(height: 12),
        ],
        LoginPrimaryButton(
          label: 'Send reset link',
          loading: loading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

/// parity: vcare-agent-app-2.0/src/features/auth/components/ForgotDisambiguateStep.tsx
class LoginForgotDisambiguateStep extends StatelessWidget {
  const LoginForgotDisambiguateStep({
    super.key,
    required this.accounts,
    required this.selectedAccountId,
    required this.dobController,
    required this.zipController,
    required this.error,
    required this.loading,
    required this.onSelectAccount,
    required this.onDobChanged,
    required this.onZipChanged,
    required this.onPickDob,
    required this.onSubmit,
  });

  final List<ForgotPasswordAccount> accounts;
  final String? selectedAccountId;
  final TextEditingController dobController;
  final TextEditingController zipController;
  final String? error;
  final bool loading;
  final ValueChanged<String> onSelectAccount;
  final VoidCallback onDobChanged;
  final VoidCallback onZipChanged;
  final VoidCallback onPickDob;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginStepHeader(
          icon: LucideIcons.users,
          title: 'Which account is yours?',
          subtitle: Text(
            'Select your account or verify with your date of birth and ZIP code.',
          ),
        ),
        for (final account in accounts) ...[
          Material(
            color: selectedAccountId == account.accountId
                ? context.vcare.primary.withValues(alpha: 0.05)
                : vcare.muted.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: VCareRadius.xlAll,
              side: BorderSide(
                color: selectedAccountId == account.accountId
                    ? context.vcare.primary
                    : vcare.border.withValues(alpha: 0.6),
              ),
            ),
            child: InkWell(
              onTap: () => onSelectAccount(account.accountId),
              borderRadius: VCareRadius.xlAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  account.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        Text(
          'Or verify with DOB and ZIP',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPickDob,
          child: AbsorbPointer(
            child: LoginTextField(
              controller: dobController,
              hint: 'Date of birth',
              prefix: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: vcare.mutedForeground,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        LoginTextField(
          controller: zipController,
          keyboardType: TextInputType.number,
          hint: 'ZIP code',
          onChanged: (_) => onZipChanged(),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(fontSize: 12, color: context.vcare.destructive),
          ),
        ],
        const SizedBox(height: 12),
        LoginPrimaryButton(
          label: 'Continue',
          loading: loading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

/// parity: vcare-agent-app-2.0/src/features/auth/components/ForgotSentStep.tsx
class LoginForgotSentStep extends StatelessWidget {
  const LoginForgotSentStep({
    super.key,
    required this.destination,
    required this.method,
    required this.onReturnToSignIn,
  });

  final String destination;
  final LoginFlowMethod method;
  final VoidCallback onReturnToSignIn;

  @override
  Widget build(BuildContext context) {
    final viaSms = method == LoginFlowMethod.phone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginStepHeader(
          icon: LucideIcons.checkCircle2,
          title: 'Check your inbox',
          subtitle: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: context.vcare.mutedForeground,
                height: 1.45,
              ),
              children: [
                const TextSpan(text: 'If an account exists for '),
                TextSpan(
                  text: destination,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: context.vcare.foreground,
                  ),
                ),
                TextSpan(
                  text: viaSms
                      ? ", you'll receive an SMS"
                      : ", you'll receive an email",
                ),
                const TextSpan(
                  text: ' with a link to reset your password.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        LoginPrimaryButton(
          label: 'Back to sign in',
          onPressed: onReturnToSignIn,
        ),
      ],
    );
  }
}










