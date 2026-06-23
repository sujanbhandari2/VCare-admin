class AuthIdentifyResult {
  const AuthIdentifyResult({
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
}
