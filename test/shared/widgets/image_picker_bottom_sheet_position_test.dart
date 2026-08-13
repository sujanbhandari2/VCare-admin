import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/widgets/image_picker_source_selection_bottom_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_floating_bottom_sheet.dart';

void main() {
  testWidgets('image picker sheet anchors to the screen bottom', (tester) async {
    const screenSize = Size(390, 844);
    const viewPadding = EdgeInsets.only(bottom: 34);

    await tester.binding.setSurfaceSize(screenSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: screenSize,
            padding: viewPadding,
          ),
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      ImagePickerSourceSelectionBottomSheet.show<void>(
                        context,
                      );
                    },
                    child: const Text('Pick'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    final cardFinder = find.byType(VcareFloatingBottomSheetCard);
    expect(cardFinder, findsOneWidget);

    final contentBottom = tester.getBottomLeft(find.text('Gallery')).dy;

    expect(contentBottom, greaterThan(screenSize.height * 0.85));
    expect(contentBottom, lessThan(screenSize.height - viewPadding.bottom));
  });
}
