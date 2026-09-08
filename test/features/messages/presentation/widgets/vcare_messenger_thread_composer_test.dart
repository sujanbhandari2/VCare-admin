import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_state.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_thread_composer.dart';

MessengerComposerData _composerData(TextEditingController controller) {
  return MessengerComposerData(
    controller: controller,
    isRecording: false,
    isSending: false,
    onSend: () {},
    onPickImage: () {},
    onPickAudio: () {},
    onToggleRecording: () {},
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [VCareThemeExtension.light]),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('shows the send affordances when not editing', (tester) async {
    final controller = TextEditingController(text: 'Hello');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(VcareMessengerThreadComposer(data: _composerData(controller))),
    );

    expect(find.text('Editing message'), findsNothing);
    expect(find.byIcon(LucideIcons.send), findsOneWidget);
    expect(find.byIcon(LucideIcons.paperclip), findsOneWidget);
    expect(find.byIcon(LucideIcons.mic), findsOneWidget);
  });

  testWidgets('swaps to edit affordances while an edit draft is open', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Amended text');
    addTearDown(controller.dispose);
    var cancelled = false;

    await tester.pumpWidget(
      _wrap(
        VcareMessengerThreadComposer(
          data: _composerData(controller),
          editDraft: const MessengerComposerEditDraft(messageId: 'message-1'),
          onCancelEditDraft: () => cancelled = true,
        ),
      ),
    );

    expect(find.text('Editing message'), findsOneWidget);
    expect(find.byIcon(LucideIcons.send), findsOneWidget);
    expect(find.byIcon(LucideIcons.paperclip), findsOneWidget);
    expect(find.byIcon(LucideIcons.mic), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x));
    expect(cancelled, isTrue);
  });
}
