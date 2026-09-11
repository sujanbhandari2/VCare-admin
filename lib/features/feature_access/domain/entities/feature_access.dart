/// Tenant-level feature toggles from `/settings` → `data.features`.
class FeatureAccess {
  const FeatureAccess({
    required this.caseManagement,
    required this.healthChat,
    required this.membership,
  });

  final bool caseManagement;
  final bool healthChat;
  final bool membership;

  /// Fail-closed defaults when settings are unavailable.
  static const FeatureAccess disabled = FeatureAccess(
    caseManagement: false,
    healthChat: false,
    membership: false,
  );

  FeatureAccess copyWith({
    bool? caseManagement,
    bool? healthChat,
    bool? membership,
  }) {
    return FeatureAccess(
      caseManagement: caseManagement ?? this.caseManagement,
      healthChat: healthChat ?? this.healthChat,
      membership: membership ?? this.membership,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FeatureAccess &&
        other.caseManagement == caseManagement &&
        other.healthChat == healthChat &&
        other.membership == membership;
  }

  @override
  int get hashCode => Object.hash(caseManagement, healthChat, membership);
}
