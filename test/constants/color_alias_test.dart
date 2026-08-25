// ignore_for_file: deprecated_member_use

import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/color.dart';

void main() {
  test('pins OTL color aliases to their ARGB values', () {
    expect(OTLColor.sparcsGold.value, 0xFFEBA12A);
    expect(OTLColor.sparcsGoldMuted.value, 0x66EBA12A);
    expect(OTLColor.divider.value, 0x40000000);
    expect(OTLColor.dialogScrim.value, 0x26000000);
    expect(OTLColor.disabledOverlay.value, 0x66000000);
    expect(OTLColor.scrollbarThumb.value, 0x80FFFFFF);
  });

  test('keeps the existing barrier color unchanged', () {
    expect(OTLColor.barrier.value, 0x40000000);
  });
}
