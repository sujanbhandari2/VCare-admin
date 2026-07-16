import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/home/data/mappers/agent_stats_mapper.dart';
import 'package:vcare_admin/features/home/data/models/agent_stats_model.dart';
import 'package:vcare_admin/features/home/domain/entities/agent_stats.dart';
import 'package:vcare_admin/features/home/domain/repositories/agent_stats_repository.dart';

class AgentStatsRepositoryImpl implements AgentStatsRepository {
  const AgentStatsRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<AgentStats>> fetchStats({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.agentStats,
        isAuthenticated: true,
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => AgentStatsModel.fromJson(data as Map<String, dynamic>),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }
}
