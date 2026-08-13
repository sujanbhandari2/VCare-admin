import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';

/// Query filter for `GET /enrollments` — parity with web
/// `ListEnrollmentsParams`.
class PendingMembershipsRequest {
  const PendingMembershipsRequest({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status = MembershipStatus.submitted,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  final int page;
  final int limit;
  final String? search;
  final MembershipStatus? status;
  final String sortBy;
  final String sortOrder;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (status != null) {
      params['status'] = status!.apiValue;
    }

    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      params['search'] = trimmedSearch;
    }

    return params;
  }
}
