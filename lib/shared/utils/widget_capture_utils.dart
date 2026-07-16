import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WidgetCaptureUtils {
  WidgetCaptureUtils._();

  static Future<Uint8List?> capturePng(
    GlobalKey key, {
    double pixelRatio = 3,
  }) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static Future<bool> saveToGallery(
    Uint8List bytes, {
    String name = 'vcare-referral-card',
  }) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          return false;
        }
      }

      await Gal.putImageBytes(
        bytes,
        name: name,
        album: 'VCare',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sharePngBytes(
    Uint8List bytes, {
    required String fileName,
    String? shareText,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: shareText,
      ),
    );

    return result.status != ShareResultStatus.unavailable;
  }
}
