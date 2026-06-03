import 'package:dio/dio.dart';

import 'package:flutter_template/core/services/network/typedefs/response_or_exception.dart';

abstract class NotificationRepository {
  /// Method to register device token
  ///
  Future<EitherResponseOrException<bool>> registerDeviceToken({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  });
}
