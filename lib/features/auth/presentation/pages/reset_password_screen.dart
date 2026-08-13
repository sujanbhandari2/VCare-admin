import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/auth/domain/auth_forgot_validators.dart';
import 'package:vcare_admin/features/auth/presentation/providers/reset_password_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// parity: vcare-agent-app-2.0/src/pages/ResetPassword.tsx + ResetPasswordBody.tsx
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
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    setState(() => _error = null);

    if (_token.isEmpty) {
      setState(
        () => _error =
            'This reset link is invalid. Request a new one from the sign-in page.',
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
      setState(() => _error = "Passwords don't match.");
      return;
    }

    await ref
        .read(resetPasswordStateProvider.notifier)
        .resetPassword(
          token: _token,
          password: _passwordController.text,
          onCompleted: (success) {
            if (!mounted || success) return;
            setState(() {
              _error =
                  ref.read(resetPasswordStateProvider).operation.errorMessage ??
                  'Unable to reset password.';
            });
          },
        );
  }

  void _goToLogin() {
    context.goNamed(AppRouter.login.toPathName);
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(resetPasswordStateProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: LoginShell(
          body: _token.isEmpty
              ? _buildInvalidLink()
              : resetState.success
              ? _buildSuccess()
              : _buildForm(resetState.resetting),
        ),
      ),
    );
  }

  Widget _buildInvalidLink() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginStepHeader(
          icon: LucideIcons.keyRound,
          title: 'Invalid reset link',
          subtitle: Text(
            'This password reset link is missing or invalid. Request a new one from the sign-in page.',
          ),
        ),
        LoginPrimaryButton(label: 'Back to sign in', onPressed: _goToLogin),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginStepHeader(
          icon: LucideIcons.keyRound,
          title: 'Password updated',
          subtitle: Text(
            'Your password has been reset. Sign in with your new password.',
          ),
        ),
        LoginPrimaryButton(label: 'Sign in', onPressed: _goToLogin),
      ],
    );
  }

  Widget _buildForm(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginStepHeader(
          icon: LucideIcons.keyRound,
          title: 'Create a new password',
          subtitle: Text(
            'Use at least 8 characters with upper and lower case letters, a number, and a special character.',
          ),
        ),
        LoginTextField(
          controller: _passwordController,
          obscureText: true,
          hint: 'New password',
          autofocus: true,
        ),
        const SizedBox(height: 12),
        LoginTextField(
          controller: _confirmPasswordController,
          obscureText: true,
          hint: 'Confirm new password',
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(fontSize: 12, color: context.vcare.destructive),
          ),
        ],
        const SizedBox(height: 12),
        LoginPrimaryButton(
          label: 'Reset password',
          loading: loading,
          onPressed: _submitReset,
        ),
      ],
    );
  }
}
