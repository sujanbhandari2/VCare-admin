import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/shared/models/loadable_list_item.dart';

class CommissionHistoryItem implements LoadableListItem {
  const CommissionHistoryItem({
    required this.id,
    this.tenantId,
    this.commissionSettingsId,
    this.transactionId,
    this.agencyGroupId,
    this.referrerAgentId,
    required this.clientId,
    this.clientName,
    this.clientPhotoUrl,
    this.offeringName,
    this.itemType,
    this.commissionValue,
    required this.commissionType,
    this.commissionAmount,
    this.salesAmount,
    required this.status,
    this.apiStatus = '',
    this.paidAt,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? tenantId;
  final String? commissionSettingsId;
  final String? transactionId;
  final String? agencyGroupId;
  final String? referrerAgentId;
  final String clientId;
  final String? clientName;
  final String? clientPhotoUrl;
  final String? offeringName;

  /// API row source: `COMMISSION` | `ENROLLMENT` | `UPCOMING`.
  final String? itemType;
  final String? commissionValue;
  final String commissionType;
  final double? commissionAmount;
  final double? salesAmount;
  final CommissionStatus status;

  /// Raw API status string used for display label resolution.
  final String apiStatus;
  final String? paidAt;
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  /// True when linked transaction payment failed (API status `FAILED`).
  bool get paymentFailed => apiStatus.toUpperCase() == 'FAILED';

  bool get canRecoverPayment =>
      paymentFailed &&
      clientId.trim().isNotEmpty &&
      (transactionId?.trim().isNotEmpty ?? false);

  /// Prefer paid date for display, matching web commission list.
  String get displayDate =>
      paidAt?.trim().isNotEmpty == true ? paidAt! : createdAt;

  String get displayClientName {
    final name = clientName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (clientId.isEmpty) return 'Client';
    final shortId = clientId.replaceAll('-', '');
    final compact = shortId.length <= 8 ? shortId : shortId.substring(0, 8);
    return 'Client ${compact.toUpperCase()}';
  }
}
