import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_list_item_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';

extension ClientListItemModelMapper on ClientListItemModel {
  ClientListItem toEntity() {
    return ClientListItem(
      id: id,
      fullName: _displayName(),
      email: contact?.email ?? '',
      phone: contact?.phoneNumber ?? '',
      location: formatClientLocation(address),
      avatarUrl: '',
      clientType: isGroup ? ClientListType.group : ClientListType.individual,
    );
  }

  String _displayName() {
    if (isGroup) {
      final company = companyName?.trim();
      if (company != null && company.isNotEmpty) {
        return company;
      }

      return joinClientName(
        firstName: contactFirstName,
        lastName: contactLastName,
      );
    }

    return joinClientNameFromModel(name);
  }
}
