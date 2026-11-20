import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

/// Auth API error codes used by password login lock handling.
abstract final class AuthPasswordLoginErrorCode {
  static const String accountPasswordLocked = 'ACCOUNT_PASSWORD_LOCKED';
}

/// Matches contact on the admin sign-in brand panel.
const String loginPasswordLockSupportEmail = 'vcare@vitafyhealth.com';

const String wrongPasswordFallback = 'Incorrect email or password.';

String formatPasswordLoginAttemptsRemaining(int triesLeft) {
  final attemptLabel =
      triesLeft == 1 ? 'login attempt' : 'login attempts';
  return 'Incorrect email or password. You have $triesLeft $attemptLabel remaining.';
}

bool isAccountPasswordLockedError(HttpException error) {
  return _readCode(error) == AuthPasswordLoginErrorCode.accountPasswordLocked;
}

String resolveAccountPasswordLockSupportEmail(HttpException error) {
  final supportEmail = _readSupportEmail(error);
  if (supportEmail != null && supportEmail.isNotEmpty) {
    return supportEmail;
  }
  return loginPasswordLockSupportEmail;
}

/// Resolves the user-facing message for a password-login failure.
///
/// Returns an empty string for account-lock errors (UI shows a dedicated
/// locked banner instead).
String resolvePasswordLoginErrorMessage(
  HttpException error, {
  String wrongPasswordFallbackMessage = wrongPasswordFallback,
}) {
  if (isAccountPasswordLockedError(error)) {
    return '';
  }

  final status = error.statusCode;
  final triesLeft = _readPasswordTriesLeft(error);
  if (status == 401 && triesLeft != null && triesLeft > 0) {
    return formatPasswordLoginAttemptsRemaining(triesLeft);
  }

  if (status == 401 && error.message == 'Invalid credentials') {
    return wrongPasswordFallbackMessage;
  }

  final sanitized = error.userMessage.trim();
  if (sanitized.isNotEmpty) {
    return sanitized;
  }
  return wrongPasswordFallbackMessage;
}

Map<String, dynamic> _unwrapPayload(Map<String, dynamic> json) {
  final nestedData = json['data'];
  if (nestedData is Map<String, dynamic>) {
    return _unwrapPayload(nestedData);
  }

  final nestedResult = json['result'];
  if (nestedResult is Map<String, dynamic>) {
    return _unwrapPayload(nestedResult);
  }

  final nestedPayload = json['payload'];
  if (nestedPayload is Map<String, dynamic>) {
    return _unwrapPayload(nestedPayload);
  }

  return json;
}

Map<String, dynamic>? _errorBody(HttpException error) {
  final data = error.responseData;
  if (data is Map<String, dynamic>) {
    return _unwrapPayload(data);
  }
  if (data is Map) {
    return _unwrapPayload(Map<String, dynamic>.from(data));
  }
  return null;
}

String? _readCode(HttpException error) {
  final body = _errorBody(error);
  final value = body?['code'];
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

String? _readSupportEmail(HttpException error) {
  final body = _errorBody(error);
  final value = body?['supportEmail'];
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

int? _readPasswordTriesLeft(HttpException error) {
  final body = _errorBody(error);
  final value = body?['passwordTriesLeft'];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}
