// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_fetch_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks whether list screens should bypass HTTP cache on their first load
/// after a cold app start. Set to [false] once bootstrap fetches complete.

@ProviderFor(NetworkFetchSession)
final networkFetchSessionProvider = NetworkFetchSessionProvider._();

/// Tracks whether list screens should bypass HTTP cache on their first load
/// after a cold app start. Set to [false] once bootstrap fetches complete.
final class NetworkFetchSessionProvider
    extends $NotifierProvider<NetworkFetchSession, bool> {
  /// Tracks whether list screens should bypass HTTP cache on their first load
  /// after a cold app start. Set to [false] once bootstrap fetches complete.
  NetworkFetchSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkFetchSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkFetchSessionHash();

  @$internal
  @override
  NetworkFetchSession create() => NetworkFetchSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$networkFetchSessionHash() =>
    r'9b3ea08f5aafd0c4a80e13234cef3f85be21cc94';

/// Tracks whether list screens should bypass HTTP cache on their first load
/// after a cold app start. Set to [false] once bootstrap fetches complete.

abstract class _$NetworkFetchSession extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
