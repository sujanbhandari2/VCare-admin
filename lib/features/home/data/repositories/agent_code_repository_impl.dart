import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/home/data/mappers/updated_agent_code_mapper.dart';
import 'package:vcare_admin/features/home/data/models/updated_agent_code_model.dart';
import 'package:vcare_admin/features/home/domain/entities/updated_agent_code.dart';
import 'package:vcare_admin/features/home/domain/repositories/agent_code_repository.dart';

class AgentCodeRepositoryImpl implements AgentCodeRepository {
  const AgentCodeRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<UpdatedAgentCode>> updateAgentCode({
    required String agentCode,
    CancelToken? cancelToken,
  }) {
    final normalized = agentCode.trim().toLowerCase();

    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.agentCode,
        JsonRequestBody({'agentCode': normalized}),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) {
          if (data is Map) {
            return UpdatedAgentCodeModel.fromJson(
              Map<String, dynamic>.from(data),
              fallbackAgentCode: normalized,
            );
          }
          // Defensive fallback if envelope unwrap leaves a non-map body.
          return UpdatedAgentCodeModel(
            agentCode: normalized,
          );
        },
      );

      return model.toEntity();
    });
  }
}
