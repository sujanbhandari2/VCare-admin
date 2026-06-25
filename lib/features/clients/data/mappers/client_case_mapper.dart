import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_case_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';

extension ClientCaseModelMapper on ClientCaseModel {
  ClientCase toEntity() {
    return ClientCase(
      id: id,
      caseId: shortCaseId(id),
      title: _resolveTitle(title, type),
      status: _mapStatus(status),
      createdAt: createdAt ?? '',
      updatedAt: updatedAt ?? createdAt ?? '',
    );
  }
}

String _resolveTitle(String? title, String? type) {
  if (title?.trim().isNotEmpty == true) return title!.trim();
  if (type?.trim().isNotEmpty == true) return type!.trim();
  return '—';
}

ClientCaseStatus _mapStatus(String? status) {
  switch (status?.toUpperCase()) {
    case 'REQUESTED':
      return ClientCaseStatus.requested;
    case 'IN_PROGRESS':
    case 'IN PROGRESS':
      return ClientCaseStatus.inProgress;
    case 'RESOLVED':
    case 'CLOSED':
    case 'COMPLETED':
      return ClientCaseStatus.resolved;
    default:
      return ClientCaseStatus.requested;
  }
}
