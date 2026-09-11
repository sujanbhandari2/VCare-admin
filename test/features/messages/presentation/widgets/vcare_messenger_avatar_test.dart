import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_avatar.dart';
import 'package:vcare_admin/shared/widgets/shimmer.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [VCareThemeExtension.light]),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('shows first and last name initials when there is no photo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const VcareMessengerAvatar(displayTitle: 'Jane Marie Doe')),
    );

    expect(find.text('JM'), findsOneWidget);
  });

  testWidgets('treats a non-url photo value as missing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const VcareMessengerAvatar(
          displayTitle: 'Alan Turing',
          imageUrl: 'users/alan/profile.jpg',
        ),
      ),
    );

    expect(find.text('AT'), findsOneWidget);
  });

  testWidgets('shows initials while a remote photo loads', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const VcareMessengerAvatar(
          displayTitle: 'Jane Doe',
          imageUrl: 'https://cdn.example.com/users/jane.jpg',
        ),
      ),
    );

    expect(find.text('JD'), findsOneWidget);
    expect(find.byType(Shimmer), findsNothing);
  });

  testWidgets('shows a group icon for group rows', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const VcareMessengerAvatar(displayTitle: 'Care Team', isGroup: true),
      ),
    );

    expect(find.byIcon(LucideIcons.users), findsOneWidget);
  });
}
