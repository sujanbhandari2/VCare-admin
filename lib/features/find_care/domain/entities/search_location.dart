class SearchLocation {
  const SearchLocation({this.city = '', this.state = ''});

  final String city;
  final String state;

  SearchLocation copyWith({String? city, String? state}) {
    return SearchLocation(city: city ?? this.city, state: state ?? this.state);
  }

  String get displayLabel {
    final parts = <String>[
      if (city.trim().isNotEmpty) city.trim(),
      if (state.trim().isNotEmpty) state.trim(),
    ];
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {'city': city, 'state': state};

  factory SearchLocation.fromJson(Map<String, dynamic> json) {
    return SearchLocation(
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}
