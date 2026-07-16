class SavedProviderModel {
  const SavedProviderModel({
    required this.linkId,
    required this.savedAt,
    required this.provider,
  });

  final String linkId;
  final DateTime? savedAt;
  final SavedProviderDetailsModel provider;

  factory SavedProviderModel.fromJson(Map<String, dynamic> json) {
    final providerJson = json['provider'];
    return SavedProviderModel(
      linkId: json['linkId']?.toString() ?? '',
      savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? ''),
      provider: providerJson is Map
          ? SavedProviderDetailsModel.fromJson(
              Map<String, dynamic>.from(providerJson),
            )
          : const SavedProviderDetailsModel(
              id: '',
              npi: '',
              addressLine1: '',
              city: '',
              state: '',
              postalCode: '',
              lastName: '',
              entityCode: '',
              type: '',
            ),
    );
  }
}

class SavedProviderDetailsModel {
  const SavedProviderDetailsModel({
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

  factory SavedProviderDetailsModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString();
    return SavedProviderDetailsModel(
      id: json['id']?.toString() ?? '',
      npi: json['npi']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString() ?? '',
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      firstName: firstName == null || firstName.trim().isEmpty ? null : firstName,
      lastName: json['lastName']?.toString() ?? '',
      entityCode: json['entityCode']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }
}
