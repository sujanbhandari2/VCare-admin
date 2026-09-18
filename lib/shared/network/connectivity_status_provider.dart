import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/connectivity/connectivity_service.dart';

/// Emits whether the device currently has a usable network transport.
final connectivityOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ConnectivityService.instance;
  yield await service.hasActiveConnection();
  yield* service.onConnectivityChanged.map(
    ConnectivityService.hasUsableNetwork,
  );
});

/// Latest online status. Defaults to online while the first check is in flight
/// so cold start does not flash an offline edge state.
final isNetworkOnlineProvider = Provider<bool>((ref) {
  return ref
      .watch(connectivityOnlineProvider)
      .maybeWhen(data: (online) => online, orElse: () => true);
});
