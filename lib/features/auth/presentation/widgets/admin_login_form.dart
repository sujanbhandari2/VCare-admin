import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

class AdminLoginForm extends StatefulWidget {
  const AdminLoginForm({
    super.key,
    required this.onSubmit,
    required this.isSubmitting,
    this.biometricAvailable = false,
    this.biometricLoading = false,
    this.onBiometricPressed,
    this.disabled = false,
  });

  final void Function(String email, String password) onSubmit;
  final bool isSubmitting;
  final bool biometricAvailable;
  final bool biometricLoading;
  final VoidCallback? onBiometricPressed;
  final bool disabled;

  @override
  State<AdminLoginForm> createState() => _AdminLoginFormState();
}

class _AdminLoginFormState extends State<AdminLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  void _handleSubmit() {
    final emailError = _validateEmail(_emailController.text);
    final passwordError = _validatePassword(_passwordController.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError != null || passwordError != null) {
      return;
    }

    widget.onSubmit(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.disabled && !widget.isSubmitting;
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title only — LoginWordmark is rendered inside LoginShell above this body.
        Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            children: [
              Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your email and password to access the admin console.',
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
        LoginFieldGroup(
          errorText: _emailError,
          field: LoginTextField(
            controller: _emailController,
            hint: 'you@company.com',
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enabled: enabled,
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
        const SizedBox(height: 12),
        LoginFieldGroup(
          errorText: _passwordError,
          field: LoginTextField(
            controller: _passwordController,
            hint: 'Password',
            obscureText: true,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enabled: enabled,
            hasError: _passwordError != null,
            prefix: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                LucideIcons.lock,
                size: 18,
                color: vcare.mutedForeground,
              ),
            ),
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: enabled
                ? () => context.pushNamed(AppRouter.forgotPassword.toPathName)
                : null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: 12,
                color: vcare.mutedForeground,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LoginPrimaryButton(
          label: 'Sign in',
          loading: widget.isSubmitting,
          onPressed: enabled ? _handleSubmit : null,
        ),
        if (widget.biometricAvailable && widget.onBiometricPressed != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: enabled && !widget.biometricLoading
                ? widget.onBiometricPressed
                : null,
            icon: widget.biometricLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.theme.colorScheme.primary,
                    ),
                  )
                : const Icon(LucideIcons.fingerprint, size: 16),
            label: const Text('Use biometric instead'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
