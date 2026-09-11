import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_repository_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/state/feature_access_state.dart';

part 'feature_access_state_provider.g.dart';

@Riverpod(keepAlive: true)
class FeatureAccessStateNotifier extends _$FeatureAccessStateNotifier {
  @override
  FeatureAccessState build() => const FeatureAccessState();

  Future<void> refreshFromApi({
    bool forceRefresh = false,
    void Function(FeatureAccess? data)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(featureAccessRepositoryProvider)
        .fetchFeatureAccess(forceRefresh: forceRefresh);

    if (response.isFailure) {
      if (ref.mounted) {
        state = state.failure(response.failureOrNull?.message);
      }
      onCompleted?.call(null);
      return;
    }

    final result = response.dataOrNull!;
    if (ref.mounted) {
      state = state.success(result);
    }
    onCompleted?.call(result);
  }

  void reset() {
    if (!ref.mounted) return;
    state = state.reset();
  }
}
