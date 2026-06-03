class PaginatedListResponseModel<T> {
  PaginatedListResponseModel({this.rows = const [], this.total = 0});

  final List<T> rows;
  final int total;

  factory PaginatedListResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic j) fromJsonT,
  ) {
    return PaginatedListResponseModel<T>(
      rows: json['rows'] is List
          ? (json['rows'] as List).map(fromJsonT).toList()
          : json['data'] is List
          ? (json['data'] as List).map(fromJsonT).toList()
          : [],
      total: json['count'] ?? json['total'] ?? 0,
    );
  }
}
