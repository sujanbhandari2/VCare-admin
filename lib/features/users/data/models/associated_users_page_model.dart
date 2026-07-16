import 'package:vcare_admin/features/users/data/models/associated_user_model.dart';

class AssociatedUsersPaginationModel {
  const AssociatedUsersPaginationModel({
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

  factory AssociatedUsersPaginationModel.fromJson(Map<String, dynamic> json) {
    return AssociatedUsersPaginationModel(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 100,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }
}

class AssociatedUsersPageModel {
  const AssociatedUsersPageModel({
    required this.users,
    required this.pagination,
  });

  final List<AssociatedUserModel> users;
  final AssociatedUsersPaginationModel pagination;

  factory AssociatedUsersPageModel.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['data'];
    final users = rawUsers is List
        ? rawUsers
            .whereType<Map>()
            .map(
              (item) => AssociatedUserModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : <AssociatedUserModel>[];

    final rawPagination = json['pagination'];
    final pagination = rawPagination is Map
        ? AssociatedUsersPaginationModel.fromJson(
            Map<String, dynamic>.from(rawPagination),
          )
        : const AssociatedUsersPaginationModel(
            page: 1,
            limit: 100,
            total: 0,
            totalPages: 0,
            hasNext: false,
            hasPrev: false,
          );

    return AssociatedUsersPageModel(users: users, pagination: pagination);
  }

  static bool isValidApiData(dynamic data) {
    return data is Map<String, dynamic> && data['data'] is List;
  }
}
