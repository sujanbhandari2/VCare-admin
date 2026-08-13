/// File record from `GET /files` (`FileRecord`).
class CaseFileModel {
  const CaseFileModel({
    required this.id,
    required this.name,
    this.url,
    this.note,
    this.date,
    this.category,
    this.categoryReferenceId,
    this.subCategoryReferenceId,
    this.userId,
    this.tenantId,
    this.createdBy,
    this.createdAt,
    this.mimeType,
    this.size,
  });

  final String id;
  final String name;
  final String? url;
  final String? note;
  final String? date;
  final String? category;
  final String? categoryReferenceId;
  final String? subCategoryReferenceId;
  final String? userId;
  final String? tenantId;
  final String? createdBy;
  final String? createdAt;
  final String? mimeType;
  final String? size;

  factory CaseFileModel.fromJson(Map<String, dynamic> json) {
    return CaseFileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      url: _optionalString(json['url']),
      note: _optionalString(json['note']),
      date: _optionalString(json['date']),
      category: _optionalString(json['category']),
      categoryReferenceId: _optionalString(json['categoryReferenceId']),
      subCategoryReferenceId: _optionalString(json['subCategoryReferenceId']),
      userId: _optionalString(json['userId']),
      tenantId: _optionalString(json['tenantId']),
      createdBy: _optionalString(json['createdBy']),
      createdAt: _optionalString(json['createdAt']),
      mimeType: _optionalString(json['mimeType'] ?? json['contentType']),
      size: _optionalString(json['size']),
    );
  }

  static bool isValidApiData(dynamic data) {
    return data is Map && data['id'] != null;
  }
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}
