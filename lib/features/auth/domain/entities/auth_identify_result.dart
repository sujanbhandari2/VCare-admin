import 'package:vcare_admin/features/auth/domain/entities/auth_identify_account.dart';

class AuthIdentifyResult {
  const AuthIdentifyResult({
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
  final List<AuthIdentifyAccount> accounts;
}
