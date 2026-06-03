import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/auth/data/vcare_mock_auth.dart';
import 'package:flutter_template/features/home/data/home_mock_data.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

enum _LoginMethod { phone, email }

enum _LoginStep { identify, verify, password }

const _demoOtp = '123456';

class VcareLoginScreen extends ConsumerStatefulWidget {
  const VcareLoginScreen({super.key});

  @override
  ConsumerState<VcareLoginScreen> createState() => _VcareLoginScreenState();
}

class _VcareLoginScreenState extends ConsumerState<VcareLoginScreen> {
  _LoginMethod _method = _LoginMethod.email;
  _LoginStep _step = _LoginStep.identify;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(text: 'alex.rivera@example.com');
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  String? _loadingKey;
  String? _error;
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _destination => _method == _LoginMethod.phone
      ? (_phoneController.text.isEmpty ? '+1 (555) 000-0000' : _phoneController.text)
      : (_emailController.text.isEmpty ? 'you@example.com' : _emailController.text);

  Future<void> _finishSignIn() async {
    setState(() => _loadingKey = 'finish');
    await VcareMockAuth.signIn(ref);
    if (!mounted) return;
    context.goNamed(AppRouter.home.toPathName);
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() {
      _error = null;
      _loadingKey = 'send';
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _loadingKey = null;
      _step = _LoginStep.verify;
      _otpController.clear();
    });
    _startResendTimer();
  }

  Future<void> _verifyCode(String value) async {
    if (value.length < 6) return;
    setState(() {
      _loadingKey = 'verify';
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    if (value != _demoOtp && value != '000000') {
      setState(() {
        _error = 'Invalid code. Try 123456 for the demo.';
        _loadingKey = null;
        _otpController.clear();
      });
      return;
    }
    setState(() {
      _loadingKey = null;
      _step = _LoginStep.password;
    });
  }

  Future<void> _finishSocial(String provider) async {
    setState(() => _loadingKey = provider);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await _finishSignIn();
  }

  void _goBack() {
    setState(() {
      _error = null;
      if (_step == _LoginStep.verify) {
        _step = _LoginStep.identify;
      } else if (_step == _LoginStep.password) {
        _step = _LoginStep.verify;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor,
                VCareColors.primary.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Material(
                    color: vcare.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                      side: BorderSide(color: vcare.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                          child: switch (_step) {
                            _LoginStep.identify => _IdentifyStep(
                                method: _method,
                                loadingKey: _loadingKey,
                                phoneController: _phoneController,
                                emailController: _emailController,
                                onMethodChanged: (m) =>
                                    setState(() => _method = m),
                                onSendCode: _sendCode,
                                onGoogle: () => _finishSocial('google'),
                                onApple: () => _finishSocial('apple'),
                                onSkip: _finishSignIn,
                              ),
                            _LoginStep.verify => _VerifyStep(
                                destination: _destination,
                                otpController: _otpController,
                                loadingKey: _loadingKey,
                                error: _error,
                                resendIn: _resendIn,
                                onBack: _goBack,
                                onVerify: _verifyCode,
                                onResend: _sendCode,
                              ),
                            _LoginStep.password => _PasswordStep(
                                loadingKey: _loadingKey,
                                error: _error,
                                passwordController: _passwordController,
                                onBack: _goBack,
                                onSubmit: () {
                                  if (_passwordController.text.length < 6) {
                                    setState(() => _error =
                                        'Enter your password to continue.');
                                    return;
                                  }
                                  _finishSignIn();
                                },
                              ),
                          },
                        ),
                        _LoginFooter(vcare: vcare),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentifyStep extends StatelessWidget {
  const _IdentifyStep({
    required this.method,
    required this.loadingKey,
    required this.phoneController,
    required this.emailController,
    required this.onMethodChanged,
    required this.onSendCode,
    required this.onGoogle,
    required this.onApple,
    required this.onSkip,
  });

  final _LoginMethod method;
  final String? loadingKey;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final ValueChanged<_LoginMethod> onMethodChanged;
  final VoidCallback onSendCode;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: vcare.gradientCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            LucideIcons.sparkles,
            color: VCareColors.primaryForeground,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome to VCare',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in or get started in one step',
          style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                loading: loadingKey == 'google',
                onTap: onGoogle,
                child: SvgPicture.asset(
                  'assets/svg/google.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'Apple',
                loading: loadingKey == 'apple',
                onTap: onApple,
                child: const Icon(LucideIcons.apple, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: vcare.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR CONTINUE WITH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: vcare.mutedForeground,
                ),
              ),
            ),
            Expanded(child: Divider(color: vcare.border)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: vcare.muted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _MethodTab(
                label: 'Phone',
                selected: method == _LoginMethod.phone,
                onTap: () => onMethodChanged(_LoginMethod.phone),
              ),
              _MethodTab(
                label: 'Email',
                selected: method == _LoginMethod.email,
                onTap: () => onMethodChanged(_LoginMethod.email),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (method == _LoginMethod.phone)
          _VcareTextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('+1', style: TextStyle(color: vcare.mutedForeground)),
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.only(left: 12),
                    color: vcare.border,
                  ),
                ],
              ),
            ),
            hint: '(555) 000-0000',
          )
        else
          _VcareTextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(LucideIcons.mail, size: 16, color: vcare.mutedForeground),
            ),
            hint: 'you@example.com',
          ),
        const SizedBox(height: 12),
        _PrimaryButton(
          label: 'Continue',
          icon: method == _LoginMethod.phone ? LucideIcons.phone : LucideIcons.mail,
          loading: loadingKey == 'send',
          onPressed: loadingKey != null ? null : onSendCode,
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: loadingKey != null ? null : onSkip,
          child: Text(
            'Skip — explore as demo user',
            style: TextStyle(
              fontSize: 12,
              color: vcare.mutedForeground,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerifyStep extends StatelessWidget {
  const _VerifyStep({
    required this.destination,
    required this.otpController,
    required this.loadingKey,
    required this.error,
    required this.resendIn,
    required this.onBack,
    required this.onVerify,
    required this.onResend,
  });

  final String destination;
  final TextEditingController otpController;
  final String? loadingKey;
  final String? error;
  final int resendIn;
  final VoidCallback onBack;
  final Future<void> Function(String) onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackLink(onTap: onBack),
        _StepHeader(
          icon: LucideIcons.lock,
          title: 'Enter verification code',
          subtitle: 'We sent a 6-digit code to $destination',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 8),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: vcare.muted.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: vcare.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: vcare.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: VCareColors.primary, width: 2),
            ),
          ),
          onChanged: (v) {
            if (v.length == 6) onVerify(v);
          },
        ),
        const SizedBox(height: 8),
        if (error != null)
          Text(error!, style: TextStyle(fontSize: 12, color: VCareColors.destructive), textAlign: TextAlign.center)
        else
          Text(
            'Demo code: $_demoOtp',
            style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Verify',
          icon: LucideIcons.arrowRight,
          loading: loadingKey == 'verify',
          onPressed: otpController.text.length >= 6 && loadingKey == null
              ? () => onVerify(otpController.text)
              : null,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: resendIn > 0 ? null : onResend,
            child: Text(
              resendIn > 0 ? 'Resend in ${resendIn}s' : 'Resend code',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: resendIn > 0 ? vcare.mutedForeground : VCareColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    required this.loadingKey,
    required this.error,
    required this.passwordController,
    required this.onBack,
    required this.onSubmit,
  });

  final String? loadingKey;
  final String? error;
  final TextEditingController passwordController;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackLink(onTap: onBack),
        _StepHeader(
          icon: LucideIcons.keyRound,
          title: 'Welcome back',
          subtitle: 'Enter your password for ${HomeMockData.member.fullName}',
        ),
        const SizedBox(height: 16),
        _VcareTextField(
          controller: passwordController,
          obscureText: true,
          hint: 'Password',
          prefix: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(LucideIcons.lock, size: 16, color: vcare.mutedForeground),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: TextStyle(fontSize: 12, color: VCareColors.destructive)),
        ],
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Sign in',
          icon: LucideIcons.arrowRight,
          loading: loadingKey == 'finish',
          onPressed: loadingKey != null ? null : onSubmit,
        ),
      ],
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter({required this.vcare});

  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.4),
        border: Border(top: BorderSide(color: vcare.border)),
      ),
      child: Column(
        children: [
          Text(
            "By continuing you agree to VCare's Terms of Service and Privacy Policy.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: vcare.mutedForeground, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shieldCheck, size: 14, color: vcare.mutedForeground),
              const SizedBox(width: 6),
              Text(
                'HIPAA COMPLIANT · SECURE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: vcare.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: VCareColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: VCareColors.primary, size: 24),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: vcare.mutedForeground, height: 1.35),
        ),
      ],
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(LucideIcons.arrowLeft, size: 14, color: vcare.mutedForeground),
        label: Text('Back', style: TextStyle(fontSize: 12, color: vcare.mutedForeground)),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
      ),
    );
  }
}

class _MethodTab extends StatelessWidget {
  const _MethodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Expanded(
      child: Material(
        color: selected ? vcare.card : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? VCareColors.primary : vcare.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VcareTextField extends StatelessWidget {
  const _VcareTextField({
    required this.controller,
    this.hint,
    this.prefix,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String? hint;
  final Widget? prefix;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: vcare.mutedForeground.withValues(alpha: 0.6)),
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: vcare.muted.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: vcare.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: vcare.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: VCareColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    this.loading = false,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: VCareColors.primary,
          foregroundColor: VCareColors.primaryForeground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VCareColors.primaryForeground,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.arrowRight, size: 16),
                ],
              ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.child,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final Widget child;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    child,
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
        ),
      ),
    );
  }
}
