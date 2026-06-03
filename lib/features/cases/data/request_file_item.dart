import 'package:flutter_template/features/cases/utils/request_attachments.dart';
import 'package:flutter_template/features/home/data/home_models.dart';

/// Flattened file from message attachments — parity with web RequestFileItem.
class RequestFileItem {
  const RequestFileItem({
    required this.attachment,
    required this.at,
    required this.sender,
  });

  final RequestAttachment attachment;
  final DateTime at;
  final String sender;
}

List<RequestFileItem> collectRequestFiles(List<RequestMessage> messages) {
  final files = <RequestFileItem>[];
  for (final message in messages) {
    for (final attachment in message.attachments ?? const []) {
      if (isRequestAudioAttachment(attachment.dataUrl, attachment.name)) {
        continue;
      }
      files.add(
        RequestFileItem(
          attachment: attachment,
          at: message.createdAt,
          sender: message.sender,
        ),
      );
    }
  }
  return files;
}
