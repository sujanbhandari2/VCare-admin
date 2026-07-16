import 'package:flutter/services.dart';

import 'package:vcare_admin/core/services/payment/card_connect_field_validators.dart';

/// Formats card numbers as the user types (4-4-4-4, or Amex 4-6-5).
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOnly(newValue.text);
    final maxDigits = maxCardNumberDigits(digits);
    final limited = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;

    final formatted = formatCardNumberDisplay(limited);
    final digitOffset = _digitOffsetBeforeCursor(
      newValue.text,
      newValue.selection.baseOffset,
    );
    final selectionOffset = _selectionOffsetForDigitIndex(
      formatted,
      digitOffset.clamp(0, limited.length),
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }

  int _digitOffsetBeforeCursor(String text, int cursor) {
    final safeCursor = cursor.clamp(0, text.length);
    return text.substring(0, safeCursor).replaceAll(RegExp(r'\D'), '').length;
  }

  int _selectionOffsetForDigitIndex(String formatted, int digitIndex) {
    if (digitIndex <= 0) return 0;

    var digitsSeen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        digitsSeen++;
        if (digitsSeen == digitIndex) return i + 1;
      }
    }
    return formatted.length;
  }
}

/// Amex max 15, others up to 19 (usually 16).
int maxCardNumberDigits(String digits) {
  if (RegExp(r'^3[47]').hasMatch(digits)) return 15;
  return 19;
}

/// Expected complete length for common brands.
int expectedCardNumberLength(String digits) {
  if (RegExp(r'^3[47]').hasMatch(digits)) return 15;
  if (RegExp(r'^3(?:0[0-5]|[68])').hasMatch(digits)) return 14; // Diners
  if (RegExp(r'^35').hasMatch(digits)) return 16; // JCB
  return 16;
}

/// Groups: Amex `XXXX XXXXXX XXXXX`, otherwise `XXXX XXXX XXXX XXXX`.
String formatCardNumberDisplay(String cardNumber) {
  final digits = digitsOnly(cardNumber);
  if (digits.isEmpty) return '';

  if (RegExp(r'^3[47]').hasMatch(digits)) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 4 || i == 10) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Inline card-number validation after the number looks complete for its brand.
String? cardNumberFieldError(String cardNumber) {
  final digits = digitsOnly(cardNumber);
  if (digits.isEmpty) return null;

  final expected = expectedCardNumberLength(digits);
  if (digits.length < expected) return null;

  if (digits.length > 19) {
    return 'Enter a valid card number';
  }

  if (!passesLuhn(digits)) {
    return 'Card number looks invalid';
  }

  return null;
}

bool isCompleteValidCardNumber(String cardNumber) {
  final digits = digitsOnly(cardNumber);
  if (digits.length < 13 || digits.length > 19) return false;
  final expected = expectedCardNumberLength(digits);
  return digits.length >= expected && passesLuhn(digits);
}
