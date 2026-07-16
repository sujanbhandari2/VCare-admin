import 'package:vcare_admin/features/home/data/models/agent_stats_model.dart';
import 'package:vcare_admin/features/home/domain/entities/agent_stats.dart';

extension AgentStatsModelMapper on AgentStatsModel {
  AgentStats toEntity() {
    return AgentStats(
      totalClients: totalClients,
      totalSales: totalSales,
      totalCommission: totalCommission,
    );
  }
}
