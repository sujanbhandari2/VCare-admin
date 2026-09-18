import 'package:dio/dio.dart';
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

    test('detects HTML 502 gateway bodies as technical', () {
      const html = '''
<html>
<head><title>502 Bad Gateway</title></head>
<body>
<center><h1>502 Bad Gateway</h1></center>
<hr><center>nginx/1.28.3 (Ubuntu)</center>
</body>
</html>
''';

      expect(NetworkErrorMessage.isTechnicalMessage(html), isTrue);
      expect(
        NetworkErrorMessage.sanitize(
          message: html,
          errorType: HttpErrorType.client,
        ),
        'Unable to connect to server. Check your internet connection.',
      );
    });

    test('detects nginx/proxy text without HTML tags', () {
      expect(
        NetworkErrorMessage.isTechnicalMessage('502 Bad Gateway nginx'),
        isTrue,
      );
    });

    test('treats empty bodies as technical', () {
      expect(NetworkErrorMessage.isTechnicalMessage(''), isTrue);
      expect(NetworkErrorMessage.isTechnicalMessage('   '), isTrue);
      expect(NetworkErrorMessage.isTechnicalMessage(null), isTrue);
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

      expect(exception.userMessage, 'Requested resource was not found.');
    });

    test('sanitizes server HTML via error type fallback', () {
      final exception = HttpException(
        message: '''
<html><head><title>502 Bad Gateway</title></head>
<body><center><h1>502 Bad Gateway</h1></center></body></html>
''',
        errorType: HttpErrorType.server,
      );

      expect(
        exception.userMessage,
        'Server encountered an error. Please try again later.',
      );
    });

    test('preserves non-technical client errors', () {
      final exception = HttpException(
        message: 'Invalid verification code',
        errorType: HttpErrorType.client,
      );

      expect(exception.userMessage, 'Invalid verification code');
    });

    test('rejects HTML string bodies when building from response', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/settings'),
        statusCode: 502,
        data: '''
<html><head><title>502 Bad Gateway</title></head>
<body><h1>502 Bad Gateway</h1><hr><center>nginx/1.28.3</center></body></html>
''',
      );

      expect(HttpException.extractMessageFromResponse(response), isNull);

      final exception = HttpException.fromResponse(response);
      expect(exception.errorType, HttpErrorType.server);
      expect(
        exception.userMessage,
        'Server encountered an error. Please try again later.',
      );
      expect(exception.message?.contains('<html>'), isNot(true));
    });
  });
}
