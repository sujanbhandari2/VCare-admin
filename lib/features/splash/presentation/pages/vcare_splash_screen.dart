import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/home/data/vcare_assets.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_state_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/widgets/tenant_branded_image.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

class VcareSplashScreen extends ConsumerStatefulWidget {
  const VcareSplashScreen({super.key});

  @override
  ConsumerState<VcareSplashScreen> createState() => _VcareSplashScreenState();
}

class _VcareSplashScreenState extends ConsumerState<VcareSplashScreen> {
  static const _delay = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleNavigate());
  }

  void _scheduleNavigate() {
    if (Platform.isAndroid) {
      _navigate();
      return;
    }
    Future.delayed(_delay, _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final isLoggedIn = ref.read(userLoggedInStateProvider);
    context.goNamed(
      isLoggedIn ? AppRouter.home.toPathName : AppRouter.login.toPathName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final logoUrl = ref.watch(tenantBrandingStateProvider).branding.logoUrl;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor,
                vcare.gradientCard.colors.first.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TenantBrandedImage(
                  source: logoUrl,
                  height: 48,
                  fallbackAsset: VCareAssets.logo,
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
