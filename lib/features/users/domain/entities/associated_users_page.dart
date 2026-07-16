import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';

class AssociatedUsersPagination {
  const AssociatedUsersPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;
}

class AssociatedUsersPage {
  const AssociatedUsersPage({
    required this.users,
    required this.pagination,
  });

  final List<AssociatedUser> users;
  final AssociatedUsersPagination pagination;
}
