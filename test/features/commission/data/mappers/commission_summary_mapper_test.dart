import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/commission/data/mappers/commission_summary_mapper.dart';
import 'package:vcare_admin/features/commission/data/models/commission_summary_model.dart';

void main() {
  group('CommissionSummaryModelMapper', () {
    test('maps individual commission summary', () {
      final model = CommissionSummaryModel.fromJson({
        'totalSales': 1200.0,
        'totalCommission': 48.0,
      });

      final entity = model.toEntity();

      expect(entity.totalSales, 1200.0);
      expect(entity.totalCommission, 48.0);
      expect(entity.isAgencyGroup, isFalse);
    });

    test('maps agency group summary when commission is null', () {
      final model = CommissionSummaryModel.fromJson({
        'totalSales': 5000.0,
        'totalCommission': null,
      });

      final entity = model.toEntity();

      expect(entity.totalSales, 5000.0);
      expect(entity.totalCommission, isNull);
      expect(entity.isAgencyGroup, isTrue);
    });

    test('maps zero commission as individual mode', () {
      final model = CommissionSummaryModel.fromJson({
        'totalSales': 0,
        'totalCommission': 0,
      });

      final entity = model.toEntity();

      expect(entity.totalCommission, 0);
      expect(entity.isAgencyGroup, isFalse);
    });

    test('parses numeric strings for backwards compatibility', () {
      final model = CommissionSummaryModel.fromJson({
        'totalSales': '1200',
        'totalCommission': '48',
      });

      expect(model.totalSales, 1200);
      expect(model.totalCommission, 48);
    });
  });
}
