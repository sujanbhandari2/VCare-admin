import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_new_chat_sheet.dart';
import 'package:vcare_admin/features/users/presentation/providers/associated_users_repository_provider.dart';

import '../../../../fixtures/repositories/fake_associated_users_repository.dart';

Widget _wrap(FakeAssociatedUsersRepository repository) {
  return ProviderScope(
    overrides: [
      associatedUsersRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: [VCareThemeExtension.light]),
      home: Scaffold(
        body: SizedBox(
          height: 600,
          child: HealthMessengerNewChatSheet(
            onOpenDirectChat: (_) async {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('loads associated users for the picker', (tester) async {
    final repository = FakeAssociatedUsersRepository(total: 45);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(repository.requestedPages, contains(1));
    expect(find.text('User 0'), findsOneWidget);
  });
}
