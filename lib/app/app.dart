import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/app/router/app_router_provider.dart';
import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/core/styles/vcare_scroll_behavior.dart';
import 'package:vcare_admin/core/styles/text_scale_provider.dart';
import 'package:vcare_admin/shared/widgets/vcare_keyboard_dismiss_scope.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/inapp_update/presentation/providers/remote_config_app_update_state_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_state_provider.dart';
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
    // Remove the StatefulShellRoute from the page stack on logout.
    ref.listen(userLoggedInStateProvider, (previous, next) {
      if (previous == next) return;
      if (previous == true && next == false) {
        AppRouter.refreshNotifier.refresh();
        // Keep slug-keyed branding cache; reset active theme to default tenant.
        unawaited(
          ref
              .read(tenantBrandingStateProvider.notifier)
              .resetActiveToDefaultTenant(),
        );
      }
      if (previous == false && next == true) {
        unawaited(
          ref.read(tenantBrandingStateProvider.notifier).refreshFromApi(),
        );
      }
    });

    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeStateProvider);
    final textScale = ref.watch(textScaleProvider);
    final brandingState = ref.watch(tenantBrandingStateProvider);
    final theme = AppTheme.light(input: brandingState.branding.themeInput);

    return MaterialApp.router(
      // Rebuild the whole tree when the session router is swapped so no element
      // is carried over from the previous session.
      key: ValueKey(router),
      title: 'VCare Admin',
      scrollBehavior: VcareScrollBehavior(),
      debugShowCheckedModeBanner: false,
      // Light-only — matches web console (dark mode not wired).
      themeMode: ThemeMode.light,
      theme: theme,
      darkTheme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return VcareKeyboardDismissScope(
          child: MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(textScale.factor),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routerConfig: router,
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
