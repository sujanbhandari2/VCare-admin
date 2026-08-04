import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/home/domain/entities/agent_stats.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_stats_repository_provider.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_stats_state_provider.dart';

import '../../../../fixtures/repositories/fake_agent_stats_repository.dart';

void main() {
  group('AgentStatsStateNotifier', () {
    late FakeAgentStatsRepository repository;
    late ProviderContainer container;

    const sampleStats = AgentStats(
      totalClients: 2,
      totalSales: 0,
      totalCommission: 0,
    );

    setUp(() {
      repository = FakeAgentStatsRepository();
      container = ProviderContainer(
        overrides: [
          agentStatsRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('fetchStats loads agent stats', () async {
      repository.fetchResult = Success(sampleStats);

      await container.read(agentStatsStateProvider.notifier).fetchStats();

      final state = container.read(agentStatsStateProvider);
      expect(state.data, sampleStats);
      expect(state.fetching, isFalse);
      expect(repository.fetchCallCount, 1);
    });

    test('fetchStats sets failure on error', () async {
      repository.fetchResult = Failure(
        HttpException(
          title: 'Error',
          message: 'Stats failed',
          errorType: HttpErrorType.client,
        ),
      );

      await container.read(agentStatsStateProvider.notifier).fetchStats();

      final state = container.read(agentStatsStateProvider);
      expect(state.data, isNull);
      expect(state.error, 'Stats failed');
    });
  });
}
