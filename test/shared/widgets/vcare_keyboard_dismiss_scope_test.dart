import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/shared/widgets/vcare_keyboard_dismiss_scope.dart';

void main() {
  group('VcareKeyboardDismissScope', () {
    testWidgets('tap outside field unfocuses', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: VcareKeyboardDismissScope(
            child: Scaffold(
              body: Column(
                children: [
                  TextField(
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Search'),
                  ),
                  const Expanded(
                    child: ColoredBox(
                      key: Key('tap_target'),
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.byKey(const Key('tap_target')));
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);

      focusNode.dispose();
    });

    testWidgets('tap on field still focuses', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: VcareKeyboardDismissScope(
            child: Scaffold(
              body: TextField(
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Search'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);

      focusNode.dispose();
    });

    testWidgets('child button tap still works', (tester) async {
      var pressed = false;
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: VcareKeyboardDismissScope(
            child: Scaffold(
              body: Column(
                children: [
                  TextField(
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Search'),
                  ),
                  ElevatedButton(
                    onPressed: () => pressed = true,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(pressed, isTrue);

      focusNode.dispose();
    });
  });
}
