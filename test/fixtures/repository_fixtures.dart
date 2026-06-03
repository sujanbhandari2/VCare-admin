import 'package:flutter_template/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_template/features/auth/domain/entities/forgot_password_response.dart';
import 'package:flutter_template/features/auth/domain/entities/register_response.dart';
import 'package:flutter_template/features/notifications/domain/entities/fcm_device_added_or_updated_response.dart';
import 'package:flutter_template/features/notifications/domain/entities/fcm_device_check_response.dart';
import 'package:flutter_template/features/profile/domain/entities/user_profile.dart';

class RepositoryFixtures {
  const RepositoryFixtures._();

  static AuthSession authSession({
    int userId = 11,
    String access = 'access_token',
    String refresh = 'refresh_token',
    String username = 'fixture.user',
    String email = 'fixture@example.com',
  }) => AuthSession(
    userId: userId,
    access: access,
    refresh: refresh,
    username: username,
    email: email,
  );

  static RegisterResponse registerResponse({
    bool success = true,
    String message = 'Registered',
  }) => RegisterResponse(success: success, message: message);

  static ForgotPasswordResponse forgotPasswordResponse({
    bool success = true,
    String message = 'Reset link sent',
  }) => ForgotPasswordResponse(success: success, message: message);

  static FcmDeviceCheckResponse fcmDeviceCheckResponse({
    bool hasFcmToken = true,
    int fcmDeviceId = 7,
    String fcmRegistrationToken = 'fcm_token',
  }) => FcmDeviceCheckResponse(
    hasFcmToken: hasFcmToken,
    fcmDeviceId: fcmDeviceId,
    fcmRegistrationToken: fcmRegistrationToken,
  );

  static FcmDeviceAddedOrUpdatedResponse fcmDeviceAddedOrUpdatedResponse({
    int id = 7,
    String registrationId = 'fcm_token',
    String type = 'android',
  }) => FcmDeviceAddedOrUpdatedResponse(
    id: id,
    registrationId: registrationId,
    type: type,
    active: true,
    dateCreated: DateTime.utc(2026, 1, 1),
  );

  static UserProfile userProfile({
    int id = 99,
    int user = 11,
    String firstName = 'Fixture',
    String lastName = 'User',
    String username = 'fixture.user',
  }) => UserProfile(
    id: id,
    user: user,
    firstName: firstName,
    lastName: lastName,
    username: username,
  );
}
