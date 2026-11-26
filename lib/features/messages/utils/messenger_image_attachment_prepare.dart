import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:vcare_admin/shared/utils/file_name.dart';
import 'package:vcare_admin/shared/widgets/image_crop_dialog.dart';

/// Crops [media] and writes a temp JPEG for messenger upload.
Future<MessengerPickedMedia?> cropMessengerPickedImage(
  BuildContext context, {
  required MessengerPickedMedia media,
}) async {
  if (media.messageType != MessageType.image) {
    return media;
  }
  final file = media.file;
  if (!file.existsSync()) {
    return null;
  }
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty || !context.mounted) {
    return null;
  }

  final cropped = await ImageCropDialog.show(
    context,
    bytes: bytes,
    title: 'Crop image',
  );
  if (cropped == null || !context.mounted) {
    return null;
  }

  try {
    final tempDir = await getTemporaryDirectory();
    final outPath = p.join(
      tempDir.path,
      'messenger_crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(outPath).writeAsBytes(cropped, flush: true);
    return MessengerPickedMedia(
      file: File(outPath),
      messageType: MessageType.image,
      displayName: defaultDisplayNameForImage(media.displayName),
    );
  } catch (_) {
    return null;
  }
}

/// Single-image picks from gallery or camera open crop; multi-select skips it.
Future<List<MessengerPickedMedia>> prepareMessengerPickedMedia(
  BuildContext context,
  MessengerMediaKind kind,
  List<MessengerPickedMedia> picked,
) async {
  if (picked.isEmpty) {
    return picked;
  }
  final isImageKind = kind == MessengerMediaKind.image ||
      kind == MessengerMediaKind.camera;
  if (!isImageKind || picked.length != 1) {
    return picked;
  }
  final only = picked.first;
  if (only.messageType != MessageType.image) {
    return picked;
  }
  final cropped = await cropMessengerPickedImage(context, media: only);
  if (!context.mounted) {
    return const [];
  }
  if (cropped == null) {
    return const [];
  }
  return [cropped];
}