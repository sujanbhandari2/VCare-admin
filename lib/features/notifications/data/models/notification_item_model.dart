class NotificationItemModel {
  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime createdAt;

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return NotificationItemModel(
      id: id?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      read: json['read'] is bool ? json['read'] as bool : false,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
