class ApiEndpoints {
  ApiEndpoints._();

  static const String authIdentify = "auth/identify/";
  static const String authRequestOtp = "auth/request-otp/";
  static const String authVerifyOtp = "auth/verify-otp/";
  static const String authPreAuthUser = "auth/pre-auth/user";
  static const String authSetupAccount = "auth/setup-account/";

  static const String authMe = "auth/me/";

  static const String login = "auth/login/";
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

  static const String agentClients = "agents/clients";
  static String agentClient(String id) => "agents/clients/$id";
  static String agentClientMemberships(String id) =>
      "agents/clients/$id/memberships";
  static String agentClientPaymentMethods(String id) =>
      "agents/clients/$id/payment-methods";
  static String agentClientTransactions(String id) =>
      "agents/clients/$id/transactions";
  static String agentClientCases(String id) => "agents/clients/$id/cases";
  static String agentClientDocuments(String id) =>
      "agents/clients/$id/documents";
}
