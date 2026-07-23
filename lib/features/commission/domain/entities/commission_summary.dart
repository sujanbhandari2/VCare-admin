/// Commission totals returned by `GET agents/commission-summary`.
class CommissionSummary {
  const CommissionSummary({this.totalSales, this.totalCommission});

  final double? totalSales;
  final double? totalCommission;

  bool get isAgencyGroup => totalCommission == null;
}
