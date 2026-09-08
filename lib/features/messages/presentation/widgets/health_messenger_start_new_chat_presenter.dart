import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';

import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_new_chat_sheet.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_new_group_sheet.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Presents the VCare-styled new chat / new group sheets when the package
/// start-new-chat controller opens the picker.
///
/// Sheets must call [MessengerStartNewChatOpenRequest.onOpenDirectChat] /
/// [MessengerStartNewChatOpenRequest.onCreateGroupRequested] so the mobile
/// shell can push the conversation thread after create/select.
Future<void> vcarePresentStartNewChat(
  BuildContext context,
  MessengerStartNewChatOpenRequest request,
) {
  return context.showBottomSheet<void>(
    isScrollControlled: true,
    builder: (_) => request.mode == MessengerStartNewChatMode.group
        ? HealthMessengerNewGroupSheet(
            onCreateGroupRequested: request.onCreateGroupRequested,
          )
        : HealthMessengerNewChatSheet(
            onOpenDirectChat: request.onOpenDirectChat,
          ),
  );
}
