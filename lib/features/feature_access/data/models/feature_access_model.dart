class FeatureAccessModel {
  const FeatureAccessModel({
    required this.caseManagement,
    required this.healthChat,
    required this.membership,
  });

  final bool caseManagement;
  final bool healthChat;
  final bool membership;

  factory FeatureAccessModel.fromSettingsJson(Map<String, dynamic> json) {
    final features = json['features'];
    final featureMap = features is Map
        ? Map<String, dynamic>.from(features)
        : null;

    return FeatureAccessModel(
      caseManagement: _readBool(featureMap, 'caseManagement'),
      healthChat: _readBool(featureMap, 'healthChat'),
      membership: _readBool(featureMap, 'membership'),
    );
  }

  static bool _readBool(Map<String, dynamic>? map, String key) {
    if (map == null) return false;
    final value = map[key];
    return value is bool && value;
  }
}
