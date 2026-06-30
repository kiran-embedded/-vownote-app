import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vownote/services/localization_service.dart';

class DisplayEngine {
  static late MediaQueryData _queryData;
  static double _screenWidth = 0;
  static double _scaleFactor = 1.0;
  static double _textScaleFactor = 1.0;

  static void init(BuildContext context) {
    _queryData = MediaQuery.of(context);
    _screenWidth = _queryData.size.width;
    _textScaleFactor = _queryData.textScaleFactor;

    // Base width for scaling is 375 (iPhone 13 mini / standard compact)
    // We cap the scale factor to avoid excessive scaling on large tablets
    _scaleFactor = (_screenWidth / 375.0).clamp(0.8, 1.4);
  }

  static double get scale => _scaleFactor;

  // Dynamic Font family loader supporting all TextStyle properties
  static TextStyle font({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    bool inherit = true,
  }) {
    final style = TextStyle(
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      inherit: inherit,
    );
    final lang = LocalizationService().currentLanguage;
    if (lang == 'ar') {
      return GoogleFonts.tajawal(textStyle: textStyle != null ? style.merge(textStyle) : style);
    } else if (lang == 'ml') {
      return GoogleFonts.notoSansMalayalam(textStyle: textStyle != null ? style.merge(textStyle) : style);
    } else {
      return GoogleFonts.inter(textStyle: textStyle != null ? style.merge(textStyle) : style);
    }
  }

  // Dynamic Heading font (Outfit font equivalent) supporting all TextStyle properties
  static TextStyle outfit({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    bool inherit = true,
  }) {
    final style = TextStyle(
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      inherit: inherit,
    );
    final lang = LocalizationService().currentLanguage;
    if (lang == 'ar') {
      return GoogleFonts.cairo(textStyle: textStyle != null ? style.merge(textStyle) : style);
    } else if (lang == 'ml') {
      return GoogleFonts.notoSansMalayalam(textStyle: textStyle != null ? style.merge(textStyle) : style);
    } else {
      return GoogleFonts.outfit(textStyle: textStyle != null ? style.merge(textStyle) : style);
    }
  }

  // Adaptive Font Size
  static double fontSize(double size) => size * _scaleFactor * _textScaleFactor;

  // Adaptive Padding/Margin
  static double spacing(double size) => size * _scaleFactor;

  // Adaptive Icon Size
  static double iconSize(double size) => size * _scaleFactor;

  // Adaptive Pill/Corner Radius
  static double radius(double size) => size * _scaleFactor;

  // Screen Width Helper
  static double get width => _screenWidth;

  // Is Tiny Device (e.g., iPhone SE, Small Androids)
  static bool get isTiny => _screenWidth < 360;
}
