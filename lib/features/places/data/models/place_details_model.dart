class PlaceAddressComponentModel {
  const PlaceAddressComponentModel({
    required this.longText,
    required this.shortText,
    required this.types,
  });

  final String longText;
  final String shortText;
  final List<String> types;

  static PlaceAddressComponentModel? tryParse(Map<String, dynamic> json) {
    final longText = _readString(json['longText']) ??
        _readString(json['long_text']) ??
        _readString(json['long_name']);
    final shortText = _readString(json['shortText']) ??
        _readString(json['short_text']) ??
        _readString(json['short_name']);
    final typesRaw = json['types'];
    final types = typesRaw is List
        ? typesRaw.whereType<String>().toList(growable: false)
        : const <String>[];

    if ((longText == null || longText.isEmpty) &&
        (shortText == null || shortText.isEmpty) &&
        types.isEmpty) {
      return null;
    }

    return PlaceAddressComponentModel(
      longText: longText ?? '',
      shortText: shortText ?? longText ?? '',
      types: types,
    );
  }

  static String? _readString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class PlaceDetailsModel {
  const PlaceDetailsModel({required this.addressComponents});

  final List<PlaceAddressComponentModel> addressComponents;

  factory PlaceDetailsModel.fromJson(Map<String, dynamic> json) {
    final raw = json['addressComponents'] ?? json['address_components'];
    final components = <PlaceAddressComponentModel>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final mapped = PlaceAddressComponentModel.tryParse(
          Map<String, dynamic>.from(item),
        );
        if (mapped != null) components.add(mapped);
      }
    }
    return PlaceDetailsModel(addressComponents: components);
  }
}
