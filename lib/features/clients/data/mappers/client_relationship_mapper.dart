import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_relationship_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';

extension ClientRelationshipModelMapper on ClientRelationshipModel {
  ClientDependent toDependentEntity() {
    final company = companyName?.trim();
    final name = (company != null && company.isNotEmpty)
        ? company
        : joinClientName(
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
          );

    return ClientDependent(
      id: clientId ?? id,
      name: name.isNotEmpty ? name : 'Dependent',
      relation: relationship != null && relationship!.trim().isNotEmpty
          ? humanizeApiEnum(relationship)
          : 'Dependent',
      avatarUrl: profilePreviewLink ?? '',
    );
  }
}
