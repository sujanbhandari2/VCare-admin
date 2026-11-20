import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [VCareThemeExtension.light]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('Vcare edge-state widgets', () {
    testWidgets('full-page panel hides raw HTML error bodies', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        _wrap(
          VcareErrorStatePanel(
            title: 'Unable to load settings',
            message: '''
<html><head><title>502 Bad Gateway</title></head>
<body><h1>502 Bad Gateway</h1><hr><center>nginx/1.28.3</center></body></html>
''',
            actionLabel: 'Retry',
            onAction: () => retried = true,
          ),
        ),
      );

      expect(find.text('Unable to load settings'), findsOneWidget);
      expect(find.textContaining('<html>'), findsNothing);
      expect(find.textContaining('502 Bad Gateway'), findsNothing);
      expect(find.textContaining('nginx'), findsNothing);
      expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('inline card hides raw HTML and keeps retry', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        _wrap(
          VcareInlineErrorCard(
            title: 'Unable to load todos',
            message: '''
<html><head><title>502 Bad Gateway</title></head>
<body><center><h1>502 Bad Gateway</h1></center></body></html>
''',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Unable to load todos'), findsOneWidget);
      expect(find.textContaining('<html>'), findsNothing);
      expect(find.textContaining('nginx'), findsNothing);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
