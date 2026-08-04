import 'package:flutter/services.dart';

import 'package:vcare_admin/core/services/payment/card_connect_field_validators.dart';

/// Formats card numbers as the user types (`xxxx xxxx xxxx xxxx`).
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOnly(newValue.text);
    final limited = digits.length > maxCardNumberDigits
        ? digits.substring(0, maxCardNumberDigits)
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

/// Card numbers are limited to 16 digits.
const int maxCardNumberDigits = 16;

/// Expected complete length (exactly 16 digits).
const int expectedCardNumberLength = 16;

/// Groups digits as `xxxx xxxx xxxx xxxx`.
String formatCardNumberDisplay(String cardNumber) {
  final digits = digitsOnly(cardNumber);
  if (digits.isEmpty) return '';

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Inline card-number validation after the number looks complete.
String? cardNumberFieldError(String cardNumber) {
  final digits = digitsOnly(cardNumber);
  if (digits.isEmpty) return null;

  if (digits.length < expectedCardNumberLength) return null;

  if (digits.length > maxCardNumberDigits) {
    return 'Enter a valid card number';
  }

  if (!passesLuhn(digits)) {
    return 'Card number looks invalid';
  }

  return null;
}

bool isCompleteValidCardNumber(String cardNumber) {
  final digits = digitsOnly(cardNumber);
  return digits.length == expectedCardNumberLength && passesLuhn(digits);
}
