import 'package:vcare_admin/features/cases/data/models/referral_case_model.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';

extension ReferralCaseModelMapper on ReferralCaseModel {
  ReferralCase toEntity() {
    final caseType = resolveCaseTypeLabel(type);
    final displayCaseNumber = caseNumber?.trim().isNotEmpty == true
        ? caseNumber!.trim()
        : formatCaseNumber(id);
    final titleValue = title?.trim().isNotEmpty == true
        ? title!.trim()
        : (caseType.isNotEmpty ? caseType : 'Case');

    return ReferralCase(
      id: id,
      caseNumber: displayCaseNumber,
      title: titleValue,
      description: description ?? '',
      status: CaseStatus.fromApi(status),
      priority: CasePriority.fromApi(priority),
      caseType: caseType,
      clientId: clientId,
      client: _mapClient(client, clientId),
      assignedTo: _mapPersonDisplay(assignee, fallback: 'Unassigned'),
      assignedToId: assignedTo,
      createdBy: _resolveCreatedByDisplay(this),
      createdById: createdBy?.id,
      clonedFromCaseId: clonedFromCaseId,
      createdAt: createdAt ?? '',
      updatedAt: updatedAt ?? createdAt ?? '',
      isBookmarked: isBookmarked,
      sponsorId: sponsorId,
      sponsorType: sponsorType,
    );
  }
}

ReferralCaseClient _mapClient(
  ReferralCaseClientModel? client,
  String clientId,
) {
  if (client == null) {
    return ReferralCaseClient(
      id: clientId,
      firstName: '',
      lastName: '',
    );
  }

  final contact = client.contact;
  final email = contact?.email ?? '';
  final phone = contact?.resolvedPhone ?? '';
  final clientType = (client.clientType ?? '').trim().toUpperCase();
  final profilePreviewLink = client.profilePreviewLink;
  final address = _formatAddress(client.address);
  final dateOfBirth = _formatApiDate(client.dateOfBirth);

  if (clientType == 'GROUP') {
    final companyName =
        client.companyName ??
        client.name?.companyName ??
        '';
    final contactFirstName =
        client.contactFirstName ??
        client.name?.contactFirstName ??
        contact?.firstName ??
        '';
    final contactLastName =
        client.contactLastName ??
        client.name?.contactLastName ??
        contact?.lastName ??
        '';

    final displayName = companyName.trim().isNotEmpty
        ? companyName.trim()
        : [
            contactFirstName.trim(),
            contactLastName.trim(),
          ].where((part) => part.isNotEmpty).join(' ');

    return ReferralCaseClient(
      id: client.id.isNotEmpty ? client.id : clientId,
      firstName: displayName,
      lastName: '',
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      avatarUrl: client.avatarUrl,
      profilePreviewLink: profilePreviewLink,
      membershipPlan: companyName.trim().isNotEmpty
          ? companyName.trim()
          : client.membershipPlan,
      bloodType: client.bloodType,
      dependentOf: client.dependentOf,
      address: address,
    );
  }

  final firstName = client.name?.firstName ?? contact?.firstName ?? '';
  final middleName = client.name?.middleName;
  final lastName = client.name?.lastName ?? contact?.lastName ?? '';

  return ReferralCaseClient(
    id: client.id.isNotEmpty ? client.id : clientId,
    firstName: firstName,
    middleName: middleName,
    lastName: lastName,
    email: email,
    phone: phone,
    dateOfBirth: dateOfBirth,
    avatarUrl: client.avatarUrl,
    profilePreviewLink: profilePreviewLink,
    membershipPlan: client.membershipPlan,
    bloodType: client.bloodType,
    dependentOf: client.dependentOf,
    address: address,
  );
}

String _formatAddress(Map<String, dynamic>? address) {
  if (address == null || address.isEmpty) return '';

  final line1 = _stringFrom(address['addressLine1']);
  final line2 = _stringFrom(address['addressLine2']);
  final city = _stringFrom(address['city']);
  final state = _stringFrom(address['state']);
  final postal = _stringFrom(address['postalCode'] ?? address['zipCode']);
  final cityState = [city, state].where((part) => part.isNotEmpty).join(', ');

  return [line1, line2, cityState, postal]
      .where((part) => part.isNotEmpty)
      .join(', ');
}

String _formatApiDate(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final local = parsed.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$month/$day/$year';
}

String _mapPersonDisplay(
  ReferralCasePersonModel? person, {
  String fallback = '—',
}) {
  if (person == null) return fallback;
  final fullName = person.fullName.trim();
  if (fullName.isNotEmpty) return fullName;
  final email = person.email?.trim();
  if (email != null && email.isNotEmpty) return email;
  return fallback;
}

String _resolveCreatedByDisplay(ReferralCaseModel record) {
  if (record.creator != null) {
    return _mapPersonDisplay(record.creator);
  }

  final createdBy = record.createdBy;
  if (createdBy != null && createdBy.fullName.trim().isNotEmpty) {
    return _mapPersonDisplay(createdBy);
  }

  final createdById = createdBy?.id;
  final assignee = record.assignee;

  if (assignee != null && createdById != null) {
    if (_idsMatch(assignee.id, createdById)) {
      return _mapPersonDisplay(assignee);
    }
    if (_idsMatch(createdById, record.assignedTo) &&
        (assignee.id == null || _idsMatch(assignee.id, record.assignedTo))) {
      return _mapPersonDisplay(assignee);
    }
  }

  if (createdById != null && createdById.isNotEmpty) return createdById;
  return '—';
}

bool _idsMatch(String? left, String? right) {
  if (left == null || right == null) return false;
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}

String _stringFrom(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}
