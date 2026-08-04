import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/domain/auth_phone_validator.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('AuthPhoneValidator', () {
    testWidgets('accepts valid 10-digit US number', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        AuthPhoneValidator.validate(
          '5551234567',
          country: AuthPhoneCountry.usa,
          context: context,
        ),
        isNull,
      );
    });

    testWidgets('accepts formatted US number', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        AuthPhoneValidator.validate(
          '(555) 123-4567',
          country: AuthPhoneCountry.usa,
          context: context,
        ),
        isNull,
      );
    });

    testWidgets('rejects empty input', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        AuthPhoneValidator.validate(
          '',
          country: AuthPhoneCountry.usa,
          context: context,
        ),
        isNotNull,
      );
    });

    testWidgets('rejects wrong length', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        AuthPhoneValidator.validate(
          '555123456',
          country: AuthPhoneCountry.usa,
          context: context,
        ),
        isNotNull,
      );
    });
  });
}
