import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/users/data/mappers/associated_user_mapper.dart';
import 'package:vcare_admin/features/users/data/models/associated_user_model.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';
import 'package:vcare_admin/features/users/domain/repositories/internal_users_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

class InternalUsersRepositoryImpl implements InternalUsersRepository {
  const InternalUsersRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  /// Web parity: `type=internal` is the staff group filter and must not be
  /// combined with `role`.
  static const String _internalType = 'internal';

  @override
  Future<EitherResponseOrException<List<AssociatedUser>>> fetchInternalUsers({
    int page = 1,
    int limit = 100,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.users,
        queryParameters: {
          'page': page,
          'limit': limit,
          'sortBy': sortBy,
          'sortOrder': sortOrder,
          'type': _internalType,
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final parsed = PaginatedResponseParser.parse(
        response,
        (json) => AssociatedUserModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ),
      );

      return parsed.items
          .map((model) => model.toEntity())
          .toList(growable: false);
    });
  }
}
