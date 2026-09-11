import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/widgets/image_picker_source_selection_bottom_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_floating_bottom_sheet.dart';

const _screenSize = Size(390, 844);
const _viewPadding = EdgeInsets.only(bottom: 34);

Widget _host() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: const MediaQueryData(size: _screenSize, padding: _viewPadding),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  ImagePickerSourceSelectionBottomSheet.show<void>(context);
                },
                child: const Text('Pick'),
              ),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('image picker sheet anchors to the screen bottom', (tester) async {
    const screenSize = _screenSize;
    const viewPadding = _viewPadding;

    await tester.binding.setSurfaceSize(screenSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host());

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    final cardFinder = find.byType(VcareFloatingBottomSheetCard);
    expect(cardFinder, findsOneWidget);

    final surface = tester.getRect(
      find.descendant(of: cardFinder, matching: find.byType(Material)).first,
    );

    expect(surface.left, 0);
    expect(surface.right, screenSize.width);
    expect(surface.bottom, screenSize.height);

    final contentBottom = tester.getBottomLeft(find.text('Gallery')).dy;

    expect(contentBottom, greaterThan(screenSize.height * 0.85));
    expect(contentBottom, lessThan(screenSize.height - viewPadding.bottom));
  });

  testWidgets('image picker sheet has a grabber and closes on drag down', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(_screenSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host());

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    final card = tester.widget<VcareFloatingBottomSheetCard>(
      find.byType(VcareFloatingBottomSheetCard),
    );
    expect(card.showDragHandle, isTrue);

    await tester.drag(find.text('Gallery'), const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(find.text('Gallery'), findsNothing);
  });

  testWidgets('image picker sheet closes when tapping the scrim', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(_screenSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host());

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('Gallery'), findsOneWidget);

    await tester.tapAt(const Offset(195, 100));
    await tester.pumpAndSettle();

    expect(find.text('Gallery'), findsNothing);
  });
}
