/// Tenant-level feature toggles from `/settings` → `data.features`.
class FeatureAccess {
  const FeatureAccess({
    required this.caseManagement,
    required this.healthChat,
    required this.membership,
    required this.taskManagement,
  });

  final bool caseManagement;
  final bool healthChat;
  final bool membership;
  final bool taskManagement;

  /// Fail-closed defaults when settings are unavailable.
  static const FeatureAccess disabled = FeatureAccess(
    caseManagement: false,
    healthChat: false,
    membership: false,
    taskManagement: false,
  );

  FeatureAccess copyWith({
    bool? caseManagement,
    bool? healthChat,
    bool? membership,
    bool? taskManagement,
  }) {
    return FeatureAccess(
      caseManagement: caseManagement ?? this.caseManagement,
      healthChat: healthChat ?? this.healthChat,
      membership: membership ?? this.membership,
      taskManagement: taskManagement ?? this.taskManagement,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FeatureAccess &&
        other.caseManagement == caseManagement &&
        other.healthChat == healthChat &&
        other.membership == membership &&
        other.taskManagement == taskManagement;
  }

  @override
  int get hashCode =>
      Object.hash(caseManagement, healthChat, membership, taskManagement);
}
