import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/saved_providers/data/mappers/saved_provider_mapper.dart';
import 'package:vcare_admin/features/saved_providers/domain/entities/saved_provider.dart';
import 'package:vcare_admin/features/saved_providers/domain/repositories/saved_provider_repository.dart';

class SavedProviderRepositoryImpl implements SavedProviderRepository {
  const SavedProviderRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<List<SavedProvider>>> fetchSavedProviders({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.providersSave,
        isAuthenticated: true,
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );

      final models = ResponseValidator.parse(
        response,
        parseSavedProviderList,
        dataValidator: (data) => data is List || data is Map,
      );

      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<EitherResponseOrException<SavedProvider>> saveProvider({
    required MedicareProviderLookupRow row,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.providersSave,
        JsonRequestBody(row.toSaveProviderPayload()),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        parseSavedProviderItem,
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<bool>> deleteSavedProvider({
    required String providerId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.delete(
        ApiEndpoints.providerSaveById(providerId),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final isValid = ResponseValidator.isValidResponse(response);
      if (!isValid) throw HttpException.fromResponse(response);

      return isValid;
    });
  }
}
