/// Query parameters for `GET /api/v1/clients` (matches web `ListClientsParams`).
enum ClientListType {
  individual,
  group;

  String get apiValue => switch (this) {
    ClientListType.individual => 'INDIVIDUAL',
    ClientListType.group => 'GROUP',
  };
}

class ClientsListRequest {
  const ClientsListRequest({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.clientType = ClientListType.individual,
    this.sortBy,
    this.sortOrder,
  });

  final int page;
  final int limit;
  final String? search;
  final ClientListType clientType;
  final String? sortBy;
  final String? sortOrder;

  String get resolvedSortBy => sortBy ?? switch (clientType) {
    ClientListType.group => 'companyName',
    ClientListType.individual => 'createdAt',
  };

  String get resolvedSortOrder => sortOrder ?? switch (clientType) {
    ClientListType.group => 'asc',
    ClientListType.individual => 'desc',
  };

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'clientType': clientType.apiValue,
      'sortBy': resolvedSortBy,
      'sortOrder': resolvedSortOrder,
    };

    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      params['search'] = trimmedSearch;
    }

    return params;
  }

  ClientsListRequest copyWith({
    int? page,
    int? limit,
    String? search,
    ClientListType? clientType,
    String? sortBy,
    String? sortOrder,
  }) {
    return ClientsListRequest(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      clientType: clientType ?? this.clientType,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
