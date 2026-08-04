import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/home/data/mappers/agent_stats_mapper.dart';
import 'package:vcare_admin/features/home/data/models/agent_stats_model.dart';

void main() {
  group('AgentStatsModelMapper', () {
    test('maps stats with commission', () {
      final model = AgentStatsModel.fromJson({
        'totalClients': 2,
        'totalSales': 124800.0,
        'totalCommission': 12480.0,
      });

      final entity = model.toEntity();

      expect(entity.totalClients, 2);
      expect(entity.totalSales, 124800.0);
      expect(entity.totalCommission, 12480.0);
      expect(entity.hasCommission, isTrue);
      expect(entity.isAgencyAssociated, isFalse);
    });

    test('maps stats without commission', () {
      final model = AgentStatsModel.fromJson({
        'totalClients': 5,
        'totalSales': 50000.0,
        'totalCommission': null,
      });

      final entity = model.toEntity();

      expect(entity.totalClients, 5);
      expect(entity.totalSales, 50000.0);
      expect(entity.totalCommission, isNull);
      expect(entity.hasCommission, isFalse);
      expect(entity.isAgencyAssociated, isTrue);
    });

    test('parses string totals for backwards compatibility', () {
      final model = AgentStatsModel.fromJson({
        'totalClients': '3',
        'totalSales': '0',
        'totalCommission': '12',
      });

      expect(model.totalClients, 3);
      expect(model.totalSales, 0);
      expect(model.totalCommission, 12);
    });
  });
}
