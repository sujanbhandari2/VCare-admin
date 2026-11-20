import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/account/presentation/widgets/account_password_requirements.dart';
import 'package:vcare_admin/features/auth/domain/auth_forgot_validators.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/reset_password_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Admin reset password — parity with ui-vcare-admin-console ResetPasswordScreen.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _error;

  String get _token => widget.token?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    if (_token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_clearLocalSession());
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _clearLocalSession() async {
    await ref.read(adminAuthSessionProvider.notifier).clearSession();
    await ref.read(tenantBrandingStateProvider.notifier).resetToDefaults();
  }

  Future<void> _submitReset() async {
    setState(() => _error = null);

    if (_token.isEmpty) {
      setState(
        () => _error =
            'Reset link is missing or invalid. Request a new link from the forgot password page.',
      );
      return;
    }

    final passwordError = AuthPasswordValidator.validateStrength(
      _passwordController.text,
    );
    if (passwordError != null) {
      setState(() => _error = passwordError);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    await ref
        .read(resetPasswordStateProvider.notifier)
        .resetPassword(
          token: _token,
          password: _passwordController.text,
          onCompleted: (success) async {
            if (!mounted) {
              return;
            }
            if (success) {
              await _clearLocalSession();
              if (!mounted) {
                return;
              }
              context.showVcareToast(
                title: 'Password updated',
                description:
                    'You can now sign in with your new password.',
                variant: VcareToastVariant.success,
              );
              context.goNamed(AppRouter.login.toPathName);
              return;
            }

            setState(() {
              _error =
                  ref.read(resetPasswordStateProvider).operation.errorMessage ??
                  'Failed to reset password';
            });
          },
        );
  }

  void _goToLogin() {
    context.goNamed(AppRouter.login.toPathName);
  }

  void _goToForgotPassword() {
    context.goNamed(AppRouter.forgotPassword.toPathName);
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(resetPasswordStateProvider);
    final vcare = context.vcare;
    final missingToken = _token.isEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: LoginShell(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  children: [
                    Text(
                      'Reset your password',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a new password for your account.',
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
              if (missingToken) ...[
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
                    'Reset link is missing or invalid. Request a new link from the forgot password page.',
                    style: TextStyle(
                      fontSize: 13,
                      color: vcare.destructive,
                    ),
                  ),
                ),
              ] else ...[
                if (_error != null) ...[
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
                      _error!,
                      style: TextStyle(
                        fontSize: 13,
                        color: vcare.destructive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'NEW PASSWORD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: vcare.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                LoginTextField(
                  controller: _passwordController,
                  obscureText: true,
                  hint: 'Create a password',
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enabled: !resetState.resetting,
                  autofocus: true,
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      LucideIcons.lock,
                      size: 18,
                      color: vcare.mutedForeground,
                    ),
                  ),
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() => _error = null);
                    } else {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 12),
                LoginTextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  hint: 'Confirm your password',
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enabled: !resetState.resetting,
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      LucideIcons.lock,
                      size: 18,
                      color: vcare.mutedForeground,
                    ),
                  ),
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() => _error = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                AccountPasswordRequirements(
                  password: _passwordController.text,
                ),
                const SizedBox(height: 16),
                LoginPrimaryButton(
                  label: resetState.resetting
                      ? 'Updating password…'
                      : 'Reset password',
                  loading: resetState.resetting,
                  onPressed: resetState.resetting ? null : _submitReset,
                ),
              ],
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: vcare.mutedForeground,
                  ),
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: TextButton(
                        onPressed: _goToForgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Request a new reset link',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: vcare.primary,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' · '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: TextButton(
                        onPressed: _goToLogin,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: vcare.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
