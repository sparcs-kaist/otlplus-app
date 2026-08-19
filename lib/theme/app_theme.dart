import 'package:flutter/material.dart';
import 'package:otlplus/utils/create_material_color.dart';

import 'app_color_scheme.dart';
import 'app_text_theme.dart';
import 'web_tokens/colors_base.dart';
import 'web_tokens/colors_dark.dart';
import 'web_tokens/fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colors = AppColorScheme.light();
    final texts = AppTextTheme.standard();
    final base = ThemeData(
      useMaterial3: false,
      fontFamily: WebFonts.family,
      primarySwatch: createMaterialColor(WebHighlightBase.defaultColor),
      canvasColor: WebBackgroundPageBase.defaultColor,
      iconTheme: const IconThemeData(color: WebTextBase.defaultColor),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        hintStyle: WebTextStyles.normal.copyWith(
          color: WebTextBase.placeholder,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[colors, texts],
    );

    return base.copyWith(
      cardTheme: base.cardTheme.copyWith(margin: const EdgeInsets.only()),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: WebBackgroundBlockBase.dark,
        pressElevation: 0,
        secondarySelectedColor: WebLineBase.block,
        labelStyle: WebTextStyles.small.copyWith(
          color: WebTextBase.defaultColor,
        ),
        secondaryLabelStyle: WebTextStyles.small.copyWith(
          color: WebTextBase.defaultColor,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: WebTextBase.defaultColor,
        displayColor: WebTextBase.defaultColor,
      ),
    );
  }

  static ThemeData dark() {
    final colors = AppColorScheme.dark();
    final texts = AppTextTheme.standard();
    final base = ThemeData(
      useMaterial3: false,
      fontFamily: WebFonts.family,
      brightness: Brightness.dark,
      primarySwatch: createMaterialColor(WebHighlightDark.defaultColor),
      canvasColor: WebBackgroundPageDark.defaultColor,
      scaffoldBackgroundColor: WebBackgroundPageDark.defaultColor,
      iconTheme: const IconThemeData(color: WebTextDark.defaultColor),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        hintStyle: WebTextStyles.normal.copyWith(
          color: WebTextDark.placeholder,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[colors, texts],
    );

    return base.copyWith(
      cardTheme: base.cardTheme.copyWith(margin: const EdgeInsets.only()),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: WebBackgroundButtonDark.dark,
        pressElevation: 0,
        secondarySelectedColor: WebLineDark.block,
        labelStyle: WebTextStyles.small.copyWith(
          color: WebTextDark.defaultColor,
        ),
        secondaryLabelStyle: WebTextStyles.small.copyWith(
          color: WebTextDark.defaultColor,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: WebTextDark.defaultColor,
        displayColor: WebTextDark.defaultColor,
      ),
    );
  }
}
