import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_users_page.dart';
import 'package:vcare_admin/features/users/domain/repositories/associated_users_repository.dart';

class FakeAssociatedUsersRepository implements AssociatedUsersRepository {
  FakeAssociatedUsersRepository({this.total = 90, this.delay = Duration.zero});

  final int total;
  final Duration delay;
  final List<int> requestedPages = <int>[];
  final List<int> requestedLimits = <int>[];

  @override
  Future<EitherResponseOrException<AssociatedUsersPage>> fetchAssociatedUsers({
    int page = 1,
    int limit = 30,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    requestedPages.add(page);
    requestedLimits.add(limit);

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    final start = (page - 1) * limit;
    final end = (start + limit) > total ? total : start + limit;
    final users = <AssociatedUser>[
      for (var index = start; index < end; index++)
        AssociatedUser(
          id: 'user-$index',
          email: 'user$index@example.com',
          firstName: 'User',
          lastName: '$index',
          userType: 'CLIENT',
          role: 'CLIENT',
          status: 'ACTIVE',
        ),
    ];

    final totalPages = (total / limit).ceil();
    return Success(
      AssociatedUsersPage(
        users: users,
        pagination: AssociatedUsersPagination(
          page: page,
          limit: limit,
          total: total,
          totalPages: totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1,
        ),
      ),
    );
  }
}
