import 'package:flutter/material.dart';

/// Layout tokens from vcareapp AVA feature (`px-5`, `gap-3`, `AvaChatMessage`, etc.).
abstract final class AvaLayout {
  static const double horizontalPadding = 20;
  static const double listTopPadding = 8;
  static const double listBottomPadding = 24;
  static const double itemGap = 12;
  static const double bubbleMaxWidthFactor = 0.78;
  static const double bubbleRadius = 16;
  static const double bubbleTailRadius = 6;
  static const EdgeInsets bubblePadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );
  static const double bubbleFontSize = 14;
  static const double avatarSize = 32;
  static const double avatarIconSize = 16;
}
