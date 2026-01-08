import 'package:flutter/material.dart';

const regularBase = TextStyle(
  letterSpacing: 0.15,
  leadingDistribution: TextLeadingDistribution.even,
);

final labelRegular = regularBase.copyWith(fontSize: 12.0, height: 1.4);
final labelBold = labelRegular.copyWith(fontWeight: FontWeight.bold);

final bodyRegular = regularBase.copyWith(fontSize: 14.0, height: 1.6);
final bodyBold = bodyRegular.copyWith(fontWeight: FontWeight.bold);

final titleRegular = regularBase.copyWith(fontSize: 16.0, height: 1.6);
final titleBold = titleRegular.copyWith(fontWeight: FontWeight.bold);

final headlineRegular = regularBase.copyWith(fontSize: 18.0, height: 1.6);
final headlineBold = headlineRegular.copyWith(fontWeight: FontWeight.bold);

final displayRegular = regularBase.copyWith(fontSize: 20.0, height: 1.6);
final displayBold = displayRegular.copyWith(fontWeight: FontWeight.bold);
