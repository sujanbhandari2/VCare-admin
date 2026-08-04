class ParsedAddressParts {
  const ParsedAddressParts({
    this.line1 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
  });

  final String line1;
  final String city;
  final String state;
  final String postalCode;
}

class PlaceAddressComponent {
  const PlaceAddressComponent({
    required this.longText,
    required this.shortText,
    required this.types,
  });

  final String longText;
  final String shortText;
  final List<String> types;
}

class PlaceDetails {
  const PlaceDetails({required this.addressComponents});

  final List<PlaceAddressComponent> addressComponents;
}
