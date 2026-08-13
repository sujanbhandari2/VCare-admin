import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

/// Normalizes enrollment list pagination so a short page always ends the list.
///
/// The enrollment endpoint pages with `page`/`limit` like web
/// `toPaginatedListParams`, but its total counts server-side rows that shift
/// while a reviewer works through the list, since approving or declining removes
/// a row. When the last page comes back short the total is pinned to what has
/// actually been loaded, which both stops paging and corrects the count the
/// header shows. Otherwise the reported total is passed through untouched — it
/// is the same number the dashboard stat card reads, so it must not be
/// second-guessed here or the header count would drift as pages arrive.
PaginationMeta buildPendingMembershipPagination({
  required int page,
  required int limit,
  required int rawItemCount,
  required int keptItemCount,
  required int loadedItemCount,
  required PaginationMeta reported,
}) {
  final loadedAfterPage = loadedItemCount + keptItemCount;
  final isLastPage = rawItemCount < limit;

  final total = isLastPage ? loadedAfterPage : reported.total;

  final totalPages = total == 0 ? 0 : (total + limit - 1) ~/ limit;

  return PaginationMeta(
    page: page,
    limit: limit,
    total: total,
    totalPages: totalPages,
    hasNext: !isLastPage && total > loadedAfterPage,
    hasPrev: page > 1,
  );
}
