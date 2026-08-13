import 'package:vcare_admin/features/auth/data/models/forgot_password_account_model.dart';

class ForgotPasswordResultModel {
  const ForgotPasswordResultModel({
    this.sent = false,
    this.accounts = const [],
  });

  final bool sent;
  final List<ForgotPasswordAccountModel> accounts;

  factory ForgotPasswordResultModel.fromJson(Map<String, dynamic> json) {
    final accountsRaw = json['accounts'];
    final accounts = accountsRaw is List
        ? accountsRaw
              .whereType<Map<String, dynamic>>()
              .map(ForgotPasswordAccountModel.fromJson)
              .toList()
        : <ForgotPasswordAccountModel>[];

    return ForgotPasswordResultModel(
      sent: json['sent'] == true,
      accounts: accounts,
    );
  }
}
