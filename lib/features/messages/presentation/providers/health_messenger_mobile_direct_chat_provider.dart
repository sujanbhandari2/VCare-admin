import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';

part 'health_messenger_mobile_direct_chat_provider.g.dart';

/// Bridges programmatic direct-chat opens to the messenger shell's mobile
/// handler (create/select + push thread route).
///
/// [MessengerStartNewChatOpenRequest.onOpenDirectChat] is registered from
/// [HealthMessengerChatBody.startNewChatPresenter] when the shell opens the
/// new-chat picker.
@Riverpod(keepAlive: true)
class HealthMessengerMobileDirectChat extends _$HealthMessengerMobileDirectChat {
  Future<void> Function(MessengerUser user)? _shellOpenDirectChat;

  @override
  void build() {}

  bool get hasShellHandler => _shellOpenDirectChat != null;

  void registerShellOpenDirectChat(
    Future<void> Function(MessengerUser user)? handler,
  ) {
    _shellOpenDirectChat = handler;
  }

  Future<void> openDirectChat(MessengerUser user) async {
    final shellOpen = _shellOpenDirectChat;
    if (shellOpen != null) {
      await shellOpen(user);
      return;
    }
    await ref.read(healthMessengerChatProvider.notifier).openDirectChat(user);
  }
}
