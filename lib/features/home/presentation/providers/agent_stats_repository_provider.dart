import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/home/data/repositories/agent_stats_repository_impl.dart';
import 'package:vcare_admin/features/home/domain/repositories/agent_stats_repository.dart';

part 'agent_stats_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AgentStatsRepository agentStatsRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return AgentStatsRepositoryImpl(apiClient);
}
