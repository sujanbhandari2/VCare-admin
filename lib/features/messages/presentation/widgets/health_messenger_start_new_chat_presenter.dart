import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';

import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_new_chat_sheet.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_new_group_sheet.dart';

/// Presents the VCare-styled new chat / new group sheets when the package
/// start-new-chat controller opens the picker.
///
/// The package [MessengerStartNewChatController] triggers this presenter; we
/// render the Messages-tab-styled sheets (already wired to the messenger
/// notifier) instead of the package's default picker, so the view matches the
/// rest of the VCare experience.
Future<void> vcarePresentStartNewChat(
  BuildContext context,
  MessengerStartNewChatOpenRequest request,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => request.mode == MessengerStartNewChatMode.group
        ? const HealthMessengerNewGroupSheet()
        : const HealthMessengerNewChatSheet(),
  );
}
