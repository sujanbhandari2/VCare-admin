class MedicareProviderLookupRow {
  const MedicareProviderLookupRow({
    required this.npi,
    required this.firstName,
    required this.lastOrOrgName,
    required this.providerType,
    required this.entityCode,
    required this.street1,
    this.street2,
    required this.city,
    required this.state,
    required this.zip5,
  });

  final String npi;
  final String firstName;
  final String lastOrOrgName;
  final String providerType;
  final String entityCode;
  final String street1;
  final String? street2;
  final String city;
  final String state;
  final String zip5;
}

class MedicareProviderListItem {
  const MedicareProviderListItem({required this.row, this.raw = const {}});

  final MedicareProviderLookupRow row;
  final Map<String, String> raw;
}

String formatMedicareProviderName(MedicareProviderLookupRow row) {
  if (row.entityCode == 'O' || row.firstName.trim().isEmpty) {
    return row.lastOrOrgName.trim().isEmpty ? '—' : row.lastOrOrgName.trim();
  }
  final joined = '${row.firstName} ${row.lastOrOrgName}'.trim();
  return joined.isEmpty ? '—' : joined;
}

String formatMedicareProviderLocation(MedicareProviderLookupRow row) {
  final streetParts = <String>[
    row.street1,
    if (row.street2 != null && row.street2!.trim().isNotEmpty) row.street2!,
  ];
  final street = streetParts.join(', ');
  final cityState = row.city.trim().isNotEmpty
      ? '${row.city}, ${row.state} ${row.zip5}'.trim()
      : '${row.state} ${row.zip5}'.trim();
  return [street, cityState].where((part) => part.isNotEmpty).join(' · ');
}

Map<String, dynamic> medicareProviderLookupRowToJson(
  MedicareProviderLookupRow row,
) {
  return {
    'npi': row.npi,
    'firstName': row.firstName,
    'lastOrOrgName': row.lastOrOrgName,
    'providerType': row.providerType,
    'entityCode': row.entityCode,
    'street1': row.street1,
    'street2': row.street2,
    'city': row.city,
    'state': row.state,
    'zip5': row.zip5,
  };
}

MedicareProviderLookupRow medicareProviderLookupRowFromJson(
  Map<String, dynamic> json,
) {
  return MedicareProviderLookupRow(
    npi: json['npi']?.toString() ?? '',
    firstName: json['firstName']?.toString() ?? '',
    lastOrOrgName:
        json['lastOrOrgName']?.toString() ?? json['lastName']?.toString() ?? '',
    providerType: json['providerType']?.toString() ?? '',
    entityCode: json['entityCode']?.toString() ?? '',
    street1: json['street1']?.toString() ?? '',
    street2: json['street2']?.toString(),
    city: json['city']?.toString() ?? '',
    state: json['state']?.toString() ?? '',
    zip5: json['zip5']?.toString() ?? '',
  );
}
