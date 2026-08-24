import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Whether the current EasyLocalization locale is English.
///
/// Single source of truth for language branching so pages stop repeating
/// `context.locale == const Locale('en')` and the EasyLocalization lookup.
/// Null-safe when no EasyLocalization ancestor exists (matches the previous
/// per-file lookups), evaluating to false outside localized trees.
extension ContextLocaleX on BuildContext {
  bool get isEn =>
      EasyLocalization.of(this)?.currentLocale == const Locale('en');
}
