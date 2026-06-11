import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/data/vcare_mock_auth.dart';
import 'package:vcare_admin/features/auth/data/vcare_mock_lookup.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

enum _LoginMethod { phone, email }

enum _LoginStep {
  identify,
  verify,
  disambiguate,
  password,
  activate,
  onboard,
  biometric,
}

/// Login flow — parity with vcareapp [/login] + auth feature.
class VcareLoginScreen extends ConsumerStatefulWidget {
  const VcareLoginScreen({super.key});

  @override
  ConsumerState<VcareLoginScreen> createState() => _VcareLoginScreenState();
}

class _VcareLoginScreenState extends ConsumerState<VcareLoginScreen> {
  _LoginMethod _method = _LoginMethod.phone;
  _LoginStep _step = _LoginStep.identify;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(
    text: 'alex.rivera@example.com',
  );
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _dobController = TextEditingController();
  final _zipController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String? _loadingKey;
  String? _error;
  int _resendIn = 0;
  Timer? _resendTimer;
  LoginLookupBranch? _branch;
  LoginClientRecord? _selectedClient;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _dobController.dispose();
    _zipController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  String get _identifier => _method == _LoginMethod.phone
      ? _phoneController.text.trim()
      : _emailController.text.trim();

  String get _destination => _method == _LoginMethod.phone
      ? (_phoneController.text.isEmpty
            ? '+1 (555) 000-0000'
            : _phoneController.text)
      : (_emailController.text.isEmpty
            ? 'you@example.com'
            : _emailController.text);

  Future<void> _finishSignIn({String? name, String? email}) async {
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
    if (value != VcareMockLookup.demoOtp && value != '000000') {
      setState(() {
        _error = 'Invalid code. Try 123456 for the demo.';
        _loadingKey = null;
        _otpController.clear();
      });
      return;
    }

    final result = await VcareMockLookup.lookup(
      _identifier.isEmpty ? 'alex.rivera@example.com' : _identifier,
    );
    if (!mounted) return;

    setState(() {
      _branch = result;
      _loadingKey = null;
    });

    switch (result) {
      case LoginLookupNew():
        setState(() => _step = _LoginStep.onboard);
      case LoginLookupActivate(:final client):
        setState(() {
          _selectedClient = client;
          _step = _LoginStep.activate;
        });
      case LoginLookupPassword(:final client):
        setState(() {
          _selectedClient = client;
          _step = _LoginStep.password;
        });
      case LoginLookupDisambiguate():
        setState(() => _step = _LoginStep.disambiguate);
    }
  }

  Future<void> _demoBranch(String email) async {
    setState(() {
      _error = null;
      _method = _LoginMethod.email;
      _emailController.text = email;
      _loadingKey = 'demo';
    });
    final result = await VcareMockLookup.lookup(email);
    if (!mounted) return;
    setState(() {
      _branch = result;
      _loadingKey = null;
    });
    switch (result) {
      case LoginLookupNew():
        setState(() => _step = _LoginStep.onboard);
      case LoginLookupActivate(:final client):
        setState(() {
          _selectedClient = client;
          _step = _LoginStep.activate;
        });
      case LoginLookupPassword(:final client):
        setState(() {
          _selectedClient = client;
          _step = _LoginStep.password;
        });
      case LoginLookupDisambiguate():
        setState(() => _step = _LoginStep.disambiguate);
    }
  }

  Future<void> _finishSocial(String provider) async {
    setState(() => _loadingKey = provider);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await _finishSignIn();
  }

  void _goBack() {
    setState(() {
      _error = null;
      switch (_step) {
        case _LoginStep.verify:
          _step = _LoginStep.identify;
        case _LoginStep.disambiguate:
        case _LoginStep.password:
        case _LoginStep.activate:
        case _LoginStep.onboard:
          _step = _LoginStep.verify;
        case _LoginStep.biometric:
          _step = _branch is LoginLookupNew
              ? _LoginStep.onboard
              : _LoginStep.activate;
        case _LoginStep.identify:
          break;
      }
    });
  }

  void _submitDisambiguation() {
    final branch = _branch;
    if (branch is! LoginLookupDisambiguate) return;
    setState(() => _error = null);
    if (_dobController.text.length < 4 || _zipController.text.length < 3) {
      setState(
        () => _error = 'Please enter your birth year and ZIP to continue.',
      );
      return;
    }
    final zipPrefix = _zipController.text.length >= 3
        ? _zipController.text.substring(0, 3)
        : _zipController.text;
    final match = branch.clients.firstWhere(
      (c) => c.zipMasked.startsWith(zipPrefix),
      orElse: () => branch.clients.first,
    );
    setState(() {
      _selectedClient = match;
      _step = match.hasLogin ? _LoginStep.password : _LoginStep.activate;
    });
  }

  void _submitPassword() {
    setState(() => _error = null);
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Enter your password to continue.');
      return;
    }
    _finishSignIn(name: _selectedClient?.fullName, email: _identifier);
  }

  void _submitActivation() {
    setState(() => _error = null);
    if (_passwordController.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = "Passwords don't match.");
      return;
    }
    setState(() => _step = _LoginStep.biometric);
  }

  void _submitOnboard() {
    setState(() => _error = null);
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = "Passwords don't match.");
      return;
    }
    setState(() => _step = _LoginStep.biometric);
  }

  Future<void> _finishBiometric(bool enroll) async {
    setState(() => _loadingKey = enroll ? 'biometric-yes' : 'biometric-no');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final name =
        _selectedClient?.fullName ??
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();
    await _finishSignIn(name: name.isEmpty ? null : name, email: _identifier);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: LoginShell(
          body: switch (_step) {
            _LoginStep.identify => _buildIdentifyStep(context),
            _LoginStep.verify => _buildVerifyStep(context),
            _LoginStep.disambiguate => _buildDisambiguateStep(context),
            _LoginStep.password => _buildPasswordStep(context),
            _LoginStep.activate => _buildActivateStep(context),
            _LoginStep.onboard => _buildOnboardStep(context),
            _LoginStep.biometric => _buildBiometricStep(context),
          },
        ),
      ),
    );
  }

  Widget _buildIdentifyStep(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      children: [
        const LoginBrandHeader(),
        Row(
          children: [
            Expanded(
              child: LoginSocialButton(
                label: 'Google',
                loading: _loadingKey == 'google',
                onTap: () => _finishSocial('google'),
                child: SvgPicture.asset(
                  'assets/svg/google.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LoginSocialButton(
                label: 'Apple',
                loading: _loadingKey == 'apple',
                onTap: () => _finishSocial('apple'),
                child: SvgPicture.asset(
                  'assets/svg/apple.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ],
        ),
        const LoginOrDivider(),
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
                selected: _method == _LoginMethod.phone,
                onTap: () => setState(() => _method = _LoginMethod.phone),
              ),
              _MethodTab(
                label: 'Email',
                selected: _method == _LoginMethod.email,
                onTap: () => setState(() => _method = _LoginMethod.email),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_method == _LoginMethod.phone)
          LoginTextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            hint: '(555) 000-0000',
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
          )
        else
          LoginTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            hint: 'you@example.com',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                LucideIcons.mail,
                size: 16,
                color: vcare.mutedForeground,
              ),
            ),
          ),
        const SizedBox(height: 12),
        LoginPrimaryButton(
          label: 'Continue',
          icon: _method == _LoginMethod.phone
              ? LucideIcons.phone
              : LucideIcons.mail,
          loading: _loadingKey == 'send',
          onPressed: _loadingKey != null ? null : _sendCode,
        ),
        const SizedBox(height: 24),
        Text(
          'DEMO BRANCHES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: vcare.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final branch in const [
              ('New user', 'new@example.com'),
              ('Activate', 'activate@example.com'),
              ('Multi-match', 'duplicate@example.com'),
            ])
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: branch.$2 == 'duplicate@example.com' ? 0 : 8,
                  ),
                  child: _DemoBranchButton(
                    label: branch.$1,
                    loading: _loadingKey == 'demo',
                    onTap: () => _demoBranch(branch.$2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loadingKey != null ? null : () => _finishSignIn(),
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

  Widget _buildVerifyStep(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginBackButton(onBack: _goBack),
        LoginStepHeader(
          icon: LucideIcons.lock,
          title: 'Enter verification code',
          subtitle: Text.rich(
            TextSpan(
              text: 'We sent a 6-digit code to ',
              children: [
                TextSpan(
                  text: _destination,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        LoginOtpInput(
          controller: _otpController,
          onCompleted: _verifyCode,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(fontSize: 12, color: VCareColors.destructive),
            textAlign: TextAlign.center,
          )
        else
          Text.rich(
            TextSpan(
              text: 'Demo code: ',
              style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
              children: [
                TextSpan(
                  text: VcareMockLookup.demoOtp,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        LoginPrimaryButton(
          label: 'Verify',
          loading: _loadingKey == 'verify',
          onPressed: _otpController.text.length >= 6 && _loadingKey == null
              ? () => _verifyCode(_otpController.text)
              : null,
        ),
        const SizedBox(height: 20),
        Center(
          child: Text.rich(
            TextSpan(
              text: "Didn't get a code? ",
              style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
              children: [
                WidgetSpan(
                  child: TextButton(
                    onPressed: _resendIn > 0 ? null : _sendCode,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _resendIn > 0 ? 'Resend in ${_resendIn}s' : 'Resend code',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _resendIn > 0
                            ? vcare.mutedForeground
                            : VCareColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisambiguateStep(BuildContext context) {
    final branch = _branch;
    if (branch is! LoginLookupDisambiguate) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginBackButton(onBack: _goBack),
        const LoginStepHeader(
          icon: LucideIcons.users,
          title: 'We found a few matches',
          subtitle: Text("Help us pick the right record. We'll only ask once."),
        ),
        for (final client in branch.clients) ...[
          LoginClientCard(
            fullName: client.fullName,
            detail: 'DOB ${client.dobMasked} · ZIP ${client.zipMasked}',
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        LoginTextField(
          controller: _dobController,
          keyboardType: TextInputType.number,
          hint: 'Year of birth (e.g. 1985)',
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        LoginTextField(
          controller: _zipController,
          keyboardType: TextInputType.number,
          hint: 'ZIP code',
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(fontSize: 12, color: VCareColors.destructive),
          ),
        ],
        const SizedBox(height: 12),
        LoginPrimaryButton(label: 'Continue', onPressed: _submitDisambiguation),
      ],
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    final client = _selectedClient;
    if (client == null) return const SizedBox.shrink();
    final branch = _branch;
    final firstName = client.fullName.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginBackButton(onBack: _goBack),
        LoginStepHeader(
          icon: LucideIcons.keyRound,
          title: 'Welcome back, $firstName',
          subtitle: const Text('Enter your password to continue.'),
        ),
        LoginTextField(
          controller: _passwordController,
          obscureText: true,
          hint: 'Password',
          autofocus: true,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(fontSize: 12, color: VCareColors.destructive),
          ),
        ],
        if (branch is LoginLookupPassword && branch.biometricEnrolled) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                _finishSignIn(name: client.fullName, email: _identifier),
            icon: const Icon(LucideIcons.fingerprint, size: 16),
            label: const Text('Use passkey instead'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        LoginPrimaryButton(
          label: 'Sign in',
          loading: _loadingKey == 'finish',
          onPressed: _loadingKey != null ? null : _submitPassword,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {},
          child: Text(
            'Forgot password?',
            style: TextStyle(
              fontSize: 12,
              color: context.vcare.mutedForeground,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivateStep(BuildContext context) {
    final client = _selectedClient;
    if (client == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginBackButton(onBack: _goBack),
        LoginStepHeader(
          icon: LucideIcons.shieldCheck,
          title: 'Activate your account',
          subtitle: Text(
            'We found your VCare record (${client.memberId}). Set up your login to continue.',
          ),
        ),
        LoginClientCard(
          fullName: client.fullName,
          detail: 'DOB ${client.dobMasked} · ZIP ${client.zipMasked}',
        ),
        const SizedBox(height: 16),
        LoginTextField(
          controller: _passwordController,
          obscureText: true,
          hint: 'Create a password (min 8 chars)',
        ),
        const SizedBox(height: 12),
        LoginTextField(
          controller: _confirmPasswordController,
          obscureText: true,
          hint: 'Confirm password',
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(fontSize: 12, color: VCareColors.destructive),
          ),
        ],
        const SizedBox(height: 12),
        LoginPrimaryButton(label: 'Continue', onPressed: _submitActivation),
      ],
    );
  }

  Widget _buildOnboardStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginBackButton(onBack: _goBack),
        const LoginStepHeader(
          icon: LucideIcons.userPlus,
          title: "Let's set up your account",
          subtitle: Text("A few details and you're in."),
        ),
        Row(
          children: [
            Expanded(
              child: LoginTextField(
                controller: _firstNameController,
                hint: 'First name',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LoginTextField(
                controller: _lastNameController,
                hint: 'Last name',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LoginTextField(
          controller: _passwordController,
          obscureText: true,
          hint: 'Create a password (min 8 chars)',
        ),
        const SizedBox(height: 12),
        LoginTextField(
          controller: _confirmPasswordController,
          obscureText: true,
          hint: 'Confirm password',
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(fontSize: 12, color: VCareColors.destructive),
          ),
        ],
        const SizedBox(height: 12),
        LoginPrimaryButton(label: 'Continue', onPressed: _submitOnboard),
      ],
    );
  }

  Widget _buildBiometricStep(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginStepHeader(
          icon: LucideIcons.fingerprint,
          title: 'Enable quick sign-in?',
          subtitle: Text(
            'Use your device biometrics or a passkey to skip passwords next time.',
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VCareColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: VCareColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.checkCircle2,
                size: 20,
                color: VCareColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your credential is stored on this device only. You can remove it any time from Settings → Security.',
                  style: TextStyle(
                    fontSize: 12,
                    color: vcare.mutedForeground,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LoginPrimaryButton(
          label: 'Enable & finish',
          icon: LucideIcons.fingerprint,
          loading: _loadingKey == 'biometric-yes',
          onPressed: _loadingKey != null ? null : () => _finishBiometric(true),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _loadingKey != null ? null : () => _finishBiometric(false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _loadingKey == 'biometric-no'
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Maybe later',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
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
        elevation: selected ? 1 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
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

class _DemoBranchButton extends StatelessWidget {
  const _DemoBranchButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.muted.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
