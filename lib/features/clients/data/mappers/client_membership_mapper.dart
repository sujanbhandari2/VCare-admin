import 'package:vcare_admin/features/clients/data/mappers/client_list_item_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_membership_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_memberships_result.dart';

extension ClientMembershipModelMapper on ClientMembershipModel {
  ClientMembership toEntity() {
    final offering = offeringDetails;
    final fee = parseAmount(offering?.fee);
    final billingInterval = offering?.billingInterval;

    return ClientMembership(
      id: id,
      plan: offering?.offeringName ?? 'Membership',
      carrier: offering?.description ?? '—',
      memberId: clientId ?? '—',
      status: _mapStatus(status),
      benefitDate: startDate ?? '',
      cost: fee,
      costUnit: billingInterval == null
          ? 'per period'
          : 'per ${billingInterval.toLowerCase()}',
      tier: enrollmentDisplayLabel ?? enrollmentType ?? '—',
      note: note,
      nextBillingDate: null,
    );
  }

  ClientDependent? toDependentEntity() {
    if (enrollmentType?.toUpperCase() == 'PRIMARY') {
      return null;
    }

    final dependentClient = client;
    if (dependentClient == null) {
      return null;
    }

    return ClientDependent(
      id: dependentClient.id,
      name: dependentClient.toEntity().fullName,
      relation: _resolveDependentRelation(
        relationshipToPrimary: relationshipToPrimary,
        enrollmentDisplayLabel: enrollmentDisplayLabel,
        enrollmentType: enrollmentType,
      ),
      avatarUrl: '',
    );
  }

  ClientDependent toDependentEntityOrFallback() {
    return toDependentEntity() ??
        ClientDependent(
          id: client?.id ?? clientId ?? id,
          name: client != null
              ? client!.toEntity().fullName
              : (enrollmentDisplayLabel ?? 'Dependent'),
          relation: _resolveDependentRelation(
            relationshipToPrimary: relationshipToPrimary,
            enrollmentDisplayLabel: enrollmentDisplayLabel,
            enrollmentType: enrollmentType,
          ),
          avatarUrl: '',
        );
  }

  ClientMembershipStatus _mapStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'APPROVED':
        return ClientMembershipStatus.approved;
      case 'SUBMITTED':
        return ClientMembershipStatus.submitted;
      case 'COMPLETED':
        return ClientMembershipStatus.completed;
      case 'CANCELLED':
        return ClientMembershipStatus.cancelled;
      default:
        return ClientMembershipStatus.submitted;
    }
  }
}

extension ClientMembershipsResultModelMapper on ClientMembershipsResultModel {
  ClientMembershipsResult toEntity() {
    final memberships = details.map((detail) => detail.toEntity()).toList();

    return ClientMembershipsResult(
      clientId: clientId,
      memberships: memberships,
      totalGroup: totalGroup,
    );
  }
}

String _resolveDependentRelation({
  String? relationshipToPrimary,
  String? enrollmentDisplayLabel,
  String? enrollmentType,
}) {
  if (relationshipToPrimary != null && relationshipToPrimary.trim().isNotEmpty) {
    return humanizeApiEnum(relationshipToPrimary);
  }
  if (enrollmentDisplayLabel != null && enrollmentDisplayLabel.trim().isNotEmpty) {
    return enrollmentDisplayLabel;
  }
  final typeLabel = humanizeApiEnum(enrollmentType);
  if (typeLabel != '—') {
    return typeLabel;
  }
  return 'Dependent';
}
