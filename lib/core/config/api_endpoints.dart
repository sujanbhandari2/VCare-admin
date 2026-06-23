class ApiEndpoints {
  ApiEndpoints._();

  static const String authIdentify = "auth/identify/";
  static const String authRequestOtp = "auth/request-otp/";
  static const String authVerifyOtp = "auth/verify-otp/";

  static const String login = "login/";
  static const String googleLogin = "google-login/";
  static const String appleLogin = "apple-login/";
  static const String register = "register/";
  static const String forgetPassword = "forget-password/";
  static const String profile = "user-profile/";
  static const String refreshToken = "refresh-token/";

  static const String fcmDevice = "fcm-device/";
  static const String fcmDeviceRegister = "fcm-device-register/";
  static const String fcmDeviceUpdate = "fcm-device-update/";
  static const String checkFcmDeviceStatus = "fcm-device-status-check/";

  static const String notifications = "notifications/";
  static const String notificationsUnreadCount = "notifications/unread-count/";
  static String notificationMarkRead(String id) => "notifications/$id/read/";
}
