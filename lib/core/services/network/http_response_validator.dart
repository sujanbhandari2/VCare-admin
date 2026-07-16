import 'package:dio/dio.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';

/// A utility class to validate HTTP responses.
class ResponseValidator {
  /// Validates whether the given [response] is successful.
  ///
  /// This method checks if the status code is a standard success code.
  /// For status code 204, a null response body is considered valid.
  ///
  /// [response] - The HTTP [Response] object to validate.
  ///
  /// Returns `true` if the response is valid, otherwise `false`.
  static bool isValidResponse(Response<dynamic> response) {
    final statusCode = response.statusCode;
    if (statusCode == null) return false;

    return statusCode >= 200 && statusCode < 300;
  }

  /// Throws [HttpException] if response is not in 2xx range.
  static void ensureValid(Response<dynamic> response) {
    if (!isValidResponse(response)) {
      throw HttpException.fromResponse(response);
    }
  }

  /// Validates and maps response data into strongly typed model/entity.
  static T parse<T>(
    Response<dynamic> response,
    T Function(dynamic data) mapper, {
    bool Function(dynamic data)? dataValidator,
  }) {
    ensureValid(response);

    final data = response.data;
    if (dataValidator != null && !dataValidator(data)) {
      throw HttpException(
        title: 'Invalid Response',
        statusCode: response.statusCode,
        message: 'Response format did not match expected schema.',
        requestMethod: response.requestOptions.method,
        requestUri: response.requestOptions.uri,
        responseData: data,
      );
    }

    return mapper(data);
  }
}
