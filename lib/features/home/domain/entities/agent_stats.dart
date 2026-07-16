/// Agent overview stats returned by `GET agents/stats`.
class AgentStats {
  const AgentStats({
    required this.totalClients,
    this.totalSales,
    this.totalCommission,
  });

  final int totalClients;
  final String? totalSales;
  final String? totalCommission;

  bool get hasCommission => totalCommission != null;
}
