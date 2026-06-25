import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_repository_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_summary_state_provider.dart';

import '../../../../fixtures/repositories/fake_commission_repository.dart';

void main() {
  group('CommissionSummaryStateNotifier', () {
    late FakeCommissionRepository repository;
    late ProviderContainer container;

    const sampleSummary = CommissionSummary(
      totalSales: '0',
      totalCommission: '0',
    );

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
      expect(state.data, sampleSummary);
      expect(state.fetching, isFalse);
      expect(repository.fetchSummaryCallCount, 1);
    });

    test('fetchSummary sets failure on error', () async {
      repository.fetchSummaryResult = Failure(
        HttpException(title: 'Error', message: 'Summary failed'),
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
