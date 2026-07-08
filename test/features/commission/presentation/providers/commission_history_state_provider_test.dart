import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_history_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_repository_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

import '../../../../fixtures/repositories/fake_commission_repository.dart';

void main() {
  group('CommissionHistoryState', () {
    late FakeCommissionRepository repository;
    late ProviderContainer container;

    const sampleItem = CommissionHistoryItem(
      id: 'item-1',
      clientId: 'client-1',
      commissionValue: '5',
      commissionType: 'PERCENTAGE',
      commissionAmount: '1.16',
      status: CommissionStatus.pending,
      createdAt: '2026-06-25T12:22:46.546Z',
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

    test('loadInitial loads commission history', () async {
      repository.fetchHistoryResult = Success(
        PaginatedResult<CommissionHistoryItem>(
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

      await container
          .read(commissionHistoryStateProvider.notifier)
          .loadInitial();

      final state = container.read(commissionHistoryStateProvider);
      expect(state.items, [sampleItem]);
      expect(state.totalItems, 1);
      expect(repository.fetchHistoryCallCount, 2);
      expect(repository.lastHistoryForceRefresh, isTrue);
    });
  });
}
