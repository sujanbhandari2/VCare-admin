import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';

class BiometricCredentialModel {
  const BiometricCredentialModel({
    required this.version,
    required this.accountId,
    required this.deviceId,
    required this.publicKeyBase64,
    required this.keyAlias,
    required this.biometricType,
    this.accountEmail,
    this.enrollmentId,
    this.deviceName,
    this.userType,
    this.enrolledAt,
    this.lastUsedAt,
    this.isCurrent = true,
  });

  static const int currentVersion = 2;

  final int version;
  final String accountId;
  final String? accountEmail;
  final String? enrollmentId;
  final String deviceId;
  final String publicKeyBase64;

  /// Native Keystore / Secure Enclave key alias. Private key material is never stored.
  final String keyAlias;
  final String biometricType;
  final String? deviceName;
  final String? userType;
  final DateTime? enrolledAt;
  final DateTime? lastUsedAt;
  final bool isCurrent;

  bool get isValidNativeCredential =>
      version >= currentVersion &&
      accountId.trim().isNotEmpty &&
      keyAlias.trim().isNotEmpty &&
      publicKeyBase64.trim().isNotEmpty &&
      deviceId.trim().isNotEmpty;

  factory BiometricCredentialModel.fromJson(Map<String, dynamic> json) {
    final legacyScalar =
        (json['privateKeyScalar'] as String?)?.trim().isNotEmpty == true;
    final keyAlias = (json['keyAlias'] as String?)?.trim() ?? '';
    final version = (json['version'] as num?)?.toInt() ?? (legacyScalar ? 1 : 2);

    return BiometricCredentialModel(
      version: version,
      accountId: (json['accountId'] as String?)?.trim() ?? '',
      accountEmail: (json['accountEmail'] as String?)?.trim(),
      enrollmentId: (json['enrollmentId'] as String?)?.trim(),
      deviceId: (json['deviceId'] as String?)?.trim() ?? '',
      publicKeyBase64: (json['publicKeyBase64'] as String?)?.trim() ?? '',
      keyAlias: keyAlias,
      biometricType: (json['biometricType'] as String?)?.trim().toUpperCase() ??
          'OTHER',
      deviceName: (json['deviceName'] as String?)?.trim(),
      userType: (json['userType'] as String?)?.trim(),
      enrolledAt: DateTime.tryParse((json['enrolledAt'] as String?) ?? ''),
      lastUsedAt: DateTime.tryParse((json['lastUsedAt'] as String?) ?? ''),
      isCurrent: json['isCurrent'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'accountId': accountId,
      if (accountEmail != null) 'accountEmail': accountEmail,
      if (enrollmentId != null) 'enrollmentId': enrollmentId,
      'deviceId': deviceId,
      'publicKeyBase64': publicKeyBase64,
      'keyAlias': keyAlias,
      'biometricType': biometricType,
      if (deviceName != null) 'deviceName': deviceName,
      if (userType != null) 'userType': userType,
      if (enrolledAt != null) 'enrolledAt': enrolledAt!.toIso8601String(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt!.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }

  BiometricCredentialModel copyWith({
    int? version,
    String? accountId,
    String? accountEmail,
    String? enrollmentId,
    String? deviceId,
    String? publicKeyBase64,
    String? keyAlias,
    String? biometricType,
    String? deviceName,
    String? userType,
    DateTime? enrolledAt,
    DateTime? lastUsedAt,
    bool? isCurrent,
  }) {
    return BiometricCredentialModel(
      version: version ?? this.version,
      accountId: accountId ?? this.accountId,
      accountEmail: accountEmail ?? this.accountEmail,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      deviceId: deviceId ?? this.deviceId,
      publicKeyBase64: publicKeyBase64 ?? this.publicKeyBase64,
      keyAlias: keyAlias ?? this.keyAlias,
      biometricType: biometricType ?? this.biometricType,
      deviceName: deviceName ?? this.deviceName,
      userType: userType ?? this.userType,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  BiometricLoginStatus toEntity() {
    return BiometricLoginStatus(
      isEnrolled: true,
      accountId: accountId,
      accountEmail: accountEmail,
      enrollmentId: enrollmentId,
      deviceId: deviceId,
      deviceName: deviceName,
      biometricType: biometricType,
      userType: userType,
      enrolledAt: enrolledAt,
      lastUsedAt: lastUsedAt,
      isCurrent: isCurrent,
    );
  }
}
