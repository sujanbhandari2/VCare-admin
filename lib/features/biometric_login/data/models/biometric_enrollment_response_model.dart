import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';

class BiometricEnrollmentDeviceModel {
  const BiometricEnrollmentDeviceModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.biometricType,
    required this.enrolledAt,
    required this.isCurrent,
    this.lastUsedAt,
  });

  final String id;
  final String deviceId;
  final String? deviceName;
  final String biometricType;
  final DateTime? enrolledAt;
  final DateTime? lastUsedAt;
  final bool isCurrent;

  factory BiometricEnrollmentDeviceModel.fromJson(Map<String, dynamic> json) {
    return BiometricEnrollmentDeviceModel(
      id: (json['id'] as String?)?.trim() ?? '',
      deviceId: (json['deviceId'] as String?)?.trim() ?? '',
      deviceName: (json['deviceName'] as String?)?.trim(),
      biometricType: (json['biometricType'] as String?)?.trim().toUpperCase() ??
          'OTHER',
      enrolledAt: DateTime.tryParse((json['enrolledAt'] as String?) ?? ''),
      lastUsedAt: DateTime.tryParse((json['lastUsedAt'] as String?) ?? ''),
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  BiometricLoginStatus toEntity({
    String? accountId,
    String? accountEmail,
    String? userType,
  }) {
    return BiometricLoginStatus(
      isEnrolled: true,
      accountId: accountId,
      accountEmail: accountEmail,
      enrollmentId: id.isEmpty ? null : id,
      deviceId: deviceId.isEmpty ? null : deviceId,
      deviceName: deviceName,
      biometricType: biometricType,
      userType: userType,
      enrolledAt: enrolledAt,
      lastUsedAt: lastUsedAt,
      isCurrent: isCurrent,
    );
  }
}

class BiometricEnrollmentResponseModel {
  const BiometricEnrollmentResponseModel({
    required this.enrolled,
    this.device,
  });

  final bool enrolled;
  final BiometricEnrollmentDeviceModel? device;

  factory BiometricEnrollmentResponseModel.fromJson(Map<String, dynamic> json) {
    final deviceJson = json['device'];
    return BiometricEnrollmentResponseModel(
      enrolled: json['enrolled'] as bool? ?? false,
      device: deviceJson is Map<String, dynamic>
          ? BiometricEnrollmentDeviceModel.fromJson(deviceJson)
          : null,
    );
  }
}
