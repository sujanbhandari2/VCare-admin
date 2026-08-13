import 'package:vcare_admin/shared/models/loadable_list_item.dart';

/// Raw enrollment status from `GET /enrollments` — parity with web
/// `ApiEnrollmentStatus`.
enum MembershipStatus {
  submitted('SUBMITTED'),
  approved('APPROVED'),
  scheduledForCompletion('SCHEDULED_FOR_COMPLETION'),
  confirmed('CONFIRMED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const MembershipStatus(this.apiValue);

  final String apiValue;

  static MembershipStatus fromApi(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final status in MembershipStatus.values) {
      if (status.apiValue == normalized) return status;
    }
    return MembershipStatus.submitted;
  }

  /// Badge label — parity with web `MembershipStatusBadge` config.
  String get label {
    switch (this) {
      case MembershipStatus.submitted:
        return 'Submitted';
      case MembershipStatus.approved:
        return 'Approved';
      case MembershipStatus.scheduledForCompletion:
      case MembershipStatus.confirmed:
      case MembershipStatus.completed:
        return 'Completed';
      case MembershipStatus.cancelled:
        return 'Declined';
    }
  }

  bool get isSubmitted => this == MembershipStatus.submitted;
}

/// Enrollment relationship type — parity with web `ApiEnrollmentType`.
enum MembershipEnrollmentType {
  primary('PRIMARY'),
  dependent('DEPENDENT'),
  group('GROUP'),
  groupMember('GROUP_MEMBER'),
  dependentOfGroupMember('DEPENDENT_OF_GROUP_MEMBER');

  const MembershipEnrollmentType(this.apiValue);

  final String apiValue;

  static MembershipEnrollmentType fromApi(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final type in MembershipEnrollmentType.values) {
      if (type.apiValue == normalized) return type;
    }
    return MembershipEnrollmentType.primary;
  }
}

/// Client profile embedded on an enrollment record.
class MembershipClient {
  const MembershipClient({
    required this.id,
    this.firstName = '',
    this.middleName,
    this.lastName = '',
    this.companyName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.avatarUrl,
    this.clientType,
    this.ssnLast4,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
  });

  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? companyName;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final String? avatarUrl;
  final String? clientType;
  final String? ssnLast4;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;

  /// Company name for groups, person name otherwise — parity with web
  /// `membershipClientDisplayName`.
  String get displayName {
    final company = companyName?.trim();
    if (company != null && company.isNotEmpty) return company;

    final joined = [
      firstName,
      middleName,
      lastName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ').trim();

    return joined.isEmpty ? 'Client' : joined;
  }

  String get formattedAddress {
    final parts = [addressLine1, addressLine2, city, state, zipCode]
        .map((part) => part?.trim())
        .where((part) => part != null && part.isNotEmpty);

    return parts.join(', ');
  }
}

/// Offering snapshot embedded on an enrollment record.
class MembershipOffering {
  const MembershipOffering({
    required this.id,
    required this.name,
    this.fee = 0,
    this.registrationFee,
    this.offeringType,
    this.billingModel,
    this.billingInterval,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String name;
  final double fee;
  final double? registrationFee;
  final String? offeringType;
  final String? billingModel;
  final String? billingInterval;
  final String? startDate;
  final String? endDate;

  static const fallback = MembershipOffering(id: '', name: 'Membership');
}

/// A single enrollment row — used for the pending list, the detail sheet, and
/// the associated/relevant sections.
class PendingMembership implements LoadableListItem {
  const PendingMembership({
    required this.id,
    required this.clientId,
    required this.client,
    required this.offering,
    required this.enrollmentType,
    required this.status,
    this.enrollmentDisplayLabel,
    this.relationshipToPrimary,
    this.benefitStartDate,
    this.benefitEndDate,
    this.createdAt,
    this.note,
  });

  final String id;
  final String clientId;
  final MembershipClient client;
  final MembershipOffering offering;
  final MembershipEnrollmentType enrollmentType;
  final MembershipStatus status;
  final String? enrollmentDisplayLabel;
  final String? relationshipToPrimary;
  final DateTime? benefitStartDate;
  final DateTime? benefitEndDate;
  final DateTime? createdAt;
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingMembership &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// `GET /enrollments/associate-membership/:clientId` result.
class MembershipAssociatedResult {
  const MembershipAssociatedResult({
    required this.clientId,
    required this.memberships,
    required this.totalCount,
  });

  final String clientId;
  final List<PendingMembership> memberships;
  final int totalCount;

  static const empty = MembershipAssociatedResult(
    clientId: '',
    memberships: [],
    totalCount: 0,
  );
}
