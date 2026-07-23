/// Agent overview stats returned by `GET agents/stats`.
class AgentStats {
  const AgentStats({
    required this.totalClients,
    this.totalSales,
    this.totalCommission,
  });

  final int totalClients;
  final double? totalSales;
  final double? totalCommission;

  bool get hasCommission => totalCommission != null;

  /// Matches web: agency-associated agents omit commission from stats.
  bool get isAgencyAssociated => totalCommission == null;
}
