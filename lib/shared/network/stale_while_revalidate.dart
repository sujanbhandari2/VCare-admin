import 'dart:async';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';

/// Fetches data using stale-while-revalidate semantics.
///
/// When [forceNetwork] is true and [currentData] is null, a cache read
/// (`forceRefresh: false`) runs in parallel so HTTP-cached data can appear
/// immediately. The network fetch always runs last and its result wins.
Future<void> fetchStaleWhileRevalidate<T>({
  required bool Function() isCurrentGeneration,
  required T? currentData,
  required bool forceNetwork,
  required Future<EitherResponseOrException<T>> Function({
    required bool forceRefresh,
  })
  fetch,
  required void Function(T data) onStaleData,
  required void Function(EitherResponseOrException<T> result) onFinalResult,
}) async {
  if (forceNetwork && currentData == null) {
    unawaited(() async {
      final cacheResult = await fetch(forceRefresh: false);
      if (!isCurrentGeneration()) return;

      cacheResult.when(
        failure: (_) {},
        success: onStaleData,
      );
    }());
  }

  final result = await fetch(forceRefresh: forceNetwork);
  if (!isCurrentGeneration()) return;

  onFinalResult(result);
}
