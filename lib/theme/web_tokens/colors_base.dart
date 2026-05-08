import 'package:flutter/material.dart';

class WebColorsBase {
  const WebColorsBase._();

  static const Color primary = Color(0xFF5B2C06); // colors.primary
  static const Color secondary = Color(0xFF000000); // colors.secondary
  static const Color tertiary = Color(0xFF000000); // colors.tertiary
  static const Color background = Color(0xFFFFFFFF); // colors.background
  static const Color backgroundText = Color(0xFFFFFFFF); // colors.backgroundText
}

class WebBackgroundBlockBase {
  const WebBackgroundBlockBase._();

  static const Color defaultColor = Color(
    0xFFFAFAFA,
  ); // colors.Background.Block.default
  static const Color dark = Color(0xFFEBEBEB); // colors.Background.Block.dark
  static const Color darker = Color(
    0xFFE1E1E1,
  ); // colors.Background.Block.darker
  static const Color highlight = Color(
    0xFFFFFFFF,
  ); // colors.Background.Block.highlight
}

class WebBackgroundPageBase {
  const WebBackgroundPageBase._();

  static const Color defaultColor = Color(
    0xFFF9F0F0,
  ); // colors.Background.Page.default
}

class WebBackgroundSectionBase {
  const WebBackgroundSectionBase._();

  static const Color defaultColor = Color(
    0xFFFFFFFF,
  ); // colors.Background.Section.default
  static const Color transparent = Color(
    0xDDDCDCDC,
  ); // colors.Background.Section.transparent
}

class WebBackgroundTabBase {
  const WebBackgroundTabBase._();

  static const Color defaultColor = Color(
    0xFFFFFFFF,
  ); // colors.Background.Tab.default
  static const Color dark = Color(0xFFE0E0E0); // colors.Background.Tab.dark
  static const Color darker = Color(
    0xFFD6D6D6,
  ); // colors.Background.Tab.darker
}

class WebBackgroundButtonBase {
  const WebBackgroundButtonBase._();

  static const Color defaultColor = Color(
    0xFFF5F5F5,
  ); // colors.Background.Button.default
  static const Color dark = Color(
    0xFFEBEBEB,
  ); // colors.Background.Button.dark
  static const Color highlight = Color(
    0xFFF9F0F0,
  ); // colors.Background.Button.highlight
  static const Color highlightDark = Color(
    0xFFFAE6E6,
  ); // colors.Background.Button.highlightDark
}

class WebBackgroundTileBase {
  const WebBackgroundTileBase._();

  static const Color highlight = Color(
    0xFFE54C65,
  ); // colors.Background.Tile.highlight
}

class WebHighlightBase {
  const WebHighlightBase._();

  static const Color defaultColor = Color(0xFFE54C65); // colors.Highlight.default
  static const Color dark = Color(0xFF963246); // colors.Highlight.dark
}

class WebLineBase {
  const WebLineBase._();

  static const Color defaultColor = Color(0xFFE8E8E8); // colors.Line.default
  static const Color divider = Color(0xFFEDD1DC); // colors.Line.divider
  static const Color block = Color(0xFFD6D6D6); // colors.Line.block
  static const Color dark = Color(0xFFD6D6D6); // colors.Line.dark
  static const Color darker = Color(0xFFBEBEBE); // colors.Line.darker
}

class WebTextBase {
  const WebTextBase._();

  static const Color bright = Color(0xFFFFFFFF); // colors.Text.bright
  static const Color disable = Color(0xFFAAAAAA); // colors.Text.disable
  static const Color placeholder = Color(
    0xFFAAAAAA,
  ); // colors.Text.placeholder
  static const Color lighter = Color(0xFF888888); // colors.Text.lighter
  static const Color light = Color(0xFF555555); // colors.Text.light
  static const Color defaultColor = Color(0xFF333333); // colors.Text.default
  static const Color dark = Color(0xFF000000); // colors.Text.dark
}

class WebTimetableBase {
  const WebTimetableBase._();

  static const Color title = Color(0xFF000000); // colors.TimeTable.title
  static const Color detail = Color(0xFF888888); // colors.TimeTable.detail
}

class WebTileTimetableBase {
  const WebTileTimetableBase._();

  static const Color red1 = Color(
    0xFFF2CECE,
  ); // colors.Tile.TimeTable.default.red.1
  static const Color red2 = Color(
    0xFFF4B3AE,
  ); // colors.Tile.TimeTable.default.red.2
  static const Color orange1 = Color(
    0xFFF2BCA0,
  ); // colors.Tile.TimeTable.default.orange.1
  static const Color orange2 = Color(
    0xFFF0D3AB,
  ); // colors.Tile.TimeTable.default.orange.2
  static const Color yellow1 = Color(
    0xFFF1E1A9,
  ); // colors.Tile.TimeTable.default.yellow.1
  static const Color yellow2 = Color(
    0xFFF4F2B3,
  ); // colors.Tile.TimeTable.default.yellow.2
  static const Color green1 = Color(
    0xFFDBF4BE,
  ); // colors.Tile.TimeTable.default.green.1
  static const Color green2 = Color(
    0xFFBEEDD7,
  ); // colors.Tile.TimeTable.default.green.2
  static const Color green3 = Color(
    0xFFB7D2DE,
  ); // colors.Tile.TimeTable.default.green.3
  static const Color blue1 = Color(
    0xFFC9DAF4,
  ); // colors.Tile.TimeTable.default.blue.1
  static const Color blue2 = Color(
    0xFFB4D3ED,
  ); // colors.Tile.TimeTable.default.blue.2
  static const Color purple1 = Color(
    0xFFB9C5ED,
  ); // colors.Tile.TimeTable.default.purple.1
  static const Color purple2 = Color(
    0xFFD8C1F0,
  ); // colors.Tile.TimeTable.default.purple.2
  static const Color pink1 = Color(
    0xFFEBCAEF,
  ); // colors.Tile.TimeTable.default.pink.1
  static const Color pink2 = Color(
    0xFFF4BADB,
  ); // colors.Tile.TimeTable.default.pink.2
}

class WebGradientBase {
  const WebGradientBase._();

  static const List<Color> blue = [
    Color(0xFFE0F7FA), // colors.gradient.blue start
    Color(0xFFB2EBF2), // colors.gradient.blue mid
    Color(0xFF80DEEA), // colors.gradient.blue end
  ];
  static const List<Color> purple = [
    Color(0xFFE1BEE7), // colors.gradient.purple start
    Color(0xFFCE93D8), // colors.gradient.purple mid
    Color(0xFFBA68C8), // colors.gradient.purple end
  ];
  static const List<Color> peach = [
    Color(0xFFFFE0B2), // colors.gradient.peach start
    Color(0xFFFFCC80), // colors.gradient.peach mid
    Color(0xFFFFB74D), // colors.gradient.peach end
  ];
  static const List<Color> mint = [
    Color(0xFFE8F5E9), // colors.gradient.mint start
    Color(0xFFC8E6C9), // colors.gradient.mint mid
    Color(0xFFA5D6A7), // colors.gradient.mint end
  ];
  static const List<Color> sunset = [
    Color(0xFFFFEBEE), // colors.gradient.sunset start
    Color(0xFFFFCDD2), // colors.gradient.sunset mid
    Color(0xFFEF9A9A), // colors.gradient.sunset end
  ];
}
