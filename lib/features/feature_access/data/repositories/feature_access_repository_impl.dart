import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/feature_access/data/mappers/feature_access_mapper.dart';
import 'package:vcare_admin/features/feature_access/data/models/feature_access_model.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';
import 'package:vcare_admin/features/feature_access/domain/repositories/feature_access_repository.dart';

class FeatureAccessRepositoryImpl implements FeatureAccessRepository {
  const FeatureAccessRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<FeatureAccess>> fetchFeatureAccess({
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.settings,
        isAuthenticated: true,
        forceRefresh: forceRefresh,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => FeatureAccessModel.fromSettingsJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }
}
