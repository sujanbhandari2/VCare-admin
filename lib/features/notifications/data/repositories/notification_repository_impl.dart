import 'package:dio/dio.dart';
import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/notifications/data/mappers/notification_mappers.dart';
import 'package:vcare_admin/features/notifications/data/models/fcm_device_check_response_model.dart';
import 'package:vcare_admin/features/notifications/data/models/notification_item_model.dart';
import 'package:vcare_admin/features/notifications/domain/entities/fcm_device_check_response.dart';
import 'package:vcare_admin/features/notifications/domain/entities/notification_item.dart';
import 'package:vcare_admin/features/notifications/domain/repositories/notification_repository.dart';

import '../../../../core/services/network/http_exception.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

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

  @override
  Future<EitherResponseOrException<bool>> updateDeviceToken({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.fcmDeviceUpdate,
        JsonRequestBody(payloads),
        cancelToken: cancelToken,
        isAuthenticated: true,
      );

      final isValid = ResponseValidator.isValidResponse(response);
      if (!isValid) throw HttpException.fromResponse(response);

      return isValid;
    });
  }

  @override
  Future<EitherResponseOrException<FcmDeviceCheckResponse>>
  checkFcmDeviceStatus({CancelToken? cancelToken}) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.checkFcmDeviceStatus,
        const EmptyRequestBody(),
        cancelToken: cancelToken,
        isAuthenticated: true,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => FcmDeviceCheckResponseModel.fromJson(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
        ),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<bool>> deregisterDeviceToken({
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.delete(
        ApiEndpoints.fcmDevice,
        cancelToken: cancelToken,
        isAuthenticated: true,
      );

      final isValid = ResponseValidator.isValidResponse(response);
      if (!isValid) throw HttpException.fromResponse(response);

      return isValid;
    });
  }

  @override
  Future<EitherResponseOrException<List<NotificationItem>>> fetchNotifications({
    int? page,
    int? limit,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final queryParameters = <String, dynamic>{};
      if (page != null) queryParameters['page'] = page;
      if (limit != null) queryParameters['limit'] = limit;

      final response = await apiClient.get(
        ApiEndpoints.notifications,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );

      final models = ResponseValidator.parse(
        response,
        _parseNotificationList,
        dataValidator: (data) => data is List || data is Map,
      );

      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<EitherResponseOrException<bool>> markNotificationRead({
    required String id,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.notificationMarkRead(id),
        const EmptyRequestBody(),
        cancelToken: cancelToken,
        isAuthenticated: true,
      );

      final isValid = ResponseValidator.isValidResponse(response);
      if (!isValid) throw HttpException.fromResponse(response);

      return isValid;
    });
  }

  @override
  Future<EitherResponseOrException<int>> fetchUnreadCount({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.notificationsUnreadCount,
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );

      return ResponseValidator.parse(
        response,
        (data) {
          if (data is int) return data;
          if (data is Map) {
            final count = data['count'] ?? data['unread_count'];
            if (count is int) return count;
            if (count is String) return int.tryParse(count) ?? 0;
          }
          return 0;
        },
        dataValidator: (data) =>
            data is int || data is Map || data is String || data is num,
      );
    });
  }

  List<NotificationItemModel> _parseNotificationList(dynamic data) {
    final rawItems = _extractList(data);
    return rawItems
        .whereType<Map>()
        .map((item) => NotificationItemModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['results', 'data', 'notifications']) {
        final value = data[key];
        if (value is List) return value;
      }
    }
    return const [];
  }
}
