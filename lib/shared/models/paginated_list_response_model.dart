import '../pagination/pagination_meta_model.dart';

/// Legacy wrapper — prefer [PaginatedResponseParser] for new code.
class PaginatedListResponseModel<T> {
  PaginatedListResponseModel({this.rows = const [], this.total = 0});

  final List<T> rows;
  final int total;

  factory PaginatedListResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic j) fromJsonT,
  ) {
    final rows = json['rows'] is List
        ? (json['rows'] as List).map(fromJsonT).toList()
        : json['data'] is List
        ? (json['data'] as List).map(fromJsonT).toList()
        : <T>[];

    final pagination = json['pagination'];
    final total = pagination is Map<String, dynamic>
        ? PaginationMetaModel.fromJson(pagination).total
        : pagination is Map
        ? PaginationMetaModel.fromJson(
            Map<String, dynamic>.from(pagination),
          ).total
        : json['count'] ?? json['total'] ?? rows.length;

    return PaginatedListResponseModel<T>(rows: rows, total: total);
  }
}
