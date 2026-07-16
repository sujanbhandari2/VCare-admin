class AgentFileModel {
  const AgentFileModel({
    required this.id,
    this.name,
    this.url,
    this.previewLink,
    this.note,
    this.date,
    this.category,
    this.categoryReferenceId,
    this.subCategoryReferenceId,
    this.userId,
    this.tenantId,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String? name;
  final String? url;
  final String? previewLink;
  final String? note;
  final String? date;
  final String? category;
  final String? categoryReferenceId;
  final String? subCategoryReferenceId;
  final String? userId;
  final String? tenantId;
  final String? createdBy;
  final String? createdAt;

  factory AgentFileModel.fromJson(Map<String, dynamic> json) {
    return AgentFileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      url: json['url']?.toString(),
      previewLink: json['previewLink']?.toString(),
      note: json['note']?.toString(),
      date: json['date']?.toString(),
      category: json['category']?.toString(),
      categoryReferenceId: json['categoryReferenceId']?.toString(),
      subCategoryReferenceId: json['subCategoryReferenceId']?.toString(),
      userId: json['userId']?.toString(),
      tenantId: json['tenantId']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
