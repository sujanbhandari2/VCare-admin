import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/notifications/domain/entities/fcm_device_check_response.dart';
import 'package:vcare_admin/features/notifications/domain/entities/notification_item.dart';

abstract class NotificationRepository {
  Future<EitherResponseOrException<bool>> registerDeviceToken({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<bool>> updateDeviceToken({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<FcmDeviceCheckResponse>> checkFcmDeviceStatus({
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<bool>> deregisterDeviceToken({
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<List<NotificationItem>>> fetchNotifications({
    int? page,
    int? limit,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<bool>> markNotificationRead({
    required String id,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<int>> fetchUnreadCount({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });
}
