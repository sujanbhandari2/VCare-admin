import 'package:dio/dio.dart';

import 'package:flutter_template/core/services/network/typedefs/response_or_exception.dart';
import 'package:flutter_template/features/notifications/domain/repositories/notification_repository.dart';

class FakeNotificationRepository implements NotificationRepository {
  EitherResponseOrException<bool> registerResult = Success(true);

  int? lastCheckedUserId;

  @override
  Future<EitherResponseOrException<bool>> registerDeviceToken({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) async {
    return Success(true);
  }
}
