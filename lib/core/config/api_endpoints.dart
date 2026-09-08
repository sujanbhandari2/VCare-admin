class ApiEndpoints {
  ApiEndpoints._();

  static const String authIdentify = "auth/identify/";
  static const String authRequestOtp = "auth/request-otp/";
  static const String authVerifyOtp = "auth/verify-otp/";
  static const String authPreAuthUser = "auth/pre-auth/user";
  static const String authSetupAccount = "auth/setup-account/";

  static const String authMe = "auth/me/";

  static const String login = "auth/login/";
  static const String authSend2fa = "auth/send-2fa/";
  static const String authVerify2fa = "auth/verify-2fa/";
  static const String googleLogin = "google-login/";
  static const String appleLogin = "apple-login/";
  static const String register = "register/";
  static const String authForgotPassword = "auth/forgot-password/";
  static const String authResetPassword = "auth/reset-password/";
  static const String profile = "user-profile/";
  static const String authRefresh = "auth/refresh/";
  static const String authLogout = "auth/logout/";

  /// Legacy alias — prefer [authRefresh].
  static const String refreshToken = authRefresh;

  static const String fcmDevice = "fcm-device/";
  static const String fcmDeviceRegister = "fcm-device-register/";
  static const String fcmDeviceUpdate = "fcm-device-update/";
  static const String checkFcmDeviceStatus = "fcm-device-status-check/";

  static const String notifications = "notifications/";
  static const String notificationsUnreadCount = "notifications/unread-count/";
  static String notificationMarkRead(String id) => "notifications/$id/read/";

  static const String agentStats = "agents/stats";
  static const String agentCode = "agents/agent-code";
  static const String agentCommissionSummary = "agents/commission-summary";
  static const String agentCommissionHistory = "agents/commission-history";
  static const String agentSalesHistory = "agents/sales-history";
  /// Platform admin client list (matches web `clientApiPaths.collection`).
  static const String clients = "clients";

  static const String agentClients = "agents/clients";
  static String agentClient(String id) => "agents/clients/$id";
  static String clientById(String id) => "clients/$id";
  static String clientRelationships(String id) => "clients/$id/relationships";
  static String clientFiles(String id) => "clients/$id/files";

  static String enrollmentsAssociateMembership(String id) =>
      "enrollments/associate-membership/$id";

  static const String transactions = "transactions";
  static const String referralCases = "referral-cases";
  static String referralCase(String id) => "referral-cases/$id";
  static String referralCaseClone(String id) => "referral-cases/$id/clone";
  static String referralCaseOtherCases(String id) =>
      "referral-cases/$id/other-cases";
  static String referralCaseNotes(String caseId) =>
      "referral-cases/$caseId/notes";
  static String referralCaseNote(String caseId, String noteId) =>
      "referral-cases/$caseId/notes/$noteId";
  static String referralCaseNoteTagUsers(String caseId) =>
      "referral-cases/$caseId/notes/tag-users";

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

  static const String todos = "todos";

  /// Admin dashboard todo list (matches web `adminTodoListApiPaths.collection`).
  static const String adminTodoList = "admin/todo-list";

  /// Enrollment list (matches web `enrollmentApiPaths.collection`).
  static const String enrollments = "enrollments";
  static String enrollmentById(String id) => "enrollments/$id";
  static String enrollmentsRelevantMembership(String id) =>
      "enrollments/relevant-membership/$id";
  static const String enrollmentsApprove = "enrollments/approve";
  static const String enrollmentsApproveCompute = "enrollments/approve/compute";
  static const String enrollmentsCancel = "enrollments/cancel";

  /// Agent list (matches web `agentApiPaths.collection`).
  static const String agents = "agents";

  /// parity: vcare-agent-app-2.0/src/features/help-support/api/contact-support.endpoints.ts
  static const String contactSupport = "contact-support";

  static const String files = "files";
  static const String filesFromUrl = "files/url";
  static const String filesDocumentTypes = "files/document-types";
  static String file(String id) => "files/$id/";
  static String fileContent(String id) => "files/$id/content";

  static const String tasks = "tasks";
  static String task(String id) => "tasks/$id";

  static const String meInteractions = "me/interactions";

  static const String providersSave = "providers/save";
  static String providerSaveById(String providerId) =>
      "providers/save/$providerId";

  static const String familyMembers = "family-members/";
  static String familyMember(String id) => "family-members/$id";

  static const String careTeam = "care-team/";
  static String careTeamMember(String id) => "care-team/$id";

  static const String users = "users";
  static String userById(String id) => "users/$id";
  static const String usersAssociated = "users/associated";

  /// Self-service password change (matches web `accountApiPaths.changePassword`).
  static const String authChangePassword = "auth/change-password";

  /// Google Places proxy (matches web `placesApiPaths`).
  static const String placesAutocomplete = "places/autocomplete";
  static String placeById(String placeId) => "places/$placeId";

  /// Tenant settings / branding (matches web `settingsApiPaths`).
  static const String settings = "settings";
  static const String settingsBranding = "settings/branding";
  static const String settingsTheme = "settings/theme";
}

