import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';

/// Query parameters for `GET /api/v1/referral-cases`.
class CasesListRequest {
  const CasesListRequest({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status,
    this.priority,
    this.type,
    this.assignedTo,
    this.clientId,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.bookmarkedFirst = true,
    this.bookmarkedOnly = false,
  });

  final int page;
  final int limit;
  final String? search;
  final CaseStatus? status;
  final CasePriority? priority;
  final String? type;
  final String? assignedTo;
  final String? clientId;
  final String sortBy;
  final String sortOrder;
  final bool bookmarkedFirst;
  final bool bookmarkedOnly;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      'bookmarkedFirst': bookmarkedFirst,
    };

    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      params['search'] = trimmedSearch;
    }
    if (status != null) {
      params['status'] = status!.apiValue;
    }
    if (priority != null) {
      params['priority'] = priority!.apiValue;
    }
    final trimmedType = type?.trim();
    if (trimmedType != null && trimmedType.isNotEmpty) {
      params['type'] = trimmedType;
    }
    final trimmedAssignee = assignedTo?.trim();
    if (trimmedAssignee != null && trimmedAssignee.isNotEmpty) {
      params['assignedTo'] = trimmedAssignee;
    }
    final trimmedClientId = clientId?.trim();
    if (trimmedClientId != null && trimmedClientId.isNotEmpty) {
      params['clientId'] = trimmedClientId;
    }
    if (bookmarkedOnly) {
      params['bookmarkedOnly'] = true;
    }

    return params;
  }

  CasesListRequest copyWith({
    int? page,
    int? limit,
    String? search,
    CaseStatus? status,
    bool clearStatus = false,
    CasePriority? priority,
    bool clearPriority = false,
    String? type,
    String? assignedTo,
    String? clientId,
    String? sortBy,
    String? sortOrder,
    bool? bookmarkedFirst,
    bool? bookmarkedOnly,
  }) {
    return CasesListRequest(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      type: type ?? this.type,
      assignedTo: assignedTo ?? this.assignedTo,
      clientId: clientId ?? this.clientId,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      bookmarkedFirst: bookmarkedFirst ?? this.bookmarkedFirst,
      bookmarkedOnly: bookmarkedOnly ?? this.bookmarkedOnly,
    );
  }
}
