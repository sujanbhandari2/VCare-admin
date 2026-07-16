// Local field validation for native CardConnect tokenization forms.

String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

bool isValidCardNumber(String cardNumber) {
  final digits = digitsOnly(cardNumber);
  return digits.length >= 13 && digits.length <= 19;
}

/// Luhn check — helps catch typos before calling CardSecure.
bool passesLuhn(String cardNumber) {
  final digits = digitsOnly(cardNumber);
  if (digits.length < 13) return false;

  var sum = 0;
  var alternate = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.parse(digits[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

int? parseExpMonth(String value) {
  final digits = digitsOnly(value);
  if (digits.isEmpty || digits.length > 2) return null;
  final month = int.tryParse(digits);
  if (month == null || month < 1 || month > 12) return null;
  return month;
}

/// Accepts YY or YYYY; always returns a full 4-digit calendar year (>= 2000).
int? parseExpYear(String value) {
  final digits = digitsOnly(value);
  if (digits.length == 2) {
    final yy = int.tryParse(digits);
    if (yy == null) return null;
    return 2000 + yy;
  }
  if (digits.length == 4) {
    final year = int.tryParse(digits);
    if (year == null || year < 2000 || year > 2100) return null;
    return year;
  }
  return null;
}

/// True when card expiry month/year is this month or in the future.
bool isExpiryCurrentOrFuture({
  required int month,
  required int year,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final currentYear = today.year;
  final currentMonth = today.month;

  if (year > currentYear) return true;
  if (year < currentYear) return false;
  return month >= currentMonth;
}

String formatExpiryMmyy({required int month, required int year}) {
  final mm = month.toString().padLeft(2, '0');
  final yy = (year % 100).toString().padLeft(2, '0');
  return '$mm$yy';
}

bool isAmexCardNumber(String cardNumber) {
  return RegExp(r'^3[47]').hasMatch(digitsOnly(cardNumber));
}

/// Amex expects 4-digit CID; other brands 3-digit CVV.
bool isValidCvv(String cvv, {String? cardNumber}) {
  final digits = digitsOnly(cvv);
  if (cardNumber != null && isAmexCardNumber(cardNumber)) {
    return digits.length == 4;
  }
  return digits.length == 3 || digits.length == 4;
}

int expectedCvvLength(String cardNumber) {
  return isAmexCardNumber(cardNumber) ? 4 : 3;
}

bool isValidRoutingNumber(String routing) {
  return RegExp(r'^\d{9}$').hasMatch(digitsOnly(routing));
}

bool isValidBankAccountNumber(String account) {
  final digits = digitsOnly(account);
  return digits.length >= 4 && digits.length <= 17;
}

String? cardLast4(String cardNumber) {
  final digits = digitsOnly(cardNumber);
  if (digits.length < 4) return null;
  return digits.substring(digits.length - 4);
}

String? accountLast4(String accountNumber) {
  final digits = digitsOnly(accountNumber);
  if (digits.length < 4) return null;
  return digits.substring(digits.length - 4);
}

/// Inline error for exp month once the user has typed 1–2 digits.
String? expMonthFieldError(String expMonth) {
  final digits = digitsOnly(expMonth);
  if (digits.isEmpty) return null;
  if (digits.length == 1) {
    final month = int.tryParse(digits);
    // Allow typing "1"…"9"; only reject impossible leading values.
    if (month == null || month > 1) {
      // "2"-"9" can still become valid as "02"-"09", but "00" impossible.
      // Don't error on single digit 1-9.
      if (month == 0) return 'Enter a valid month (01–12)';
    }
    return null;
  }
  if (parseExpMonth(digits) == null) {
    return 'Enter a valid month (01–12)';
  }
  return null;
}

/// Inline error for exp year once YY or YYYY looks complete.
String? expYearFieldError(String expYear, {String? expMonth}) {
  final digits = digitsOnly(expYear);
  if (digits.isEmpty) return null;

  // Still typing a 4-digit year (e.g. "2", "20", "202").
  if (digits.length < 4) {
    if (digits.length == 2) {
      // YY is accepted on submit, but encourage YYYY for the API.
      return null;
    }
    return null;
  }

  final year = parseExpYear(digits);
  if (year == null) {
    return 'Enter a valid year (YYYY)';
  }

  final today = DateTime.now();
  if (year < today.year) {
    return 'Year must be ${today.year} or later';
  }

  final month = expMonth == null ? null : parseExpMonth(expMonth);
  if (month != null &&
      !isExpiryCurrentOrFuture(month: month, year: year, now: today)) {
    return 'Card has expired';
  }

  return null;
}

/// Inline CVV error once length reaches expected for the brand.
String? cvvFieldError(String cvv, {String? cardNumber}) {
  final digits = digitsOnly(cvv);
  if (digits.isEmpty) return null;

  final expected = cardNumber == null || cardNumber.trim().isEmpty
      ? 3
      : expectedCvvLength(cardNumber);

  if (digits.length < expected) return null;

  if (!isValidCvv(cvv, cardNumber: cardNumber)) {
    return expected == 4 ? 'Enter a 4-digit CVV' : 'Enter a 3-digit CVV';
  }
  return null;
}

bool isExpiryFieldsValid({
  required String expMonth,
  required String expYear,
}) {
  final month = parseExpMonth(expMonth);
  if (month == null) return false;

  final yearDigits = digitsOnly(expYear);
  // Require a full 4-digit year so we never POST a 2-digit value like `26`.
  if (yearDigits.length != 4) return false;

  final year = parseExpYear(expYear);
  if (year == null) return false;
  return isExpiryCurrentOrFuture(month: month, year: year);
}

String? validateCardFields({
  required String cardNumber,
  required String expMonth,
  required String expYear,
  required String cvv,
}) {
  final digits = digitsOnly(cardNumber);
  if (digits.isEmpty || !isValidCardNumber(cardNumber)) {
    return 'Enter a valid card number';
  }
  if (!passesLuhn(cardNumber)) {
    return 'Card number looks invalid';
  }

  final month = parseExpMonth(expMonth);
  if (month == null) {
    return 'Enter a valid expiration month (01–12)';
  }

  final year = parseExpYear(expYear);
  if (year == null || digitsOnly(expYear).length != 4) {
    return 'Enter a 4-digit expiration year (e.g. ${DateTime.now().year + 1})';
  }

  final today = DateTime.now();
  if (year < today.year) {
    return 'Expiration year must be ${today.year} or later';
  }

  if (!isExpiryCurrentOrFuture(month: month, year: year, now: today)) {
    return 'Card has expired';
  }

  final expectedCvv = expectedCvvLength(cardNumber);
  if (!isValidCvv(cvv, cardNumber: cardNumber)) {
    return expectedCvv == 4
        ? 'Enter a 4-digit CVV'
        : 'Enter a 3-digit CVV';
  }

  return null;
}

String? validateBankFields({
  required String routingNumber,
  required String accountNumber,
}) {
  if (!isValidRoutingNumber(routingNumber)) {
    return 'Enter a valid 9-digit routing number';
  }
  if (!isValidBankAccountNumber(accountNumber)) {
    return 'Enter a valid account number';
  }
  return null;
}
