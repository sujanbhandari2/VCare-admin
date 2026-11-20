import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';

/// Owner filter for the My Tasks queue — mirrors web `QueueOwnerFilterId`.
sealed class MyTaskOwnerFilter {
  const MyTaskOwnerFilter();

  static const MyTaskOwnerFilter me = MyTaskOwnerFilterMe();
  static const MyTaskOwnerFilter all = MyTaskOwnerFilterAll();
  static const MyTaskOwnerFilter unassigned = MyTaskOwnerFilterUnassigned();

  factory MyTaskOwnerFilter.user(String userId) =>
      MyTaskOwnerFilterUser(userId);
}

class MyTaskOwnerFilterMe extends MyTaskOwnerFilter {
  const MyTaskOwnerFilterMe();
}

class MyTaskOwnerFilterAll extends MyTaskOwnerFilter {
  const MyTaskOwnerFilterAll();
}

class MyTaskOwnerFilterUnassigned extends MyTaskOwnerFilter {
  const MyTaskOwnerFilterUnassigned();
}

class MyTaskOwnerFilterUser extends MyTaskOwnerFilter {
  const MyTaskOwnerFilterUser(this.userId);

  final String userId;
}

/// Quick filter chips — mirrors web `QueueQuickFilter`.
enum MyTaskQuickFilter { overdue, snoozed }

/// Queue category filter — mirrors web `FILTERS` ids.
enum MyTaskQueueCategoryFilter {
  all,
  payment,
  enrollment,
  case_,
  ack;

  String get label => switch (this) {
    MyTaskQueueCategoryFilter.all => 'All',
    MyTaskQueueCategoryFilter.payment => 'Payment',
    MyTaskQueueCategoryFilter.enrollment => 'Membership',
    MyTaskQueueCategoryFilter.case_ => 'Case',
    MyTaskQueueCategoryFilter.ack => 'Care coordination',
  };

  /// Maps to API `category` query param, or null for all.
  String? get apiValue => switch (this) {
    MyTaskQueueCategoryFilter.all => null,
    MyTaskQueueCategoryFilter.payment => 'Payment Transaction',
    MyTaskQueueCategoryFilter.enrollment => 'ENROLLMENT',
    MyTaskQueueCategoryFilter.case_ => 'REFERRAL',
    MyTaskQueueCategoryFilter.ack => 'CARE_COORDINATION',
  };
}

/// Paginated list request for `GET /tasks`.
class MyTaskListRequest {
  const MyTaskListRequest({
    this.page = 1,
    this.limit = 25,
    this.search,
    this.status,
    this.priority,
    this.assignedToUser,
    this.category,
    this.categoryReferenceId,
    this.type,
    this.snooze,
    this.origin,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  final int page;
  final int limit;
  final String? search;
  final MyTaskStatus? status;
  final MyTaskPriority? priority;
  final String? assignedToUser;
  final String? category;
  final String? categoryReferenceId;
  final MyTaskListType? type;
  final bool? snooze;
  final MyTaskOrigin? origin;
  final String sortBy;
  final String sortOrder;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      params['search'] = trimmedSearch;
    }

    if (status != null) params['status'] = status!.apiValue;
    if (priority != null) {
      // Queue filter collapses urgent into "high" — send HIGH for both.
      params['priority'] = priority == MyTaskPriority.urgent
          ? MyTaskPriority.high.apiValue
          : priority!.apiValue;
    }
    final assignee = assignedToUser?.trim();
    if (assignee != null && assignee.isNotEmpty) {
      params['assignedToUser'] = assignee;
    }
    final cat = category?.trim();
    if (cat != null && cat.isNotEmpty) params['category'] = cat;
    final refId = categoryReferenceId?.trim();
    if (refId != null && refId.isNotEmpty) {
      params['categoryReferenceId'] = refId;
    }
    if (type != null) params['type'] = type!.apiValue;
    if (snooze == true) params['snooze'] = true;
    if (origin != null) params['origin'] = origin!.apiValue;

    return params;
  }

  MyTaskListRequest copyWith({
    int? page,
    int? limit,
    String? search,
    MyTaskStatus? status,
    bool clearStatus = false,
    MyTaskPriority? priority,
    bool clearPriority = false,
    String? assignedToUser,
    bool clearAssignedToUser = false,
    String? category,
    bool clearCategory = false,
    String? categoryReferenceId,
    MyTaskListType? type,
    bool clearType = false,
    bool? snooze,
    bool clearSnooze = false,
    MyTaskOrigin? origin,
    bool clearOrigin = false,
    String? sortBy,
    String? sortOrder,
  }) {
    return MyTaskListRequest(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      assignedToUser: clearAssignedToUser
          ? null
          : (assignedToUser ?? this.assignedToUser),
      category: clearCategory ? null : (category ?? this.category),
      categoryReferenceId: categoryReferenceId ?? this.categoryReferenceId,
      type: clearType ? null : (type ?? this.type),
      snooze: clearSnooze ? null : (snooze ?? this.snooze),
      origin: clearOrigin ? null : (origin ?? this.origin),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Builds a [MyTaskListRequest] from queue UI filter state.
MyTaskListRequest buildMyTaskListRequest({
  required int page,
  required int limit,
  required String? currentUserId,
  required MyTaskOwnerFilter ownerFilter,
  required Set<MyTaskQuickFilter> quickFilters,
  required MyTaskStatus? statusFilter,
  required MyTaskPriority? priorityFilter,
  required MyTaskQueueCategoryFilter categoryFilter,
  required MyTaskOrigin? originFilter,
  required String? search,
}) {
  final snoozed = quickFilters.contains(MyTaskQuickFilter.snoozed);
  final overdue = quickFilters.contains(MyTaskQuickFilter.overdue);

  MyTaskListType? type;
  if (overdue && !snoozed) {
    type = MyTaskListType.overdue;
  } else if (ownerFilter is MyTaskOwnerFilterUnassigned) {
    type = MyTaskListType.open;
  }

  String? assignedToUser;
  if (ownerFilter is MyTaskOwnerFilterMe) {
    assignedToUser = currentUserId;
  } else if (ownerFilter is MyTaskOwnerFilterUser) {
    assignedToUser = ownerFilter.userId;
  }

  return MyTaskListRequest(
    page: page,
    limit: limit,
    search: search,
    assignedToUser: assignedToUser,
    type: type,
    category: categoryFilter.apiValue,
    status: snoozed ? null : statusFilter,
    snooze: snoozed ? true : null,
    priority: priorityFilter,
    origin: originFilter,
  );
}
