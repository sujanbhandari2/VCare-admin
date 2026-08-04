enum TodoType {
  paymentFailed,
  w9FormMissing,
  completeProfile,
  unknown;

  static TodoType fromApi(String? value) {
    switch ((value ?? '').trim().toUpperCase()) {
      case 'PAYMENT_FAILED':
        return TodoType.paymentFailed;
      case 'W9_FORM_MISSING':
      case 'W9_FORM_REQUIRED':
        return TodoType.w9FormMissing;
      case 'COMPLETE_PROFILE':
        return TodoType.completeProfile;
      default:
        return TodoType.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case TodoType.paymentFailed:
        return 'PAYMENT_FAILED';
      case TodoType.w9FormMissing:
        return 'W9_FORM_MISSING';
      case TodoType.completeProfile:
        return 'COMPLETE_PROFILE';
      case TodoType.unknown:
        return 'UNKNOWN';
    }
  }
}
