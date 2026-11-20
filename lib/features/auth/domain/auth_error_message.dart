import 'package:vcare_admin/core/services/network/http_exception.dart';

/// Canonical auth API error messages returned during biometric login.
class AuthErrorMessage {
  const AuthErrorMessage._();

  static const String userAccessRevoked = 'User access has been revoked';

  static const String biometricLoginNotEnrolled =
      'Biometric login is not set up on this device.';

  static const String biometricLoginRevoked =
      'Biometric login is no longer active on this device. Sign in with your password to continue.';

  static const List<String> biometricLoginDisablingMessages = [
    userAccessRevoked,
    biometricLoginNotEnrolled,
    biometricLoginRevoked,
  ];
}

/// Returns the canonical user-facing message when [error] matches a known
/// biometric-login auth failure, otherwise `null`.
String? resolveBiometricLoginAuthErrorMessage(Object? error) {
  final haystack = _collectErrorText(error).toLowerCase();
  if (haystack.isEmpty) {
    return null;
  }

  for (final message in AuthErrorMessage.biometricLoginDisablingMessages) {
    if (haystack.contains(message.toLowerCase())) {
      return message;
    }
  }

  return null;
}

/// Whether [error] should disable biometric login on the device.
bool isBiometricLoginDisablingAuthError(Object? error) {
  return resolveBiometricLoginAuthErrorMessage(error) != null;
}

String _collectErrorText(Object? error) {
  if (error == null) {
    return '';
  }

  return [
    error.toString(),
    if (error is HttpException) error.message,
    if (error is HttpException) error.responseData?.toString(),
  ].whereType<String>().join(' ');
}
