import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_scope.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

void main() {
  group('VCareMobileShellScope', () {
    testWidgets('mobileShellBottomContentPadding is zero when shell applies inset',
        (WidgetTester tester) async {
      late double paddingInsideScope;
      late double paddingOutsideScope;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              paddingOutsideScope = context.mobileShellBottomContentPadding;
              return VCareMobileShellScope(
                appliesBottomContentInset: true,
                child: Builder(
                  builder: (context) {
                    paddingInsideScope =
                        context.mobileShellBottomContentPadding;
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(paddingInsideScope, 0);
      expect(paddingOutsideScope, isNot(0));
    });

    testWidgets('mobileShellBottomContentPadding is zero when keyboard is open',
        (WidgetTester tester) async {
      late double padding;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                padding = context.mobileShellBottomContentPadding;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(padding, 0);
    });

    testWidgets('mobileShellScrollPadding keeps horizontal page padding in shell',
        (WidgetTester tester) async {
      late EdgeInsets scrollPadding;

      await tester.pumpWidget(
        MaterialApp(
          home: VCareMobileShellScope(
            appliesBottomContentInset: true,
            child: Builder(
              builder: (context) {
                scrollPadding = context.mobileShellScrollPadding;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(scrollPadding.left, VCareLayout.pageHorizontalPadding);
      expect(scrollPadding.right, VCareLayout.pageHorizontalPadding);
      expect(scrollPadding.bottom, 0);
    });
  });
}
