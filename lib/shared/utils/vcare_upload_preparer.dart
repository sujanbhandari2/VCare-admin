import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:vcare_admin/shared/utils/file_name.dart';
import 'package:vcare_admin/shared/widgets/image_crop_dialog.dart';
import 'package:vcare_admin/shared/widgets/upload_file_name_prompt_dialog.dart';

/// Controls whether rename is required before upload.
enum VcareUploadPrepareKind {
  /// Free crop; no rename (registration, profile, family, care team).
  profilePhoto,

  /// Free crop for images; rename for all file types (agent/client docs, W-9).
  document,

  /// Free crop for images; rename for all file types (client case attachments).
  caseAttachment,

  /// Free crop for images; rename for all file types (contact support).
  supportAttachment,
}

extension VcareUploadPrepareKindX on VcareUploadPrepareKind {
  /// Always free-aspect crop so users can resize edges independently.
  double? get cropAspectRatio => null;

  bool get requiresRename => this != VcareUploadPrepareKind.profilePhoto;

  String get cropTitle => switch (this) {
        VcareUploadPrepareKind.profilePhoto => 'Crop profile photo',
        _ => 'Crop image',
      };
}

/// Result of [VcareUploadPreparer.prepare] after crop / rename / compress.
class UploadPrepareResult {
  const UploadPrepareResult({
    required this.fileName,
    required this.bytes,
    required this.mime,
  });

  final String fileName;
  final Uint8List bytes;
  final String mime;

  bool get isImage => mime.startsWith('image/');
}

/// Shared pick → crop → optional rename pipeline for upload flows.
class VcareUploadPreparer {
  const VcareUploadPreparer._();

  /// Returns prepared bytes + name, or null when the user cancels a step.
  static Future<UploadPrepareResult?> prepare(
    BuildContext context, {
    required List<int> bytes,
    required String originalFileName,
    required String mime,
    required VcareUploadPrepareKind kind,
  }) async {
    if (bytes.isEmpty) return null;

    var resultBytes =
        bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    var resultMime = mime.trim().isEmpty ? 'application/octet-stream' : mime;
    var displayName =
        originalFileName.trim().isEmpty ? 'attachment' : originalFileName.trim();

    if (shouldCropUploadMime(resultMime)) {
      final cropped = await ImageCropDialog.show(
        context,
        bytes: resultBytes,
        title: kind.cropTitle,
        aspectRatio: kind.cropAspectRatio,
      );
      if (cropped == null || !context.mounted) return null;
      resultBytes = cropped;
      resultMime = 'image/jpeg';
      displayName = defaultDisplayNameForImage(displayName);
    }

    if (kind.requiresRename) {
      final chosenName = await UploadFileNamePromptDialog.show(
        context,
        defaultName: displayName,
      );
      if (chosenName == null || !context.mounted) return null;
      displayName = chosenName;
    }

    return UploadPrepareResult(
      fileName: displayName,
      bytes: resultBytes,
      mime: resultMime,
    );
  }

  /// Crops a profile photo and writes a temp JPEG for path-based upload APIs.
  ///
  /// Returns the absolute file path, or null when cancelled / failed.
  static Future<String?> prepareProfilePhotoPath(
    BuildContext context, {
    required List<int> bytes,
    String originalFileName = 'photo.jpg',
    String filePrefix = 'profile_photo',
  }) async {
    final prepared = await prepare(
      context,
      bytes: bytes,
      originalFileName: originalFileName,
      mime: 'image/jpeg',
      kind: VcareUploadPrepareKind.profilePhoto,
    );
    if (prepared == null || !context.mounted) return null;

    try {
      final tempDir = await getTemporaryDirectory();
      final outPath = p.join(
        tempDir.path,
        '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(outPath).writeAsBytes(prepared.bytes, flush: true);
      return outPath;
    } catch (_) {
      return null;
    }
  }
}
