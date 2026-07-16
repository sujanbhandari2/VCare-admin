import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';

/// Fetches data using stale-while-revalidate semantics.
///
/// Callers should keep showing any existing [currentData] while the network
/// request runs. The network fetch always runs last and its result wins.
///
/// Parallel HTTP-cache reads are not started here because they duplicate
/// network calls on cold loads and can race with the network response.
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
  final result = await fetch(forceRefresh: forceNetwork);
  if (!isCurrentGeneration()) return;

  onFinalResult(result);
}
