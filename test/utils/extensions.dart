import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

extension WidgetForTest on Widget {
  Widget get material => EasyLocalization(
    supportedLocales: [Locale('ko')],
    path: 'assets/translations',
    child: MaterialApp(home: this),
  );

  Widget get scaffold => EasyLocalization(
    supportedLocales: [Locale('ko')],
    path: 'assets/translations',
    child: MaterialApp(home: Scaffold(body: this)),
  );

  Widget get inScrollView => SingleChildScrollView(child: this);

  Widget materialAndNotifier<T extends ChangeNotifier>(T model) {
    return ChangeNotifierProvider(
      create: (_) => model,
      child: MaterialApp(home: this),
    );
  }

  Widget scaffoldAndNotifier<T extends ChangeNotifier>(T model) {
    return ChangeNotifierProvider<T>(
      create: (_) => model,
      child: MaterialApp(home: Scaffold(body: this)),
    );
  }

  Widget scaffoldAndNotifiers<T extends ChangeNotifier>(List<T>? models) {
    return MultiProvider(
      providers: models!
          .map((model) => ChangeNotifierProvider<T>(create: (_) => model))
          .toList(),
      child: MaterialApp(home: Scaffold(body: this)),
    );
  }
}
