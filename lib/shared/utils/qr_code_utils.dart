import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeUtils {
  QrCodeUtils._();

  static const defaultErrorCorrectLevel = QrErrorCorrectLevel.H;
  static const defaultExportSize = 512;

  static QrImage createQrImage(
    String data, {
    int errorCorrectLevel = defaultErrorCorrectLevel,
  }) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: errorCorrectLevel,
    );
    return QrImage(qrCode);
  }

  static PrettyQrDecoration decoration({
    Color? foreground,
    Color? background,
    ImageProvider? centerImage,
  }) {
    return PrettyQrDecoration(
      shape: PrettyQrSmoothSymbol(color: foreground ?? Colors.black),
      background: background ?? Colors.white,
      quietZone: PrettyQrQuietZone.standard,
      image: centerImage == null
          ? null
          : PrettyQrDecorationImage(image: centerImage),
    );
  }

  static PrettyQrDecoration decorationFromContext(
    BuildContext context, {
    ImageProvider? centerImage,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return decoration(
      foreground: colorScheme.onSurface,
      background: colorScheme.surface,
      centerImage: centerImage,
    );
  }

  static Future<Uint8List?> toPngBytes(
    String data, {
    int size = defaultExportSize,
    PrettyQrDecoration? decoration,
    int errorCorrectLevel = defaultErrorCorrectLevel,
  }) async {
    final qrImage = createQrImage(data, errorCorrectLevel: errorCorrectLevel);
    final byteData = await qrImage.toImageAsBytes(
      size: size,
      decoration: decoration ?? QrCodeUtils.decoration(),
    );
    return byteData?.buffer.asUint8List();
  }

  static Future<bool> sharePng(
    String data, {
    int size = defaultExportSize,
    String fileName = 'vcare-qr.png',
    PrettyQrDecoration? decoration,
  }) async {
    final bytes = await toPngBytes(
      data,
      size: size,
      decoration: decoration,
    );
    if (bytes == null) {
      return false;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );

    return result.status != ShareResultStatus.unavailable;
  }
}
