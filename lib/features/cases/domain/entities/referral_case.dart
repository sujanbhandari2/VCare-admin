import 'package:vcare_admin/shared/models/loadable_list_item.dart';

/// Case status values matching web `CaseStatus`.
enum CaseStatus {
  newCase,
  requested,
  inProgress,
  closed,
  deleted;

  String get apiValue => switch (this) {
    CaseStatus.newCase => 'NEW',
    CaseStatus.requested => 'REQUESTED',
    CaseStatus.inProgress => 'IN_PROGRESS',
    CaseStatus.closed => 'CLOSED',
    CaseStatus.deleted => 'DELETED',
  };

  /// Lowercase snake value used in note multipart form fields.
  String get multipartValue => switch (this) {
    CaseStatus.newCase => 'new',
    CaseStatus.requested => 'requested',
    CaseStatus.inProgress => 'in_progress',
    CaseStatus.closed => 'closed',
    CaseStatus.deleted => 'deleted',
  };

  String get label => switch (this) {
    CaseStatus.newCase => 'New',
    CaseStatus.requested => 'Requested',
    CaseStatus.inProgress => 'In Progress',
    CaseStatus.closed => 'Closed',
    CaseStatus.deleted => 'Deleted',
  };

  static CaseStatus fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'NEW':
        return CaseStatus.newCase;
      case 'REQUESTED':
      case 'OPEN':
        return CaseStatus.requested;
      case 'IN_PROGRESS':
      case 'IN PROGRESS':
      case 'ACTIVE':
        return CaseStatus.inProgress;
      case 'CLOSED':
      case 'RESOLVED':
      case 'COMPLETED':
        return CaseStatus.closed;
      case 'DELETED':
        return CaseStatus.deleted;
      default:
        return CaseStatus.newCase;
    }
  }
}

/// Case priority values matching web `CasePriority`.
enum CasePriority {
  low,
  medium,
  high,
  urgent;

  String get apiValue => switch (this) {
    CasePriority.low => 'LOW',
    CasePriority.medium => 'MEDIUM',
    CasePriority.high => 'HIGH',
    CasePriority.urgent => 'URGENT',
  };

  String get label => switch (this) {
    CasePriority.low => 'Low',
    CasePriority.medium => 'Medium',
    CasePriority.high => 'High',
    CasePriority.urgent => 'Urgent',
  };

  String get filterLabel => '$label Priority';

  static CasePriority fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'LOW':
        return CasePriority.low;
      case 'HIGH':
        return CasePriority.high;
      case 'URGENT':
        return CasePriority.urgent;
      case 'MEDIUM':
      default:
        return CasePriority.medium;
    }
  }
}

/// Domain entity for a referral case (list + detail).
class ReferralCase implements LoadableListItem {
  const ReferralCase({
    required this.id,
    required this.caseNumber,
    required this.title,
    required this.status,
    required this.priority,
    required this.caseType,
    required this.clientId,
    required this.client,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.assignedTo = 'Unassigned',
    this.assignedToId,
    this.createdBy = '',
    this.createdById,
    this.clonedFromCaseId,
    this.isBookmarked = false,
    this.sponsorId,
    this.sponsorType,
  });

  final String id;
  final String caseNumber;
  final String title;
  final String description;
  final CaseStatus status;
  final CasePriority priority;
  final String caseType;
  final String clientId;
  final ReferralCaseClient client;
  final String assignedTo;
  final String? assignedToId;
  final String createdBy;
  final String? createdById;
  final String? clonedFromCaseId;
  final String createdAt;
  final String updatedAt;
  final bool isBookmarked;
  final String? sponsorId;
  final String? sponsorType;

  String get listItemId => id;

  ReferralCase copyWith({
    String? id,
    String? caseNumber,
    String? title,
    String? description,
    CaseStatus? status,
    CasePriority? priority,
    String? caseType,
    String? clientId,
    ReferralCaseClient? client,
    String? assignedTo,
    String? assignedToId,
    bool clearAssignedToId = false,
    String? createdBy,
    String? createdById,
    String? clonedFromCaseId,
    String? createdAt,
    String? updatedAt,
    bool? isBookmarked,
    String? sponsorId,
    String? sponsorType,
  }) {
    return ReferralCase(
      id: id ?? this.id,
      caseNumber: caseNumber ?? this.caseNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      caseType: caseType ?? this.caseType,
      clientId: clientId ?? this.clientId,
      client: client ?? this.client,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToId: clearAssignedToId
          ? null
          : (assignedToId ?? this.assignedToId),
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      clonedFromCaseId: clonedFromCaseId ?? this.clonedFromCaseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      sponsorId: sponsorId ?? this.sponsorId,
      sponsorType: sponsorType ?? this.sponsorType,
    );
  }
}

/// Client profile embedded on a referral case.
class ReferralCaseClient {
  const ReferralCaseClient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.email = '',
    this.phone = '',
    this.dateOfBirth = '',
    this.avatarUrl,
    this.profilePreviewLink,
    this.membershipPlan,
    this.bloodType,
    this.dependentOf,
    this.address,
  });

  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String phone;
  final String dateOfBirth;
  final String? avatarUrl;
  final String? profilePreviewLink;
  final String? membershipPlan;
  final String? bloodType;
  final String? dependentOf;
  final String? address;

  String get fullName {
    final parts = [
      firstName.trim(),
      if (middleName != null && middleName!.trim().isNotEmpty)
        middleName!.trim(),
      lastName.trim(),
    ].where((p) => p.isNotEmpty);
    return parts.join(' ');
  }

  /// Prefer a real name; fall back to email when the API omitted name fields.
  String get displayName {
    final name = fullName.trim();
    if (name.isNotEmpty) return name;
    final mail = email.trim();
    if (mail.isNotEmpty) return mail;
    return 'Unknown client';
  }

  String get initials {
    final name = fullName.trim();
    if (name.isNotEmpty) {
      final parts = name
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.length == 1) {
        return parts.first.substring(0, 1).toUpperCase();
      }
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    final mail = email.trim();
    if (mail.isNotEmpty) return mail[0].toUpperCase();
    return '?';
  }

  bool get hasIdentity => fullName.trim().isNotEmpty || email.trim().isNotEmpty;
}
