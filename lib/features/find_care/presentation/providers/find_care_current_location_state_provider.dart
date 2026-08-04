import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/find_care/domain/entities/current_location_result.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_location_repository_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_location_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/state/find_care_current_location_state.dart';

part 'find_care_current_location_state_provider.g.dart';

@Riverpod(keepAlive: true)
class FindCareCurrentLocationStateNotifier
    extends _$FindCareCurrentLocationStateNotifier {
  @override
  FindCareCurrentLocationState build() => const FindCareCurrentLocationState();

  Future<bool> hasPermission() {
    return ref.read(findCareLocationRepositoryProvider).hasPermission();
  }

  void markAutoPromptCompleted() {
    if (!ref.mounted) return;
    if (state.autoPromptCompleted) return;
    state = state.copyWith(autoPromptCompleted: true);
  }

  Future<CurrentLocationResult> detectCurrentLocation({
    bool requestPermission = true,
  }) async {
    if (state.detecting) {
      return const CurrentLocationFailure(
        reason: CurrentLocationFailureReason.error,
        message: 'Location detection is already in progress.',
      );
    }

    if (ref.mounted) {
      state = state.loading();
    }

    final result = await ref
        .read(findCareLocationRepositoryProvider)
        .detectCurrentLocation(requestPermission: requestPermission);

    if (!ref.mounted) return result;

    switch (result) {
      case CurrentLocationSuccess(:final location):
        await ref
            .read(findCareSearchLocationProvider.notifier)
            .setFromCurrentLocation(location);
        if (ref.mounted) {
          state = state.success(
            location.copyWith(fromCurrentLocation: true),
          );
        }
        return result;
      case CurrentLocationFailure(:final userMessage, :final reason):
        state = state.failure(message: userMessage, reason: reason);
        return result;
    }
  }
}
