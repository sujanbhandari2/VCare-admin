class ClientCaseModel {
  const ClientCaseModel({
    required this.id,
    this.status,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? status;
  final String? type;
  final String? createdAt;
  final String? updatedAt;

  factory ClientCaseModel.fromJson(Map<String, dynamic> json) {
    return ClientCaseModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString(),
      type: json['type']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
