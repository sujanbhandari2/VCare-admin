import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/home/data/repositories/agent_code_repository_impl.dart';
import 'package:vcare_admin/features/home/domain/repositories/agent_code_repository.dart';

part 'agent_code_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AgentCodeRepository agentCodeRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return AgentCodeRepositoryImpl(apiClient);
}
