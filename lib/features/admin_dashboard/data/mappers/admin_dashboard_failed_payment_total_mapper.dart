import 'package:vcare_admin/features/admin_dashboard/data/models/admin_dashboard_failed_payment_total_model.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_failed_payment_total.dart';

extension AdminDashboardFailedPaymentTotalModelMapper
    on AdminDashboardFailedPaymentTotalModel {
  AdminDashboardFailedPaymentTotal toEntity() {
    return AdminDashboardFailedPaymentTotal(totalAmount: totalAmount);
  }
}