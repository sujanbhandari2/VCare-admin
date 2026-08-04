/// Agent-voiced copy for a referred client's failed charge.
/// Parity with web `getFailedPaymentCopy`.
class FailedPaymentCopy {
  const FailedPaymentCopy({
    required this.shortLabel,
    required this.explanation,
  });

  final String shortLabel;
  final String explanation;
}

String _normalize(String? reason) => reason?.trim().toLowerCase() ?? '';

String _clientLabel(String? payerName) {
  final name = payerName?.trim();
  return (name != null && name.isNotEmpty) ? name : 'the client';
}

FailedPaymentCopy getFailedPaymentCopy(
  String? failureReason, [
  String? payerName,
]) {
  final reason = _normalize(failureReason);
  final name = _clientLabel(payerName);

  if (reason.contains('insufficient') ||
      reason.contains('funds') ||
      reason.contains('balance') ||
      reason.contains('nsf')) {
    return FailedPaymentCopy(
      shortLabel: 'Not enough funds',
      explanation: "$name's bank didn't have enough for this charge.",
    );
  }

  if (reason.contains('expired') ||
      reason.contains('expir') ||
      reason.contains('invalid card') ||
      reason.contains('do not honor') ||
      reason.contains('stolen') ||
      reason.contains('lost') ||
      reason.contains('pick up') ||
      reason.contains('restricted')) {
    return FailedPaymentCopy(
      shortLabel: 'Card problem',
      explanation: "This card couldn't be charged for $name.",
    );
  }

  if (reason.contains('declined') ||
      reason.contains('refuse') ||
      reason.contains('denied') ||
      reason.contains('reject')) {
    return FailedPaymentCopy(
      shortLabel: 'Card declined',
      explanation: "$name's bank declined this charge.",
    );
  }

  final trimmed = failureReason?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return FailedPaymentCopy(
      shortLabel: 'Payment failed',
      explanation: trimmed,
    );
  }

  return FailedPaymentCopy(
    shortLabel: 'Payment failed',
    explanation: "We couldn't charge the card on file for $name.",
  );
}
