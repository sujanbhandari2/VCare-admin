import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/network/connectivity_status_provider.dart';
import 'package:vcare_admin/shared/widgets/vcare_network_edge_widgets.dart';

void main() {
  group('Vcare network edge widgets', () {
    testWidgets('shows offline banner when connectivity is offline', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityOnlineProvider.overrideWith(
              (ref) => Stream<bool>.value(false),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [VCareThemeExtension.light]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: VcareOfflineBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active internet connection'), findsOneWidget);
    });

    testWidgets('hides offline banner when connectivity is online', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityOnlineProvider.overrideWith(
              (ref) => Stream<bool>.value(true),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [VCareThemeExtension.light]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: VcareOfflineBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active internet connection'), findsNothing);
    });
  });
}
