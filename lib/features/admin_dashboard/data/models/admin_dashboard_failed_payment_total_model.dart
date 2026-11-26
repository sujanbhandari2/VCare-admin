class AdminDashboardFailedPaymentTotalModel {
  const AdminDashboardFailedPaymentTotalModel({this.totalAmount = 0});

  final double totalAmount;

  factory AdminDashboardFailedPaymentTotalModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['totalAmount'];
    final amount = switch (raw) {
      null => 0.0,
      num value => value.toDouble(),
      String value => double.tryParse(value) ?? 0.0,
      _ => 0.0,
    };

    return AdminDashboardFailedPaymentTotalModel(totalAmount: amount);
  }
}