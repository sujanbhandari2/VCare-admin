import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_users_page.dart';

abstract class AssociatedUsersRepository {
  Future<EitherResponseOrException<AssociatedUsersPage>> fetchAssociatedUsers({
    int page = 1,
    int limit = 100,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });
}
