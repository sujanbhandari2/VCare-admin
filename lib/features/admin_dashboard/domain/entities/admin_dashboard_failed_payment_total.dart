/// Total at-risk amount from `GET /admin/todo-list/failed-payments/total`.
class AdminDashboardFailedPaymentTotal {
  const AdminDashboardFailedPaymentTotal({this.totalAmount = 0});

  final double totalAmount;

  static const zero = AdminDashboardFailedPaymentTotal();
}