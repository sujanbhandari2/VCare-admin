import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_list_item_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';

extension ClientListItemModelMapper on ClientListItemModel {
  ClientListItem toEntity() {
    return ClientListItem(
      id: id,
      fullName: joinClientNameFromModel(name),
      email: contact?.email ?? '',
      phone: contact?.phoneNumber ?? '',
      location: formatClientLocation(address),
      avatarUrl: '',
    );
  }
}
