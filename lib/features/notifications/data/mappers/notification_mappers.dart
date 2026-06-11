import 'package:vcare_admin/features/notifications/data/models/fcm_device_added_or_updated_response_model.dart'
    as model;
import 'package:vcare_admin/features/notifications/data/models/fcm_device_check_response_model.dart'
    as model;
import 'package:vcare_admin/features/notifications/data/models/notification_item_model.dart'
    as model;
import 'package:vcare_admin/features/notifications/domain/entities/fcm_device_added_or_updated_response.dart';
import 'package:vcare_admin/features/notifications/domain/entities/fcm_device_check_response.dart';
import 'package:vcare_admin/features/notifications/domain/entities/notification_item.dart';

extension FcmDeviceCheckResponseMapper on model.FcmDeviceCheckResponseModel {
  FcmDeviceCheckResponse toEntity() {
    return FcmDeviceCheckResponse(
      hasFcmToken: hasFcmToken,
      fcmDeviceId: fcmDeviceId,
      fcmRegistrationToken: fcmRegistrationToken,
    );
  }
}

extension FcmDeviceCheckResponseEntityMapper on FcmDeviceCheckResponse {
  model.FcmDeviceCheckResponseModel toModel() {
    return model.FcmDeviceCheckResponseModel(
      hasFcmToken: hasFcmToken,
      fcmDeviceId: fcmDeviceId,
      fcmRegistrationToken: fcmRegistrationToken,
    );
  }
}

extension FcmDeviceAddedOrUpdatedResponseMapper
    on model.FcmDeviceAddedOrUpdatedResponseModel {
  FcmDeviceAddedOrUpdatedResponse toEntity() {
    return FcmDeviceAddedOrUpdatedResponse(
      id: id,
      name: name,
      registrationId: registrationId,
      deviceId: deviceId,
      active: active,
      dateCreated: dateCreated,
      type: type,
    );
  }
}

extension FcmDeviceAddedOrUpdatedResponseEntityMapper
    on FcmDeviceAddedOrUpdatedResponse {
  model.FcmDeviceAddedOrUpdatedResponseModel toModel() {
    return model.FcmDeviceAddedOrUpdatedResponseModel(
      id: id,
      name: name,
      registrationId: registrationId,
      deviceId: deviceId,
      active: active,
      dateCreated: dateCreated,
      type: type,
    );
  }
}

extension NotificationItemModelMapper on model.NotificationItemModel {
  NotificationItem toEntity() {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      read: read,
      createdAt: createdAt,
    );
  }
}
