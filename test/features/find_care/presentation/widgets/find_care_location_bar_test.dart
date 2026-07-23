import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/find_care/presentation/widgets/find_care_location_bar.dart';

void main() {
  testWidgets('shows progress and disables tap while detecting', (
    tester,
  ) async {
    var taps = 0;
    final controller = TextEditingController(text: 'Austin, TX');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [VCareThemeExtension.light]),
        home: Scaffold(
          body: FindCareLocationBar(
            locationController: controller,
            isDetecting: true,
            onDetectLocation: () => taps += 1,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(LucideIcons.locateFixed), findsNothing);

    await tester.tap(find.byType(InkWell).last);
    await tester.pump();
    expect(taps, 0);

    controller.dispose();
  });

  testWidgets('invokes locate callback when idle', (tester) async {
    var taps = 0;
    final controller = TextEditingController(text: 'Austin, TX');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [VCareThemeExtension.light]),
        home: Scaffold(
          body: FindCareLocationBar(
            locationController: controller,
            onDetectLocation: () => taps += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.locateFixed));
    await tester.pump();
    expect(taps, 1);

    controller.dispose();
  });
}
