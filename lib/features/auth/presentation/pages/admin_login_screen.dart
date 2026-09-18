import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/app/router/app_router_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_login_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/admin_login_state.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/admin_login_form.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/admin_tenant_picker.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_two_factor_step.dart';
import 'package:vcare_admin/features/biometric_login/presentation/providers/biometric_login_state_provider.dart';
import 'package:vcare_admin/features/biometric_login/presentation/widgets/biometric_login_method_picker.dart';
import 'package:vcare_admin/features/biometric_login/presentation/widgets/biometric_login_prompt_sheet.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_state_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  static const _resendCooldownSeconds = 90;

  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _resendIn = 0;
  bool _twoFactorRememberMe = false;
  String? _twoFactorLocalError;
  String? _startedChallengeToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(adminAuthSessionProvider);
      if (session.isAuthenticated && mounted) {
        startAuthenticatedRouterSession(ref);
        return;
      }

      ref.read(biometricLoginStateProvider.notifier).refreshStatus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  /// Completes sign-in without awaiting network side effects first.
  ///
  /// Awaiting auth/me or branding here used to leave the login screen mounted
  /// (and briefly reset to credentials) before home appeared. Match the agent
  /// flow: fire side effects, then swap the router so home is the first frame.
  void _handleAuthenticated() {
    ref.read(networkFetchSessionProvider.notifier).resetSession();
    final session = ref.read(adminAuthSessionProvider);
    final tenantSlug = session.user?.currentTenant.slug;

    unawaited(ref.read(authMeStateProvider.notifier).fetchMe());
    unawaited(
      ref.read(tenantBrandingStateProvider.notifier).refreshFromApi(
            tenantSlug: tenantSlug,
          ),
    );

    if (mounted) {
      context.showVcareToast(
        title: 'Signed in successfully',
        variant: VcareToastVariant.success,
      );
    }

    // Must be last: this disposes the router that owns this screen and starts
    // a fresh session already at home — no login flash, no shell GlobalKey clash.
    startAuthenticatedRouterSession(ref);
  }

  void _showLoginError(String message) {
    context.showVcareToast(
      title: message,
      variant: VcareToastVariant.destructive,
    );
  }

  void _backToCredentials() {
    _resendTimer?.cancel();
    setState(() {
      _resendIn = 0;
      _twoFactorRememberMe = false;
      _twoFactorLocalError = null;
      _startedChallengeToken = null;
      _otpController.clear();
    });
    ref.read(adminLoginStateProvider.notifier).backToCredentials();
  }

  void _startResendTimer({int seconds = _resendCooldownSeconds}) {
    _resendTimer?.cancel();
    setState(() => _resendIn = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendIn <= 1) {
        timer.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  void _prepareTwoFactorStep(AdminLoginState loginState) {
    final token = loginState.challengeToken;
    if (loginState.phase != AdminLoginPhase.twoFactor ||
        token == null ||
        token == _startedChallengeToken) {
      return;
    }
    _startedChallengeToken = token;
    _otpController.clear();
    _twoFactorLocalError = null;
    _twoFactorRememberMe = false;
    _startResendTimer();
  }

  void _verifyTwoFactor(String code) {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _twoFactorLocalError = 'Enter a valid 6-digit code');
      return;
    }

    setState(() => _twoFactorLocalError = null);
    ref.read(adminLoginStateProvider.notifier).verifyTwoFactor(
          otp: code,
          rememberMe: _twoFactorRememberMe,
          onAuthenticated: (_) async {
            await _handleBiometricEnrollmentPrompt();
            _handleAuthenticated();
          },
          onError: (_) {},
        );
  }

  Future<void> _resendTwoFactor() async {
    if (_resendIn > 0) {
      return;
    }

    await ref.read(adminLoginStateProvider.notifier).sendTwoFactorCode(
          onSuccess: () {
            if (!mounted) {
              return;
            }
            _otpController.clear();
            setState(() => _twoFactorLocalError = null);
            _startResendTimer();
            context.showVcareToast(
              title: 'Code sent',
              description: 'A new verification code has been sent.',
              variant: VcareToastVariant.success,
            );
          },
        );
  }

  Future<void> _handleBiometricEnrollmentPrompt() async {
    final session = ref.read(adminAuthSessionProvider);
    final accountId = session.user?.id.trim() ?? '';
    final biometricLabel =
        ref.read(biometricLoginStateProvider).status?.displayType ??
            'Biometric';
    final shouldEnroll = await showBiometricPromptSheet(
      context,
      title: biometricLabel == 'Face ID'
          ? 'Enable Face ID?'
          : 'Enable fingerprint?',
      description: 'Use Biometric to log in faster from this device.',
      primaryLabel: 'Enable Biometric',
      secondaryLabel: 'Maybe later',
      biometricLabel: biometricLabel,
      onPrimaryPressed: () async {
        await ref.read(biometricLoginStateProvider.notifier).enroll(
              accessToken: session.accessToken ?? '',
              accountId: accountId,
              accountEmail: session.user?.email,
              onError: (message) {
                if (message == null || !mounted) {
                  return;
                }
                context.showVcareToast(
                  title: 'Biometric enrollment failed',
                  description: message,
                  variant: VcareToastVariant.destructive,
                );
              },
            );
      },
    );

    if (shouldEnroll != true) {
      return;
    }
  }

  Future<void> _loginWithBiometric() async {
    final method = await resolveBiometricLoginMethod(context);
    if (method == null || !mounted) {
      return;
    }

    await ref.read(biometricLoginStateProvider.notifier).login(
          preferredBiometric: method.nativePreference,
          biometricReason: method.reason,
          onAuthenticated: (_) async {
            _handleAuthenticated();
          },
          onError: (message) {
            if (message == null || !mounted) {
              return;
            }
            _showLoginError(message);
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AdminLoginState>(adminLoginStateProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage) {
        _showLoginError(error);
      }
      if (next.phase == AdminLoginPhase.twoFactor &&
          next.challengeToken != null &&
          next.challengeToken != _startedChallengeToken) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _prepareTwoFactorStep(next);
        });
      }
    });

    final loginState = ref.watch(adminLoginStateProvider);
    final biometricState = ref.watch(biometricLoginStateProvider);

    final showBack = loginState.phase == AdminLoginPhase.tenantSelection ||
        loginState.phase == AdminLoginPhase.twoFactor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: LoginShell(
          onBack: showBack ? _backToCredentials : null,
          body: switch (loginState.phase) {
            AdminLoginPhase.credentials => AdminLoginForm(
                isSubmitting: loginState.isSubmitting,
                biometricAvailable: biometricState.isActive,
                biometricLoading: biometricState.loading,
                onBiometricPressed:
                    biometricState.isActive ? _loginWithBiometric : null,
                onSubmit: (email, password) {
                  ref.read(adminLoginStateProvider.notifier).submitCredentials(
                        email: email,
                        password: password,
                        onAuthenticated: (_) async {
                          _handleAuthenticated();
                        },
                        onError: (_) {},
                      );
                },
              ),
            AdminLoginPhase.tenantSelection => AdminTenantPicker(
                tenants: loginState.tenantOptions,
                isSubmitting: loginState.isSubmitting,
                onContinue: (tenantSlug) {
                  ref.read(adminLoginStateProvider.notifier).submitTenant(
                        tenantSlug: tenantSlug,
                        onAuthenticated: (_) async {
                          _handleAuthenticated();
                        },
                        onError: (_) {},
                      );
                },
              ),
            AdminLoginPhase.twoFactor => LoginTwoFactorStep(
                key: ValueKey(loginState.challengeToken),
                destination: loginState.storedEmail?.trim() ?? '',
                otpController: _otpController,
                error: _twoFactorLocalError,
                loading: loginState.isSubmitting,
                resendIn: _resendIn,
                resendLoading: loginState.isResending,
                rememberMe: _twoFactorRememberMe,
                onRememberMeChanged: (value) {
                  setState(() => _twoFactorRememberMe = value);
                },
                onCompleted: _verifyTwoFactor,
                onVerify: () => _verifyTwoFactor(_otpController.text),
                onResend: () => unawaited(_resendTwoFactor()),
                onChanged: (_) {
                  if (_twoFactorLocalError != null) {
                    setState(() => _twoFactorLocalError = null);
                  } else {
                    setState(() {});
                  }
                },
              ),
          },
        ),
      ),
    );
  }
}
