import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/core/styles/text_scale_provider.dart';
import 'package:vcare_admin/core/styles/theme_appearance_provider.dart';
import 'package:vcare_admin/core/styles/theme_mode_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/inapp_update/presentation/providers/remote_config_app_update_state_provider.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/l10n/l10n.dart';

import '../core/services/firebase/firebase_remote_config_service.dart';

/// Main App Widget
///
class MyApp extends ConsumerStatefulWidget {
  /// Creates new instance of [MyApp]
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<RemoteConfigUpdate>? _remoteConfigUpdateSubscription;

  @override
  void initState() {
    super.initState();

    // Listening the firebase config value changes for update.
    _remoteConfigUpdateSubscription = FirebaseRemoteConfigService
        .instance
        .onConfigUpdated
        .listen((data) {
          if (data.updatedKeys.contains('flutter_template_config')) {
            _checkForUpdate();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    // Tear down StatefulShellRoute on logout only. Refreshing on login races with
    // context.goNamed(home) and remounts StatefulNavigationShell with the same
    // GlobalKey (Duplicate GlobalKey / inactive element assertions).
    ref.listen(userLoggedInStateProvider, (previous, next) {
      if (previous == next) return;
      if (previous == true && next == false) {
        AppRouter.refreshNotifier.refresh();
      }
    });

    final locale = ref.watch(localeStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeAppearance = ref.watch(themeAppearanceProvider);
    final textScale = ref.watch(textScaleProvider);

    return MaterialApp.router(
      title: "VCare client",
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(
        seedColor: themeAppearance.seedColor,
        dynamicSchemeVariant: themeAppearance.colorSchemeStyle.variant,
        contrastLevel: themeAppearance.contrastMode.level,
      ),
      darkTheme: AppTheme.dark(
        seedColor: themeAppearance.seedColor,
        dynamicSchemeVariant: themeAppearance.colorSchemeStyle.variant,
        contrastLevel: themeAppearance.contrastMode.level,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale.factor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: AppRouter.router,
    );
  }

  Future<void> _checkForUpdate() async {
    if (!mounted) return;
    FirebaseRemoteConfigService.instance.refetch().then((fetched) {
      if (fetched) {
        ref.read(remoteConfigAppUpdateStateProvider.notifier).checkForUpdate();
      }
    });
  }

  @override
  void dispose() {
    try {
      _remoteConfigUpdateSubscription?.cancel();
    } catch (_) {}
    super.dispose();
  }
}
