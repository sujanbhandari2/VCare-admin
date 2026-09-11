import 'package:vcare_admin/features/biometric_login/data/models/biometric_credential_model.dart';
import 'package:vcare_admin/features/biometric_login/data/models/biometric_enrollment_response_model.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';

extension BiometricCredentialModelMapper on BiometricCredentialModel {
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

extension BiometricEnrollmentDeviceModelMapper
    on BiometricEnrollmentDeviceModel {
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
