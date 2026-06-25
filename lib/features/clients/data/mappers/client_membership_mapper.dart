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
      relation: relationshipToPrimary ??
          enrollmentDisplayLabel ??
          enrollmentType ??
          'Dependent',
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
    final memberships = <ClientMembership>[];
    final dependents = <ClientDependent>[];

    for (final detail in details) {
      memberships.add(detail.toEntity());
      final dependent = detail.toDependentEntity();
      if (dependent != null) {
        dependents.add(dependent);
      }
    }

    return ClientMembershipsResult(
      clientId: clientId,
      memberships: memberships,
      dependents: dependents,
      totalGroup: totalGroup,
    );
  }
}
