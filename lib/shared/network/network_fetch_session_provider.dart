import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_fetch_session_provider.g.dart';

/// Tracks whether list screens should bypass HTTP cache on their first load
/// after a cold app start. Set to [false] once bootstrap fetches complete.
@Riverpod(keepAlive: true)
class NetworkFetchSession extends _$NetworkFetchSession {
  @override
  bool build() => true;

  void markSessionHydrated() => state = false;

  void resetSession() => state = true;
}
