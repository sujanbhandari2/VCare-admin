import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_login_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/admin_login_state.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/admin_auth_brand_panel.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/admin_login_form.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/admin_tenant_picker.dart';
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
        context.goNamed(AppRouter.home.toPathName);
      }
    });
  }

  Future<void> _handleAuthenticated() async {
    ref.read(networkFetchSessionProvider.notifier).resetSession();
    final session = ref.read(adminAuthSessionProvider);
    final tenantSlug = session.user?.currentTenant.slug;
    await Future.wait([
      ref.read(authMeStateProvider.notifier).fetchMe(),
      ref.read(tenantBrandingStateProvider.notifier).refreshFromApi(
            tenantSlug: tenantSlug,
          ),
    ]);

    if (!mounted) {
      return;
    }

    context.showVcareToast(
      title: 'Signed in successfully',
      variant: VcareToastVariant.success,
    );
    context.goNamed(AppRouter.home.toPathName);
  }

  void _showLoginError(String message) {
    context.showVcareToast(
      title: message,
      variant: VcareToastVariant.destructive,
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
                loginState.phase == AdminLoginPhase.credentials
                    ? 'Welcome back'
                    : 'Select organization',
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
              if (loginState.phase == AdminLoginPhase.credentials)
                AdminLoginForm(
                  isSubmitting: loginState.isSubmitting,
                  onSubmit: (email, password) {
                    ref.read(adminLoginStateProvider.notifier).submitCredentials(
                      email: email,
                      password: password,
                      onAuthenticated: (_) => _handleAuthenticated(),
                      onError: (_) {},
                    );
                  },
                )
              else
                AdminTenantPicker(
                  tenants: loginState.tenantOptions,
                  isSubmitting: loginState.isSubmitting,
                  onBack: () {
                    ref.read(adminLoginStateProvider.notifier).backToCredentials();
                  },
                  onContinue: (tenantSlug) {
                    ref.read(adminLoginStateProvider.notifier).submitTenant(
                      tenantSlug: tenantSlug,
                      onAuthenticated: (_) => _handleAuthenticated(),
                      onError: (_) {},
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
