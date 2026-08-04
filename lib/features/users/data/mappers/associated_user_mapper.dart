import 'package:vcare_admin/features/users/data/models/associated_user_model.dart';
import 'package:vcare_admin/features/users/data/models/associated_users_page_model.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_users_page.dart';

extension AssociatedUserModelMapper on AssociatedUserModel {
  AssociatedUser toEntity() {
    return AssociatedUser(
      id: id,
      email: email,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      profileImage: profileImage,
      profilePreviewLink: profilePreviewLink,
      userType: userType,
      role: role,
      status: status,
    );
  }
}

extension AssociatedUsersPageModelMapper on AssociatedUsersPageModel {
  AssociatedUsersPage toEntity() {
    return AssociatedUsersPage(
      users: users.map((user) => user.toEntity()).toList(growable: false),
      pagination: AssociatedUsersPagination(
        page: pagination.page,
        limit: pagination.limit,
        total: pagination.total,
        totalPages: pagination.totalPages,
        hasNext: pagination.hasNext,
        hasPrev: pagination.hasPrev,
      ),
    );
  }
}
