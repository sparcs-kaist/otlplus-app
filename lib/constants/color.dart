import 'package:flutter/material.dart';

class OTLColor {
  static const gray0 = Color(0xFF000000);
  static const gray3 = Color(0xFF333333);
  static const gray5 = Color(0xFF555555);
  static const gray6 = Color(0xFF666666);
  static const gray75 = Color(0xFF757575);
  static const grayA = Color(0xFFAAAAAA);
  static const grayD = Color(0xFFDDDDDD);
  static const grayE = Color(0xFFEEEEEE);
  static const grayF = Color(0xFFFFFFFF);
  static const barrier = Color(0x40000000);
  static const sparcsGold = Color(0xFFEBA12A);
  // Equals sparcsGold at 40% opacity.
  static const sparcsGoldMuted = Color(0x66EBA12A);
  // Equals gray0 at 25% opacity; same value as barrier, kept separate for
  // non-modal use.
  static const divider = Color(0x40000000);
  static const dialogScrim = Color(0x26000000);
  static const disabledOverlay = Color(0x66000000);
  static const scrollbarThumb = Color(0x80FFFFFF);

  static const pinksLight = Color(0xFFF9F0F0);
  static const pinksSub = Color(0xFFF6C5CD);

  /// Legacy/intentional near-duplicate hex value: #E54C65 vs #E54C64.
  static const pinksMain = Color(0xFFE54C65);

  /// Legacy/intentional near-duplicate hex value: #E54C65 vs #E54C64.
  static const pinksSelected = Color(0xFFE54C64);

  static const red = Color(0xFFFF453A);

  static const blockColors = [
    Color(0xFFF2CECE),
    Color(0xFFF4B3AE),
    Color(0xFFF2BCA0),
    Color(0xFFF0D3AB),
    Color(0xFFF1E1A9),
    Color(0xFFF4F2B3),
    Color(0xFFDBF4BE),
    Color(0xFFBEEDD7),
    Color(0xFFB7E2DE),
    Color(0xFFC9EAF4),
    Color(0xFFB4D3ED),
    Color(0xFFB9C5ED),
    Color(0xFFCCC6ED),
    Color(0xFFD8C1F0),
    Color(0xFFEBCAEF),
    Color(0xFFF4BADB),
  ];
}
