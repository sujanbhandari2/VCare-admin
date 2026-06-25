import 'package:vcare_admin/features/auth/data/models/auth_identify_account_model.dart';

class AuthIdentifyResultModel {
  AuthIdentifyResultModel({
    required this.userExists,
    required this.multipleAccounts,
    required this.atLeastOneAccountLoggedIn,
    required this.otherPendingAccount,
    required this.otpSend,
    this.accounts = const [],
  });

  final bool userExists;
  final bool multipleAccounts;
  final bool atLeastOneAccountLoggedIn;
  final bool otherPendingAccount;
  final bool otpSend;
  final List<AuthIdentifyAccountModel> accounts;

  factory AuthIdentifyResultModel.fromJson(Map<String, dynamic> json) {
    final accountsRaw = json['accounts'];
    final accounts = accountsRaw is List
        ? accountsRaw
            .whereType<Map<String, dynamic>>()
            .map(AuthIdentifyAccountModel.fromJson)
            .toList()
        : <AuthIdentifyAccountModel>[];

    return AuthIdentifyResultModel(
      userExists: json['userExists'] as bool? ?? false,
      multipleAccounts: json['multipleAccounts'] as bool? ?? false,
      atLeastOneAccountLoggedIn:
          json['atLeastOneAccountLoggedIn'] as bool? ?? false,
      otherPendingAccount: json['otherPendingAccount'] as bool? ?? false,
      otpSend: json['otpSend'] as bool? ?? false,
      accounts: accounts,
    );
  }
}
