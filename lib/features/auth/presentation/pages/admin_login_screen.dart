import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/app/router/app_router_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_login_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/admin_login_state.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/admin_auth_brand_panel.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/admin_login_form.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/admin_tenant_picker.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/admin_two_factor_form.dart';
import 'package:vcare_admin/features/biometric_login/presentation/providers/biometric_login_state_provider.dart';
import 'package:vcare_admin/features/biometric_login/presentation/widgets/biometric_login_prompt_sheet.dart';
import 'package:vcare_admin/features/home/data/vcare_assets.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_state_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/widgets/tenant_branded_image.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
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
      description:
          'Use $biometricLabel to sign in faster next time. You can still keep using your password.',
      primaryLabel: 'Enable $biometricLabel',
      secondaryLabel: 'Skip',
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
    await ref.read(biometricLoginStateProvider.notifier).login(
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

  Future<void> _promptBiometricLogin() async {
    final biometricLabel =
        ref.read(biometricLoginStateProvider).status?.displayType ??
        'Biometric';

    await showBiometricPromptSheet(
      context,
      title: biometricLabel == 'Face ID'
          ? 'Align your face to sign in'
          : 'Use fingerprint to sign in',
      description:
          'Confirm with $biometricLabel to continue. We’ll handle the rest for you.',
      primaryLabel: 'Continue',
      secondaryLabel: 'Cancel',
      biometricLabel: biometricLabel,
      onPrimaryPressed: _loginWithBiometric,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AdminLoginState>(adminLoginStateProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage) {
        _showLoginError(error);
      }
    });

    final loginState = ref.watch(adminLoginStateProvider);
    final branding = ref.watch(tenantBrandingStateProvider).branding;
    final isWide = context.width >= 960;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: isWide
            ? Row(
                children: [
                  const Expanded(child: AdminAuthBrandPanel()),
                  Expanded(
                    child: _buildFormPanel(context, loginState, branding.logoUrl),
                  ),
                ],
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: _buildFormPanel(context, loginState, branding.logoUrl),
                ),
              ),
      ),
    );
  }

  Widget _buildFormPanel(
    BuildContext context,
    AdminLoginState loginState,
    String? logoUrl,
  ) {
    final biometricState = ref.watch(biometricLoginStateProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (context.width < 960) ...[
                Center(
                  child: TenantBrandedImage(
                    source: logoUrl,
                    height: 48,
                    fallbackAsset: VCareAssets.logo,
                  ),
                ),
                const SizedBox(height: 32),
              ],
              Text(
                _phaseTitleFor(loginState.phase),
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (loginState.phase == AdminLoginPhase.credentials) ...[
                const SizedBox(height: 8),
                Text(
                  'Enter your email and password to access the admin console.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.theme.hintColor,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              switch (loginState.phase) {
                AdminLoginPhase.credentials => AdminLoginForm(
                    isSubmitting: loginState.isSubmitting,
                    biometricAvailable: biometricState.isActive,
                    biometricLoading: biometricState.loading,
                    onBiometricPressed: biometricState.isActive
                        ? _promptBiometricLogin
                        : null,
                    onSubmit: (email, password) {
                      ref
                          .read(adminLoginStateProvider.notifier)
                          .submitCredentials(
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
                    onBack: () {
                      ref
                          .read(adminLoginStateProvider.notifier)
                          .backToCredentials();
                    },
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
                AdminLoginPhase.twoFactor => AdminTwoFactorForm(
                    key: ValueKey(loginState.challengeToken),
                    email: loginState.storedEmail,
                    expiresIn: loginState.expiresIn,
                    isVerifying: loginState.isSubmitting,
                    isResending: loginState.isResending,
                    onBack: () {
                      ref
                          .read(adminLoginStateProvider.notifier)
                          .backToCredentials();
                    },
                    onResend: () async {
                      await ref
                          .read(adminLoginStateProvider.notifier)
                          .sendTwoFactorCode(
                            onSuccess: () {
                              if (!mounted) {
                                return;
                              }
                              context.showVcareToast(
                                title: 'Code sent',
                                description:
                                    'A new verification code has been sent.',
                                variant: VcareToastVariant.success,
                              );
                            },
                          );
                    },
                    onVerify: ({required otp, required rememberMe}) {
                      ref
                          .read(adminLoginStateProvider.notifier)
                          .verifyTwoFactor(
                            otp: otp,
                            rememberMe: rememberMe,
                            onAuthenticated: (_) async {
                              await _handleBiometricEnrollmentPrompt();
                              _handleAuthenticated();
                            },
                            onError: (_) {},
                          );
                    },
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }

  String _phaseTitleFor(AdminLoginPhase phase) {
    return switch (phase) {
      AdminLoginPhase.credentials => 'Welcome back',
      AdminLoginPhase.tenantSelection => 'Select organization',
      AdminLoginPhase.twoFactor => 'Verify your identity',
    };
  }
}
