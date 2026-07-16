import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/users/data/mappers/associated_user_mapper.dart';
import 'package:vcare_admin/features/users/data/models/associated_users_page_model.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_users_page.dart';
import 'package:vcare_admin/features/users/domain/repositories/associated_users_repository.dart';

class AssociatedUsersRepositoryImpl implements AssociatedUsersRepository {
  AssociatedUsersRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<AssociatedUsersPage>> fetchAssociatedUsers({
    int page = 1,
    int limit = 100,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.usersAssociated,
        queryParameters: {
          'page': page,
          'limit': limit,
          'sortBy': sortBy,
          'sortOrder': sortOrder,
        },
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
        isAuthenticated: true,
      );

      final pageModel = ResponseValidator.parse(
        response,
        (data) => AssociatedUsersPageModel.fromJson(
          data as Map<String, dynamic>,
        ),
        dataValidator: AssociatedUsersPageModel.isValidApiData,
      );
      return pageModel.toEntity();
    });
  }
}
