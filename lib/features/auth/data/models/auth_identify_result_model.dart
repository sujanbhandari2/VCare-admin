class AuthIdentifyResultModel {
  AuthIdentifyResultModel({
    required this.userExists,
    required this.multipleAccounts,
    required this.atLeastOneAccountLoggedIn,
    required this.otherPendingAccount,
    required this.otpSend,
  });

  final bool userExists;
  final bool multipleAccounts;
  final bool atLeastOneAccountLoggedIn;
  final bool otherPendingAccount;
  final bool otpSend;

  factory AuthIdentifyResultModel.fromJson(Map<String, dynamic> json) {
    return AuthIdentifyResultModel(
      userExists: json['userExists'] as bool? ?? false,
      multipleAccounts: json['multipleAccounts'] as bool? ?? false,
      atLeastOneAccountLoggedIn:
          json['atLeastOneAccountLoggedIn'] as bool? ?? false,
      otherPendingAccount: json['otherPendingAccount'] as bool? ?? false,
      otpSend: json['otpSend'] as bool? ?? false,
    );
  }
}
