import 'package:flutter/material.dart';

import 'app_color_scheme.dart';
import 'app_text_theme.dart';

extension AppThemeX on BuildContext {
  AppColorScheme get colors => Theme.of(this).extension<AppColorScheme>()!;
  AppTextTheme get texts => Theme.of(this).extension<AppTextTheme>()!;
}
