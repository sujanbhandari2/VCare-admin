class ClientDocumentModel {
  const ClientDocumentModel({
    required this.id,
    this.name,
    this.url,
    this.note,
    this.date,
    this.category,
    this.createdAt,
  });

  final String id;
  final String? name;
  final String? url;
  final String? note;
  final String? date;
  final String? category;
  final String? createdAt;

  factory ClientDocumentModel.fromJson(Map<String, dynamic> json) {
    return ClientDocumentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      url: json['url']?.toString(),
      note: json['note']?.toString(),
      date: json['date']?.toString(),
      category: json['category']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
