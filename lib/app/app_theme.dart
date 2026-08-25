import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/utils/create_material_color.dart';

class NoEndOfScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: false,
    fontFamily: 'NotoSansKR',
    primarySwatch: createMaterialColor(OTLColor.pinksMain),
    canvasColor: OTLColor.grayF,
    iconTheme: const IconThemeData(color: OTLColor.gray3),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      contentPadding: EdgeInsets.only(),
      isDense: true,
      hintStyle: TextStyle(color: OTLColor.pinksMain, fontSize: 14.0),
    ),
  );

  return base.copyWith(
    cardTheme: base.cardTheme.copyWith(margin: const EdgeInsets.only()),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: OTLColor.grayE,
      pressElevation: 0.0,
      secondarySelectedColor: OTLColor.grayD,
      labelStyle: const TextStyle(color: OTLColor.gray3, fontSize: 12.0),
      secondaryLabelStyle: const TextStyle(
        color: OTLColor.gray3,
        fontSize: 12.0,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: OTLColor.gray3,
      displayColor: OTLColor.gray3,
    ),
  );
}
