import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_filter.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_repository_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_summary_state_provider.dart';

import '../../../../fixtures/repositories/fake_commission_repository.dart';

void main() {
  group('CommissionSummaryStateNotifier', () {
    late FakeCommissionRepository repository;
    late ProviderContainer container;

    const sampleSummary = CommissionSummary(totalSales: 0, totalCommission: 0);

    setUp(() {
      repository = FakeCommissionRepository();
      container = ProviderContainer(
        overrides: [
          commissionRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('fetchSummary loads commission summary', () async {
      repository.fetchSummaryResult = Success(sampleSummary);

      await container
          .read(commissionSummaryStateProvider.notifier)
          .fetchSummary();

      final state = container.read(commissionSummaryStateProvider);
      expect(state.data?.totalSales, 0);
      expect(state.data?.totalCommission, 0);
      expect(state.data?.upcomingCount, 0);
      expect(state.data?.needsAttentionCount, 0);
      expect(state.fetching, isFalse);
      expect(repository.fetchSummaryCallCount, 1);
      expect(repository.fetchHistoryCallCount, 2);
      expect(repository.historyTypesCalled, ['upcoming', 'commission']);
      expect(repository.lastSummaryAgencyGroupId, isNull);
      expect(repository.lastSummaryStatus, isNull);
    });

    test('setFilter sends mapped API status', () async {
      repository.fetchSummaryResult = Success(sampleSummary);

      final notifier = container.read(commissionSummaryStateProvider.notifier);
      await notifier.setFilter(CommissionFilter.paid);

      expect(notifier.filter, CommissionFilter.paid);
      expect(repository.lastSummaryStatus, 'PAID');
      expect(repository.lastSummaryAgencyGroupId, isNull);
    });

    test('fetchSummary sets failure on error', () async {
      repository.fetchSummaryResult = Failure(
        HttpException(
          title: 'Error',
          message: 'Summary failed',
          errorType: HttpErrorType.client,
        ),
      );

      await container
          .read(commissionSummaryStateProvider.notifier)
          .fetchSummary();

      final state = container.read(commissionSummaryStateProvider);
      expect(state.data, isNull);
      expect(state.error, 'Summary failed');
    });
  });
}
