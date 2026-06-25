import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/home/domain/entities/agent_stats.dart';
import 'package:vcare_admin/features/home/domain/repositories/agent_stats_repository.dart';

class FakeAgentStatsRepository implements AgentStatsRepository {
  EitherResponseOrException<AgentStats> fetchResult = Success(
    const AgentStats(
      totalClients: 2,
      totalSales: '0',
      totalCommission: '0',
    ),
  );

  int fetchCallCount = 0;
  bool? lastForceRefresh;

  @override
  Future<EitherResponseOrException<AgentStats>> fetchStats({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    fetchCallCount++;
    lastForceRefresh = forceRefresh;
    return fetchResult;
  }
}
