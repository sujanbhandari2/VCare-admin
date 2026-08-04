// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Router for the current sign-in.
///
/// Invalidate this through [startAuthenticatedRouterSession] once a sign-in has
/// been persisted. See [AppRouter.startSession] for why a router must not be
/// shared across sessions.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Router for the current sign-in.
///
/// Invalidate this through [startAuthenticatedRouterSession] once a sign-in has
/// been persisted. See [AppRouter.startSession] for why a router must not be
/// shared across sessions.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Router for the current sign-in.
  ///
  /// Invalidate this through [startAuthenticatedRouterSession] once a sign-in has
  /// been persisted. See [AppRouter.startSession] for why a router must not be
  /// shared across sessions.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'1fb795ae8e08da7540915fb5c7afacf932268962';
