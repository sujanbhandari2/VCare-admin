class UpdatedAgentCodeModel {
  const UpdatedAgentCodeModel({
    required this.agentCode,
    this.referralLink,
  });

  final String agentCode;
  final String? referralLink;

  factory UpdatedAgentCodeModel.fromJson(
    Map<String, dynamic> json, {
    required String fallbackAgentCode,
  }) {
    final agentCode =
        _optionalString(json['agentCode']) ?? fallbackAgentCode;
    final referralLink = _optionalString(json['referralLink']);

    return UpdatedAgentCodeModel(
      agentCode: agentCode,
      referralLink: referralLink,
    );
  }

  static String? _optionalString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
