class AdminDashboardTodoMetricsModel {
  const AdminDashboardTodoMetricsModel({
    this.failedPayments = 0,
    this.overdue = 0,
    this.dueSoon = 0,
  });

  factory AdminDashboardTodoMetricsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardTodoMetricsModel(
      failedPayments: _parseInt(json['failedPayments']),
      overdue: _parseInt(json['overdue']),
      dueSoon: _parseInt(json['dueSoon']),
    );
  }

  final int failedPayments;
  final int overdue;
  final int dueSoon;

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
