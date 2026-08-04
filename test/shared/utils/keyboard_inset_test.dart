import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/shared/utils/keyboard_inset.dart';

void main() {
  group('isSoftKeyboardOpen', () {
    testWidgets('true when MediaQuery viewInsets.bottom > 0', (tester) async {
      late bool open;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: Builder(
            builder: (context) {
              open = isSoftKeyboardOpen(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(open, isTrue);
    });

    testWidgets('false when no insets and no text focus', (tester) async {
      late bool open;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(390, 800)),
          child: Builder(
            builder: (context) {
              open = isSoftKeyboardOpen(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(open, isFalse);
    });

    testWidgets('false when an EditableText has focus but IME insets are 0',
        (tester) async {
      late bool open;
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(390, 800)),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  open = isSoftKeyboardOpen(context);
                  return EditableText(
                    controller: TextEditingController(),
                    focusNode: focusNode,
                    style: const TextStyle(),
                    cursorColor: Colors.black,
                    backgroundCursorColor: Colors.grey,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(open, isFalse);

      focusNode.requestFocus();
      await tester.pump();

      open = isSoftKeyboardOpen(
        tester.element(find.byType(EditableText)),
      );
      // Focus without IME insets must not keep shell chrome collapsed.
      expect(open, isFalse);

      focusNode.dispose();
    });
  });
}
