import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_forgot_password_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

enum _ForgotPasswordStep { email, sent }

/// Admin forgot password — parity with ui-vcare-admin-console ForgotPasswordScreen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  _ForgotPasswordStep _step = _ForgotPasswordStep.email;
  String? _emailError;
  String? _submitError;
  String _submittedEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Email is required';
    }
    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _submitEmail() async {
    final emailError = _validateEmail(_emailController.text);
    setState(() {
      _emailError = emailError;
      _submitError = null;
    });
    if (emailError != null) {
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    await ref.read(adminForgotPasswordStateProvider.notifier).requestReset(
          email: email,
          onCompleted: (success) {
            if (!mounted) {
              return;
            }
            if (success) {
              setState(() {
                _submittedEmail = email;
                _step = _ForgotPasswordStep.sent;
                _submitError = null;
              });
              return;
            }

            setState(() {
              _submitError =
                  ref.read(adminForgotPasswordStateProvider).error ??
                  'Failed to send password reset email';
            });
          },
        );
  }

  void _sendAnotherLink() {
    ref.read(adminForgotPasswordStateProvider.notifier).reset();
    setState(() {
      _step = _ForgotPasswordStep.email;
      _submitError = null;
      _emailError = null;
    });
  }

  void _goToLogin() {
    context.goNamed(AppRouter.login.toPathName);
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        ref.watch(adminForgotPasswordStateProvider).requesting;
    final vcare = context.vcare;
    final successColors =
        VCareStatusColors.of(context, VCareStatusTone.success);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: LoginShell(
          onBack: _goToLogin,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == _ForgotPasswordStep.email) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    children: [
                      Text(
                        'Forgot password?',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Enter your email and we'll send you a link to reset your password.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: vcare.mutedForeground,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_submitError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: vcare.destructive.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: vcare.destructive.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      _submitError!,
                      style: TextStyle(
                        fontSize: 13,
                        color: vcare.destructive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                LoginFieldGroup(
                  errorText: _emailError,
                  field: LoginTextField(
                    controller: _emailController,
                    hint: 'you@company.com',
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    enabled: !isSubmitting,
                    hasError: _emailError != null,
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        LucideIcons.mail,
                        size: 18,
                        color: vcare.mutedForeground,
                      ),
                    ),
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                LoginPrimaryButton(
                  label: isSubmitting ? 'Sending…' : 'Send reset link',
                  loading: isSubmitting,
                  onPressed: isSubmitting ? null : _submitEmail,
                ),
              ] else ...[
                Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: successColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.checkCircle2,
                        size: 24,
                        color: successColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Check your inbox',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: vcare.mutedForeground,
                          height: 1.35,
                        ),
                        children: [
                          const TextSpan(
                            text: 'If an account exists for ',
                          ),
                          TextSpan(
                            text: _submittedEmail,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: vcare.foreground,
                            ),
                          ),
                          const TextSpan(
                            text:
                                ', we sent a password reset link. Follow the link in the email to choose a new password.',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _sendAnotherLink,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Send another link'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: _goToLogin,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.arrowLeft,
                      size: 14,
                      color: vcare.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Back to sign in',
                      style: TextStyle(
                        fontSize: 14,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
