/// Standard query parameters for paginated list endpoints.
class PaginatedListRequest {
  const PaginatedListRequest({
    this.page = 1,
    this.limit = 20,
    this.search,
  });

  final int page;
  final int limit;
  final String? search;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      params['search'] = trimmedSearch;
    }

    return params;
  }

  PaginatedListRequest copyWith({
    int? page,
    int? limit,
    String? search,
  }) {
    return PaginatedListRequest(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
    );
  }
}
