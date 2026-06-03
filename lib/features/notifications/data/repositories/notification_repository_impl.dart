import 'package:dio/dio.dart';
import 'package:flutter_template/core/config/api_endpoints.dart';
import 'package:flutter_template/core/services/network/http_response_validator.dart';
import 'package:flutter_template/core/services/network/api_client.dart';
import 'package:flutter_template/core/services/network/models/request_body.dart';
import 'package:flutter_template/core/services/network/typedefs/response_or_exception.dart';
import 'package:flutter_template/features/notifications/domain/repositories/notification_repository.dart';

import '../../../../core/services/network/http_exception.dart';

class NotificationRepositoryImpl extends NotificationRepository {
  /// API Client Instance
  final ApiClient apiClient;

  /// Constructor
  NotificationRepositoryImpl(this.apiClient);

  /// Method to register device token
  ///
  @override
  Future<EitherResponseOrException<bool>> registerDeviceToken({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.fcmDeviceRegister,
        JsonRequestBody(payloads),
        cancelToken: cancelToken,
        isAuthenticated: true,
      );

      final isValid = ResponseValidator.isValidResponse(response);
      if (!isValid) throw HttpException.fromResponse(response);

      return isValid;
    });
  }
}
