/// Commission totals returned by `GET agents/commission-summary`,
/// plus client-side Upcoming / Needs Attention aggregates from history.
class CommissionSummary {
  const CommissionSummary({
    this.totalSales,
    this.totalCommission,
    this.upcomingSales = 0,
    this.upcomingCount = 0,
    this.needsAttentionSales = 0,
    this.needsAttentionCount = 0,
  });

  final double? totalSales;
  final double? totalCommission;

  /// Sum of sale amounts from `type=upcoming` history (limit 100).
  final double upcomingSales;
  final int upcomingCount;

  /// Sum of sale amounts from failed `type=commission` rows (limit 100).
  final double needsAttentionSales;
  final int needsAttentionCount;

  bool get isAgencyGroup => totalCommission == null;

  CommissionSummary copyWithAggregates({
    required double upcomingSales,
    required int upcomingCount,
    required double needsAttentionSales,
    required int needsAttentionCount,
  }) {
    return CommissionSummary(
      totalSales: totalSales,
      totalCommission: totalCommission,
      upcomingSales: upcomingSales,
      upcomingCount: upcomingCount,
      needsAttentionSales: needsAttentionSales,
      needsAttentionCount: needsAttentionCount,
    );
  }
}
