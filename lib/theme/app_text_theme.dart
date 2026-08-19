import 'package:flutter/material.dart';

import 'web_tokens/fonts.dart';

class AppTextTheme extends ThemeExtension<AppTextTheme> {
  const AppTextTheme({
    required this.smaller,
    required this.smallerBold,
    required this.small,
    required this.smallMedium,
    required this.smallBold,
    required this.normal,
    required this.normalMedium,
    required this.normalBold,
    required this.big,
    required this.bigBold,
    required this.bigger,
    required this.biggerBold,
  });

  final TextStyle smaller;
  final TextStyle smallerBold;
  final TextStyle small;
  final TextStyle smallMedium;
  final TextStyle smallBold;
  final TextStyle normal;
  final TextStyle normalMedium;
  final TextStyle normalBold;
  final TextStyle big;
  final TextStyle bigBold;
  final TextStyle bigger;
  final TextStyle biggerBold;

  factory AppTextTheme.standard() {
    return const AppTextTheme(
      smaller: WebTextStyles.smaller,
      smallerBold: WebTextStyles.smallerBold,
      small: WebTextStyles.small,
      smallMedium: WebTextStyles.smallMedium,
      smallBold: WebTextStyles.smallBold,
      normal: WebTextStyles.normal,
      normalMedium: WebTextStyles.normalMedium,
      normalBold: WebTextStyles.normalBold,
      big: WebTextStyles.big,
      bigBold: WebTextStyles.bigBold,
      bigger: WebTextStyles.bigger,
      biggerBold: WebTextStyles.biggerBold,
    );
  }

  @override
  AppTextTheme copyWith({
    TextStyle? smaller,
    TextStyle? smallerBold,
    TextStyle? small,
    TextStyle? smallMedium,
    TextStyle? smallBold,
    TextStyle? normal,
    TextStyle? normalMedium,
    TextStyle? normalBold,
    TextStyle? big,
    TextStyle? bigBold,
    TextStyle? bigger,
    TextStyle? biggerBold,
  }) {
    return AppTextTheme(
      smaller: smaller ?? this.smaller,
      smallerBold: smallerBold ?? this.smallerBold,
      small: small ?? this.small,
      smallMedium: smallMedium ?? this.smallMedium,
      smallBold: smallBold ?? this.smallBold,
      normal: normal ?? this.normal,
      normalMedium: normalMedium ?? this.normalMedium,
      normalBold: normalBold ?? this.normalBold,
      big: big ?? this.big,
      bigBold: bigBold ?? this.bigBold,
      bigger: bigger ?? this.bigger,
      biggerBold: biggerBold ?? this.biggerBold,
    );
  }

  @override
  AppTextTheme lerp(ThemeExtension<AppTextTheme>? other, double t) {
    if (other is! AppTextTheme) {
      return this;
    }

    return AppTextTheme(
      smaller: TextStyle.lerp(smaller, other.smaller, t)!,
      smallerBold: TextStyle.lerp(smallerBold, other.smallerBold, t)!,
      small: TextStyle.lerp(small, other.small, t)!,
      smallMedium: TextStyle.lerp(smallMedium, other.smallMedium, t)!,
      smallBold: TextStyle.lerp(smallBold, other.smallBold, t)!,
      normal: TextStyle.lerp(normal, other.normal, t)!,
      normalMedium: TextStyle.lerp(normalMedium, other.normalMedium, t)!,
      normalBold: TextStyle.lerp(normalBold, other.normalBold, t)!,
      big: TextStyle.lerp(big, other.big, t)!,
      bigBold: TextStyle.lerp(bigBold, other.bigBold, t)!,
      bigger: TextStyle.lerp(bigger, other.bigger, t)!,
      biggerBold: TextStyle.lerp(biggerBold, other.biggerBold, t)!,
    );
  }
}
