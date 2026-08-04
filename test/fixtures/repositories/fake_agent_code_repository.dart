import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/home/domain/entities/updated_agent_code.dart';
import 'package:vcare_admin/features/home/domain/repositories/agent_code_repository.dart';

class FakeAgentCodeRepository implements AgentCodeRepository {
  EitherResponseOrException<UpdatedAgentCode> updateResult = Success(
    const UpdatedAgentCode(
      agentCode: 'new-code',
      referralLink: 'https://vcare.app/refer/new-code',
    ),
  );

  int updateCallCount = 0;
  String? lastAgentCode;

  @override
  Future<EitherResponseOrException<UpdatedAgentCode>> updateAgentCode({
    required String agentCode,
    CancelToken? cancelToken,
  }) async {
    updateCallCount++;
    lastAgentCode = agentCode;
    return updateResult;
  }
}
