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
    this.commissionValue,
    required this.commissionType,
    this.commissionAmount,
    required this.status,
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
  final String? commissionValue;
  final String commissionType;
  final double? commissionAmount;
  final CommissionStatus status;
  final String? paidAt;
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  String get displayClientName {
    final name = clientName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (clientId.isEmpty) return 'Client';
    if (clientId.length <= 8) return 'Client $clientId';
    return 'Client ${clientId.substring(0, 8)}…';
  }
}
