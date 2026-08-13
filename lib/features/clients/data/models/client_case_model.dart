class ClientCaseModel {
  const ClientCaseModel({
    required this.id,
    this.status,
    this.title,
    this.type,
    this.caseNumber,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? status;
  final String? title;
  final String? type;
  final String? caseNumber;
  final String? createdAt;
  final String? updatedAt;

  factory ClientCaseModel.fromJson(Map<String, dynamic> json) {
    return ClientCaseModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString(),
      title: json['title']?.toString(),
      type: json['type']?.toString(),
      caseNumber: json['caseNumber']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
