class MedicareProviderLookupRow {
  const MedicareProviderLookupRow({
    required this.npi,
    required this.firstName,
    required this.lastName,
    required this.providerType,
    required this.street1,
    this.street2,
    required this.city,
    required this.state,
    required this.zip5,
  });

  final String npi;
  final String firstName;
  final String lastName;
  final String providerType;
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
  final parts = [row.firstName, row.lastName].where((p) => p.trim().isNotEmpty);
  final joined = parts.join(' ').trim();
  return joined.isEmpty ? 'Medicare provider' : joined;
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
