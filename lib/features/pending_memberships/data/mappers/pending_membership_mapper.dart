import 'package:vcare_admin/features/pending_memberships/data/models/pending_membership_model.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/utils/membership_parsers.dart';

extension MembershipClientModelMapper on MembershipClientModel {
  MembershipClient toEntity({String? fallbackId}) {
    return MembershipClient(
      id: id.trim().isNotEmpty ? id : (fallbackId ?? ''),
      firstName: firstName?.trim() ?? '',
      middleName: middleName?.trim(),
      lastName: lastName?.trim() ?? '',
      companyName: companyName?.trim(),
      email: email?.trim(),
      phone: phoneNumber?.trim(),
      dateOfBirth: dateOfBirth?.trim(),
      avatarUrl: profilePreviewLink?.trim(),
      clientType: clientType?.trim(),
      ssnLast4: ssnLast4?.trim(),
      addressLine1: addressLine1?.trim(),
      addressLine2: addressLine2?.trim(),
      city: city?.trim(),
      state: state?.trim(),
      zipCode: zipCode?.trim(),
    );
  }
}

extension MembershipOfferingModelMapper on MembershipOfferingModel {
  MembershipOffering toEntity({String? fallbackId}) {
    final registration = parseMembershipAmount(registrationFee);

    return MembershipOffering(
      id: id?.trim().isNotEmpty == true ? id!.trim() : (fallbackId ?? ''),
      name: name?.trim().isNotEmpty == true ? name!.trim() : 'Membership',
      fee: parseMembershipAmount(fee),
      registrationFee: registration > 0 ? registration : null,
      offeringType: offeringType?.trim(),
      billingModel: billingModel?.trim(),
      billingInterval: billingInterval?.trim(),
      startDate: startDate?.trim(),
      endDate: endDate?.trim(),
    );
  }
}

extension PendingMembershipModelMapper on PendingMembershipModel {
  PendingMembership toEntity() {
    final resolvedClientId = clientId?.trim() ?? '';
    final createdAtDate = parseMembershipDate(createdAt);

    return PendingMembership(
      id: id,
      clientId: resolvedClientId,
      client:
          client?.toEntity(fallbackId: resolvedClientId) ??
          MembershipClient(id: resolvedClientId),
      offering:
          offering?.toEntity(fallbackId: offeringId?.trim()) ??
          MembershipOffering.fallback,
      enrollmentType: MembershipEnrollmentType.fromApi(enrollmentType),
      status: MembershipStatus.fromApi(status),
      enrollmentDisplayLabel: enrollmentDisplayLabel?.trim(),
      relationshipToPrimary: relationshipToPrimary?.trim(),
      benefitStartDate: parseMembershipDate(startDate) ?? createdAtDate,
      benefitEndDate: parseMembershipDate(endDate),
      createdAt: createdAtDate,
      note: note?.trim(),
    );
  }
}

extension MembershipAssociatedResultModelMapper
    on MembershipAssociatedResultModel {
  MembershipAssociatedResult toEntity() {
    final memberships = details
        .map((detail) => detail.toEntity())
        .toList(growable: false);

    return MembershipAssociatedResult(
      clientId: clientId,
      memberships: memberships,
      totalCount: totalGroup > 0 ? totalGroup : memberships.length,
    );
  }
}
