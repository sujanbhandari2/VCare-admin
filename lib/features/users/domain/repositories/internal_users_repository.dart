import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';

/// Staff accounts from `GET users?type=internal` — the assignable team members.
abstract class InternalUsersRepository {
  Future<EitherResponseOrException<List<AssociatedUser>>> fetchInternalUsers({
    int page = 1,
    int limit = 100,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool forceRefresh = false,
    CancelToken? cancelToken,
  });
}
