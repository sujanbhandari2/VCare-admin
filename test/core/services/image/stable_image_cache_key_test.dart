import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/image/stable_image_cache_key.dart';

void main() {
  group('stableImageCacheKey', () {
    test('prefers storage path over url and entity id', () {
      expect(
        stableImageCacheKey(
          prefix: 'profile-photo',
          storagePath: 'users/123/profile.jpg',
          entityId: 'user-123',
          imageUrl: 'https://cdn.example.com/users/123/profile.jpg?token=abc',
        ),
        'profile-photo:users/123/profile.jpg',
      );
    });

    test('falls back to url path without query params', () {
      expect(
        stableImageCacheKey(
          prefix: 'profile-photo',
          imageUrl:
              'https://cdn.example.com/users/123/profile.jpg?X-Amz-Signature=abc',
        ),
        'profile-photo:cdn.example.com/users/123/profile.jpg',
      );
    });

    test('falls back to entity id when url is unavailable', () {
      expect(
        stableImageCacheKey(
          prefix: 'profile-photo',
          entityId: 'user-123',
        ),
        'profile-photo:user-123',
      );
    });

    test('returns null when no stable inputs are available', () {
      expect(
        stableImageCacheKey(prefix: 'profile-photo'),
        isNull,
      );
    });
  });
}
