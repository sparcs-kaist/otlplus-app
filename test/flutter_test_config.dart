import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final content = await File(
    'assets/translations/ko.json',
  ).readAsString(); // <- Or `ru.json`
  final data = jsonDecode(content) as Map<String, dynamic>;

  // easy_localization works with a singleton instance internally. We abuse
  // this fact in tests and just let it load the English translations.
  // Therefore we don't need to deal with any wrapper widgets and
  // waiting/pumping in our widget tests.
  Localization.load(const Locale('ko'), translations: Translations(data));

  await testMain();
}
