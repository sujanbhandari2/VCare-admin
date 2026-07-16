/// Pagination metadata returned by paginated API endpoints.
class PaginationMeta {
  const PaginationMeta({
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

  static const empty = PaginationMeta(
    page: 1,
    limit: 0,
    total: 0,
    totalPages: 0,
    hasNext: false,
    hasPrev: false,
  );
}
