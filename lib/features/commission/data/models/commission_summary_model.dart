class CommissionSummaryModel {
  const CommissionSummaryModel({this.totalSales, this.totalCommission});

  final double? totalSales;
  final double? totalCommission;

  factory CommissionSummaryModel.fromJson(Map<String, dynamic> json) {
    return CommissionSummaryModel(
      totalSales: _asDouble(json['totalSales']),
      totalCommission: _asDouble(json['totalCommission']),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
