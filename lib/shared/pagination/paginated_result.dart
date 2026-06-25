import 'pagination_meta.dart';

/// A page of items paired with pagination metadata from the API.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.pagination,
  });

  final List<T> items;
  final PaginationMeta pagination;
}
