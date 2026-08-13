import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

/// Builds pagination for the admin todo endpoint, which returns mixed item
/// types while each mobile list renders only one of them.
///
/// Because filtered-out items still count towards the reported total, the total
/// is pinned to what has actually been kept once a short page arrives — that is
/// the last page, so `hasMore` has to settle to false.
PaginationMeta buildAdminTodoPagination({
  required PaginatedListRequest request,
  required int rawItemCount,
  required int keptItemCount,
  required int loadedItemCount,
  required int reportedTotal,
}) {
  final isLastPage = rawItemCount < request.limit;
  final total = isLastPage ? loadedItemCount + keptItemCount : reportedTotal;
  final totalPages =
      total == 0 ? 0 : (total + request.limit - 1) ~/ request.limit;

  return PaginationMeta(
    page: request.page,
    limit: request.limit,
    total: total,
    totalPages: totalPages,
    hasNext: !isLastPage,
    hasPrev: request.page > 1,
  );
}
