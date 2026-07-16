import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'package:vcare_admin/shared/utils/qr_code_utils.dart';

/// Reusable on-screen QR code widget backed by [pretty_qr_code].
class VcareQrCode extends StatefulWidget {
  const VcareQrCode({
    super.key,
    required this.data,
    this.size,
    this.decoration,
    this.errorCorrectLevel = QrCodeUtils.defaultErrorCorrectLevel,
    this.semanticLabel,
  });

  final String data;
  final double? size;
  final PrettyQrDecoration? decoration;
  final int errorCorrectLevel;
  final String? semanticLabel;

  @override
  State<VcareQrCode> createState() => _VcareQrCodeState();
}

class _VcareQrCodeState extends State<VcareQrCode> {
  late QrImage _qrImage;

  @override
  void initState() {
    super.initState();
    _qrImage = _createQrImage();
  }

  @override
  void didUpdateWidget(covariant VcareQrCode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.errorCorrectLevel != widget.errorCorrectLevel) {
      _qrImage = _createQrImage();
    }
  }

  QrImage _createQrImage() {
    return QrCodeUtils.createQrImage(
      widget.data,
      errorCorrectLevel: widget.errorCorrectLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrView = PrettyQrView(
      qrImage: _qrImage,
      decoration:
          widget.decoration ?? QrCodeUtils.decorationFromContext(context),
    );

    final child = widget.size == null
        ? qrView
        : SizedBox(width: widget.size, height: widget.size, child: qrView);

    if (widget.semanticLabel == null) {
      return child;
    }

    return Semantics(label: widget.semanticLabel, child: child);
  }
}
