import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/admin_dashboard/data/mappers/admin_dashboard_failed_payment_total_mapper.dart';
import 'package:vcare_admin/features/admin_dashboard/data/models/admin_dashboard_failed_payment_total_model.dart';

void main() {
  group('AdminDashboardFailedPaymentTotalModel', () {
    test('parses numeric and string totalAmount values', () {
      final fromNumber = AdminDashboardFailedPaymentTotalModel.fromJson({
        'totalAmount': 1250.5,
      });
      final fromString = AdminDashboardFailedPaymentTotalModel.fromJson({
        'totalAmount': '99.99',
      });

      expect(fromNumber.toEntity().totalAmount, 1250.5);
      expect(fromString.toEntity().totalAmount, 99.99);
    });

    test('defaults invalid values to zero', () {
      final model = AdminDashboardFailedPaymentTotalModel.fromJson({
        'totalAmount': 'not-a-number',
      });

      expect(model.toEntity().totalAmount, 0);
    });
  });
}