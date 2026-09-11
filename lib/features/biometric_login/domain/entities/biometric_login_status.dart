class BiometricLoginStatus {
  const BiometricLoginStatus({
    required this.isEnrolled,
    this.accountId,
    this.accountEmail,
    this.enrollmentId,
    this.deviceId,
    this.deviceName,
    this.biometricType,
    this.userType,
    this.enrolledAt,
    this.lastUsedAt,
    this.isCurrent = false,
  });

  final bool isEnrolled;
  final String? accountId;
  final String? accountEmail;
  final String? enrollmentId;
  final String? deviceId;
  final String? deviceName;
  final String? biometricType;
  final String? userType;
  final DateTime? enrolledAt;
  final DateTime? lastUsedAt;
  final bool isCurrent;

  String get displayType {
    return switch (biometricType?.trim().toUpperCase()) {
      'FACE' => 'Face ID',
      'FINGERPRINT' => 'Fingerprint',
      _ => 'Biometric',
    };
  }

  String get displayStatus => isEnrolled ? 'Active' : 'Inactive';

  /// Whether [candidateAccountId] owns the stored enrollment.
  bool belongsToAccount(String? candidateAccountId) {
    final stored = accountId?.trim() ?? '';
    final candidate = candidateAccountId?.trim() ?? '';
    if (stored.isEmpty || candidate.isEmpty) {
      return false;
    }
    return stored == candidate;
  }

  BiometricLoginStatus copyWith({
    bool? isEnrolled,
    String? accountId,
    String? accountEmail,
    String? enrollmentId,
    String? deviceId,
    String? deviceName,
    String? biometricType,
    String? userType,
    DateTime? enrolledAt,
    DateTime? lastUsedAt,
    bool? isCurrent,
  }) {
    return BiometricLoginStatus(
      isEnrolled: isEnrolled ?? this.isEnrolled,
      accountId: accountId ?? this.accountId,
      accountEmail: accountEmail ?? this.accountEmail,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      biometricType: biometricType ?? this.biometricType,
      userType: userType ?? this.userType,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  static const BiometricLoginStatus disabled =
      BiometricLoginStatus(isEnrolled: false);
}
