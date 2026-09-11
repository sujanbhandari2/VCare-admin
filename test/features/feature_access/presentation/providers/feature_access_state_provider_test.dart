import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';
import 'package:vcare_admin/features/feature_access/domain/repositories/feature_access_repository.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_repository_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_state_provider.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class _FakeFeatureAccessRepository implements FeatureAccessRepository {
  _FakeFeatureAccessRepository(this.result);

  EitherResponseOrException<FeatureAccess> result;
  var callCount = 0;
  var lastForceRefresh = false;

  @override
  Future<EitherResponseOrException<FeatureAccess>> fetchFeatureAccess({
    bool forceRefresh = false,
  }) async {
    callCount++;
    lastForceRefresh = forceRefresh;
    return result;
  }
}

void main() {
  group('FeatureAccessStateNotifier', () {
    test('refreshFromApi stores success and exposes flags', () async {
      final repository = _FakeFeatureAccessRepository(
        Success(
          const FeatureAccess(
            caseManagement: true,
            healthChat: false,
            membership: true,
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          featureAccessRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(featureAccessStateProvider.notifier)
          .refreshFromApi(forceRefresh: false);

      final state = container.read(featureAccessStateProvider);
      expect(state.isResolved, isTrue);
      expect(state.caseManagementEnabled, isTrue);
      expect(state.healthChatEnabled, isFalse);
      expect(state.membershipEnabled, isTrue);
      expect(repository.lastForceRefresh, isFalse);
    });

    test('refreshFromApi stores failure for retry', () async {
      final repository = _FakeFeatureAccessRepository(
        Failure(HttpException(message: 'Network error')),
      );

      final container = ProviderContainer(
        overrides: [
          featureAccessRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(featureAccessStateProvider.notifier)
          .refreshFromApi(forceRefresh: true);

      final state = container.read(featureAccessStateProvider);
      expect(state.hasError, isTrue);
      expect(state.error, 'Network error');
      expect(state.data, isNull);
    });

    test('reset returns to idle state', () async {
      final repository = _FakeFeatureAccessRepository(
        Success(
          const FeatureAccess(
            caseManagement: true,
            healthChat: true,
            membership: true,
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          featureAccessRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(featureAccessStateProvider.notifier)
          .refreshFromApi();
      container.read(featureAccessStateProvider.notifier).reset();

      final state = container.read(featureAccessStateProvider);
      expect(state.operation.status, OperationStatus.idle);
      expect(state.data, isNull);
    });
  });
}
