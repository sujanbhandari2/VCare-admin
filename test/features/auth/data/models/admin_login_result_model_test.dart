import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/data/models/admin_login_result_model.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_login_outcome.dart';

void main() {
  group('AdminLoginResultModel', () {
    test('fromJson maps authenticated session', () {
      final model = AdminLoginResultModel.fromJson({
        'user': {
          'id': 'user-id',
          'email': 'admin@example.com',
          'firstName': 'Jane',
          'lastName': 'Admin',
          'currentTenant': {
            'id': 'tenant-id',
            'slug': 'default',
            'name': 'Default Tenant',
          },
          'currentRoles': ['ADMIN'],
        },
        'tokens': {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
        },
        'menu': ['dashboard', 'clients'],
        'urls': {
          'portal': 'https://portal.example.com',
        },
      });

      final outcome = model.toOutcome();
      expect(outcome, isA<AdminLoginAuthenticated>());

      final session = (outcome as AdminLoginAuthenticated).session;
      expect(session.accessToken, 'access-token');
      expect(session.refreshToken, 'refresh-token');
      expect(session.user.email, 'admin@example.com');
      expect(session.user.currentTenant.slug, 'default');
      expect(session.menu, ['dashboard', 'clients']);
      expect(session.urls?.portal, 'https://portal.example.com');
    });

    test('fromJson maps tenant selection response', () {
      final model = AdminLoginResultModel.fromJson({
        'requiresTenantSelection': true,
        'tenants': [
          {'slug': 'acme', 'name': 'Acme Corp'},
          {'slug': 'beta', 'name': 'Beta Org'},
        ],
      });

      final outcome = model.toOutcome();
      expect(outcome, isA<AdminLoginTenantSelectionRequired>());

      final tenants =
          (outcome as AdminLoginTenantSelectionRequired).tenants;
      expect(tenants, hasLength(2));
      expect(tenants.first.slug, 'acme');
      expect(tenants.last.name, 'Beta Org');
    });
  });
}
