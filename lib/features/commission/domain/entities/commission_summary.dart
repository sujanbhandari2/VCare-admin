/// Commission totals returned by `GET agents/commission-summary`.
class CommissionSummary {
  const CommissionSummary({
    this.totalSales,
    this.totalCommission,
  });

  final String? totalSales;
  final String? totalCommission;

  bool get isAgencyGroup => totalCommission == null;
}
