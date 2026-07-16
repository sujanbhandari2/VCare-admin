import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/saved_providers/data/models/saved_provider_model.dart';
import 'package:vcare_admin/features/saved_providers/domain/entities/saved_provider.dart';

extension SavedProviderModelMapper on SavedProviderModel {
  SavedProvider toEntity() {
    return SavedProvider(
      linkId: linkId,
      savedAt: savedAt,
      provider: provider.toEntity(),
    );
  }
}

extension SavedProviderDetailsModelMapper on SavedProviderDetailsModel {
  SavedProviderDetails toEntity() {
    return SavedProviderDetails(
      id: id,
      npi: npi,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      postalCode: postalCode,
      firstName: firstName,
      lastName: lastName,
      entityCode: entityCode,
      type: type,
    );
  }
}

extension SavedProviderDetailsMapper on SavedProviderDetails {
  MedicareProviderLookupRow toMedicareProviderLookupRow() {
    return MedicareProviderLookupRow(
      npi: npi,
      firstName: firstName ?? '',
      lastOrOrgName: lastName,
      providerType: type,
      entityCode: entityCode,
      street1: addressLine1,
      street2: addressLine2,
      city: city,
      state: state,
      zip5: postalCode,
    );
  }
}

extension MedicareProviderLookupRowSavePayloadMapper on MedicareProviderLookupRow {
  Map<String, dynamic> toSaveProviderPayload() {
    final payload = <String, dynamic>{
      'npi': npi,
      'lastName': lastOrOrgName,
      'addressLine1': street1,
      'city': city,
      'state': state,
      'postalCode': zip5,
      'entityCode': entityCode,
      'type': providerType,
    };

    if (firstName.trim().isNotEmpty) {
      payload['firstName'] = firstName.trim();
    }

    return payload;
  }
}

List<SavedProviderModel> parseSavedProviderList(dynamic data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map(
          (entry) => SavedProviderModel.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .where((model) => model.linkId.isNotEmpty && model.provider.npi.isNotEmpty)
        .toList();
  }

  if (data is Map) {
    return [SavedProviderModel.fromJson(Map<String, dynamic>.from(data))];
  }

  return const [];
}

SavedProviderModel parseSavedProviderItem(dynamic data) {
  if (data is Map) {
    return SavedProviderModel.fromJson(Map<String, dynamic>.from(data));
  }

  throw FormatException('Expected saved provider object, got $data');
}
