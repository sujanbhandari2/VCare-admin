import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_filter.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_transaction_status.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_repository_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_sales_history_state_provider.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

import '../../../../fixtures/repositories/fake_commission_repository.dart';

void main() {
  group('CommissionSalesHistoryState', () {
    late FakeCommissionRepository repository;
    late ProviderContainer container;

    const sampleItem = SalesHistoryItem(
      id: 'sale-1',
      payerId: 'payer-1',
      payer: SalesHistoryPayer(id: 'payer-1', name: 'Jane Doe'),
      status: SalesTransactionStatus.paid,
      amount: 500,
      currency: 'usd',
      transactionDate: '2026-07-01T12:00:00.000Z',
    );

    const agencyProfile = LocalProfile(
      firstName: 'Agency',
      lastName: 'Agent',
      email: 'agent@example.com',
      phone: '',
      dob: '',
      agencyGroupId: 'agency-group-1',
    );

    setUp(() {
      repository = FakeCommissionRepository();
      container = ProviderContainer(
        overrides: [
          commissionRepositoryProvider.overrideWith((ref) => repository),
          localProfileStateProvider.overrideWithValue(agencyProfile),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loadInitial loads sales history with page size 20', () async {
      repository.fetchSalesHistoryResult = Success(
        PaginatedResult<SalesHistoryItem>(
          items: const [sampleItem],
          pagination: const PaginationMeta(
            page: 1,
            limit: 20,
            total: 1,
            totalPages: 1,
            hasNext: false,
            hasPrev: false,
          ),
        ),
      );

      await container
          .read(commissionSalesHistoryStateProvider.notifier)
          .loadInitial();

      final state = container.read(commissionSalesHistoryStateProvider);
      expect(state.items, [sampleItem]);
      expect(state.totalItems, 1);
      expect(repository.fetchSalesHistoryCallCount, 1);
      expect(repository.lastSalesHistoryForceRefresh, isTrue);
      expect(repository.lastSalesHistoryStatus, isNull);
      expect(repository.lastSalesHistoryAgencyGroupId, 'agency-group-1');
      expect(repository.lastSalesHistoryRequest?.limit, 20);
    });

    test('setFilter sends mapped API status', () async {
      repository.fetchSalesHistoryResult = Success(
        PaginatedResult<SalesHistoryItem>(
          items: const [sampleItem],
          pagination: const PaginationMeta(
            page: 1,
            limit: 10,
            total: 1,
            totalPages: 1,
            hasNext: false,
            hasPrev: false,
          ),
        ),
      );

      final notifier = container.read(
        commissionSalesHistoryStateProvider.notifier,
      );

      await notifier.setFilter(CommissionFilter.paid);
      expect(notifier.filter, CommissionFilter.paid);
      expect(repository.lastSalesHistoryStatus, 'PAID');

      await notifier.setFilter(CommissionFilter.rejected);
      expect(notifier.filter, CommissionFilter.rejected);
      expect(repository.lastSalesHistoryStatus, 'REJECTED');
    });
  });
}
