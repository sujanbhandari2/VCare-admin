import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

class AdminLoginForm extends StatefulWidget {
  const AdminLoginForm({
    super.key,
    required this.onSubmit,
    required this.isSubmitting,
    this.disabled = false,
  });

  final void Function(String email, String password) onSubmit;
  final bool isSubmitting;
  final bool disabled;

  @override
  State<AdminLoginForm> createState() => _AdminLoginFormState();
}

class _AdminLoginFormState extends State<AdminLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required';
    }
    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  void _handleSubmit() {
    if (!( _formKey.currentState?.validate() ?? false)) {
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

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@company.com',
            inputType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: enabled,
            validator: _validateEmail,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Icon(LucideIcons.mail, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: true,
            textInputAction: TextInputAction.done,
            enabled: enabled,
            validator: _validatePassword,
            onSubmitted: (_) => _handleSubmit(),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Icon(LucideIcons.lock, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: enabled
                  ? () => context.pushNamed(AppRouter.forgotPassword.toPathName)
                  : null,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          AppButton.elevated(
            text: widget.isSubmitting ? 'Signing in…' : 'Sign in',
            loading: widget.isSubmitting,
            onPressed: enabled ? _handleSubmit : null,
          ),
        ],
      ),
    );
  }
}
