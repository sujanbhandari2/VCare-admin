import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/home/domain/entities/agent_stats.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_stats_repository_provider.dart';
import 'package:vcare_admin/features/home/presentation/state/agent_stats_state.dart';

part 'agent_stats_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AgentStatsStateNotifier extends _$AgentStatsStateNotifier {
  @override
  AgentStatsState build() => const AgentStatsState();

  Future<void> fetchStats({
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(AgentStats? stats)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref.read(agentStatsRepositoryProvider).fetchStats(
          forceRefresh: forceRefresh,
          cancelToken: cancelToken,
        );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.message);
        }
        onCompleted?.call(null);
      },
      success: (stats) {
        if (ref.mounted) {
          state = state.success(stats);
        }
        onCompleted?.call(stats);
      },
    );
  }
}
