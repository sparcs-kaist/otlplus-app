import 'package:flutter/material.dart';

import 'web_tokens/colors_base.dart';
import 'web_tokens/colors_dark.dart';

class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.background,
    required this.backgroundText,
    required this.textDefault,
    required this.textLight,
    required this.textLighter,
    required this.textDark,
    required this.textBright,
    required this.textDisable,
    required this.textPlaceholder,
    required this.backgroundPageDefault,
    required this.backgroundBlockDefault,
    required this.backgroundBlockDark,
    required this.backgroundBlockDarker,
    required this.backgroundBlockHighlight,
    required this.backgroundSectionDefault,
    required this.backgroundSectionTransparent,
    required this.backgroundTabDefault,
    required this.backgroundTabDark,
    required this.backgroundTabDarker,
    required this.backgroundButtonDefault,
    required this.backgroundButtonDark,
    required this.backgroundButtonHighlight,
    required this.backgroundButtonHighlightDark,
    required this.backgroundTileHighlight,
    required this.highlightDefault,
    required this.highlightDark,
    required this.lineDefault,
    required this.lineDivider,
    required this.lineBlock,
    required this.lineDark,
    required this.lineDarker,
    required this.timetableTitle,
    required this.timetableDetail,
    required this.tileTimetableRed1,
    required this.tileTimetableRed2,
    required this.tileTimetableOrange1,
    required this.tileTimetableOrange2,
    required this.tileTimetableYellow1,
    required this.tileTimetableYellow2,
    required this.tileTimetableGreen1,
    required this.tileTimetableGreen2,
    required this.tileTimetableGreen3,
    required this.tileTimetableBlue1,
    required this.tileTimetableBlue2,
    required this.tileTimetablePurple1,
    required this.tileTimetablePurple2,
    required this.tileTimetablePink1,
    required this.tileTimetablePink2,
    required this.gradientBlue,
    required this.gradientPurple,
    required this.gradientPeach,
    required this.gradientMint,
    required this.gradientSunset,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color background;
  final Color backgroundText;
  final Color textDefault;
  final Color textLight;
  final Color textLighter;
  final Color textDark;
  final Color textBright;
  final Color textDisable;
  final Color textPlaceholder;
  final Color backgroundPageDefault;
  final Color backgroundBlockDefault;
  final Color backgroundBlockDark;
  final Color backgroundBlockDarker;
  final Color backgroundBlockHighlight;
  final Color backgroundSectionDefault;
  final Color backgroundSectionTransparent;
  final Color backgroundTabDefault;
  final Color backgroundTabDark;
  final Color backgroundTabDarker;
  final Color backgroundButtonDefault;
  final Color backgroundButtonDark;
  final Color backgroundButtonHighlight;
  final Color backgroundButtonHighlightDark;
  final Color backgroundTileHighlight;
  final Color highlightDefault;
  final Color highlightDark;
  final Color lineDefault;
  final Color lineDivider;
  final Color lineBlock;
  final Color lineDark;
  final Color lineDarker;
  final Color timetableTitle;
  final Color timetableDetail;
  final Color tileTimetableRed1;
  final Color tileTimetableRed2;
  final Color tileTimetableOrange1;
  final Color tileTimetableOrange2;
  final Color tileTimetableYellow1;
  final Color tileTimetableYellow2;
  final Color tileTimetableGreen1;
  final Color tileTimetableGreen2;
  final Color tileTimetableGreen3;
  final Color tileTimetableBlue1;
  final Color tileTimetableBlue2;
  final Color tileTimetablePurple1;
  final Color tileTimetablePurple2;
  final Color tileTimetablePink1;
  final Color tileTimetablePink2;
  final List<Color> gradientBlue;
  final List<Color> gradientPurple;
  final List<Color> gradientPeach;
  final List<Color> gradientMint;
  final List<Color> gradientSunset;

  factory AppColorScheme.light() {
    return const AppColorScheme(
      primary: WebColorsBase.primary,
      secondary: WebColorsBase.secondary,
      tertiary: WebColorsBase.tertiary,
      background: WebColorsBase.background,
      backgroundText: WebColorsBase.backgroundText,
      textDefault: WebTextBase.defaultColor,
      textLight: WebTextBase.light,
      textLighter: WebTextBase.lighter,
      textDark: WebTextBase.dark,
      textBright: WebTextBase.bright,
      textDisable: WebTextBase.disable,
      textPlaceholder: WebTextBase.placeholder,
      backgroundPageDefault: WebBackgroundPageBase.defaultColor,
      backgroundBlockDefault: WebBackgroundBlockBase.defaultColor,
      backgroundBlockDark: WebBackgroundBlockBase.dark,
      backgroundBlockDarker: WebBackgroundBlockBase.darker,
      backgroundBlockHighlight: WebBackgroundBlockBase.highlight,
      backgroundSectionDefault: WebBackgroundSectionBase.defaultColor,
      backgroundSectionTransparent: WebBackgroundSectionBase.transparent,
      backgroundTabDefault: WebBackgroundTabBase.defaultColor,
      backgroundTabDark: WebBackgroundTabBase.dark,
      backgroundTabDarker: WebBackgroundTabBase.darker,
      backgroundButtonDefault: WebBackgroundButtonBase.defaultColor,
      backgroundButtonDark: WebBackgroundButtonBase.dark,
      backgroundButtonHighlight: WebBackgroundButtonBase.highlight,
      backgroundButtonHighlightDark: WebBackgroundButtonBase.highlightDark,
      backgroundTileHighlight: WebBackgroundTileBase.highlight,
      highlightDefault: WebHighlightBase.defaultColor,
      highlightDark: WebHighlightBase.dark,
      lineDefault: WebLineBase.defaultColor,
      lineDivider: WebLineBase.divider,
      lineBlock: WebLineBase.block,
      lineDark: WebLineBase.dark,
      lineDarker: WebLineBase.darker,
      timetableTitle: WebTimetableBase.title,
      timetableDetail: WebTimetableBase.detail,
      tileTimetableRed1: WebTileTimetableBase.red1,
      tileTimetableRed2: WebTileTimetableBase.red2,
      tileTimetableOrange1: WebTileTimetableBase.orange1,
      tileTimetableOrange2: WebTileTimetableBase.orange2,
      tileTimetableYellow1: WebTileTimetableBase.yellow1,
      tileTimetableYellow2: WebTileTimetableBase.yellow2,
      tileTimetableGreen1: WebTileTimetableBase.green1,
      tileTimetableGreen2: WebTileTimetableBase.green2,
      tileTimetableGreen3: WebTileTimetableBase.green3,
      tileTimetableBlue1: WebTileTimetableBase.blue1,
      tileTimetableBlue2: WebTileTimetableBase.blue2,
      tileTimetablePurple1: WebTileTimetableBase.purple1,
      tileTimetablePurple2: WebTileTimetableBase.purple2,
      tileTimetablePink1: WebTileTimetableBase.pink1,
      tileTimetablePink2: WebTileTimetableBase.pink2,
      gradientBlue: WebGradientBase.blue,
      gradientPurple: WebGradientBase.purple,
      gradientPeach: WebGradientBase.peach,
      gradientMint: WebGradientBase.mint,
      gradientSunset: WebGradientBase.sunset,
    );
  }

  factory AppColorScheme.dark() {
    return const AppColorScheme(
      primary: WebColorsDark.primary,
      secondary: WebColorsDark.secondary,
      tertiary: WebColorsDark.tertiary,
      background: WebColorsDark.background,
      backgroundText: WebColorsDark.backgroundText,
      textDefault: WebTextDark.defaultColor,
      textLight: WebTextDark.light,
      textLighter: WebTextDark.lighter,
      textDark: WebTextDark.dark,
      textBright: WebTextDark.bright,
      textDisable: WebTextDark.disable,
      textPlaceholder: WebTextDark.placeholder,
      backgroundPageDefault: WebBackgroundPageDark.defaultColor,
      backgroundBlockDefault: WebBackgroundBlockDark.defaultColor,
      backgroundBlockDark: WebBackgroundBlockDark.dark,
      backgroundBlockDarker: WebBackgroundBlockDark.darker,
      backgroundBlockHighlight: WebBackgroundBlockDark.highlight,
      backgroundSectionDefault: WebBackgroundSectionDark.defaultColor,
      backgroundSectionTransparent: WebBackgroundSectionDark.transparent,
      backgroundTabDefault: WebBackgroundTabDark.defaultColor,
      backgroundTabDark: WebBackgroundTabDark.dark,
      backgroundTabDarker: WebBackgroundTabDark.darker,
      backgroundButtonDefault: WebBackgroundButtonDark.defaultColor,
      backgroundButtonDark: WebBackgroundButtonDark.dark,
      backgroundButtonHighlight: WebBackgroundButtonDark.highlight,
      backgroundButtonHighlightDark: WebBackgroundButtonDark.highlightDark,
      backgroundTileHighlight: WebBackgroundTileDark.highlight,
      highlightDefault: WebHighlightDark.defaultColor,
      highlightDark: WebHighlightDark.dark,
      lineDefault: WebLineDark.defaultColor,
      lineDivider: WebLineDark.divider,
      lineBlock: WebLineDark.block,
      lineDark: WebLineDark.dark,
      lineDarker: WebLineDark.darker,
      timetableTitle: WebTimetableDark.title,
      timetableDetail: WebTimetableDark.detail,
      tileTimetableRed1: WebTileTimetableDark.red1,
      tileTimetableRed2: WebTileTimetableDark.red2,
      tileTimetableOrange1: WebTileTimetableDark.orange1,
      tileTimetableOrange2: WebTileTimetableDark.orange2,
      tileTimetableYellow1: WebTileTimetableDark.yellow1,
      tileTimetableYellow2: WebTileTimetableDark.yellow2,
      tileTimetableGreen1: WebTileTimetableDark.green1,
      tileTimetableGreen2: WebTileTimetableDark.green2,
      tileTimetableGreen3: WebTileTimetableDark.green3,
      tileTimetableBlue1: WebTileTimetableDark.blue1,
      tileTimetableBlue2: WebTileTimetableDark.blue2,
      tileTimetablePurple1: WebTileTimetableDark.purple1,
      tileTimetablePurple2: WebTileTimetableDark.purple2,
      tileTimetablePink1: WebTileTimetableDark.pink1,
      tileTimetablePink2: WebTileTimetableDark.pink2,
      gradientBlue: WebGradientDark.blue,
      gradientPurple: WebGradientDark.purple,
      gradientPeach: WebGradientDark.peach,
      gradientMint: WebGradientDark.mint,
      gradientSunset: WebGradientDark.sunset,
    );
  }

  @override
  AppColorScheme copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? background,
    Color? backgroundText,
    Color? textDefault,
    Color? textLight,
    Color? textLighter,
    Color? textDark,
    Color? textBright,
    Color? textDisable,
    Color? textPlaceholder,
    Color? backgroundPageDefault,
    Color? backgroundBlockDefault,
    Color? backgroundBlockDark,
    Color? backgroundBlockDarker,
    Color? backgroundBlockHighlight,
    Color? backgroundSectionDefault,
    Color? backgroundSectionTransparent,
    Color? backgroundTabDefault,
    Color? backgroundTabDark,
    Color? backgroundTabDarker,
    Color? backgroundButtonDefault,
    Color? backgroundButtonDark,
    Color? backgroundButtonHighlight,
    Color? backgroundButtonHighlightDark,
    Color? backgroundTileHighlight,
    Color? highlightDefault,
    Color? highlightDark,
    Color? lineDefault,
    Color? lineDivider,
    Color? lineBlock,
    Color? lineDark,
    Color? lineDarker,
    Color? timetableTitle,
    Color? timetableDetail,
    Color? tileTimetableRed1,
    Color? tileTimetableRed2,
    Color? tileTimetableOrange1,
    Color? tileTimetableOrange2,
    Color? tileTimetableYellow1,
    Color? tileTimetableYellow2,
    Color? tileTimetableGreen1,
    Color? tileTimetableGreen2,
    Color? tileTimetableGreen3,
    Color? tileTimetableBlue1,
    Color? tileTimetableBlue2,
    Color? tileTimetablePurple1,
    Color? tileTimetablePurple2,
    Color? tileTimetablePink1,
    Color? tileTimetablePink2,
    List<Color>? gradientBlue,
    List<Color>? gradientPurple,
    List<Color>? gradientPeach,
    List<Color>? gradientMint,
    List<Color>? gradientSunset,
  }) {
    return AppColorScheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      background: background ?? this.background,
      backgroundText: backgroundText ?? this.backgroundText,
      textDefault: textDefault ?? this.textDefault,
      textLight: textLight ?? this.textLight,
      textLighter: textLighter ?? this.textLighter,
      textDark: textDark ?? this.textDark,
      textBright: textBright ?? this.textBright,
      textDisable: textDisable ?? this.textDisable,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      backgroundPageDefault:
          backgroundPageDefault ?? this.backgroundPageDefault,
      backgroundBlockDefault:
          backgroundBlockDefault ?? this.backgroundBlockDefault,
      backgroundBlockDark: backgroundBlockDark ?? this.backgroundBlockDark,
      backgroundBlockDarker:
          backgroundBlockDarker ?? this.backgroundBlockDarker,
      backgroundBlockHighlight:
          backgroundBlockHighlight ?? this.backgroundBlockHighlight,
      backgroundSectionDefault:
          backgroundSectionDefault ?? this.backgroundSectionDefault,
      backgroundSectionTransparent:
          backgroundSectionTransparent ?? this.backgroundSectionTransparent,
      backgroundTabDefault: backgroundTabDefault ?? this.backgroundTabDefault,
      backgroundTabDark: backgroundTabDark ?? this.backgroundTabDark,
      backgroundTabDarker: backgroundTabDarker ?? this.backgroundTabDarker,
      backgroundButtonDefault:
          backgroundButtonDefault ?? this.backgroundButtonDefault,
      backgroundButtonDark: backgroundButtonDark ?? this.backgroundButtonDark,
      backgroundButtonHighlight:
          backgroundButtonHighlight ?? this.backgroundButtonHighlight,
      backgroundButtonHighlightDark:
          backgroundButtonHighlightDark ?? this.backgroundButtonHighlightDark,
      backgroundTileHighlight:
          backgroundTileHighlight ?? this.backgroundTileHighlight,
      highlightDefault: highlightDefault ?? this.highlightDefault,
      highlightDark: highlightDark ?? this.highlightDark,
      lineDefault: lineDefault ?? this.lineDefault,
      lineDivider: lineDivider ?? this.lineDivider,
      lineBlock: lineBlock ?? this.lineBlock,
      lineDark: lineDark ?? this.lineDark,
      lineDarker: lineDarker ?? this.lineDarker,
      timetableTitle: timetableTitle ?? this.timetableTitle,
      timetableDetail: timetableDetail ?? this.timetableDetail,
      tileTimetableRed1: tileTimetableRed1 ?? this.tileTimetableRed1,
      tileTimetableRed2: tileTimetableRed2 ?? this.tileTimetableRed2,
      tileTimetableOrange1:
          tileTimetableOrange1 ?? this.tileTimetableOrange1,
      tileTimetableOrange2:
          tileTimetableOrange2 ?? this.tileTimetableOrange2,
      tileTimetableYellow1:
          tileTimetableYellow1 ?? this.tileTimetableYellow1,
      tileTimetableYellow2:
          tileTimetableYellow2 ?? this.tileTimetableYellow2,
      tileTimetableGreen1: tileTimetableGreen1 ?? this.tileTimetableGreen1,
      tileTimetableGreen2: tileTimetableGreen2 ?? this.tileTimetableGreen2,
      tileTimetableGreen3: tileTimetableGreen3 ?? this.tileTimetableGreen3,
      tileTimetableBlue1: tileTimetableBlue1 ?? this.tileTimetableBlue1,
      tileTimetableBlue2: tileTimetableBlue2 ?? this.tileTimetableBlue2,
      tileTimetablePurple1:
          tileTimetablePurple1 ?? this.tileTimetablePurple1,
      tileTimetablePurple2:
          tileTimetablePurple2 ?? this.tileTimetablePurple2,
      tileTimetablePink1: tileTimetablePink1 ?? this.tileTimetablePink1,
      tileTimetablePink2: tileTimetablePink2 ?? this.tileTimetablePink2,
      gradientBlue: gradientBlue ?? this.gradientBlue,
      gradientPurple: gradientPurple ?? this.gradientPurple,
      gradientPeach: gradientPeach ?? this.gradientPeach,
      gradientMint: gradientMint ?? this.gradientMint,
      gradientSunset: gradientSunset ?? this.gradientSunset,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) {
      return this;
    }

    return AppColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      background: Color.lerp(background, other.background, t)!,
      backgroundText: Color.lerp(backgroundText, other.backgroundText, t)!,
      textDefault: Color.lerp(textDefault, other.textDefault, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      textLighter: Color.lerp(textLighter, other.textLighter, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textBright: Color.lerp(textBright, other.textBright, t)!,
      textDisable: Color.lerp(textDisable, other.textDisable, t)!,
      textPlaceholder: Color.lerp(textPlaceholder, other.textPlaceholder, t)!,
      backgroundPageDefault:
          Color.lerp(backgroundPageDefault, other.backgroundPageDefault, t)!,
      backgroundBlockDefault:
          Color.lerp(backgroundBlockDefault, other.backgroundBlockDefault, t)!,
      backgroundBlockDark:
          Color.lerp(backgroundBlockDark, other.backgroundBlockDark, t)!,
      backgroundBlockDarker:
          Color.lerp(backgroundBlockDarker, other.backgroundBlockDarker, t)!,
      backgroundBlockHighlight: Color.lerp(
        backgroundBlockHighlight,
        other.backgroundBlockHighlight,
        t,
      )!,
      backgroundSectionDefault: Color.lerp(
        backgroundSectionDefault,
        other.backgroundSectionDefault,
        t,
      )!,
      backgroundSectionTransparent: Color.lerp(
        backgroundSectionTransparent,
        other.backgroundSectionTransparent,
        t,
      )!,
      backgroundTabDefault:
          Color.lerp(backgroundTabDefault, other.backgroundTabDefault, t)!,
      backgroundTabDark:
          Color.lerp(backgroundTabDark, other.backgroundTabDark, t)!,
      backgroundTabDarker:
          Color.lerp(backgroundTabDarker, other.backgroundTabDarker, t)!,
      backgroundButtonDefault: Color.lerp(
        backgroundButtonDefault,
        other.backgroundButtonDefault,
        t,
      )!,
      backgroundButtonDark: Color.lerp(
        backgroundButtonDark,
        other.backgroundButtonDark,
        t,
      )!,
      backgroundButtonHighlight: Color.lerp(
        backgroundButtonHighlight,
        other.backgroundButtonHighlight,
        t,
      )!,
      backgroundButtonHighlightDark: Color.lerp(
        backgroundButtonHighlightDark,
        other.backgroundButtonHighlightDark,
        t,
      )!,
      backgroundTileHighlight: Color.lerp(
        backgroundTileHighlight,
        other.backgroundTileHighlight,
        t,
      )!,
      highlightDefault: Color.lerp(highlightDefault, other.highlightDefault, t)!,
      highlightDark: Color.lerp(highlightDark, other.highlightDark, t)!,
      lineDefault: Color.lerp(lineDefault, other.lineDefault, t)!,
      lineDivider: Color.lerp(lineDivider, other.lineDivider, t)!,
      lineBlock: Color.lerp(lineBlock, other.lineBlock, t)!,
      lineDark: Color.lerp(lineDark, other.lineDark, t)!,
      lineDarker: Color.lerp(lineDarker, other.lineDarker, t)!,
      timetableTitle: Color.lerp(timetableTitle, other.timetableTitle, t)!,
      timetableDetail: Color.lerp(timetableDetail, other.timetableDetail, t)!,
      tileTimetableRed1:
          Color.lerp(tileTimetableRed1, other.tileTimetableRed1, t)!,
      tileTimetableRed2:
          Color.lerp(tileTimetableRed2, other.tileTimetableRed2, t)!,
      tileTimetableOrange1:
          Color.lerp(tileTimetableOrange1, other.tileTimetableOrange1, t)!,
      tileTimetableOrange2:
          Color.lerp(tileTimetableOrange2, other.tileTimetableOrange2, t)!,
      tileTimetableYellow1:
          Color.lerp(tileTimetableYellow1, other.tileTimetableYellow1, t)!,
      tileTimetableYellow2:
          Color.lerp(tileTimetableYellow2, other.tileTimetableYellow2, t)!,
      tileTimetableGreen1:
          Color.lerp(tileTimetableGreen1, other.tileTimetableGreen1, t)!,
      tileTimetableGreen2:
          Color.lerp(tileTimetableGreen2, other.tileTimetableGreen2, t)!,
      tileTimetableGreen3:
          Color.lerp(tileTimetableGreen3, other.tileTimetableGreen3, t)!,
      tileTimetableBlue1:
          Color.lerp(tileTimetableBlue1, other.tileTimetableBlue1, t)!,
      tileTimetableBlue2:
          Color.lerp(tileTimetableBlue2, other.tileTimetableBlue2, t)!,
      tileTimetablePurple1:
          Color.lerp(tileTimetablePurple1, other.tileTimetablePurple1, t)!,
      tileTimetablePurple2:
          Color.lerp(tileTimetablePurple2, other.tileTimetablePurple2, t)!,
      tileTimetablePink1:
          Color.lerp(tileTimetablePink1, other.tileTimetablePink1, t)!,
      tileTimetablePink2:
          Color.lerp(tileTimetablePink2, other.tileTimetablePink2, t)!,
      gradientBlue: _lerpColorList(gradientBlue, other.gradientBlue, t),
      gradientPurple: _lerpColorList(gradientPurple, other.gradientPurple, t),
      gradientPeach: _lerpColorList(gradientPeach, other.gradientPeach, t),
      gradientMint: _lerpColorList(gradientMint, other.gradientMint, t),
      gradientSunset: _lerpColorList(gradientSunset, other.gradientSunset, t),
    );
  }

  static List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    return List<Color>.generate(
      a.length,
      (index) => Color.lerp(a[index], b[index], t)!,
      growable: false,
    );
  }
}
