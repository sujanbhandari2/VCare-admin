class ForgotPasswordAccount {
  const ForgotPasswordAccount({
    required this.accountId,
    required this.displayName,
  });

  final String accountId;
  final String displayName;
}

/// Result of POST auth/forgot-password — non-empty [accounts] means disambiguation.
class ForgotPasswordResult {
  const ForgotPasswordResult({
    this.sent = false,
    this.accounts = const [],
  });

  final bool sent;
  final List<ForgotPasswordAccount> accounts;

  bool get requiresDisambiguation => accounts.isNotEmpty;
}
