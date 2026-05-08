import 'package:flutter/material.dart';

class WebFonts {
  const WebFonts._();

  static const family = 'Pretendard';
  static const fallbackFamily = 'NotoSansKR';
  static const weightRegular = FontWeight.w400;
  static const weightMedium = FontWeight.w500;
  static const weightSemibold = FontWeight.w600;
  static const weightBold = FontWeight.w700;
}

class WebTextStyles {
  const WebTextStyles._();

  static const smaller = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 10,
    height: 12.5 / 10,
    fontWeight: WebFonts.weightRegular,
  );

  static const smallerBold = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 10,
    height: 12.5 / 10,
    fontWeight: WebFonts.weightBold,
  );

  static const small = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 12,
    height: 15 / 12,
    fontWeight: WebFonts.weightRegular,
  );

  static const smallMedium = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 12,
    height: 15 / 12,
    fontWeight: WebFonts.weightMedium,
  );

  static const smallBold = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 12,
    height: 15 / 12,
    fontWeight: WebFonts.weightBold,
  );

  static const normal = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 14,
    height: 17.5 / 14,
    fontWeight: WebFonts.weightRegular,
  );

  static const normalMedium = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 14,
    height: 17.5 / 14,
    fontWeight: WebFonts.weightMedium,
  );

  static const normalBold = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 14,
    height: 17.5 / 14,
    fontWeight: WebFonts.weightBold,
  );

  static const big = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 16,
    height: 20 / 16,
    fontWeight: WebFonts.weightRegular,
  );

  static const bigBold = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 16,
    height: 20 / 16,
    fontWeight: WebFonts.weightBold,
  );

  static const bigger = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 20,
    height: 25 / 20,
    fontWeight: WebFonts.weightRegular,
  );

  static const biggerBold = TextStyle(
    fontFamily: WebFonts.family,
    fontFamilyFallback: [WebFonts.fallbackFamily],
    fontSize: 20,
    height: 25 / 20,
    fontWeight: WebFonts.weightBold,
  );
}
