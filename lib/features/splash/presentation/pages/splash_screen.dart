import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_template/features/onboarding/presentation/providers/is_already_onboarded_provider.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';
import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/features/auth/presentation/providers/user_logged_in_state_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Duration _navigationDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Calling function to handle navigation
      _handleNavigate();
    });
  }

  /// Method to handle navigation after certain time
  ///
  void _handleNavigate() {
    if (Platform.isAndroid) {
      _navigate();
      return;
    }

    Future.delayed(_navigationDelay, _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final isLoggedIn = ref.read(userLoggedInStateProvider);
    final isAlreadyOnboarded = ref.read(isAlreadyOnboardedProvider);

    context.goNamed(
      isLoggedIn
          ? AppRouter.home.toPathName
          : isAlreadyOnboarded
          ? AppRouter.login.toPathName
          : AppRouter.onboarding.toPathName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Center(
          child: Text(
            context.flavorConfiguration.flavor.localizedAppName(context),
            style: context.textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
