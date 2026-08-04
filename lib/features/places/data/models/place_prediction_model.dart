class PlacePredictionModel {
  const PlacePredictionModel({
    required this.placeId,
    required this.label,
  });

  final String placeId;
  final String label;

  static PlacePredictionModel? tryParse(Map<String, dynamic> json) {
    final placeId =
        _readString(json['placeId']) ?? _readString(json['place_id']);
    final label = _readString(json['label']) ??
        _readString(json['description']) ??
        _readString(json['text']);
    if (placeId == null || label == null) return null;
    return PlacePredictionModel(placeId: placeId, label: label);
  }

  static String? _readString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
