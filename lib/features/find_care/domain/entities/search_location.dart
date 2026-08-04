class SearchLocation {
  const SearchLocation({
    this.city = '',
    this.state = '',
    this.fromCurrentLocation = false,
  });

  final String city;
  final String state;

  /// True when the search area was resolved from the device GPS.
  final bool fromCurrentLocation;

  SearchLocation copyWith({
    String? city,
    String? state,
    bool? fromCurrentLocation,
  }) {
    return SearchLocation(
      city: city ?? this.city,
      state: state ?? this.state,
      fromCurrentLocation: fromCurrentLocation ?? this.fromCurrentLocation,
    );
  }

  String get displayLabel {
    final parts = <String>[
      if (city.trim().isNotEmpty) city.trim(),
      if (state.trim().isNotEmpty) state.trim(),
    ];
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'state': state,
    'fromCurrentLocation': fromCurrentLocation,
  };

  factory SearchLocation.fromJson(Map<String, dynamic> json) {
    return SearchLocation(
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      fromCurrentLocation: json['fromCurrentLocation'] == true,
    );
  }
}
