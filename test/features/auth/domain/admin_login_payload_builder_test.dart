import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/domain/admin_login_payload_builder.dart';

void main() {
  group('AdminLoginPayloadBuilder', () {
    test('maps email to identifier and applies default tenant slug', () {
      final payload = const AdminLoginPayloadBuilder(
        defaultTenantSlug: 'default',
      ).build(
        email: ' admin@example.com ',
        password: 'secret',
      );

      expect(payload['identifier'], 'admin@example.com');
      expect(payload['password'], 'secret');
      expect(payload['tenantSlug'], 'default');
    });

    test('uses explicit tenant slug when provided', () {
      final payload = const AdminLoginPayloadBuilder(
        defaultTenantSlug: 'default',
      ).build(
        email: 'admin@example.com',
        password: 'secret',
        tenantSlug: 'acme-corp',
      );

      expect(payload['tenantSlug'], 'acme-corp');
    });
  });
}
