class ProfileAddress {
  const ProfileAddress({
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  ProfileAddress copyWith({
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    return ProfileAddress(
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }

  String format() {
    return [
      line1,
      if (line2 != null && line2!.isNotEmpty) line2,
      '$city, $state $postalCode',
      country,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
  }
}
