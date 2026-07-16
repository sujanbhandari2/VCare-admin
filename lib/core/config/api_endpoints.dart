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

  static const String agentStats = "agents/stats";
  static const String agentCommissionSummary = "agents/commission-summary";
  static const String agentCommissionHistory = "agents/commission-history";
  static const String agentClients = "agents/clients";
  static String agentClient(String id) => "agents/clients/$id";
  static String agentClientMemberships(String id) =>
      "agents/clients/$id/memberships";
  static String agentClientTransactions(String id) =>
      "agents/clients/$id/transactions";
  static String agentClientCases(String id) => "agents/clients/$id/cases";
  static String agentClientDocuments(String id) =>
      "agents/clients/$id/documents";
  static String clientDependents(String id) => "clients/$id/dependents";

  /// Billing payment methods (matches web `clientBillingApiPaths`).
  static String clientPaymentMethods(String id) =>
      "clients/$id/payment-methods";
  static String clientPaymentMethod(String clientId, String paymentMethodId) =>
      "clients/$clientId/payment-methods/$paymentMethodId";
  static String clientPaymentMethodSetPrimary(
    String clientId,
    String paymentMethodId,
  ) => "clients/$clientId/payment-methods/$paymentMethodId/set-primary";

  static String transactionCharge(String id) => "transactions/$id/charge";

  static const String files = "files";
  static String file(String id) => "files/$id/";

  static const String providersSave = "providers/save";
  static String providerSaveById(String providerId) => "providers/save/$providerId";

  static const String familyMembers = "family-members/";
  static String familyMember(String id) => "family-members/$id";

  static const String careTeam = "care-team/";
  static String careTeamMember(String id) => "care-team/$id";

  static const String usersAssociated = "users/associated";
}
