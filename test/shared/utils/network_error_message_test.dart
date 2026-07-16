import 'package:flutter_test/flutter_test.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

void main() {
  group('NetworkErrorMessage', () {
    test('detects API route technical messages', () {
      expect(
        NetworkErrorMessage.isTechnicalMessage(
          'Route GET/api/v1/notification not found',
        ),
        isTrue,
      );
    });

    test('keeps user-facing validation messages', () {
      expect(
        NetworkErrorMessage.isTechnicalMessage('Invalid verification code'),
        isFalse,
      );
    });

    test('sanitizes technical API route errors', () {
      final exception = HttpException(
        message: 'Route GET/api/v1/notification not found',
        errorType: HttpErrorType.notFound,
      );

      expect(
        exception.userMessage,
        'Unable to connect to server. Check your internet connection.',
      );
    });

    test('preserves non-technical client errors', () {
      final exception = HttpException(
        message: 'Invalid verification code',
        errorType: HttpErrorType.client,
      );

      expect(exception.userMessage, 'Invalid verification code');
    });
  });
}
