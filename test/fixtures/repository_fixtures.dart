import 'package:vcare_admin/features/auth/domain/entities/admin_auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_tenant.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_user.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_pre_auth_user.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/forgot_password_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/reset_password_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/register_response.dart';
import 'package:vcare_admin/features/notifications/domain/entities/fcm_device_added_or_updated_response.dart';
import 'package:vcare_admin/features/notifications/domain/entities/fcm_device_check_response.dart';
import 'package:vcare_admin/features/profile/domain/entities/user_profile.dart';

class RepositoryFixtures {
  const RepositoryFixtures._();

  static AuthPreAuthUser authPreAuthUser({
    String firstName = 'Fixture',
    String lastName = 'User',
    String dob = '1990-01-01',
    String zipCode = '12345',
    String email = 'fixture@example.com',
    String phone = '5551234567',
    String? gender,
    String? primaryCity,
    String? primaryState,
  }) => AuthPreAuthUser(
    firstName: firstName,
    lastName: lastName,
    dob: dob,
    zipCode: zipCode,
    email: email,
    phone: phone,
    gender: gender,
    primaryCity: primaryCity,
    primaryState: primaryState,
  );

  static AuthSession authSession({
    int userId = 11,
    String access = 'access_token',
    String refresh = 'refresh_token',
    String username = 'fixture.user',
    String email = 'fixture@example.com',
    String? profileId,
    String? tenantId,
  }) => AuthSession(
    userId: userId,
    access: access,
    refresh: refresh,
    username: username,
    email: email,
    profileId: profileId,
    tenantId: tenantId,
  );

  static AdminAuthSession adminAuthSession({
    String accessToken = 'access_token',
    String refreshToken = 'refresh_token',
    String userId = 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a',
    String email = 'admin@example.com',
    String firstName = 'Admin',
    String lastName = 'User',
    String tenantId = 'tenant-id',
    String tenantSlug = 'default',
    String tenantName = 'Default Tenant',
    List<String> currentRoles = const ['ADMIN'],
    List<String> menu = const ['dashboard', 'clients'],
  }) => AdminAuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    user: AdminAuthUser(
      id: userId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      currentTenant: AdminAuthTenant(
        id: tenantId,
        slug: tenantSlug,
        name: tenantName,
      ),
      currentRoles: currentRoles,
    ),
    menu: menu,
  );

  static RegisterResponse registerResponse({
    bool success = true,
    String message = 'Registered',
  }) => RegisterResponse(success: success, message: message);

  static ForgotPasswordResult forgotPasswordResult({
    bool sent = true,
    List<ForgotPasswordAccount> accounts = const [],
  }) => ForgotPasswordResult(sent: sent, accounts: accounts);

  static ResetPasswordResult resetPasswordResult({
    String message = 'Password updated',
  }) => ResetPasswordResult(message: message);

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

  static AuthMe authMe({
    String id = 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a',
    String firstName = 'Jane',
    String lastName = 'Doe',
    String email = 'sujan@vitafyhealth.com',
    List<String> menu = const ['files', 'activities'],
  }) => AuthMe(
    user: AuthMeUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
    ),
    menu: menu,
  );
}
