class ApiResponse<T> {
  ApiResponse({required this.success, required this.message, this.data});

  final bool success;
  final String message;
  final T? data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: _messageFromJson(json['message']),
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  static String _messageFromJson(dynamic raw) {
    if (raw == null) {
      return '';
    }
    if (raw is String) {
      return raw;
    }
    if (raw is List) {
      return raw
          .map(_messageFromJson)
          .where((part) => part.trim().isNotEmpty)
          .join('; ');
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in const ['message', 'error', 'detail', 'description']) {
        final nested = _messageFromJson(map[key]);
        if (nested.trim().isNotEmpty) {
          return nested;
        }
      }
      // Avoid dumping raw map contents into UI-facing error copy.
      return '';
    }
    return raw.toString();
  }
}
