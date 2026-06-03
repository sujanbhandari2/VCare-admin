enum AvaSender { me, ava }

class AvaMessage {
  const AvaMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final AvaSender sender;
  final String body;
  final DateTime createdAt;

  bool get isMe => sender == AvaSender.me;

  AvaMessage copyWith({
    String? id,
    AvaSender? sender,
    String? body,
    DateTime? createdAt,
  }) {
    return AvaMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
