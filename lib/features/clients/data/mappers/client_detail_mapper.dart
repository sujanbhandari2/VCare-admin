import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_detail_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';

extension ClientDetailModelMapper on ClientDetailModel {
  ClientDetail toEntity() {
    final isGroup = profile.isGroup;
    final fullName = isGroup
        ? _groupDisplayName()
        : joinClientName(
            firstName: profile.firstName,
            middleName: profile.middleName,
            lastName: profile.lastName,
          );

    return ClientDetail(
      id: profile.id,
      fullName: fullName,
      email: contact.email ?? '',
      phone: contact.phoneNumber ?? '',
      avatarUrl: profile.profilePreviewLink ?? '',
      dob: profile.dateOfBirth ?? '',
      location: formatClientLocation(profile.address),
      gender: _mapGender(profile.gender),
      ssn: formatClientSsn(profile.ssnLast4),
      status: profile.status ?? '',
      allowTextNotification: contact.allowTextNotification ?? false,
      clientType: isGroup
          ? ClientListType.group
          : ClientListType.individual,
      cardLast4: memberCard?.cardLast4,
      cardBrand: memberCard?.cardBrand,
      affiliateAgents: affiliateAgents
          .map((agent) => agent.toEntity())
          .toList(),
    );
  }

  String _groupDisplayName() {
    final company = profile.companyName?.trim();
    if (company != null && company.isNotEmpty) return company;

    return joinClientName(
      firstName: profile.contactFirstName ?? profile.firstName,
      lastName: profile.contactLastName ?? profile.lastName,
    );
  }

  ClientGender _mapGender(String? value) {
    switch (value?.toUpperCase()) {
      case 'MALE':
        return ClientGender.male;
      case 'FEMALE':
        return ClientGender.female;
      default:
        return ClientGender.nonBinary;
    }
  }
}

extension ClientAffiliateAgentModelMapper on ClientAffiliateAgentModel {
  ClientAffiliateAgent toEntity() {
    final agency = agencyGroupName?.trim();
    final code = agentCode?.trim();

    return ClientAffiliateAgent(
      id: id,
      name: _displayName(agency: agency, code: code),
      roleLabel: _roleLabel(agency: agency, code: code),
      avatarUrl: profilePreviewLink ?? '',
      email: _trimToNull(email),
      phone: _trimToNull(phoneNumber),
    );
  }

  String _displayName({String? agency, String? code}) {
    final name = joinClientName(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
    );
    if (name.isNotEmpty) return name;
    if (agency != null && agency.isNotEmpty) return agency;
    if (code != null && code.isNotEmpty) return code;
    return 'Affiliate';
  }

  String _roleLabel({String? agency, String? code}) {
    if (isAgencyGroup) {
      return agency != null && agency.isNotEmpty ? agency : 'Agency Group';
    }
    return code != null && code.isNotEmpty ? 'Agent · $code' : 'Agent';
  }

  String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
