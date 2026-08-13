import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_insets.dart';

void main() {
  group('VCareMobileShellInsets geometry', () {
    test('pill and bar body heights match shell layout constants', () {
      expect(VCareMobileShellInsets.pillHeight, 64);
      expect(VCareMobileShellInsets.barBodyHeight, 88);
    });
  });

  group('vcareMobileBottomNavContentPadding', () {
    Future<double> pumpAndReadPadding({
      required WidgetTester tester,
      required double width,
      required double bottomSafeArea,
      required String initialLocation,
      TargetPlatform? platform,
    }) async {
      late double padding;

      final router = GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: '/clients',
            builder: (context, state) {
              padding = vcareMobileBottomNavContentPadding(context);
              return const SizedBox();
            },
          ),
          GoRoute(
            path: '/cases',
            builder: (context, state) {
              padding = vcareMobileBottomNavContentPadding(context);
              return const SizedBox();
            },
          ),
          GoRoute(
            path: '/requests',
            builder: (context, state) {
              padding = vcareMobileBottomNavContentPadding(context);
              return const SizedBox();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            padding: EdgeInsets.only(bottom: bottomSafeArea),
          ),
          child: MaterialApp.router(
            theme: ThemeData(platform: platform ?? TargetPlatform.android),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return padding;
    }

    testWidgets('android phone on tab route uses 90px content padding', (
      WidgetTester tester,
    ) async {
      final padding = await pumpAndReadPadding(
        tester: tester,
        width: 390,
        bottomSafeArea: 0,
        initialLocation: '/clients',
        platform: TargetPlatform.android,
      );

      expect(padding, VCareLayout.mobileBottomNavContentPaddingAndroid);
      expect(padding, 90);
    });

    testWidgets('iphone on tab route uses 105px content padding', (
      WidgetTester tester,
    ) async {
      final padding = await pumpAndReadPadding(
        tester: tester,
        width: 390,
        bottomSafeArea: 34,
        initialLocation: '/cases',
        platform: TargetPlatform.iOS,
      );

      expect(padding, VCareLayout.mobileBottomNavContentPaddingIos);
      expect(padding, 105);
    });

    testWidgets('tablet uses fallback padding', (WidgetTester tester) async {
      final padding = await pumpAndReadPadding(
        tester: tester,
        width: VCareLayout.mobileBreakpoint,
        bottomSafeArea: 34,
        initialLocation: '/clients',
        platform: TargetPlatform.iOS,
      );

      expect(padding, VCareMobileShellInsets.fallbackContentPadding);
    });

    testWidgets('phone on non-tab route uses fallback padding', (
      WidgetTester tester,
    ) async {
      final padding = await pumpAndReadPadding(
        tester: tester,
        width: 390,
        bottomSafeArea: 34,
        initialLocation: '/requests',
        platform: TargetPlatform.iOS,
      );

      expect(padding, VCareMobileShellInsets.fallbackContentPadding);
    });
  });

  group('vcareMobileBottomNavHeight', () {
    testWidgets('matches bar body, outer bottom, and safe area on phone', (
      WidgetTester tester,
    ) async {
      late double height;

      final router = GoRouter(
        initialLocation: '/clients',
        routes: [
          GoRoute(
            path: '/clients',
            builder: (context, state) {
              height = vcareMobileBottomNavHeight(context);
              return const SizedBox();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 800),
            padding: EdgeInsets.only(bottom: 34),
          ),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(height, VCareMobileShellInsets.barBodyHeight + 8 + 34);
      expect(height, 130);
    });
  });
}
