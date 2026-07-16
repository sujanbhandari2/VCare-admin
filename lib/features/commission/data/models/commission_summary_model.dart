class CommissionSummaryModel {
  const CommissionSummaryModel({
    this.totalSales,
    this.totalCommission,
  });

  final String? totalSales;
  final String? totalCommission;

  factory CommissionSummaryModel.fromJson(Map<String, dynamic> json) {
    return CommissionSummaryModel(
      totalSales: json['totalSales']?.toString(),
      totalCommission: json['totalCommission']?.toString(),
    );
  }
}
