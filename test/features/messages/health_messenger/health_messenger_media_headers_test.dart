import 'package:flutter_test/flutter_test.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_media_headers.dart';

void main() {
  const auth = ChatAuth(
    apiKey: 'access:secret',
    chatUserId: '10',
    accessToken: 'jwt-token',
  );
  const apiBaseUrl = 'https://api-generic-chat.example.com';

  group('healthMessengerMediaHeaders', () {
    test('sends chat auth headers for media on the chat API origin', () {
      final headers = healthMessengerMediaHeaders(
        mediaUrl: '$apiBaseUrl/api/upload/file/photo.png',
        apiBaseUrl: apiBaseUrl,
        auth: auth,
      );

      expect(headers['X-Api-Key'], 'access:secret');
      expect(headers['Authorization'], 'Bearer jwt-token');
    });

    test('omits headers for object storage hosts', () {
      final headers = healthMessengerMediaHeaders(
        mediaUrl:
            'https://bucket.s3.amazonaws.com/uploads/photo.png?X-Amz-Signature=abc',
        apiBaseUrl: apiBaseUrl,
        auth: auth,
      );

      expect(headers, isEmpty);
    });

    test('omits headers when the session has no auth', () {
      final headers = healthMessengerMediaHeaders(
        mediaUrl: '$apiBaseUrl/api/upload/file/photo.png',
        apiBaseUrl: apiBaseUrl,
        auth: null,
      );

      expect(headers, isEmpty);
    });

    test('omits headers for local files and unparseable origins', () {
      expect(
        healthMessengerMediaHeaders(
          mediaUrl: '/data/user/0/cache/photo.png',
          apiBaseUrl: apiBaseUrl,
          auth: auth,
        ),
        isEmpty,
      );
      expect(
        healthMessengerMediaHeaders(
          mediaUrl: '$apiBaseUrl/api/upload/file/photo.png',
          apiBaseUrl: '',
          auth: auth,
        ),
        isEmpty,
      );
    });
  });

  group('healthMessengerMediaIsChatApiOrigin', () {
    test('compares hosts case-insensitively and ignores paths', () {
      expect(
        healthMessengerMediaIsChatApiOrigin(
          mediaUrl: 'https://API-Generic-Chat.example.com/api/upload/a.png',
          apiBaseUrl: '$apiBaseUrl/',
        ),
        isTrue,
      );
      expect(
        healthMessengerMediaIsChatApiOrigin(
          mediaUrl: 'https://cdn.example.com/a.png',
          apiBaseUrl: apiBaseUrl,
        ),
        isFalse,
      );
    });
  });
}
