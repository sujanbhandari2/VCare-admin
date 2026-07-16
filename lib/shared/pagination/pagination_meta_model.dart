import 'pagination_meta.dart';

class PaginationMetaModel {
  const PaginationMetaModel({
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

  factory PaginationMetaModel.fromJson(Map<String, dynamic> json) {
    return PaginationMetaModel(
      page: _asInt(json['page']),
      limit: _asInt(json['limit']),
      total: _asInt(json['total']),
      totalPages: _asInt(json['totalPages']),
      hasNext: json['hasNext'] == true,
      hasPrev: json['hasPrev'] == true,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

extension PaginationMetaModelMapper on PaginationMetaModel {
  PaginationMeta toEntity() {
    return PaginationMeta(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrev: hasPrev,
    );
  }
}
