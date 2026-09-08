import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';

import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';

void main() {
  group('composer drafts notify the shell content listenable', () {
    late ProviderContainer container;
    late HealthMessengerChatNotifier notifier;
    late int notifications;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      notifier = container.read(healthMessengerChatProvider.notifier);
      notifications = 0;
      notifier.shellContentListenable.addListener(() => notifications++);
    });

    test('beginComposerEdit stores the draft and notifies', () {
      notifier.beginComposerEdit('message-1');

      expect(
        container.read(healthMessengerChatProvider).composerEditDraft?.messageId,
        'message-1',
      );
      expect(notifications, 1);
    });

    test('clearComposerEdit drops the draft and notifies', () {
      notifier.beginComposerEdit('message-1');
      notifier.clearComposerEdit();

      expect(
        container.read(healthMessengerChatProvider).composerEditDraft,
        isNull,
      );
      expect(notifications, 2);
    });

    test('beginComposerEdit ignores a blank message id', () {
      notifier.beginComposerEdit('   ');

      expect(
        container.read(healthMessengerChatProvider).composerEditDraft,
        isNull,
      );
      expect(notifications, 0);
    });

    test('updateComposerReplyDraft notifies', () {
      notifier.updateComposerReplyDraft(
        const MessengerComposerReplyDraft(
          targetMessageId: 'message-1',
          senderLabel: 'Me',
          preview: 'hello there',
        ),
      );

      expect(
        container
            .read(healthMessengerChatProvider)
            .composerReplyDraft
            ?.targetMessageId,
        'message-1',
      );
      expect(notifications, 1);
    });
  });
}
