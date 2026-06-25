import 'package:vcare_admin/features/commission/data/models/commission_summary_model.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';

extension CommissionSummaryModelMapper on CommissionSummaryModel {
  CommissionSummary toEntity() {
    return CommissionSummary(
      totalSales: totalSales,
      totalCommission: totalCommission,
    );
  }
}
