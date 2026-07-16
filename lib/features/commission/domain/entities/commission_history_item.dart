import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/shared/models/loadable_list_item.dart';

class CommissionHistoryItem implements LoadableListItem {
  const CommissionHistoryItem({
    required this.id,
    required this.clientId,
    this.clientName,
    required this.commissionValue,
    required this.commissionType,
    required this.commissionAmount,
    required this.status,
    this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String? clientName;
  final String commissionValue;
  final String commissionType;
  final String commissionAmount;
  final CommissionStatus status;
  final String? paidAt;
  final String createdAt;

  String get displayClientName {
    final name = clientName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (clientId.isEmpty) return 'Client';
    if (clientId.length <= 8) return 'Client $clientId';
    return 'Client ${clientId.substring(0, 8)}…';
  }
}
