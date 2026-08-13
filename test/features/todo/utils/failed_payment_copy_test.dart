import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/todo/utils/failed_payment_copy.dart';

void main() {
  group('getFailedPaymentCopy', () {
    test('maps insufficient funds reasons', () {
      final copy = getFailedPaymentCopy('Insufficient funds', 'Jane Doe');
      expect(copy.shortLabel, 'Not enough funds');
      expect(copy.explanation, "Jane Doe's bank didn't have enough for this charge.");
    });

    test('maps expired card reasons', () {
      final copy = getFailedPaymentCopy('Card expired', 'Jane');
      expect(copy.shortLabel, 'Card expired');
      expect(copy.explanation, "This card couldn't be charged for Jane.");
    });

    test('maps declined reasons', () {
      final copy = getFailedPaymentCopy('Declined by issuer', 'Sam');
      expect(copy.shortLabel, 'Card declined');
      expect(copy.explanation, "Sam's bank declined this charge.");
    });

    test('uses raw reason when unmatched', () {
      final copy = getFailedPaymentCopy('Processor timeout', 'Alex');
      expect(copy.shortLabel, 'Payment failed');
      expect(copy.explanation, 'Processor timeout');
    });

    test('falls back when reason empty', () {
      final copy = getFailedPaymentCopy(null, null);
      expect(copy.shortLabel, 'Payment failed');
      expect(
        copy.explanation,
        "We couldn't charge the card on file for the client.",
      );
    });
  });
}
