class SavedProvider {
  const SavedProvider({
    required this.linkId,
    required this.savedAt,
    required this.provider,
  });

  final String linkId;
  final DateTime? savedAt;
  final SavedProviderDetails provider;
}

class SavedProviderDetails {
  const SavedProviderDetails({
    required this.id,
    required this.npi,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.firstName,
    required this.lastName,
    required this.entityCode,
    required this.type,
  });

  final String id;
  final String npi;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String? firstName;
  final String lastName;
  final String entityCode;
  final String type;
}
