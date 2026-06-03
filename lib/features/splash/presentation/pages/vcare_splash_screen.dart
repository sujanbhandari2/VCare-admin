import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:flutter_template/features/home/data/vcare_assets.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
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
                Image.asset(
                  VCareAssets.logo,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    VCareAssets.member,
                    width: 56,
                    height: 56,
                  ),
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
