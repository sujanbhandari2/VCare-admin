import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/users/data/mappers/associated_user_mapper.dart';
import 'package:vcare_admin/features/users/data/models/associated_user_model.dart';

void main() {
  group('AssociatedUserModel', () {
    test('reads flat name fields', () {
      final user = AssociatedUserModel.fromJson({
        'id': 'user-1',
        'firstName': 'Vcare',
        'lastName': 'Admin',
        'email': 'admin@vcareadvocacy.com',
        'userType': 'PLATFORM_USER',
        'role': 'PLATFORM_ADMIN',
        'status': 'ACTIVE',
      }).toEntity();

      expect(user.displayName, 'Vcare Admin');
      expect(user.role, 'PLATFORM_ADMIN');
    });

    test('falls back to the nested profile object', () {
      final user = AssociatedUserModel.fromJson({
        'id': 'user-2',
        'profile': {
          'firstName': 'Jane',
          'lastName': 'Doe',
          'email': 'jane@vcareadvocacy.com',
        },
        'roles': ['ADVOCATE'],
      }).toEntity();

      expect(user.displayName, 'Jane Doe');
      expect(user.email, 'jane@vcareadvocacy.com');
      expect(user.role, 'ADVOCATE');
    });

    test('splits a collapsed full name', () {
      final user = AssociatedUserModel.fromJson({
        'id': 'user-3',
        'fullName': 'Ada Byron Lovelace',
      }).toEntity();

      expect(user.firstName, 'Ada');
      expect(user.lastName, 'Byron Lovelace');
      expect(user.displayName, 'Ada Byron Lovelace');
    });

    test('falls back to email then id when no name is returned', () {
      final withEmail = AssociatedUserModel.fromJson({
        'id': 'user-4',
        'email': 'ops@vcareadvocacy.com',
      }).toEntity();
      final bare = AssociatedUserModel.fromJson({'id': 'user-5'}).toEntity();

      expect(withEmail.displayName, 'ops@vcareadvocacy.com');
      expect(bare.displayName, 'user-5');
    });

    test('reads the profile file url as the photo url', () {
      final user = AssociatedUserModel.fromJson({
        'id': 'user-6',
        'profileFile': {'id': 'file-1', 'url': 'https://cdn/photo.png'},
      }).toEntity();

      expect(user.profilePhotoUrl, 'https://cdn/photo.png');
    });
  });
}
