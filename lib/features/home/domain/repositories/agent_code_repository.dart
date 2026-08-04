import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/home/domain/entities/updated_agent_code.dart';

abstract class AgentCodeRepository {
  Future<EitherResponseOrException<UpdatedAgentCode>> updateAgentCode({
    required String agentCode,
    CancelToken? cancelToken,
  });
}
