import 'package:flutter/material.dart';

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
