import 'dart:async';

import 'package:flutter/material.dart';

import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

/// Admin 2FA form — parity with web TwoFactorForm.tsx.
class AdminTwoFactorForm extends StatefulWidget {
  const AdminTwoFactorForm({
    super.key,
    required this.email,
    required this.expiresIn,
    required this.isVerifying,
    required this.isResending,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  final String? email;
  final int? expiresIn;
  final bool isVerifying;
  final bool isResending;
  final void Function({required String otp, required bool rememberMe}) onVerify;
  final Future<void> Function() onResend;
  final VoidCallback onBack;

  @override
  State<AdminTwoFactorForm> createState() => _AdminTwoFactorFormState();
}

class _AdminTwoFactorFormState extends State<AdminTwoFactorForm> {
  static const _resendCooldownSeconds = 90;

  final _otpController = TextEditingController();
  bool _rememberMe = false;
  bool _showValidationError = false;
  int _cooldownSeconds = _resendCooldownSeconds;
  Timer? _cooldownTimer;
  String? _autoSubmittedOtp;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_handleControllerChanged);
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
        return;
      }
      setState(() => _cooldownSeconds -= 1);
    });
  }

  bool get _canResend =>
      _cooldownSeconds <= 0 && !widget.isResending && !widget.isVerifying;

  String? get _expiresLabel {
    final expiresIn = widget.expiresIn;
    if (expiresIn == null || expiresIn <= 0) {
      return null;
    }
    if (expiresIn < 60) {
      return '${expiresIn}s';
    }
    final minutes = (expiresIn / 60).round().clamp(1, 999);
    return '$minutes min';
  }

  String get _cooldownLabel {
    final mins = _cooldownSeconds ~/ 60;
    final secs = _cooldownSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  void _submitOtp(String code) {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _showValidationError = true);
      return;
    }
    setState(() => _showValidationError = false);
    widget.onVerify(otp: code, rememberMe: _rememberMe);
  }

  void _handleOtpChanged(String value) {
    setState(() => _showValidationError = false);
    if (value.length == 6 &&
        !widget.isVerifying &&
        RegExp(r'^\d{6}$').hasMatch(value) &&
        _autoSubmittedOtp != value) {
      _autoSubmittedOtp = value;
      _submitOtp(value);
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) {
      return;
    }
    try {
      await widget.onResend();
      if (!mounted) {
        return;
      }
      _otpController.clear();
      _autoSubmittedOtp = null;
      setState(() => _showValidationError = false);
      _startCooldown();
    } catch (_) {
      // Parent surfaces the error; keep resend available.
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email?.trim();
    final expiresLabel = _expiresLabel;
    final enabled = !widget.isVerifying;
    final otpReady = _otpController.text.length == 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.theme.hintColor,
            ),
            children: [
              if (email != null && email.isNotEmpty) ...[
                const TextSpan(text: 'Enter the 6-digit code we sent to\n'),
                TextSpan(
                  text: email,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: context.theme.colorScheme.onSurface,
                  ),
                ),
                if (expiresLabel != null)
                  TextSpan(text: '\nCode expires in $expiresLabel.'),
              ] else ...[
                TextSpan(
                  text: expiresLabel != null
                      ? 'Enter the 6-digit code we sent to your email or phone. Code expires in $expiresLabel.'
                      : 'Enter the 6-digit code we sent to your email or phone.',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        LoginOtpInput(
          controller: _otpController,
          onChanged: _handleOtpChanged,
          onCompleted: _submitOtp,
        ),
        if (_showValidationError) ...[
          const SizedBox(height: 8),
          Text(
            'Enter a valid 6-digit code',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        InkWell(
          onTap: enabled
              ? () => setState(() => _rememberMe = !_rememberMe)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: enabled
                        ? (value) =>
                            setState(() => _rememberMe = value == true)
                        : null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Remember me for 7 days',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.theme.hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppButton.elevated(
          text: widget.isVerifying ? 'Verifying…' : 'Verify and sign in',
          loading: widget.isVerifying,
          onPressed: enabled && otpReady
              ? () => _submitOtp(_otpController.text)
              : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: widget.isVerifying || widget.isResending
                  ? null
                  : widget.onBack,
              child: const Text('Back'),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      _canResend ? () => unawaited(_handleResend()) : null,
                  child: Text(
                    widget.isResending
                        ? 'Sending…'
                        : _cooldownSeconds > 0
                            ? 'Resend code in $_cooldownLabel'
                            : 'Resend code',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
