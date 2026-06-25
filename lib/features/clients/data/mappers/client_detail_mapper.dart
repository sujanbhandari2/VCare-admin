import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_detail_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';

extension ClientDetailModelMapper on ClientDetailModel {
  ClientDetail toEntity() {
    return ClientDetail(
      id: profile.id,
      fullName: joinClientName(
        firstName: profile.firstName,
        middleName: profile.middleName,
        lastName: profile.lastName,
      ),
      email: contact.email ?? '',
      phone: contact.phoneNumber ?? '',
      avatarUrl: '',
      dob: profile.dateOfBirth ?? '',
      location: formatClientLocation(profile.address),
      gender: _mapGender(profile.gender),
      ssn: formatClientSsn(profile.ssnLast4),
      status: profile.status ?? '',
      allowTextNotification: contact.allowTextNotification ?? false,
      cardLast4: memberCard?.cardLast4,
      cardBrand: memberCard?.cardBrand,
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
