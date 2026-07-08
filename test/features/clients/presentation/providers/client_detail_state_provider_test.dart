import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/clients/presentation/providers/client_detail_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';

import '../../../../fixtures/repositories/fake_client_repository.dart';

void main() {
  group('ClientDetailState', () {
    late FakeClientRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeClientRepository();
      container = ProviderContainer(
        overrides: [
          clientRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('fetchDetail stores client detail', () async {
      await container
          .read(clientDetailStateProvider('client-1').notifier)
          .fetchDetail();

      final state = container.read(clientDetailStateProvider('client-1'));

      expect(state.fetching, isFalse);
      expect(state.data?.id, 'client-1');
      expect(repository.lastClientId, 'client-1');
    });

    test('fetchDetail forces network refresh', () async {
      await container
          .read(clientDetailStateProvider('client-1').notifier)
          .fetchDetail();

      expect(repository.lastDetailForceRefresh, isTrue);
    });
  });
}
