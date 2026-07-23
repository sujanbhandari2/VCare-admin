import 'package:vcare_admin/features/commission/data/models/commission_history_item_model.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';

extension CommissionHistoryItemModelMapper on CommissionHistoryItemModel {
  CommissionHistoryItem toEntity() {
    return CommissionHistoryItem(
      id: id,
      tenantId: tenantId,
      commissionSettingsId: commissionSettingsId,
      transactionId: transactionId,
      agencyGroupId: agencyGroupId,
      referrerAgentId: referrerAgentId,
      clientId: clientId,
      clientName: clientName,
      commissionValue: commissionValue,
      commissionType: commissionType,
      commissionAmount: commissionAmount,
      status: _mapStatus(status),
      paidAt: paidAt,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CommissionStatus _mapStatus(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return CommissionStatus.pending;
      case 'PAID':
        return CommissionStatus.paid;
      case 'REJECTED':
      case 'CANCELLED':
      case 'CANCELED':
        return CommissionStatus.cancelled;
      default:
        return CommissionStatus.unknown;
    }
  }
}
