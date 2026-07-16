import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/notifications/domain/entities/fcm_device_check_response.dart';
import 'package:vcare_admin/features/notifications/domain/entities/notification_item.dart';
import 'package:vcare_admin/features/notifications/domain/repositories/notification_repository.dart';

class FakeNotificationRepository implements NotificationRepository {
  EitherResponseOrException<bool> registerResult = Success(true);
  EitherResponseOrException<bool> updateResult = Success(true);
  EitherResponseOrException<FcmDeviceCheckResponse> checkResult = Success(
    FcmDeviceCheckResponse(hasFcmToken: false),
  );
  EitherResponseOrException<bool> deregisterResult = Success(true);
  EitherResponseOrException<List<NotificationItem>> fetchResult = Success(
    const [],
  );
  EitherResponseOrException<bool> markReadResult = Success(true);
  EitherResponseOrException<int> unreadCountResult = Success(0);

  int registerCallCount = 0;
  int updateCallCount = 0;
  int checkCallCount = 0;
  String? lastMarkedReadId;

  @override
  Future<EitherResponseOrException<bool>> registerDeviceToken({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) async {
    registerCallCount++;
    return registerResult;
  }

  @override
  Future<EitherResponseOrException<bool>> updateDeviceToken({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) async {
    updateCallCount++;
    return updateResult;
  }

  @override
  Future<EitherResponseOrException<FcmDeviceCheckResponse>> checkFcmDeviceStatus({
    CancelToken? cancelToken,
  }) async {
    checkCallCount++;
    return checkResult;
  }

  @override
  Future<EitherResponseOrException<bool>> deregisterDeviceToken({
    CancelToken? cancelToken,
  }) async {
    return deregisterResult;
  }

  @override
  Future<EitherResponseOrException<List<NotificationItem>>> fetchNotifications({
    int? page,
    int? limit,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    return fetchResult;
  }

  @override
  Future<EitherResponseOrException<bool>> markNotificationRead({
    required String id,
    CancelToken? cancelToken,
  }) async {
    lastMarkedReadId = id;
    return markReadResult;
  }

  @override
  Future<EitherResponseOrException<int>> fetchUnreadCount({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    return unreadCountResult;
  }
}
