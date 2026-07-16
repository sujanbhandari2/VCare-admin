import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/home/domain/entities/agent_stats.dart';

abstract class AgentStatsRepository {
  Future<EitherResponseOrException<AgentStats>> fetchStats({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });
}
